import {
  authenticateUser, cors, getDb, HttpError, normalizeAttendees, validateEventBody,
  type VercelRequest, type VercelResponse,
} from '../../_shared';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  cors(res);
  if (req.method === 'OPTIONS') return res.status(204).end();

  try {
    const uid = await authenticateUser(req);
    const id = req.query.id as string;
    if (!id) return res.status(400).json({ error: 'Missing event id' });

    const sql = getDb();

    if (req.method === 'DELETE') {
      // Soft delete: tombstone the row so the deletion can sync to other
      // devices (via a `since` delta query) and remain recoverable.
      await sql`
        UPDATE events
        SET deleted_at = now(), updated_at = now()
        WHERE id = ${id} AND user_id = ${uid}
      `;
      return res.status(200).json({ ok: true });
    }

    if (req.method === 'PUT') {
      const body = req.body as Record<string, unknown>;
      validateEventBody(body);

      // Idempotent upsert keyed by the client-generated id. This lets an event
      // created offline (whose id the server has never seen) sync on the first
      // PUT, and makes replaying a queued mutation safe. `updated_at` is taken
      // from the client so last-write-wins ordering is preserved across
      // devices; the `WHERE user_id` guard stops one user overwriting another's
      // row even if a client guesses an id.
      const updatedAt =
        typeof body.updated_at === 'string' && body.updated_at
          ? body.updated_at
          : new Date().toISOString();

      const rows = await sql`
        INSERT INTO events
          (id, title, is_all_day, start_at, end_at, location, url, note,
           reminder, repeat_rule, attendees, calendar_id, user_id, updated_at, deleted_at)
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
          ${body.calendar_id as string},
          ${uid},
          ${updatedAt},
          NULL
        )
        ON CONFLICT (id) DO UPDATE SET
          title       = EXCLUDED.title,
          is_all_day  = EXCLUDED.is_all_day,
          start_at    = EXCLUDED.start_at,
          end_at      = EXCLUDED.end_at,
          location    = EXCLUDED.location,
          url         = EXCLUDED.url,
          note        = EXCLUDED.note,
          reminder    = EXCLUDED.reminder,
          repeat_rule = EXCLUDED.repeat_rule,
          attendees   = EXCLUDED.attendees,
          calendar_id = EXCLUDED.calendar_id,
          updated_at  = EXCLUDED.updated_at,
          deleted_at  = NULL
        WHERE events.user_id = ${uid}
        RETURNING id, title, is_all_day, start_at, end_at, location, url, note,
                  reminder, repeat_rule, attendees, calendar_id
      `;
      if (rows.length === 0) return res.status(404).json({ error: 'Event not found' });
      return res.status(200).json({ event: rows[0] });
    }

    return res.status(405).json({ error: 'Method not allowed' });
  } catch (err) {
    if (err instanceof HttpError) return res.status(err.status).json({ error: err.message });
    return res.status(500).json({ error: err instanceof Error ? err.message : 'Unexpected error' });
  }
}
