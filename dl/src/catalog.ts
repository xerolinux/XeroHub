export interface Entry { name: string; key: string; size: number; modified: number; md5: string; sha1: string; sha256: string }

export const PUBLIC_EDITIONS = ['std', 'nvidia'] as const;
// Same editions and key prefixes as register-iso.py; test-edition is for checking uploads, staff only.
export const PREFIX: Record<string, string> = { std: 'std/', nvidia: 'nvidia/', 'test-edition': 'test/test-edition/' };

const MIN_DATE = 1577836800;
const NAME_RE = /^[A-Za-z0-9][A-Za-z0-9._-]*\.[iI][sS][oO]$/;
const HEX_LEN = { md5: 32, sha1: 40, sha256: 64 } as const;
const REGISTER_FIELDS = ['action', 'edition', 'key', 'name', 'size', 'date', 'md5', 'sha1', 'sha256'];
const QUERY_FIELDS = ['action', 'edition'];

export class Fail extends Error {}

const isInt = (v: unknown): v is number => typeof v === 'number' && Number.isInteger(v);

export function validateEntry(e: Record<string, unknown>, edition: string, date: unknown, now = Date.now() / 1000) {
  if (typeof e.name !== 'string' || !NAME_RE.test(e.name)) throw new Fail('invalid name');
  if (e.key !== PREFIX[edition] + e.name) throw new Fail(`key must be ${PREFIX[edition]}<name>`);
  if (!isInt(e.size) || e.size <= 0) throw new Fail('invalid size');
  if (!isInt(date) || date < MIN_DATE || date > now + 86400) throw new Fail('invalid date');
  for (const [field, len] of Object.entries(HEX_LEN)) {
    const v = e[field];
    if (typeof v !== 'string' || !new RegExp(`^[0-9a-f]{${len}}$`).test(v)) throw new Fail(`invalid ${field}`);
  }
  return { name: e.name, key: e.key as string, size: e.size, modified: date as number, md5: e.md5 as string, sha1: e.sha1 as string, sha256: e.sha256 as string };
}

export async function current(db: D1Database, edition: string): Promise<Entry | null> {
  const row = await db.prepare('SELECT entry FROM catalog WHERE edition = ?').bind(edition).first<{ entry: string }>();
  return row ? (JSON.parse(row.entry) as Entry) : null;
}

const same = (a: Entry, b: Entry) => (Object.keys(b) as (keyof Entry)[]).every((k) => a[k] === b[k]) && Object.keys(a).length === Object.keys(b).length;

// Mirrors register-iso.py: one entry per edition, replaced in place, R2 untouched.
export async function register(db: D1Database, raw: string) {
  if (raw.length > 4096) throw new Fail('input too large');
  let req: unknown;
  try { req = JSON.parse(raw); } catch { throw new Fail('invalid JSON'); }
  if (!req || typeof req !== 'object' || Array.isArray(req)) throw new Fail('input must be a JSON object');
  const r = req as Record<string, unknown>;
  const allowed = r.action === 'query' ? QUERY_FIELDS : r.action === 'register' ? REGISTER_FIELDS : null;
  if (!allowed) throw new Fail('unknown action');
  const extra = Object.keys(r).filter((k) => !allowed.includes(k)).sort();
  if (extra.length) throw new Fail(`unknown field: ${extra[0]}`);
  const missing = allowed.filter((k) => !(k in r)).sort();
  if (missing.length) throw new Fail(`missing field: ${missing[0]}`);
  const edition = r.edition;
  if (typeof edition !== 'string' || !(edition in PREFIX)) throw new Fail('unknown edition');

  const cur = await current(db, edition);
  if (r.action === 'query') return { ok: true, entry: cur };

  const next = validateEntry(r, edition, r.date);
  const rep = await db.prepare('SELECT new_key, old_key FROM replaced WHERE edition = ?').bind(edition).first<{ new_key: string; old_key: string | null }>();
  if (cur && same(cur, next)) return { ok: true, old_key: rep && rep.new_key === next.key ? rep.old_key : null };
  if (cur && cur.key === next.key) throw new Fail('key already listed with different data');

  const oldKey = cur?.key ?? null;
  const now = Math.floor(Date.now() / 1000);
  await db.batch([
    db.prepare('INSERT INTO catalog_backups (edition, entry, at) VALUES (?, ?, ?)').bind(edition, cur ? JSON.stringify(cur) : null, now),
    db.prepare('INSERT INTO catalog (edition, entry) VALUES (?, ?) ON CONFLICT(edition) DO UPDATE SET entry = excluded.entry').bind(edition, JSON.stringify(next)),
    db.prepare('INSERT INTO replaced (edition, new_key, old_key) VALUES (?, ?, ?) ON CONFLICT(edition) DO UPDATE SET new_key = excluded.new_key, old_key = excluded.old_key').bind(edition, next.key, oldKey),
  ]);
  return { ok: true, old_key: oldKey };
}

// One-time import of the VPS's catalog.json and each edition's downloads.json.
export async function importVps(db: D1Database, raw: string) {
  let body: unknown;
  try { body = JSON.parse(raw); } catch { throw new Fail('invalid JSON'); }
  const b = body as { catalog?: Record<string, unknown>; counts?: Record<string, unknown> };
  if (!b || typeof b.catalog !== 'object' || typeof b.counts !== 'object' || !b.catalog || !b.counts) throw new Fail('expected { catalog, counts }');
  // Counts import once. The catalog may already be filled by /admin/register; the import then overwrites it.
  const existing = await db.prepare('SELECT COUNT(*) AS n FROM counts').first<{ n: number }>();
  if (existing && existing.n > 0) throw new Fail('already imported');

  const stmts: D1PreparedStatement[] = [];
  for (const edition of PUBLIC_EDITIONS) {
    const list = b.catalog[edition] ?? [];
    if (!Array.isArray(list) || list.length > 1) throw new Fail(`expected at most one catalog entry for ${edition}`);
    if (list.length) {
      const e = list[0] as Record<string, unknown>;
      const entry = validateEntry(e, edition, e.modified);
      stmts.push(db.prepare('INSERT INTO catalog (edition, entry) VALUES (?, ?) ON CONFLICT(edition) DO UPDATE SET entry = excluded.entry').bind(edition, JSON.stringify(entry)));
    }
    const counts = b.counts[edition];
    if (counts === undefined) continue;
    if (!counts || typeof counts !== 'object' || Array.isArray(counts)) throw new Fail(`counts for ${edition} must be an object`);
    for (const [file, n] of Object.entries(counts)) {
      if (!isInt(n) || n < 0) throw new Fail(`invalid count for ${file}`);
      stmts.push(db.prepare('INSERT INTO counts (edition, file, n) VALUES (?, ?, ?)').bind(edition, file, n));
    }
  }
  if (stmts.length) await db.batch(stmts);
  return { ok: true, rows: stmts.length };
}
