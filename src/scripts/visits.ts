import { COUNT_HOSTS, FIREBASE } from '../config';

interface Token { id: string; refresh: string; exp: number }

const TOKEN_KEY = 'xero-anon';
const TOTAL_KEY = 'xero-visits';
const DOCS = `https://firestore.googleapis.com/v1/projects/${FIREBASE.projectId}/databases/(default)/documents`;

const read = (k: string) => { try { return localStorage.getItem(k); } catch { return null; } };
const write = (k: string, v: string) => { try { localStorage.setItem(k, v); } catch { /* storage blocked */ } };

async function post(url: string, body: object, token?: string) {
  const r = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: JSON.stringify(body),
  });
  if (!r.ok) throw new Error(String(r.status));
  return r.json();
}

// Anonymous Firebase sign-in over REST, kept across visits like the old site's SDK session.
async function token(): Promise<string> {
  let t: Token | null = null;
  try { t = JSON.parse(read(TOKEN_KEY) ?? 'null'); } catch { t = null; }
  if (t && t.exp > Date.now() + 60_000) return t.id;
  const signUp = () => post(`https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${FIREBASE.apiKey}`, { returnSecureToken: true });
  const d = t
    ? await post(`https://securetoken.googleapis.com/v1/token?key=${FIREBASE.apiKey}`, { grant_type: 'refresh_token', refresh_token: t.refresh }).catch(signUp)
    : await signUp();
  const id = d.idToken ?? d.id_token;
  const next: Token = { id, refresh: d.refreshToken ?? d.refresh_token, exp: Date.now() + Number(d.expiresIn ?? d.expires_in) * 1000 };
  write(TOKEN_KEY, JSON.stringify(next));
  return id;
}

// Server-side sum: billed one read per 1000 docs, where listing the collection costs one read per doc.
async function total(id: string) {
  const d = await post(`${DOCS}:runAggregationQuery`, {
    structuredAggregationQuery: {
      aggregations: [{ alias: 'total', sum: { field: { fieldPath: 'views' } } }],
      structuredQuery: { from: [{ collectionId: 'views' }] },
    },
  }, id);
  const v = d[0]?.result?.aggregateFields?.total;
  const n = Number(v?.integerValue ?? v?.doubleValue);
  if (!n) throw new Error('no total');
  return n;
}

// Same page ids and once-per-visitor-per-page flag as the old site, so returning visitors are not counted again.
async function count(id: string) {
  const pageId = location.pathname.replace(/^\//, '').replace(/\/$/, '').replace(/\//g, '-') || 'home';
  const flag = `viewed-${pageId}`;
  if (!COUNT_HOSTS.includes(location.hostname) || read(flag)) return;
  write(flag, '1');
  await post(`${DOCS}:commit`, {
    writes: [{
      update: { name: `projects/${FIREBASE.projectId}/databases/(default)/documents/views/${pageId}`, fields: {} },
      updateMask: { fieldPaths: [] },
      updateTransforms: [{ fieldPath: 'views', increment: { integerValue: '1' } }],
    }],
  }, id);
}

function show(n: number) {
  document.querySelectorAll<HTMLElement>('[data-visits-n]').forEach((el) => { el.textContent = n.toLocaleString('en-US'); });
}

export async function initVisits() {
  const cached = Number(read(TOTAL_KEY));
  if (cached) show(cached);
  try {
    const id = await token();
    await count(id);
    const n = await total(id);
    show(n);
    write(TOTAL_KEY, String(n));
  } catch { /* counter unavailable; keep the cached figure */ }
}
