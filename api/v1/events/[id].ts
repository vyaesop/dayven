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
      await sql`DELETE FROM events WHERE id = ${id} AND user_id = ${uid}`;
      return res.status(200).json({ ok: true });
    }

    if (req.method === 'PUT') {
      const body = req.body as Record<string, unknown>;
      validateEventBody(body);

      const rows = await sql`
        UPDATE events
        SET
          title       = ${body.title as string},
          is_all_day  = ${(body.is_all_day as boolean) ?? false},
          start_at    = ${body.start_at as string},
          end_at      = ${body.end_at as string},
          location    = ${(body.location as string) ?? ''},
          url         = ${(body.url as string) ?? ''},
          note        = ${(body.note as string) ?? ''},
          reminder    = ${(body.reminder as string) ?? 'none'},
          repeat_rule = ${(body.repeat_rule as string) ?? 'never'},
          attendees   = ${JSON.stringify(normalizeAttendees(body.attendees))}::jsonb,
          calendar_id = ${body.calendar_id as string},
          updated_at  = now()
        WHERE id = ${id} AND user_id = ${uid}
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
