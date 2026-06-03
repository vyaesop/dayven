import {
  authenticateUser, cors, getDb, HttpError,
  type VercelRequest, type VercelResponse,
} from '../../_shared';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  cors(res);
  if (req.method === 'OPTIONS') return res.status(204).end();

  try {
    if (req.method !== 'DELETE') return res.status(405).json({ error: 'Method not allowed' });

    // Re-read the raw Authorization header so we can pass it to Firebase for deletion.
    const authHeader = (req.headers['authorization'] ?? '') as string;
    const idToken = authHeader.replace(/^Bearer\s+/i, '').trim();

    const uid = await authenticateUser(req);
    const sql = getDb();

    // Wipe all user data from NeonDB
    await sql`DELETE FROM events    WHERE user_id = ${uid}`;
    await sql`DELETE FROM calendars WHERE user_id = ${uid}`;

    // Delete Firebase account via the Identity Toolkit REST API.
    // Uses the user's own ID token — no service account required.
    const apiKey = process.env.FIREBASE_WEB_API_KEY;
    if (apiKey) {
      await fetch(
        `https://identitytoolkit.googleapis.com/v1/accounts:delete?key=${apiKey}`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ idToken }),
        },
      );
    }

    return res.status(200).json({ ok: true });
  } catch (err) {
    if (err instanceof HttpError) return res.status(err.status).json({ error: err.message });
    return res.status(500).json({ error: err instanceof Error ? err.message : 'Unexpected error' });
  }
}
