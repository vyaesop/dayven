export const FIREBASE_PROJECT_ID = 'vplanner-notification';

const JWK_URL =
  'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com';

export interface FirebaseUser {
  uid: string;
  email: string;
}

let _cachedKeys: (JsonWebKey & { kid: string })[] = [];
let _keysExpiry = 0;

async function getPublicKey(kid: string): Promise<CryptoKey> {
  if (Date.now() > _keysExpiry) {
    const res = await fetch(JWK_URL);
    const json = (await res.json()) as { keys: (JsonWebKey & { kid: string })[] };
    _cachedKeys = json.keys;
    _keysExpiry = Date.now() + 3_600_000;
  }
  const jwk = _cachedKeys.find((k) => k.kid === kid);
  if (!jwk) throw new Error('Unknown signing key');
  return crypto.subtle.importKey(
    'jwk',
    jwk,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['verify'],
  );
}

function b64url(s: string): Uint8Array {
  const b64 = s.replace(/-/g, '+').replace(/_/g, '/') + '=='.slice(0, (4 - (s.length % 4)) % 4);
  return Uint8Array.from(atob(b64), (c) => c.charCodeAt(0));
}

export async function verifyFirebaseToken(idToken: string): Promise<FirebaseUser> {
  const parts = idToken.split('.');
  if (parts.length !== 3) throw new Error('Malformed token');
  const [hB64, pB64, sigB64] = parts;

  const header = JSON.parse(new TextDecoder().decode(b64url(hB64))) as { kid: string; alg: string };
  const payload = JSON.parse(new TextDecoder().decode(b64url(pB64))) as {
    exp: number;
    iss: string;
    aud: string;
    sub: string;
    email?: string;
  };

  const now = Math.floor(Date.now() / 1000);
  if (payload.exp <= now) throw new Error('Token expired');
  if (payload.iss !== `https://securetoken.google.com/${FIREBASE_PROJECT_ID}`)
    throw new Error('Invalid issuer');
  if (payload.aud !== FIREBASE_PROJECT_ID) throw new Error('Invalid audience');
  if (!payload.sub) throw new Error('Missing subject');

  const key = await getPublicKey(header.kid);
  const data = new TextEncoder().encode(`${hB64}.${pB64}`);
  const signature = b64url(sigB64);
  const valid = await crypto.subtle.verify(
    'RSASSA-PKCS1-v1_5',
    key,
    signature as BufferSource,
    data as BufferSource,
  );
  if (!valid) throw new Error('Invalid signature');

  return { uid: payload.sub, email: payload.email ?? '' };
}
