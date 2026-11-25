import { env } from 'cloudflare:workers';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import worker from '../src/index';
import { ipScope } from '../src/crypto';

const R2 = { R2_ENDPOINT: 'https://acc.r2.cloudflarestorage.com', R2_BUCKET: 'isos', R2_ACCESS_KEY_ID: 'AKIDTEST', R2_SECRET_ACCESS_KEY: 'secret' };
const live = { ...env, ...R2 };
const BASE = 'https://dl.xerolinux.xyz';
const hex = (n: number) => 'a'.repeat(n);
const ENTRY = { name: 'xerolinux-2026.09-x86_64.iso', size: 5661872128, md5: hex(32), sha1: hex(40), sha256: hex(64) };
const reg = (edition: string, over: Record<string, unknown> = {}) => ({ action: 'register', edition, key: `${edition === 'test-edition' ? 'test/test-edition' : edition}/${ENTRY.name}`, date: 1788378373, ...ENTRY, ...over });

let free = true;
const call = (path: string, init: RequestInit & { ip?: string } = {}, e = live) => {
  const headers = new Headers(init.headers);
  if (init.ip !== undefined) headers.set('cf-connecting-ip', init.ip);
  return worker.fetch(new Request(BASE + path, { ...init, headers }), e);
};
const adminPost = (path: string, body: unknown, token = 'test-admin-token') =>
  call(path, { method: 'POST', headers: { authorization: `Bearer ${token}` }, body: typeof body === 'string' ? body : JSON.stringify(body) });
const dl = (ip: string, cookie = '', edition = 'std', name = ENTRY.name, e = live) =>
  call(`/dl/${edition}?dl=${encodeURIComponent(name)}`, { ip, headers: cookie ? { cookie } : {} }, e);
const counts = async () => (await env.DB.prepare('SELECT edition, file, n FROM counts ORDER BY edition, file').all()).results;
const staffCookie = async () => {
  const r = await call('/staff', { method: 'POST', ip: '9.9.9.9', body: new URLSearchParams({ key: 'test-staff-key' }) });
  return (r.headers.get('set-cookie') ?? '').split(';')[0];
};

beforeEach(async () => {
  free = true;
  await env.DB.batch(['counts', 'links', 'catalog', 'replaced', 'catalog_backups', 'staff_attempts'].map((t) => env.DB.prepare(`DELETE FROM ${t}`)));
  vi.spyOn(globalThis, 'fetch').mockImplementation(async (input) => {
    if (String(input instanceof Request ? input.url : input) === env.SETTINGS_URL) return Response.json({ free });
    throw new Error(`unexpected fetch ${String(input)}`);
  });
});
afterEach(() => vi.restoreAllMocks());

describe('ipScope', () => {
  it('keeps IPv4 and reduces IPv6 to its /64', () => {
    expect(ipScope('203.0.113.7')).toBe('203.0.113.7');
    expect(ipScope('2001:db8:1:2:3:4:5:6')).toBe('2001:db8:1:2::/64');
    expect(ipScope('2001:DB8:1:2::9')).toBe('2001:db8:1:2::/64');
    expect(ipScope('2001:db8::1')).toBe('2001:db8:0:0::/64');
    expect(ipScope('::ffff:198.51.100.4')).toBe('198.51.100.4');
    expect(ipScope('')).toBe('');
  });
});

describe('admin', () => {
  it('rejects a missing or wrong token', async () => {
    expect((await adminPost('/admin/register', reg('std'), 'nope')).status).toBe(401);
    expect((await call('/admin/register', { method: 'POST', body: '{}' })).status).toBe(401);
  });

  it('validates like register-iso.py', async () => {
    const err = async (body: unknown) => (await (await adminPost('/admin/register', body)).json<{ error: string }>()).error;
    expect(await err('nope')).toBe('invalid JSON');
    expect(await err({ action: 'drop', edition: 'std' })).toBe('unknown action');
    expect(await err({ ...reg('std'), extra: 1 })).toBe('unknown field: extra');
    expect(await err({ action: 'register', edition: 'std' })).toBe('missing field: date');
    expect(await err(reg('arm'))).toBe('unknown edition');
    expect(await err(reg('std', { name: '../x.iso', key: 'std/../x.iso' }))).toBe('invalid name');
    expect(await err(reg('std', { key: 'nvidia/' + ENTRY.name }))).toBe('key must be std/<name>');
    expect(await err(reg('std', { size: 0 }))).toBe('invalid size');
    expect(await err(reg('std', { date: 1000 }))).toBe('invalid date');
    expect(await err(reg('std', { sha256: 'XYZ' }))).toBe('invalid sha256');
    expect(await err('x'.repeat(5000))).toBe('input too large');
  });

  it('registers, replaces, is idempotent and refuses a changed entry under the same key', async () => {
    expect(await (await adminPost('/admin/register', reg('std'))).json()).toEqual({ ok: true, old_key: null });
    expect(await (await adminPost('/admin/register', reg('std'))).json()).toEqual({ ok: true, old_key: null });
    expect((await (await adminPost('/admin/register', reg('std', { size: 1 }))).json<{ error: string }>()).error).toBe('key already listed with different data');

    const next = reg('std', { name: 'xerolinux-2026.12-x86_64.iso', key: 'std/xerolinux-2026.12-x86_64.iso' });
    expect(await (await adminPost('/admin/register', next)).json()).toEqual({ ok: true, old_key: `std/${ENTRY.name}` });
    expect(await (await adminPost('/admin/register', next)).json()).toEqual({ ok: true, old_key: `std/${ENTRY.name}` });
    const q = await (await adminPost('/admin/register', { action: 'query', edition: 'std' })).json<{ entry: { name: string } }>();
    expect(q.entry.name).toBe('xerolinux-2026.12-x86_64.iso');
    expect((await env.DB.prepare('SELECT COUNT(*) AS n FROM catalog_backups').first<{ n: number }>())!.n).toBe(2);
  });

  it('imports counts even when the catalog was already registered', async () => {
    await adminPost('/admin/register', reg('std'));
    const r = await adminPost('/admin/import', { catalog: { std: [{ ...ENTRY, key: `std/${ENTRY.name}`, modified: 1788378373 }] }, counts: { std: { [ENTRY.name]: 3 } } });
    expect(await r.json()).toEqual({ ok: true, rows: 2 });
  });

  it('imports the VPS data once', async () => {
    const body = {
      catalog: { std: [{ ...ENTRY, key: `std/${ENTRY.name}`, modified: 1788378373 }], nvidia: [] },
      counts: { std: { [ENTRY.name]: 171, 'xerolinux-2026.06-x86_64.iso': 873, 'notes.txt': 4 }, nvidia: { 'xerolinux-nvidia-2026.06-x86_64.iso': 500 } },
    };
    expect(await (await adminPost('/admin/import', body)).json()).toEqual({ ok: true, rows: 5 });
    expect((await adminPost('/admin/import', body)).status).toBe(409);
    expect((await counts()).length).toBe(4);
  });
});

describe('stats', () => {
  it('reports release and all-time counts per edition, with CORS for the site only', async () => {
    await adminPost('/admin/import', {
      catalog: { std: [{ ...ENTRY, key: `std/${ENTRY.name}`, modified: 1788378373 }] },
      counts: { std: { [ENTRY.name]: 171, 'xerolinux-2026.06-x86_64.iso': 873, 'notes.txt': 4 }, nvidia: { 'xerolinux-nvidia-2026.06-x86_64.iso': 500 } },
    });
    const r = await call('/stats', { headers: { origin: 'https://xerolinux.xyz' } });
    expect(r.headers.get('access-control-allow-origin')).toBe('https://xerolinux.xyz');
    expect(await r.json()).toEqual({
      editions: { std: { file: ENTRY.name, version: '2026.09', size: ENTRY.size, date: 1788378373, md5: ENTRY.md5, sha1: ENTRY.sha1, sha256: ENTRY.sha256, release: 171, total: 1044 } },
      allTime: 1544,
      releaseTotal: 171,
    });
    const other = await call('/stats', { headers: { origin: 'https://evil.example' } });
    expect(other.headers.get('access-control-allow-origin')).toBeNull();
  });
});

describe('download', () => {
  beforeEach(async () => { await adminPost('/admin/register', reg('std')); });

  it('stays closed until settings.json says free, then hands out a 45 minute R2 link and counts it', async () => {
    free = false;
    expect((await dl('1.1.1.1')).status).toBe(403);
    expect(await counts()).toEqual([]);

    free = true;
    const r = await dl('1.1.1.1');
    expect(r.status).toBe(302);
    const loc = new URL(r.headers.get('location')!);
    expect(loc.origin + loc.pathname).toBe(`https://acc.r2.cloudflarestorage.com/isos/std/${ENTRY.name}`);
    expect(loc.searchParams.get('X-Amz-Expires')).toBe('2700');
    expect(loc.searchParams.get('X-Amz-Signature')).toMatch(/^[0-9a-f]{64}$/);
    expect(loc.searchParams.get('response-content-disposition')).toBe(`attachment; filename="${ENTRY.name}"`);
    expect(await counts()).toEqual([{ edition: 'std', file: ENTRY.name, n: 1 }]);
  });

  it('fails closed when settings.json cannot be read', async () => {
    vi.mocked(globalThis.fetch).mockRejectedValue(new Error('down'));
    expect((await dl('1.1.1.1')).status).toBe(403);
  });

  it('checks the whitelist before anything else and 503s without R2', async () => {
    expect((await dl('1.1.1.1', '', 'std', 'other.iso')).status).toBe(404);
    expect((await dl('1.1.1.1', '', 'arm')).status).toBe(404);
    const r = await dl('1.1.1.1', '', 'std', ENTRY.name, env);
    expect(r.status).toBe(503);
    expect(await r.text()).toBe('Downloads are temporarily unavailable. Please try again later.');
    expect(await counts()).toEqual([]);
  });

  it('gives each visitor 5 links for life, shared by a whole IPv6 /64', async () => {
    for (let i = 0; i < 5; i++) expect((await dl(`2001:db8:1:2::${i + 1}`)).status).toBe(302);
    const r = await dl('2001:db8:1:2:ffff::9');
    expect(r.status).toBe(403);
    expect(await r.text()).toBe('You have reached your download limit.');
    expect((await dl('2001:db8:1:3::1')).status).toBe(302);
    expect((await counts())[0]).toMatchObject({ n: 6 });
    const stored = (await env.DB.prepare('SELECT user FROM links').all<{ user: string }>()).results.map((r) => r.user);
    expect(stored.every((u) => /^[0-9a-f]{64}$/.test(u))).toBe(true);
  });

  it('refuses a request with no client IP', async () => {
    expect((await call(`/dl/std?dl=${ENTRY.name}`)).status).toBe(403);
  });
});

describe('staff', () => {
  beforeEach(async () => {
    await adminPost('/admin/register', reg('std'));
    await adminPost('/admin/register', reg('test-edition'));
  });

  it('sets a signed cookie for the right key only', async () => {
    const bad = await call('/staff', { method: 'POST', ip: '5.5.5.5', body: new URLSearchParams({ key: 'wrong' }) });
    expect(bad.status).toBe(403);
    expect(bad.headers.get('set-cookie')).toBeNull();
    const cookie = await staffCookie();
    expect(cookie).toMatch(/^xero_staff=[0-9a-f]{64}$/);
    expect(await (await call('/staff', { headers: { cookie } })).text()).toContain('Staff mode is on');
  });

  it('rate limits wrong keys', async () => {
    for (let i = 0; i < 10; i++) await call('/staff', { method: 'POST', ip: '6.6.6.6', body: new URLSearchParams({ key: 'x' }) });
    expect((await call('/staff', { method: 'POST', ip: '6.6.6.6', body: new URLSearchParams({ key: 'test-staff-key' }) })).status).toBe(429);
  });

  it('skips the free switch, the limit and the counter, and can reach test-edition', async () => {
    free = false;
    const cookie = await staffCookie();
    for (let i = 0; i < 7; i++) expect((await dl('7.7.7.7', cookie)).status).toBe(302);
    expect((await dl('7.7.7.7', cookie, 'test-edition')).status).toBe(302);
    expect((await dl('7.7.7.7', '', 'test-edition')).status).toBe(404);
    expect(await counts()).toEqual([]);
  });

  it('stops honouring old cookies when the staff key changes', async () => {
    const cookie = await staffCookie();
    expect((await dl('8.8.8.8', cookie, 'std', ENTRY.name, { ...live, STAFF_KEY: 'rotated' })).status).toBe(302);
    free = false;
    expect((await dl('8.8.8.8', cookie, 'std', ENTRY.name, { ...live, STAFF_KEY: 'rotated' })).status).toBe(403);
  });
});
