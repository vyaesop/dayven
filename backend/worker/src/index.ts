import { neon } from "@neondatabase/serverless";

type Env = {
  NEON_DATABASE_URL: string;
  API_BEARER_TOKEN?: string;
};

type CalendarRow = {
  id: string;
  name: string;
  color: string;
  position: number;
};

type EventRow = {
  id: string;
  title: string;
  is_all_day: boolean;
  start_at: string;
  end_at: string;
  location: string;
  url: string;
  note: string;
  reminder: string;
  repeat_rule: string;
  attendees: string[];
  calendar_id: string;
};

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method === "OPTIONS") {
      return new Response(null, {
        status: 204,
        headers: corsHeaders(),
      });
    }

    try {
      authorize(request, env);
      const url = new URL(request.url);
      const sql = neon(env.NEON_DATABASE_URL);

      if (request.method === "GET" && url.pathname === "/v1/planner") {
        return jsonResponse(await handleGetPlanner(url, sql));
      }

      if (request.method === "POST" && url.pathname === "/v1/events") {
        return jsonResponse(await handleCreateEvent(request, sql), 201);
      }

      if (request.method === "PUT" && url.pathname.startsWith("/v1/events/")) {
        const id = url.pathname.split("/").pop() ?? "";
        return jsonResponse(await handleUpdateEvent(id, request, sql));
      }

      if (
        request.method === "DELETE" &&
        url.pathname.startsWith("/v1/events/")
      ) {
        const id = url.pathname.split("/").pop() ?? "";
        await handleDeleteEvent(id, sql);
        return jsonResponse({ ok: true });
      }

      return jsonResponse({ error: "Not found" }, 404);
    } catch (error) {
      if (error instanceof HttpError) {
        return jsonResponse({ error: error.message }, error.status);
      }

      return jsonResponse(
        {
          error: error instanceof Error ? error.message : "Unexpected error",
        },
        500,
      );
    }
  },
};

async function handleGetPlanner(
  url: URL,
  sql: any,
): Promise<Record<string, unknown>> {
  const selectedDate = parseDateOnly(url.searchParams.get("date"));
  const monthStart = new Date(
    Date.UTC(selectedDate.getUTCFullYear(), selectedDate.getUTCMonth(), 1),
  );

  const calendars = (await sql`
    select id, name, color, position
    from calendars
    order by position asc, name asc
  `) as CalendarRow[];

  // Return the full event set: the client expands recurrence + navigates months
  // in memory, so a month-bounded query would hide other months and series
  // anchored elsewhere.
  const events = (await sql`
    select id, title, is_all_day, start_at, end_at, location, url, note, reminder, repeat_rule, attendees, calendar_id
    from events
    order by start_at asc
  `) as EventRow[];

  return {
    selected_date: selectedDate.toISOString(),
    focused_month: monthStart.toISOString(),
    calendars,
    events,
  };
}

async function handleCreateEvent(
  request: Request,
  sql: any,
): Promise<Record<string, unknown>> {
  const body = await request.json<Partial<EventRow>>();
  validateEventBody(body);
  const id = crypto.randomUUID();

  const rows = (await sql`
    insert into events (id, title, is_all_day, start_at, end_at, location, url, note, reminder, repeat_rule, attendees, calendar_id)
    values (
      ${id},
      ${body.title!},
      ${body.is_all_day ?? false},
      ${body.start_at!},
      ${body.end_at!},
      ${body.location ?? ""},
      ${body.url ?? ""},
      ${body.note ?? ""},
      ${body.reminder ?? "none"},
      ${body.repeat_rule ?? "never"},
      ${JSON.stringify(normalizeAttendees(body.attendees))}::jsonb,
      ${body.calendar_id!}
    )
    returning id, title, is_all_day, start_at, end_at, location, url, note, reminder, repeat_rule, attendees, calendar_id
  `) as EventRow[];

  return { event: rows[0] };
}

async function handleUpdateEvent(
  id: string,
  request: Request,
  sql: any,
): Promise<Record<string, unknown>> {
  if (!id) {
    throw new HttpError(400, "Missing event id");
  }

  const body = await request.json<Partial<EventRow>>();
  validateEventBody(body);

  const rows = (await sql`
    update events
    set
      title = ${body.title!},
      is_all_day = ${body.is_all_day ?? false},
      start_at = ${body.start_at!},
      end_at = ${body.end_at!},
      location = ${body.location ?? ""},
      url = ${body.url ?? ""},
      note = ${body.note ?? ""},
      reminder = ${body.reminder ?? "none"},
      repeat_rule = ${body.repeat_rule ?? "never"},
      attendees = ${JSON.stringify(normalizeAttendees(body.attendees))}::jsonb,
      calendar_id = ${body.calendar_id!},
      updated_at = now()
    where id = ${id}
    returning id, title, is_all_day, start_at, end_at, location, url, note, reminder, repeat_rule, attendees, calendar_id
  `) as EventRow[];

  if (rows.length === 0) {
    throw new HttpError(404, "Event not found");
  }

  return { event: rows[0] };
}

async function handleDeleteEvent(id: string, sql: any): Promise<void> {
  if (!id) {
    throw new HttpError(400, "Missing event id");
  }

  await sql`
    delete from events
    where id = ${id}
  `;
}

function validateEventBody(body: Partial<EventRow>): void {
  if (!body.title || !body.start_at || !body.end_at || !body.calendar_id) {
    throw new HttpError(400, "Missing required event fields");
  }
}

function normalizeAttendees(input: unknown): string[] {
  if (!Array.isArray(input)) {
    return [];
  }

  return [
    ...new Set(
      input
        .map((item) => String(item).trim())
        .filter((item) => item.length > 0),
    ),
  ];
}

function parseDateOnly(input: string | null): Date {
  if (!input) {
    return startOfUtcDay(new Date());
  }

  const parsed = new Date(input);
  if (Number.isNaN(parsed.getTime())) {
    throw new HttpError(400, "Invalid date query parameter");
  }

  return startOfUtcDay(parsed);
}

function startOfUtcDay(date: Date): Date {
  return new Date(
    Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()),
  );
}

function authorize(request: Request, env: Env): void {
  // NOTE: This Worker is a legacy, single-tenant backend. The canonical backend
  // is the Firebase-authenticated, per-user Vercel API under /api. This Worker
  // does not scope data per user, so it must never run unauthenticated: if no
  // shared token is configured we fail closed rather than exposing all data.
  const expectedToken = env.API_BEARER_TOKEN?.trim();
  if (!expectedToken) {
    throw new HttpError(503, "Backend not configured: API_BEARER_TOKEN is required");
  }

  const authHeader = request.headers.get("authorization") ?? "";
  const providedToken = authHeader.replace(/^Bearer\s+/i, "").trim();
  if (providedToken !== expectedToken) {
    throw new HttpError(401, "Unauthorized");
  }
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      ...corsHeaders(),
    },
  });
}

function corsHeaders(): Record<string, string> {
  return {
    "access-control-allow-origin": "*",
    "access-control-allow-methods": "GET,POST,PUT,DELETE,OPTIONS",
    "access-control-allow-headers": "content-type,authorization",
  };
}

class HttpError extends Error {
  constructor(
    readonly status: number,
    message: string,
  ) {
    super(message);
  }
}
