import {
  authenticateUser, cors, getDb, HttpError,
  type VercelRequest, type VercelResponse,
} from '../../_shared';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  cors(res);
  if (req.method === 'OPTIONS') return res.status(204).end();

  try {
    const uid = await authenticateUser(req);
    const id = req.query.id as string;
    if (!id) return res.status(400).json({ error: 'Missing calendar id' });

    const sql = getDb();

    if (req.method === 'PUT') {
      const body = (req.body ?? {}) as Record<string, unknown>;
      const name = typeof body.name === 'string' ? body.name.trim() : '';
      const color = typeof body.color === 'string' ? body.color.trim() : undefined;
      if (!name && color === undefined) throw new HttpError(400, 'Nothing to update');

      // Update an existing calendar (covers renames, which send only `name`).
      const updated = await sql`
        UPDATE calendars
        SET
          name       = COALESCE(${name || null}, name),
          color      = COALESCE(${color ?? null}, color),
          updated_at = now(),
          deleted_at = NULL
        WHERE id = ${id} AND user_id = ${uid}
        RETURNING id, name, color, position
      `;
      if (updated.length > 0) return res.status(200).json({ calendar: updated[0] });

      // No existing row: a calendar created offline (with a client-generated
      // id) is being synced for the first time. Insert it when we have enough
      // to define it (name + color).
      if (name && color) {
        const [{ next }] = (await sql`
          SELECT COALESCE(MAX(position), -1) + 1 AS next FROM calendars WHERE user_id = ${uid}
        `) as [{ next: number }];
        const inserted = await sql`
          INSERT INTO calendars (id, name, color, position, user_id)
          VALUES (${id}, ${name}, ${color}, ${next}, ${uid})
          ON CONFLICT (id) DO NOTHING
          RETURNING id, name, color, position
        `;
        if (inserted.length > 0) return res.status(201).json({ calendar: inserted[0] });
      }

      return res.status(404).json({ error: 'Calendar not found' });
    }

    return res.status(405).json({ error: 'Method not allowed' });
  } catch (err) {
    if (err instanceof HttpError) return res.status(err.status).json({ error: err.message });
    return res.status(500).json({ error: err instanceof Error ? err.message : 'Unexpected error' });
  }
}
