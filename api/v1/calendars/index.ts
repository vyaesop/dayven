import {
  authenticateUser, cors, getDb, HttpError,
  type VercelRequest, type VercelResponse,
} from '../../_shared';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  cors(res);
  if (req.method === 'OPTIONS') return res.status(204).end();

  try {
    const uid = await authenticateUser(req);
    if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

    const body = (req.body ?? {}) as Record<string, unknown>;
    const name = typeof body.name === 'string' ? body.name.trim() : '';
    const color = typeof body.color === 'string' ? body.color.trim() : '';
    if (!name) throw new HttpError(400, 'Missing calendar name');
    if (!color) throw new HttpError(400, 'Missing calendar color');

    const sql = getDb();
    // Per-user, globally-unique id (matches the seeding scheme in planner.ts).
    const id = `${uid}-${crypto.randomUUID()}`;

    // Place the new calendar after the user's existing ones.
    const [{ next }] = (await sql`
      SELECT COALESCE(MAX(position), -1) + 1 AS next FROM calendars WHERE user_id = ${uid}
    `) as [{ next: number }];

    const rows = await sql`
      INSERT INTO calendars (id, name, color, position, user_id)
      VALUES (${id}, ${name}, ${color}, ${next}, ${uid})
      RETURNING id, name, color, position
    `;

    return res.status(201).json({ calendar: rows[0] });
  } catch (err) {
    if (err instanceof HttpError) return res.status(err.status).json({ error: err.message });
    return res.status(500).json({ error: err instanceof Error ? err.message : 'Unexpected error' });
  }
}
