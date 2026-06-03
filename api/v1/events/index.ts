import {
  authorize, cors, getDb, HttpError, normalizeAttendees, validateEventBody,
  type VercelRequest, type VercelResponse,
} from '../../_shared';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  cors(res);
  if (req.method === 'OPTIONS') return res.status(204).end();

  try {
    authorize(req);
    if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

    const body = req.body as Record<string, unknown>;
    validateEventBody(body);

    const sql = getDb();
    const id = crypto.randomUUID();

    const rows = await sql`
      INSERT INTO events
        (id, title, is_all_day, start_at, end_at, location, url, note, reminder, repeat_rule, attendees, calendar_id)
      VALUES (
        ${id},
        ${body.title as string},
        ${(body.is_all_day as boolean) ?? false},
        ${body.start_at as string},
        ${body.end_at as string},
        ${(body.location as string) ?? ''},
        ${(body.url as string) ?? ''},
        ${(body.note as string) ?? ''},
        ${(body.reminder as string) ?? 'none'},
        ${(body.repeat_rule as string) ?? 'never'},
        ${JSON.stringify(normalizeAttendees(body.attendees))}::jsonb,
        ${body.calendar_id as string}
      )
      RETURNING id, title, is_all_day, start_at, end_at, location, url, note,
                reminder, repeat_rule, attendees, calendar_id
    `;

    return res.status(201).json({ event: rows[0] });
  } catch (err) {
    if (err instanceof HttpError) return res.status(err.status).json({ error: err.message });
    return res.status(500).json({ error: err instanceof Error ? err.message : 'Unexpected error' });
  }
}
