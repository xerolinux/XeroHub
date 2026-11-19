interface Edition { file: string; size: number; date: number; md5: string; sha1: string; sha256: string; release: number; total: number }
interface Session { token: string; expires: number; linksLeft: number | null; editions: Record<string, Edition> }

const KEY = 'xero-access';
const fmt = (n: number) => n.toLocaleString('en-US');

function load(): Session | null {
  try {
    const s = JSON.parse(sessionStorage.getItem(KEY) ?? 'null') as Session | null;
    return s && s.expires * 1000 > Date.now() ? s : null;
  } catch {
    return null;
  }
}
function save(s: Session | null) {
  try {
    if (s) sessionStorage.setItem(KEY, JSON.stringify(s));
    else sessionStorage.removeItem(KEY);
  } catch { /* storage blocked */ }
}

async function call(api: string, action: string, body: object) {
  const r = await fetch(`${api}?action=${action}`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
  const data = await r.json().catch(() => ({ error: 'Something went wrong. Please try again.' }));
  if (!r.ok) throw new Error(data.error ?? 'Something went wrong. Please try again.');
  return data;
}

export function initAccess() {
  const root = document.querySelector<HTMLElement>('[data-access]');
  if (!root?.dataset.access) return;
  const api = root.dataset.access;
  const loginView = root.querySelector<HTMLElement>('[data-view="login"]')!;
  const filesView = root.querySelector<HTMLElement>('[data-view="files"]')!;
  const form = root.querySelector<HTMLFormElement>('[data-login]')!;
  const msg = root.querySelector<HTMLElement>('[data-msg]')!;
  let session = load();

  const setLinks = (left: number | null) => {
    root.querySelector('[data-f="links"]')!.textContent = left === null ? '∞' : String(left);
    root.querySelector('[data-f="linksLabel"]')!.textContent = left === null ? 'staff · unlimited' : left === 1 ? 'download link left' : 'download links left';
  };

  const render = () => {
    loginView.hidden = !!session;
    filesView.hidden = !session;
    if (!session) return;
    setLinks(session.linksLeft);
    root.querySelectorAll<HTMLElement>('[data-edition]').forEach((card) => {
      const e = session!.editions[card.dataset.edition ?? ''];
      card.hidden = !e;
      if (!e) return;
      const put = (f: string, v: string) => card.querySelectorAll<HTMLElement>(`[data-f="${f}"]`).forEach((el) => { el.textContent = v; });
      put('file', e.file);
      put('version', e.file.match(/\d{4}\.\d{2}/)?.[0] ?? '');
      put('release', fmt(e.release));
      put('total', fmt(e.total));
      put('size', `${(e.size / 1e9).toFixed(1)} GB`);
      put('date', new Date(e.date * 1000).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }));
      (['sha256', 'sha1', 'md5'] as const).forEach((h) => {
        put(h, e[h]);
        card.querySelector<HTMLElement>(`[data-copy-f="${h}"]`)!.dataset.copy = e[h];
      });
    });
  };

  form.addEventListener('submit', async (ev) => {
    ev.preventDefault();
    msg.textContent = '';
    const fd = new FormData(form);
    try {
      session = await call(api, 'login', { email: fd.get('email'), code: fd.get('code') }) as Session;
      save(session);
      form.reset();
      render();
    } catch (err) {
      msg.textContent = (err as Error).message;
    }
  });

  root.querySelector('[data-logout]')!.addEventListener('click', () => {
    session = null;
    save(null);
    render();
  });

  root.querySelectorAll<HTMLButtonElement>('[data-get]').forEach((btn) => btn.addEventListener('click', async () => {
    const card = btn.closest<HTMLElement>('[data-edition]')!;
    const err = card.querySelector<HTMLElement>('[data-f="err"]')!;
    const edition = btn.dataset.get!;
    err.textContent = '';
    btn.disabled = true;
    try {
      const r = await call(api, 'link', { token: session?.token, edition, file: session?.editions[edition]?.file });
      if (session) {
        session.linksLeft = r.linksLeft;
        save(session);
        setLinks(r.linksLeft);
      }
      window.location.href = r.url;
    } catch (e) {
      err.textContent = (e as Error).message;
      if (/expired/i.test(err.textContent)) { session = null; save(null); render(); msg.textContent = err.textContent; }
    } finally {
      btn.disabled = false;
    }
  }));

  render();
}
