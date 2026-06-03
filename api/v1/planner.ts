import {
  authenticateUser, cors, getDb, HttpError, parseDateOnly,
  type VercelRequest, type VercelResponse,
} from '../_shared';

const DEFAULT_CALENDARS = [
  { suffix: 'calendar', name: 'Calendar', color: '#5B8CFF', position: 0 },
  { suffix: 'exercise', name: 'Exercise', color: '#4CAF50', position: 1 },
  { suffix: 'family',   name: 'Family',   color: '#FF9800', position: 2 },
  { suffix: 'friends',  name: 'Friends',  color: '#E91E63', position: 3 },
  { suffix: 'work',     name: 'Work',     color: '#607D8B', position: 4 },
];

export default async function handler(req: VercelRequest, res: VercelResponse) {
  cors(res);
  if (req.method === 'OPTIONS') return res.status(204).end();

  try {
    const uid = await authenticateUser(req);
    if (req.method !== 'GET') return res.status(405).json({ error: 'Method not allowed' });

    const sql = getDb();

    // Seed default calendars on first sign-in
    const [{ count }] = await sql`
      SELECT COUNT(*)::int AS count FROM calendars WHERE user_id = ${uid}
    ` as [{ count: number }];

    if (count === 0) {
      for (const cal of DEFAULT_CALENDARS) {
        await sql`
          INSERT INTO calendars (id, name, color, position, user_id)
          VALUES (${`${uid}-${cal.suffix}`}, ${cal.name}, ${cal.color}, ${cal.position}, ${uid})
          ON CONFLICT (id) DO NOTHING
        `;
      }
    }

    const selected = parseDateOnly(req.query.date as string | undefined);
    const monthStart = new Date(Date.UTC(selected.getUTCFullYear(), selected.getUTCMonth(), 1));
    const monthEnd   = new Date(Date.UTC(selected.getUTCFullYear(), selected.getUTCMonth() + 1, 1));

    const [calendars, events] = await Promise.all([
      sql`
        SELECT id, name, color, position
        FROM calendars
        WHERE user_id = ${uid}
        ORDER BY position, name
      `,
      sql`
        SELECT id, title, is_all_day, start_at, end_at, location, url, note,
               reminder, repeat_rule, attendees, calendar_id
        FROM events
        WHERE user_id = ${uid}
          AND start_at >= ${monthStart.toISOString()}
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
