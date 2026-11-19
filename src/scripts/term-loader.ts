// The terminal is a desktop-only easter egg, so its code loads on first use instead of with every page.
import { STACKED as MOBILE } from './layout';
let mod: Promise<typeof import('./terminal')> | undefined;
let bound = false;

async function boot() {
  const m = await (mod ??= import('./terminal'));
  if (!bound) {
    m.initTerminal();
    bound = true;
  }
  return m;
}

const wasOpen = () => {
  try { return JSON.parse(sessionStorage.getItem('xero-term') ?? 'null')?.open === true; } catch { return false; }
};

document.addEventListener('astro:page-load', () => {
  bound = false;
  if (window.matchMedia(MOBILE).matches) return;
  if (wasOpen()) void boot();
  document.querySelector('[data-term-open]')?.addEventListener('click', async () => (await boot()).toggleTerminal());
});

window.addEventListener('keydown', (ev) => {
  if (ev.key !== '`' || ev.ctrlKey || ev.metaKey || ev.altKey) return;
  if ((ev.target as HTMLElement).closest('input, textarea, [contenteditable]')) return;
  if (window.matchMedia(MOBILE).matches || !document.querySelector('[data-term]')) return;
  ev.preventDefault();
  void boot().then((m) => m.toggleTerminal());
});
