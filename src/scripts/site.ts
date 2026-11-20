import { navigate } from 'astro:transitions/client';
import { FREE_DEFAULT, SETTINGS_URL } from '../config';
import { STACKED } from './layout';
import { applyTheme, currentTheme } from './theme';
import './picker';
import { initFestive } from './festive';

const DESIGN_W = 1920;
const DESIGN_H = 950;
// Smallest canvas every page fits without scrolling; shorter or narrower windows shrink it to fit.
const MIN_W = 1400;
const MIN_H = 880;
const reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

function fit() {
  const frame = document.querySelector<HTMLElement>('[data-frame]');
  if (!frame) return;
  const w = window.innerWidth;
  const h = window.innerHeight;
  const big = w > DESIGN_W;
  const scale = big ? Math.min(w / DESIGN_W, h / DESIGN_H) : Math.min(w / MIN_W, h / MIN_H);
  if (!window.matchMedia(STACKED).matches && (big || scale < 1)) {
    frame.classList.add('scaled');
    frame.style.width = `${big ? DESIGN_W : w / scale}px`;
    frame.style.height = `${big ? DESIGN_H : h / scale}px`;
    frame.style.transform = `translate(-50%, -50%) scale(${scale})`;
  } else {
    frame.classList.remove('scaled');
    frame.style.width = frame.style.height = frame.style.transform = '';
  }
}
window.addEventListener('resize', fit);

function setWindow(title?: string, sub?: string) {
  const t = document.querySelector<HTMLElement>('[data-wt]');
  const s = document.querySelector<HTMLElement>('[data-ws]');
  if (t && title !== undefined) t.textContent = title;
  if (s && sub !== undefined) s.textContent = sub;
}

let slide = 0;
let timer: number | undefined;
function show(i: number) {
  slide = i;
  document.querySelectorAll<HTMLElement>('[data-bg]').forEach((el, k) => el.classList.toggle('on', k === i));
  const shots = [...document.querySelectorAll<HTMLElement>('[data-slide]')];
  shots.forEach((el, k) => el.classList.toggle('on', k === i));
  document.querySelectorAll<HTMLButtonElement>('[data-slide-btn]').forEach((b, k) => b.setAttribute('aria-pressed', String(k === i)));
  if (shots[i]) setWindow(shots[i].dataset.title, shots[i].dataset.sub);
}
function start() {
  window.clearInterval(timer);
  const count = document.querySelectorAll('[data-bg]').length;
  if (!reduced && count > 1) timer = window.setInterval(() => show((slide + 1) % count), 14000);
}

const RING_MS = 10000;
function syncRings() {
  const phase = -(Date.now() % RING_MS) / 1000;
  ([['.hdr', 0], ['.ftr', 0], ['.main>section:first-child', -3.3], ['.main>section:last-child', -6.6]] as const).forEach(([sel, off]) => {
    const el = document.querySelector<HTMLElement>(sel);
    if (el && !el.style.getPropertyValue('--rd')) el.style.setProperty('--rd', `${(phase + off).toFixed(3)}s`);
  });
}

interface Asset { name: string; browser_download_url: string }

// Same approach as the wiki: swap release-page links for the newest AppImage files.
async function releaseAssets(repo: string): Promise<Asset[]> {
  const key = `gh-assets:${repo}`;
  try { const hit = sessionStorage.getItem(key); if (hit) return JSON.parse(hit); } catch { /* storage blocked */ }
  const r = await fetch(`https://api.github.com/repos/${repo}/releases/latest`);
  if (!r.ok) throw new Error(String(r.status));
  const assets: Asset[] = ((await r.json()).assets ?? []).map((a: Asset) => ({ name: a.name, browser_download_url: a.browser_download_url }));
  try { sessionStorage.setItem(key, JSON.stringify(assets)); } catch { /* storage blocked */ }
  return assets;
}

function appImageLinks() {
  const links = [...document.querySelectorAll<HTMLAnchorElement>('[data-appimage]')];
  for (const repo of new Set(links.map((a) => a.dataset.appimage!))) {
    releaseAssets(repo).then((assets) => {
      for (const a of links.filter((l) => l.dataset.appimage === repo)) {
        const file = assets.find((x) => x.name.endsWith(`-${a.dataset.arch}.AppImage`));
        if (!file) continue;
        a.href = file.browser_download_url;
        a.setAttribute('download', '');
        a.removeAttribute('target');
      }
    }).catch(() => {});
  }
}

function initPage() {
  fit();
  syncRings();
  show(slide);
  start();

  const current = document.querySelector<HTMLElement>('[data-current]')?.dataset.current;
  document.querySelectorAll<HTMLAnchorElement>('.nav a[href^="/"]').forEach((a) => {
    if (a.pathname === current) a.setAttribute('aria-current', 'page');
    else a.removeAttribute('aria-current');
  });

  document.querySelectorAll<HTMLButtonElement>('[data-slide-btn]').forEach((b, k) => b.addEventListener('click', () => { show(k); start(); }));

  document.querySelectorAll<HTMLElement>('[data-tabs]').forEach((group) => {
    const btns = [...group.querySelectorAll<HTMLButtonElement>('[data-tab]')];
    const panes = [...group.querySelectorAll<HTMLElement>('[data-pane]')];
    btns.forEach((btn) => btn.addEventListener('click', () => {
      btns.forEach((b) => b.setAttribute('aria-pressed', String(b === btn)));
      panes.forEach((p) => {
        const on = p.dataset.pane === btn.dataset.tab;
        p.hidden = !on;
        p.querySelectorAll('video').forEach((v) => (on ? v.play().catch(() => {}) : v.pause()));
        if (on && p.dataset.title) setWindow(p.dataset.title, p.dataset.sub);
      });
    }));
  });

  appImageLinks();
  document.querySelectorAll<HTMLButtonElement>('[data-copy]').forEach((btn) => {
    const label = btn.innerHTML;
    btn.addEventListener('click', () => {
      navigator.clipboard?.writeText(btn.dataset.copy ?? '').then(() => {
        btn.textContent = btn.querySelector('svg') ? '✓' : 'Copied';
        window.setTimeout(() => { btn.innerHTML = label; }, 2000);
      }, () => {});
    });
  });

  document.querySelectorAll<HTMLElement>('.ed').forEach((card) => {
    const pop = card.querySelector<HTMLElement>('[data-pop]');
    const open = card.querySelector<HTMLButtonElement>('[data-pop-open]');
    const close = card.querySelector<HTMLButtonElement>('[data-pop-close]');
    if (!pop || !open || !close) return;
    const set = (on: boolean) => {
      pop.hidden = !on;
      open.setAttribute('aria-expanded', String(on));
      (on ? close : open).focus();
    };
    open.addEventListener('click', () => set(true));
    close.addEventListener('click', () => set(false));
    pop.addEventListener('keydown', (e) => { if (e.key === 'Escape') set(false); });
  });

  document.querySelectorAll<HTMLElement>('[data-sale-window]').forEach((w) => {
    const now = Date.now();
    const on = w.dataset.enabled === 'true'
      && now >= new Date(`${w.dataset.start}T00:00:00`).getTime()
      && now <= new Date(`${w.dataset.end}T23:59:59`).getTime();
    w.querySelectorAll<HTMLElement>('[data-sale]').forEach((el) => { el.hidden = (el.dataset.sale === 'on') !== on; });
  });

  document.querySelectorAll<HTMLButtonElement>('[data-cl-open]').forEach((clOpen) => {
    const cl = clOpen.nextElementSibling as HTMLElement | null;
    const clClose = cl?.querySelector<HTMLButtonElement>('[data-cl-close]');
    if (!cl?.matches('[data-cl]') || !clClose) return;
    const set = (on: boolean) => {
      cl.hidden = !on;
      (on ? clClose : clOpen).focus({ preventScroll: true });
      if (on) cl.querySelector('.clbody')?.scrollIntoView({ block: 'center', behavior: reduced ? 'auto' : 'smooth' });
    };
    clOpen.addEventListener('click', () => set(true));
    clClose.addEventListener('click', () => set(false));
    cl.addEventListener('click', (e) => { if (e.target === cl) set(false); });
    cl.addEventListener('keydown', (e) => { if (e.key === 'Escape') set(false); });
  });

  loadStats();
  void syncSettings();
  void loadGoal();
}

let goalAt = 0;

async function loadGoal() {
  const el = document.querySelector<HTMLElement>('[data-kgoal]');
  if (!el?.dataset.kgoal || Date.now() - goalAt < 60_000) return;
  goalAt = Date.now();
  try {
    const d = await (await fetch(el.dataset.kgoal)).json() as { percentage?: number; currentEUR?: number; targetEUR?: number; title?: string };
    if (typeof d.percentage !== 'number' || typeof d.targetEUR !== 'number') return;
    const pct = Math.min(100, Math.max(0, Math.round(d.percentage)));
    const eur = (n: number) => `€${n.toLocaleString('en-US')}`;
    const put = (k: string, v: string) => { const t = el.querySelector(`[data-kg="${k}"]`); if (t) t.textContent = v; };
    put('pct', `${pct}%`);
    put('current', eur(d.currentEUR ?? Math.round((pct / 100) * d.targetEUR)));
    put('target', eur(d.targetEUR));
    if (d.title) put('title', d.title);
    el.querySelector<HTMLElement>('[data-kg="fill"]')!.style.width = `${pct}%`;
    el.setAttribute('aria-label', `Ko-fi goal: ${d.title ?? ''}, ${pct}% funded. Opens Ko-fi.`);
  } catch { /* keep the build-time figures */ }
}

const FREE_KEY = 'xero-free';
const isFree = () => document.documentElement.dataset.free === 'true';

function setFree(free: boolean) {
  const changed = isFree() !== free;
  document.documentElement.dataset.free = String(free);
  try { localStorage.setItem(FREE_KEY, String(free)); } catch { /* storage blocked */ }
  return changed;
}

function applyMode() {
  if (isFree() && location.pathname.startsWith('/access')) navigate('/download/');
}

async function syncSettings() {
  applyMode();
  try {
    const r = await fetch(SETTINGS_URL, { cache: 'no-cache' });
    const d = await r.json() as { free?: unknown };
    if (typeof d.free === 'boolean' && setFree(d.free)) {
      loadStats();
      applyMode();
    }
  } catch { /* keep the last known mode */ }
}

interface Edition { file: string; version: string; release: number; total: number }
interface Stats { editions: Record<string, Edition>; allTime: number; releaseTotal: number }

function loadStats() {
  const statsEl = document.querySelector<HTMLElement>(`[data-mode="${isFree() ? 'free' : 'paid'}"] [data-stats]`);
  const url = statsEl?.dataset.stats;
  if (!url) return;
  const fmt = (n: number) => n.toLocaleString('en-US');
  const put = (key: string, value: string) => {
    document.querySelectorAll<HTMLElement>(`[data-stat="${key}"]`).forEach((el) => { el.textContent = value; });
  };
  fetch(url)
    .then((r) => (r.ok ? r.json() as Promise<Stats> : Promise.reject(new Error(String(r.status)))))
    .then((d) => {
      put('allTime', fmt(d.allTime));
      put('releaseTotal', fmt(d.releaseTotal));
      Object.entries(d.editions).forEach(([id, e]) => {
        put(`${id}.release`, fmt(e.release));
        put(`${id}.total`, fmt(e.total));
        put(`${id}.version`, e.version);
        put(`${id}.file`, e.file);
        const link = document.querySelector<HTMLAnchorElement>(`[data-dl="${id}"]`);
        if (link) link.href = `${new URL(url).origin}/dl/${id}?dl=${encodeURIComponent(e.file)}`;
      });
    })
    .catch(() => {});
}

document.addEventListener('astro:after-swap', () => {
  const root = document.documentElement;
  let free = String(FREE_DEFAULT);
  applyTheme(currentTheme());
  try { free = localStorage.getItem(FREE_KEY) ?? free; } catch { /* storage blocked */ }
  root.dataset.free = free;
});
document.addEventListener('astro:page-load', initPage);

initFestive();
