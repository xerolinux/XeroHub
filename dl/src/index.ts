import type { Env } from './env';
import { Fail, PREFIX, PUBLIC_EDITIONS, current, importVps, register, type Entry } from './catalog';
import { hmac, ipScope, safeEqual } from './crypto';
import { presign, r2Ready } from './r2';

const LIMIT = 5;
const STAFF_COOKIE = 'xero_staff';
const STAFF_TRIES = 10;
const STAFF_WINDOW = 900;

const MSG = {
  notFound: 'File not found.',
  unavailable: 'Downloads are temporarily unavailable. Please try again later.',
  limit: 'You have reached your download limit.',
  notFree: 'XeroLinux downloads open here once the ISO goes free.',
};

const text = (body: string, status: number, headers: Record<string, string> = {}) =>
  new Response(body, { status, headers: { 'content-type': 'text/plain; charset=utf-8', 'cache-control': 'no-store', 'x-content-type-options': 'nosniff', ...headers } });
const json = (body: unknown, status = 200, headers: Record<string, string> = {}) =>
  new Response(JSON.stringify(body), { status, headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store', 'x-content-type-options': 'nosniff', ...headers } });

// The same switch the site reads: public/settings.json { "free": true } opens downloads.
async function isFree(env: Env) {
  try {
    const r = await fetch(env.SETTINGS_URL, { cf: { cacheTtl: 60, cacheEverything: true } });
    if (!r.ok) return false;
    const d = await r.json<{ free?: unknown }>();
    return d.free === true;
  } catch {
    return false;
  }
}

const visitor = (req: Request, env: Env) => {
  const scope = ipScope(req.headers.get('cf-connecting-ip') ?? '');
  return scope ? hmac(env.SALT, `ip:${scope}`) : Promise.resolve('');
};

const staffToken = (env: Env) => hmac(env.SALT, `staff:${env.STAFF_KEY}`);

async function isStaff(req: Request, env: Env) {
  const m = (req.headers.get('cookie') ?? '').match(new RegExp(`(?:^|;\\s*)${STAFF_COOKIE}=([0-9a-f]{64})`));
  if (!m || !env.STAFF_KEY) return false;
  return safeEqual(m[1], await staffToken(env), env.SALT);
}

function cors(req: Request, env: Env): Record<string, string> {
  const origin = req.headers.get('origin') ?? '';
  const ok = env.ORIGINS.split(',').map((o) => o.trim()).includes(origin);
  return ok ? { 'access-control-allow-origin': origin, 'access-control-allow-methods': 'GET, OPTIONS', 'access-control-max-age': '600', vary: 'Origin' } : { vary: 'Origin' };
}

async function stats(env: Env) {
  const rows = (await env.DB.prepare('SELECT edition, file, n FROM counts').all<{ edition: string; file: string; n: number }>()).results;
  const editions: Record<string, unknown> = {};
  let allTime = 0, releaseTotal = 0;
  for (const id of PUBLIC_EDITIONS) {
    const f = await current(env.DB, id);
    const mine = rows.filter((r) => r.edition === id);
    const total = mine.filter((r) => r.file.toLowerCase().endsWith('.iso')).reduce((s, r) => s + r.n, 0);
    allTime += total;
    if (!f) continue;
    const release = mine.find((r) => r.file === f.name)?.n ?? 0;
    releaseTotal += release;
    editions[id] = {
      file: f.name, version: f.name.match(/\d{4}\.\d{2}(?:\.\d+)?/)?.[0] ?? '', size: f.size, date: f.modified,
      md5: f.md5, sha1: f.sha1, sha256: f.sha256, release, total,
    };
  }
  return { editions, allTime, releaseTotal };
}

// Same steps and order as KDEPlasma/<edition>/index.php ?dl=.
async function download(req: Request, env: Env, edition: string, name: string) {
  const staff = await isStaff(req, env);
  if (!(edition in PREFIX) || (!staff && !(PUBLIC_EDITIONS as readonly string[]).includes(edition))) return text(MSG.notFound, 404);
  if (!staff && !(await isFree(env))) return text(MSG.notFree, 403);

  const file: Entry | null = await current(env.DB, edition);
  if (!file || file.name !== name.trim()) return text(MSG.notFound, 404);
  if (!r2Ready(env)) return text(MSG.unavailable, 503);

  if (!staff) {
    const user = await visitor(req, env);
    if (!user) return text(MSG.limit, 403);
    let taken: { n: number } | null;
    try {
      taken = await env.DB.prepare('INSERT INTO links (user, n) VALUES (?, 1) ON CONFLICT(user) DO UPDATE SET n = n + 1 WHERE n < ? RETURNING n').bind(user, LIMIT).first<{ n: number }>();
    } catch {
      return text(MSG.unavailable, 503);
    }
    if (!taken) return text(MSG.limit, 403);
    await env.DB.prepare('INSERT INTO counts (edition, file, n) VALUES (?, ?, 1) ON CONFLICT(edition, file) DO UPDATE SET n = n + 1').bind(edition, file.name).run();
  }

  return new Response(null, { status: 302, headers: { location: await presign(env, file), 'cache-control': 'no-store' } });
}

const page = (body: string, status = 200, headers: Record<string, string> = {}) =>
  new Response(`<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="noindex"><title>Staff</title><style>body{margin:0;min-height:100vh;display:grid;place-items:center;background:#16181d;color:#e8e8ee;font:15px system-ui,sans-serif}form,p{display:flex;gap:8px;margin:0}input,button{font:inherit;padding:10px 12px;border-radius:8px;border:1px solid #4a4c6a;background:#22242c;color:inherit}button{background:#5d5ef7;border-color:#5d5ef7;color:#fff}</style></head><body>${body}</body></html>`, {
    status,
    headers: { 'content-type': 'text/html; charset=utf-8', 'cache-control': 'no-store', 'content-security-policy': "default-src 'none'; style-src 'unsafe-inline'; form-action 'self'; frame-ancestors 'none'", 'x-content-type-options': 'nosniff', ...headers },
  });

const staffForm = (note = '', status = 200) => page(`<form method="post" action="/staff">${note ? `<p>${note}</p>` : ''}<input type="password" name="key" autocomplete="current-password" aria-label="Staff key" required><button>Enter</button></form>`, status);

async function staffLogin(req: Request, env: Env) {
  const user = (await visitor(req, env)) || 'unknown';
  const now = Math.floor(Date.now() / 1000);
  const row = await env.DB.prepare('SELECT n, t FROM staff_attempts WHERE user = ?').bind(user).first<{ n: number; t: number }>();
  if (row && now - row.t < STAFF_WINDOW && row.n >= STAFF_TRIES) return page('<p>Too many attempts. Try again later.</p>', 429);

  const key = String((await req.formData()).get('key') ?? '');
  if (!env.STAFF_KEY || !(await safeEqual(key, env.STAFF_KEY, env.SALT))) {
    const n = row && now - row.t < STAFF_WINDOW ? row.n + 1 : 1;
    await env.DB.prepare('INSERT INTO staff_attempts (user, n, t) VALUES (?, ?, ?) ON CONFLICT(user) DO UPDATE SET n = excluded.n, t = excluded.t').bind(user, n, now).run();
    return staffForm('Wrong key.', 403);
  }
  await env.DB.prepare('DELETE FROM staff_attempts WHERE user = ?').bind(user).run();
  return page('<p>Staff mode is on for this browser.</p>', 200, {
    'set-cookie': `${STAFF_COOKIE}=${await staffToken(env)}; Path=/; Max-Age=31536000; HttpOnly; Secure; SameSite=Lax`,
  });
}

async function admin(req: Request, env: Env, fn: (db: D1Database, raw: string) => Promise<unknown>) {
  const auth = req.headers.get('authorization') ?? '';
  if (!env.ADMIN_TOKEN || !auth.startsWith('Bearer ') || !(await safeEqual(auth.slice(7), env.ADMIN_TOKEN, env.SALT))) return json({ ok: false, error: 'unauthorized' }, 401);
  try {
    return json(await fn(env.DB, await req.text()));
  } catch (e) {
    if (e instanceof Fail) return json({ ok: false, error: e.message }, e.message === 'already imported' ? 409 : 400);
    return json({ ok: false, error: 'internal error' }, 500);
  }
}

export default {
  async fetch(req: Request, env: Env): Promise<Response> {
    const url = new URL(req.url);
    const path = url.pathname.replace(/\/+$/, '') || '/';

    if (path === '/stats') {
      if (req.method === 'OPTIONS') return new Response(null, { status: 204, headers: cors(req, env) });
      if (req.method !== 'GET') return text('Method not allowed.', 405);
      return json(await stats(env), 200, { ...cors(req, env), 'cache-control': 'public, max-age=60' });
    }

    const dl = path.match(/^\/dl\/([a-z-]+)$/);
    if (dl && req.method === 'GET') return download(req, env, dl[1], url.searchParams.get('dl') ?? '');

    if (path === '/staff') {
      if (req.method === 'POST') return staffLogin(req, env);
      if (req.method === 'GET') return (await isStaff(req, env)) ? page('<p>Staff mode is on for this browser.</p>') : staffForm();
    }

    if (req.method === 'POST' && path === '/admin/register') return admin(req, env, register);
    if (req.method === 'POST' && path === '/admin/import') return admin(req, env, importVps);

    return text('Not found.', 404);
  },
} satisfies ExportedHandler<Env>;
