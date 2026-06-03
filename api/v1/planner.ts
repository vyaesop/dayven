import {
  authorize, cors, getDb, HttpError, parseDateOnly,
  type VercelRequest, type VercelResponse,
} from '../_shared';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  cors(res);
  if (req.method === 'OPTIONS') return res.status(204).end();

  try {
    authorize(req);
    if (req.method !== 'GET') return res.status(405).json({ error: 'Method not allowed' });

    const sql = getDb();
    const selected = parseDateOnly(req.query.date as string | undefined);
    const monthStart = new Date(Date.UTC(selected.getUTCFullYear(), selected.getUTCMonth(), 1));
    const monthEnd = new Date(Date.UTC(selected.getUTCFullYear(), selected.getUTCMonth() + 1, 1));

    const [calendars, events] = await Promise.all([
      sql`SELECT id, name, color, position FROM calendars ORDER BY position, name`,
      sql`
        SELECT id, title, is_all_day, start_at, end_at, location, url, note,
               reminder, repeat_rule, attendees, calendar_id
        FROM events
        WHERE start_at >= ${monthStart.toISOString()}
          AND start_at <  ${monthEnd.toISOString()}
        ORDER BY start_at
      `,
    ]);

    return res.status(200).json({
      selected_date: selected.toISOString(),
      focused_month: monthStart.toISOString(),
      calendars,
      events,
    });
  } catch (err) {
    if (err instanceof HttpError) return res.status(err.status).json({ error: err.message });
    return res.status(500).json({ error: err instanceof Error ? err.message : 'Unexpected error' });
  }
}
