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
  const pad = getComputedStyle(frame.parentElement!);
  const w = window.innerWidth - parseFloat(pad.paddingLeft) - parseFloat(pad.paddingRight);
  const h = window.innerHeight - parseFloat(pad.paddingTop) - parseFloat(pad.paddingBottom);
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

function lightbox() {
  let lb = document.querySelector<HTMLDialogElement>('dialog.lb');
  if (lb) return lb;
  lb = document.createElement('dialog');
  lb.className = 'lb';
  lb.setAttribute('aria-label', 'Photo');
  lb.innerHTML = '<button type="button" aria-label="Close photo">✕</button><img alt="">';
  lb.addEventListener('click', () => lb!.close());
  document.body.append(lb);
  return lb;
}

function openLightbox(src: string, alt: string) {
  const lb = lightbox();
  const img = lb.querySelector('img')!;
  img.src = src;
  img.alt = alt;
  lb.showModal();
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

  const kset = [...document.querySelectorAll<HTMLButtonElement>('[data-kset]')];
  if (kset.length) {
    const groupBtns = [...document.querySelectorAll<HTMLButtonElement>('.dk[data-group]')];
    const pick = (name: string) => {
      kset.forEach((b) => b.setAttribute('aria-pressed', String(b.dataset.kset === name)));
      groupBtns.forEach((b) => { b.hidden = b.dataset.group !== name; });
      groupBtns.find((b) => b.dataset.group === name)?.click();
    };
    kset.forEach((b) => b.addEventListener('click', () => {
      pick(b.dataset.kset ?? 'apps');
      history.replaceState(history.state, '', b.dataset.kset === 'scripts' ? '#scripts' : location.pathname);
    }));
    if (location.hash === '#scripts') pick('scripts');
  }

  document.querySelectorAll<HTMLButtonElement>('[data-lightbox]').forEach((btn) => btn.addEventListener('click', () => {
    openLightbox(btn.dataset.lightbox ?? '', btn.querySelector('img')?.alt ?? '');
  }));

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
  void loadSupporters();
  void loadAnnouncements();
  pollAnnouncements();
  liveBars();
}

let supportersAt = 0;

async function loadSupporters() {
  const el = document.querySelector<HTMLElement>('[data-supporters]');
  if (!el?.dataset.supporters || Date.now() - supportersAt < 60_000) return;
  supportersAt = Date.now();
  try {
    const d = await (await fetch(el.dataset.supporters)).json() as { supporters?: number };
    if (typeof d.supporters === 'number') el.textContent = d.supporters.toLocaleString('en-US');
  } catch { /* keep the build-time figure */ }
}

interface Post { id: string; ts: string; edited: string | null; text: string; images: string[]; files?: { name: string; url: string }[] }

const esc = (s: string) => s.replace(/[&<>"']/g, (c) => `&#${c.charCodeAt(0)};`);
const stamp = (iso: string) => new Date(iso).toLocaleString('en-US', { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit', hourCycle: 'h23' });

// Discord's markdown subset, on already-escaped text; links are http(s) only.
const SITES: Record<string, string> = { 'github.com': 'GitHub', 'youtube.com': 'YouTube', 'youtu.be': 'YouTube', 'aur.archlinux.org': 'the AUR', 'wiki.xerolinux.xyz': 'the Wiki', 'xerolinux.xyz': 'xerolinux.xyz', 'ko-fi.com': 'Ko-fi', 'reddit.com': 'Reddit' };

// A bare URL shown as a name: owner/repo for GitHub, otherwise the site's name.
function linkName(raw: string) {
  try {
    const u = new URL(raw.replace(/&#38;/g, '&'));
    const host = u.hostname.replace(/^www\./, '');
    const parts = u.pathname.split('/').filter(Boolean);
    if (host === 'github.com' && parts.length >= 2) return `${parts[0]}/${parts[1]} on GitHub`;
    if (SITES[host]) return SITES[host];
    return host;
  } catch {
    return raw;
  }
}

function discordMarkdown(text: string) {
  // Code and links are set aside first so formatting never reaches inside them.
  const kept: string[] = [];
  const keep = (html: string) => `\u0000${kept.push(html) - 1}\u0000`;
  const link = (href: string, label: string) => keep(`<a href="${href}" target="_blank" rel="noopener noreferrer">${label}</a>`);
  return esc(text)
    .replace(/```(?:\w*\n)?([\s\S]*?)```/g, (_, c) => keep(`<pre>${c.trim()}</pre>`))
    .replace(/`([^`\n]+)`/g, (_, c) => keep(`<code>${c}</code>`))
    .replace(/\[([^\]\n]+)\]\((https?:\/\/[^\s)]+)\)/g, (_, label, href) => link(href, label))
    .replace(/https?:\/\/[^\s<\u0000]+[^\s<.,;:!?)\u0000]/g, (url) => link(url, `${linkName(url)} ↗`))
    .replace(/^#{1,3} (.+)$/gm, '<b class="ah">$1</b>')
    .replace(/^-# (.+)$/gm, '<small>$1</small>')
    .replace(/^&#62; (.+)$/gm, '<q>$1</q>')
    .replace(/\*\*(.+?)\*\*/g, '<b>$1</b>')
    .replace(/__(.+?)__/g, '<u>$1</u>')
    .replace(/~~(.+?)~~/g, '<s>$1</s>')
    .replace(/(^|[^*\w])[*_](?=\S)(.+?)(?<=\S)[*_](?![*\w])/g, '$1<i>$2</i>')
    .replace(/\|\|(.+?)\|\|/g, '<span class="spoil" tabindex="0">$1</span>')
    .replace(/\u0000(\d+)\u0000/g, (_, i) => kept[+i]);
}

// Five bars this week, fading to two for anything older than three months
function bars(iso: string) {
  const days = (Date.now() - new Date(iso).getTime()) / 864e5;
  const on = days <= 7 ? 5 : days <= 30 ? 4 : days <= 90 ? 3 : 2;
  return [5, 8, 11, 14, 17].map((h, k) => `<i style="height:${h}px"${k < on ? ' class="on"' : ''}></i>`).join('');
}

// 64 pastel tints, stepped round the colour wheel by the golden angle so neighbours never look alike
const tint = (i: number) => `hsl(${Math.round(((i % 64) * 137.508 + 230) % 360)} 72% 72%)`;

let annAt = 0;
let annFeed = '';
let annTimer = 0;

// While the Updates page is open and visible, check for new posts every 5 minutes
function pollAnnouncements() {
  if (annTimer || !document.querySelector('[data-ann]')) return;
  annTimer = window.setInterval(() => {
    if (!document.querySelector('[data-ann]')) { clearInterval(annTimer); annTimer = 0; return; }
    if (!document.hidden) { annAt = 0; void loadAnnouncements(); }
  }, 300_000);
}

// Faint signal-bars wave behind the Live strip; stops once the page navigates away
function liveBars() {
  const canvas = document.querySelector<HTMLCanvasElement>('[data-ann-bars]');
  const g = canvas?.getContext('2d');
  if (!canvas || !g) return;
  const draw = (t: number) => {
    if (!canvas.isConnected) return;
    const dpr = devicePixelRatio || 1;
    // Sized from the strip, not the canvas, so a canvas without its CSS can't grow itself
    const box = canvas.parentElement!;
    const w = box.clientWidth, h = box.clientHeight;
    if (canvas.width !== w * dpr || canvas.height !== h * dpr) { canvas.width = w * dpr; canvas.height = h * dpr; }
    g.setTransform(dpr, 0, 0, dpr, 0, 0);
    g.clearRect(0, 0, w, h);
    const n = Math.floor(w / 9);
    for (let i = 0; i < n; i++) {
      const lit = Math.max(1, Math.round((Math.sin(t / 330 - i * 0.35) * 0.5 + 0.5) * 4));
      for (let s = 0; s < 4; s++) {
        const bh = 4 + s * 5;
        g.fillStyle = `rgba(255,255,255,${s < lit ? 0.09 : 0.03})`;
        g.fillRect(i * 9, h - bh - 3, 3, bh);
      }
    }
    if (!reduced) requestAnimationFrame(draw);
  };
  requestAnimationFrame(draw);
}

async function loadAnnouncements() {
  const log = document.querySelector<HTMLElement>('[data-ann]');
  // The throttle only applies when posts are already on screen; a fresh visit always loads
  if (!log?.dataset.ann || (log.querySelector('.atx') && Date.now() - annAt < 30_000)) return;
  annAt = Date.now();
  const status = document.querySelector<HTMLElement>('[data-ann-status]');
  try {
    const d = await (await fetch(log.dataset.ann)).json() as { posts?: Post[]; error?: string };
    if (!d.posts) throw new Error(d.error ?? 'bad response');
    if (status) status.textContent = `synced ${new Date().toTimeString().slice(0, 5)}`;
    const feed = JSON.stringify(d.posts);
    if (feed === annFeed && log.querySelector('.atx')) return;
    annFeed = feed;
    const total = d.posts.length;
    log.innerHTML = d.posts.map((p, i) => `<article class="atx" style="--tint:${tint(i)}"><div class="atop"><span class="abars" title="Signal fades with age">${bars(p.ts)}</span><span class="afreq">TX-${String(total - i).padStart(3, '0')}</span><time datetime="${esc(p.ts)}">${stamp(p.ts)}</time>${p.edited ? '<span>edited</span>' : ''}${i ? '' : '<span class="aonair">on air</span>'}</div><div class="abody"><span class="awm" aria-hidden="true">${String(total - i).padStart(3, '0')}</span>${p.text ? `<div class="atext">${discordMarkdown(p.text)}</div>` : ''}${p.images.length || p.files?.length ? `<div class="aatt">${p.images.map((u, k) => `<button type="button" class="aimg" data-src="${esc(u)}">View image ${k + 1}</button>`).join('')}${(p.files ?? []).map((f) => `<a class="afile" href="${esc(f.url)}" target="_blank" rel="noopener noreferrer">${esc(f.name)}</a>`).join('')}</div>` : ''}</div></article>`).join('')
      || '<p class="aempty">No updates yet.</p>';
    log.querySelectorAll<HTMLButtonElement>('.aimg').forEach((b) => b.addEventListener('click', () => openLightbox(b.dataset.src ?? '', b.textContent ?? '')));
  } catch {
    annAt = 0;
    log.innerHTML = '<p class="aempty">Could not reach the updates feed. Try again in a minute.</p>';
    if (status) status.textContent = 'offline';
  }
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
