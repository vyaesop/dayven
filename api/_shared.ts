import type { VercelRequest, VercelResponse } from '@vercel/node';
import { neon } from '@neondatabase/serverless';
import { verifyFirebaseToken } from './_firebase_auth';

export type { VercelRequest, VercelResponse };

export function getDb() {
  const url = process.env.NEON_DATABASE_URL;
  if (!url) throw new HttpError(500, 'NEON_DATABASE_URL not configured');
  return neon(url);
}

export async function authenticateUser(req: VercelRequest): Promise<string> {
  const header = (req.headers['authorization'] ?? '') as string;
  const token = header.replace(/^Bearer\s+/i, '').trim();
  if (!token) throw new HttpError(401, 'Unauthorized');
  try {
    const { uid } = await verifyFirebaseToken(token);
    return uid;
  } catch (err) {
    throw new HttpError(401, `Unauthorized: ${err instanceof Error ? err.message : 'invalid token'}`);
  }
}

export function cors(res: VercelResponse): void {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,PUT,DELETE,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'content-type,authorization');
}

export class HttpError extends Error {
  constructor(readonly status: number, message: string) {
    super(message);
  }
}

export function normalizeAttendees(input: unknown): string[] {
  if (!Array.isArray(input)) return [];
  return [...new Set(input.map((i) => String(i).trim()).filter((i) => i.length > 0))];
}

export function parseDateOnly(value: string | string[] | undefined): Date {
  const input = Array.isArray(value) ? value[0] : value;
  if (!input) return startOfUtcDay(new Date());
  const parsed = new Date(input);
  if (Number.isNaN(parsed.getTime())) throw new HttpError(400, 'Invalid date');
  return startOfUtcDay(parsed);
}

function startOfUtcDay(d: Date): Date {
  return new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()));
}

export function validateEventBody(body: Record<string, unknown>): void {
  if (!body.title || !body.start_at || !body.end_at || !body.calendar_id) {
    throw new HttpError(400, 'Missing required event fields');
  }
}
