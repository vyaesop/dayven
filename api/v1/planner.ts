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

    // Optional delta sync: when the client passes a `since` watermark we return
    // only rows changed after it — including tombstoned rows so deletions made
    // on other devices propagate. Without `since` we return the full live set
    // (tombstones excluded). The client loads once and then expands recurring
    // series + navigates months entirely in memory, so a month-bounded query
    // would hide events in other months; personal calendars are small enough
    // that returning the full set is fine.
    const sinceRaw = req.query.since as string | undefined;
    const since = sinceRaw ? new Date(sinceRaw) : null;
    if (since && Number.isNaN(since.getTime())) {
      return res.status(400).json({ error: 'Invalid since parameter' });
    }
    const serverTime = new Date().toISOString();

    const [calendars, events] = since
      ? await Promise.all([
          sql`
            SELECT id, name, color, position, deleted_at
            FROM calendars
            WHERE user_id = ${uid} AND updated_at > ${since.toISOString()}
            ORDER BY position, name
          `,
          sql`
            SELECT id, title, is_all_day, start_at, end_at, location, url, note,
                   reminder, repeat_rule, attendees, calendar_id, updated_at, deleted_at
            FROM events
            WHERE user_id = ${uid} AND updated_at > ${since.toISOString()}
            ORDER BY start_at
          `,
        ])
      : await Promise.all([
          sql`
            SELECT id, name, color, position
            FROM calendars
            WHERE user_id = ${uid} AND deleted_at IS NULL
            ORDER BY position, name
          `,
          sql`
            SELECT id, title, is_all_day, start_at, end_at, location, url, note,
                   reminder, repeat_rule, attendees, calendar_id, updated_at
            FROM events
            WHERE user_id = ${uid} AND deleted_at IS NULL
            ORDER BY start_at
          `,
        ]);

    return res.status(200).json({
      selected_date: selected.toISOString(),
      focused_month: monthStart.toISOString(),
      server_time: serverTime,
      calendars,
      events,
    });
  } catch (err) {
    if (err instanceof HttpError) return res.status(err.status).json({ error: err.message });
    return res.status(500).json({ error: err instanceof Error ? err.message : 'Unexpected error' });
  }
}
