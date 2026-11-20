import { FESTIVE_IDS, FESTIVITIES, festiveFor, type FestiveId } from '../data/festive';
import { DECOR, clearDecor, mountDecor, type Fall } from './festive-decor';

interface Flake { x: number; y: number; vy: number; r: number; ph: number; a: number; c: string }

const FORCE = 'festive-force';
const offKey = (id: FestiveId) => `festive-off:${id}`;
const rand = (a: number, b: number) => a + Math.random() * (b - a);
const get = (k: string) => { try { return localStorage.getItem(k); } catch { return null; } };
const put = (k: string, v: string | null) => { try { if (v === null) localStorage.removeItem(k); else localStorage.setItem(k, v); } catch { /* storage blocked */ } };

const reduced = () => window.matchMedia('(prefers-reduced-motion: reduce)').matches;
let stopLoop: (() => void) | null = null;

export function forcedFestive(): FestiveId | null {
  const f = get(FORCE);
  return f && (FESTIVE_IDS as string[]).includes(f) ? (f as FestiveId) : null;
}

export function festiveState() {
  const forced = forcedFestive();
  const id = forced ?? festiveFor(new Date());
  return { id, forced: !!forced, on: !!id && get(offKey(id)) !== '1' };
}

const COLORS: Record<Fall, string[]> = { snow: ['#ffffff', '#e8f1ff'], hearts: ['#ff5d8f', '#ff8fab', '#e63946'], clovers: ['#2bb24c', '#5fd38a', '#1f9d55'] };

function heart(ctx: CanvasRenderingContext2D, f: Flake, x: number) {
  const s = f.r / 8;
  ctx.save(); ctx.translate(x, f.y); ctx.rotate(Math.sin(f.a) * 0.3); ctx.scale(s, s);
  ctx.beginPath(); ctx.moveTo(0, 6); ctx.bezierCurveTo(-10, -1, -5, -9, 0, -3); ctx.bezierCurveTo(5, -9, 10, -1, 0, 6); ctx.fill();
  ctx.restore();
}

function clover(ctx: CanvasRenderingContext2D, f: Flake, x: number) {
  ctx.save(); ctx.translate(x, f.y); ctx.rotate(f.a);
  for (let i = 0; i < 3; i++) { const g = (i / 3) * Math.PI * 2 - Math.PI / 2; ctx.beginPath(); ctx.arc(Math.cos(g) * f.r * 0.55, Math.sin(g) * f.r * 0.55, f.r * 0.5, 0, 7); ctx.fill(); }
  ctx.strokeStyle = f.c; ctx.lineWidth = 1.4; ctx.beginPath(); ctx.moveTo(0, 0); ctx.quadraticCurveTo(f.r * 0.3, f.r, f.r * 0.1, f.r * 1.4); ctx.stroke();
  ctx.restore();
}

function falling(kind: Fall) {
  const canvas = document.querySelector<HTMLCanvasElement>('[data-festive-canvas]');
  if (!canvas) return;
  const ctx = canvas.getContext('2d')!;
  let w = 0, h = 0;
  const size = () => {
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    w = innerWidth; h = innerHeight;
    canvas.width = Math.round(w * dpr); canvas.height = Math.round(h * dpr);
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  };
  size();
  const big = kind !== 'snow';
  const flake = (top: boolean): Flake => ({ x: rand(0, w), y: top ? rand(-40, -5) : rand(0, h), vy: big ? rand(0.02, 0.04) : rand(0.025, 0.06), r: big ? rand(5, 9) : rand(1.2, 3), ph: rand(0, 6.28), a: rand(0, 6.28), c: COLORS[kind][(Math.random() * COLORS[kind].length) | 0] });
  const flakes = Array.from({ length: big ? 14 : 30 }, () => flake(false));
  const draw = (dt: number) => {
    ctx.clearRect(0, 0, w, h);
    for (let i = 0; i < flakes.length; i++) {
      const f = flakes[i];
      f.y += f.vy * dt;
      f.ph += dt / 1500;
      f.a += dt / 2000;
      if (f.y > h + 20) flakes[i] = flake(true);
      const x = f.x + Math.sin(f.ph) * 12;
      ctx.fillStyle = f.c;
      if (kind === 'hearts') heart(ctx, f, x);
      else if (kind === 'clovers') clover(ctx, f, x);
      else { ctx.beginPath(); ctx.arc(x, f.y, f.r, 0, 7); ctx.fill(); }
    }
  };
  if (reduced()) { draw(0); stopLoop = () => ctx.clearRect(0, 0, w, h); return; }
  let raf = 0;
  let last = performance.now();
  const loop = (ts: number) => { raf = requestAnimationFrame(loop); draw(Math.min(50, ts - last)); last = ts; };
  raf = requestAnimationFrame(loop);
  const vis = () => { cancelAnimationFrame(raf); if (!document.hidden) { last = performance.now(); raf = requestAnimationFrame(loop); } };
  document.addEventListener('visibilitychange', vis);
  window.addEventListener('resize', size);
  stopLoop = () => { cancelAnimationFrame(raf); document.removeEventListener('visibilitychange', vis); window.removeEventListener('resize', size); ctx.clearRect(0, 0, w, h); };
}

export function applyFestive() {
  stopLoop?.();
  stopLoop = null;
  const { id, on } = festiveState();
  const root = document.documentElement;
  if (id && on) root.dataset.festive = id;
  else delete root.dataset.festive;
  const btn = document.querySelector<HTMLButtonElement>('[data-festive-toggle]');
  if (btn) {
    btn.hidden = !id;
    btn.setAttribute('aria-pressed', String(on));
    btn.title = id ? `${FESTIVITIES[id].name} decorations: ${on ? 'on' : 'off'}` : '';
  }
  if (id && on) {
    mountDecor(id);
    const fall = DECOR[id].fall;
    if (fall) falling(fall);
  } else clearDecor();
  document.dispatchEvent(new CustomEvent('xero-festive'));
}

export function setFestiveOn(on: boolean) {
  const { id } = festiveState();
  if (!id) return;
  put(offKey(id), on ? null : '1');
  applyFestive();
}

export function forceFestive(id: FestiveId | null) {
  put(FORCE, id);
  if (id) put(offKey(id), null);
  applyFestive();
}

export function initFestive() {
  document.querySelector('[data-festive-toggle]')?.addEventListener('click', () => setFestiveOn(!festiveState().on));
  document.addEventListener('astro:after-swap', () => {
    const { id, on } = festiveState();
    if (id && on) document.documentElement.dataset.festive = id;
  });
  document.addEventListener('astro:page-load', () => {
    const { id, on } = festiveState();
    if (id && on) mountDecor(id);
  });
  applyFestive();
}
