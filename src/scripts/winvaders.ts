import type { Palette } from '../data/themes';

export const LEVELS = 12;
export const BOSS_IDS = ['clippy', 'update', 'bsod', 'recall'] as const;
export type BossId = (typeof BOSS_IDS)[number];
export const bossFor = (level: number): BossId | null => (level % 3 === 0 ? BOSS_IDS[level / 3 - 1] ?? null : null);

type Drop = 'dbl' | 'rapid' | 'shield' | 'life';
interface Box { x: number; y: number; w: number; h: number }
interface Enemy extends Box { app: number; hp: number; pts: number; flash: number }
interface Boss extends Box { id: BossId; hp: number; max: number; vx: number; cd: number; turn: number }
interface Shot { x: number; y: number; vx: number; vy: number; g: string; c: string; mine: boolean; oy?: number }
interface Item { x: number; y: number; k: Drop }
interface Spark { x: number; y: number; vx: number; vy: number; life: number; g: string; c: string }

const DROPS: Record<Drop, string> = { dbl: '[2X]', rapid: '[>>]', shield: '[()]', life: '[1UP]' };

const GLYPH: Record<string, string[]> = {
  W: ['#...#', '#...#', '#...#', '#.#.#', '#.#.#', '##.##', '#...#'],
  X: ['#...#', '#...#', '.#.#.', '..#..', '.#.#.', '#...#', '#...#'],
  P: ['####.', '#...#', '#...#', '####.', '#....', '#....', '#....'],
  O: ['.###.', '#...#', '#...#', '#...#', '#...#', '#...#', '.###.'],
  T: ['#####', '..#..', '..#..', '..#..', '..#..', '..#..', '..#..'],
  S: ['.####', '#....', '#....', '.###.', '....#', '....#', '####.'],
};

// 11x11 app tile: rounded body, darker bottom edge, white letter.
const tile = (letter: string): string[] =>
  Array.from({ length: 11 }, (_, y) => Array.from({ length: 11 }, (_, x) => {
    if ((x === 0 || x === 10) && (y === 0 || y === 10)) return '.';
    const gx = x - 3, gy = y - 2;
    if (gx >= 0 && gx < 5 && gy >= 0 && gy < 7 && GLYPH[letter][gy][gx] === '#') return 'w';
    return y === 10 || x === 10 ? 'd' : 'b';
  }).join(''));

const APPS: { name: string; rows: string[]; map: Record<string, string> }[] = [
  { name: 'Word', rows: tile('W'), map: { b: '#2b6fd6', d: '#1a4a9c', w: '#ffffff' } },
  { name: 'Excel', rows: tile('X'), map: { b: '#1f9d55', d: '#136b39', w: '#ffffff' } },
  { name: 'PowerPoint', rows: tile('P'), map: { b: '#e0562f', d: '#a63a1c', w: '#ffffff' } },
  { name: 'Outlook', rows: tile('O'), map: { b: '#0f7ee0', d: '#0a5aa3', w: '#ffffff' } },
  { name: 'Teams', rows: tile('T'), map: { b: '#6264d8', d: '#4446a8', w: '#ffffff' } },
  { name: 'Skype', rows: tile('S'), map: { b: '#16a9ea', d: '#0e7bb0', w: '#ffffff' } },
  { name: 'Edge', map: { b: '#1b7fd6', g: '#3bd18f', l: '#7fd6ff' }, rows: [
    '...bbbbb...', '..bbbbbbb..', '.bbll..bbb.', 'bbl.....bbg', 'bb..gggggg.', 'bb.gg......', 'bb.gg..ggg.', 'bbb.ggggg..', '.bbb.......', '..bbbbbbb..', '...bbbbb...'] },
  { name: 'Internet Explorer', map: { b: '#1e88e5', y: '#f6c343' }, rows: [
    '.......yyy.', '...bbbbb..y', '..bb...bb.y', '.bb.....bby', '.bbbbbbbbb.', 'ybb........', 'y.bb....bb.', 'y..bbbbbb..', '.y.........', '..yy....yy.', '....yyyy...'] },
  { name: 'OneDrive', map: { c: '#2f8ff0', l: '#8cc4ff' }, rows: [
    '...........', '...........', '....lll....', '...lcccl...', '.llcccccl..', 'lcccccccccl', 'ccccccccccc', 'ccccccccccc', '.ccccccccc.', '...........', '...........'] },
  { name: 'Notepad', map: { k: '#5b6b80', w: '#f4f6fb', l: '#8fb4e6' }, rows: [
    '.k.k.k.k.k.', 'wkwkwkwkwkw', 'wwwwwwwwwww', 'w.........w', 'wlllllllllw', 'w.........w', 'wlllllllllw', 'w.........w', 'wllllll...w', 'w.........w', 'wwwwwwwwwww'] },
];

const ARCH = ['......#......', '.....###.....', '.....###.....', '....#####....', '....#####....', '...###.###...', '...##...##...', '..###...###..', '..##.....##..', '.###.....###.', '###.......###'];

function bake(rows: string[], map: Record<string, string>, s: number) {
  const c = document.createElement('canvas');
  c.width = rows[0].length * s;
  c.height = rows.length * s;
  const g = c.getContext('2d')!;
  rows.forEach((r, y) => [...r].forEach((ch, x) => { if (map[ch]) { g.fillStyle = map[ch]; g.fillRect(x * s, y * s, s, s); } }));
  return c;
}

const BOSSES: Record<BossId, { name: string; hp: number; speed: number; cd: number; size: [number, number]; taunts: string[] }> = {
  clippy: {
    name: 'CLIPPY', hp: 28, speed: 70, cd: 1.3, size: [100, 170],
    taunts: ["It looks like you're trying to win.", 'Would you like help with that?', 'I see you are dodging. Need a hand?'],
  },
  update: {
    name: 'WINDOWS UPDATE', hp: 46, speed: 55, cd: 1.4, size: [300, 130],
    taunts: ['Working on updates...', 'Restarting in 5 minutes.', 'Just one more update.', 'Undoing changes made to your computer.'],
  },
  bsod: {
    name: 'BLUE SCREEN', hp: 64, speed: 95, cd: 1.0, size: [300, 175],
    taunts: ['Collecting error info...', 'IRQL_NOT_LESS_OR_EQUAL', 'KERNEL_SECURITY_CHECK_FAILURE'],
  },
  recall: {
    name: 'RECALL', hp: 88, speed: 80, cd: 1.5, size: [230, 120],
    taunts: ['Snapshot saved.', 'I remember everything you did.', 'Screenshot 4096 of 4096.'],
  },
};

const get = (k: string) => { try { return localStorage.getItem(k); } catch { return null; } };
const put = (k: string, v: string) => { try { localStorage.setItem(k, v); } catch { /* storage blocked */ } };
const rand = (a: number, b: number) => a + Math.random() * (b - a);
const pick = <T,>(a: T[]) => a[(Math.random() * a.length) | 0];
const hitBox = (s: Shot, b: Box) => s.x >= b.x && s.x <= b.x + b.w && Math.max(s.y, s.oy ?? s.y) >= b.y && Math.min(s.y, s.oy ?? s.y) <= b.y + b.h;

function audio() {
  let ac: AudioContext | null = null;
  let out: GainNode;
  let noise: AudioBuffer;
  const init = () => {
    if (ac) return true;
    try { ac = new AudioContext(); } catch { return false; }
    out = ac.createGain();
    out.gain.value = 0.5;
    out.connect(ac.destination);
    noise = ac.createBuffer(1, ac.sampleRate, ac.sampleRate);
    const d = noise.getChannelData(0);
    for (let i = 0; i < d.length; i++) d[i] = Math.random() * 2 - 1;
    return true;
  };
  const tone = (type: OscillatorType, f1: number, f2: number, dur: number, vol: number, delay = 0) => {
    const t = ac!.currentTime + delay;
    const o = ac!.createOscillator();
    const g = ac!.createGain();
    o.type = type;
    o.frequency.setValueAtTime(f1, t);
    o.frequency.exponentialRampToValueAtTime(f2, t + dur);
    g.gain.setValueAtTime(vol, t);
    g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    o.connect(g).connect(out);
    o.start(t);
    o.stop(t + dur + 0.02);
  };
  const hiss = (dur: number, vol: number, freq: number) => {
    const t = ac!.currentTime;
    const s = ac!.createBufferSource();
    const f = ac!.createBiquadFilter();
    const g = ac!.createGain();
    s.buffer = noise;
    f.type = 'lowpass';
    f.frequency.value = freq;
    g.gain.setValueAtTime(vol, t);
    g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    s.connect(f).connect(g).connect(out);
    s.start(t);
    s.stop(t + dur);
  };
  const arp = (notes: number[], step: number, type: OscillatorType = 'square') => notes.forEach((f, i) => tone(type, f, f, step, 0.05, i * step));
  const FX = {
    shoot: () => tone('square', 900, 280, 0.07, 0.03),
    hit: () => hiss(0.12, 0.14, 2600),
    bhit: () => tone('triangle', 190, 110, 0.06, 0.08),
    boom: () => { hiss(0.6, 0.3, 700); tone('sawtooth', 170, 35, 0.5, 0.06); },
    power: () => tone('sine', 520, 1300, 0.16, 0.08),
    shield: () => tone('triangle', 300, 900, 0.2, 0.08),
    life: () => arp([523, 659, 784, 1047], 0.08),
    level: () => arp([392, 523, 659], 0.09, 'triangle'),
    boss: () => arp([196, 185, 175, 165], 0.16, 'sawtooth'),
    warn: () => tone('square', 240, 240, 0.12, 0.035),
    over: () => tone('sawtooth', 420, 50, 1.1, 0.06),
    win: () => arp([523, 659, 784, 1047, 784, 1047, 1319], 0.1),
  };
  return {
    muted: false,
    play(name: keyof typeof FX) { if (!this.muted && init() && ac!.state !== 'closed') FX[name](); },
    close() { ac?.close().catch(() => {}); },
  };
}

export function winvaders(p: Palette, start = 1) {
  return (ctx: CanvasRenderingContext2D, w: number, h: number, dpr: number) => {
    const F = Math.round(15 * dpr);
    const font = (px: number) => `700 ${px}px 'JetBrains Mono', monospace`;
    ctx.font = font(F);
    const cw = ctx.measureText('M').width;
    const lh = Math.round(F * 1.3);
    const U = dpr;
    const top = lh * 3.4;
    const py = h - lh * 2 - 33 * dpr;
    const S = Math.max(2, Math.round(3 * dpr));
    const ICONS = APPS.map((a) => bake(a.rows, a.map, S));
    const SHIP = bake(ARCH, { '#': p.accentL }, S);
    const PW = SHIP.width, PH = SHIP.height;
    const ES = 11 * S;
    const BOSS_COLOR = (id: BossId) => ({ clippy: p.yellow, update: p.cyan, bsod: '#ffffff', recall: p.c3L })[id];
    const sfx = audio();
    const keys = new Set<string>();
    const stars = Array.from({ length: 70 }, () => ({ x: rand(0, w), y: rand(0, h), v: rand(8, 40) * U }));

    let mode: 'banner' | 'play' | 'dead' | 'over' | 'won' = 'banner';
    let paused = false;
    let level = start, score = 0, lives = 3, nextLife = 15000, hi = Number(get('winvaders-hi')) || 0;
    let px = w / 2, inv = 0, shield = false, dbl = 0, rapid = 0, cool = 0, timer = 0, clock = 0;
    let enemies: Enemy[] = [], shots: Shot[] = [], items: Item[] = [], sparks: Spark[] = [];
    let boss: Boss | null = null, beam: { x: number; t: number } | null = null;
    let total = 1, dir = 1, fireAcc = 0;

    const text = (s: string, x: number, y: number, c: string, size = F) => { ctx.font = font(size); ctx.fillStyle = c; ctx.fillText(s, x, y); };
    const center = (s: string, y: number, c: string, size = F) => { ctx.font = font(size); ctx.fillStyle = c; ctx.fillText(s, (w - ctx.measureText(s).width) / 2, y); };
    const burst = (x: number, y: number, c: string, n = 10, g = '*') => {
      for (let i = 0; i < n; i++) { const a = rand(0, Math.PI * 2), v = rand(40, 220) * U; sparks.push({ x, y, vx: Math.cos(a) * v, vy: Math.sin(a) * v, life: rand(0.4, 0.9), g: pick([g, '+', '.', 'x']), c }); }
    };
    const fire = (x: number, y: number, tx: number, ty: number, speed: number, g: string, c: string) => {
      const d = Math.hypot(tx - x, ty - y) || 1;
      shots.push({ x, y, vx: ((tx - x) / d) * speed * U, vy: ((ty - y) / d) * speed * U, g, c, mine: false });
    };
    const spread = (x: number, y: number, n: number, arc: number, speed: number, g: string, c: string) => {
      for (let i = 0; i < n; i++) { const a = Math.PI / 2 + (n > 1 ? (i / (n - 1) - 0.5) * arc : 0); shots.push({ x, y, vx: Math.cos(a) * speed * U, vy: Math.sin(a) * speed * U, g, c, mine: false }); }
    };
    const addScore = (n: number) => {
      score += n;
      if (score >= nextLife) { nextLife += 15000; lives++; sfx.play('life'); }
    };

    function startLevel() {
      shots = []; items = []; beam = null; boss = null; enemies = []; dir = 1; fireAcc = 0;
      const id = bossFor(level);
      if (id) {
        const d = BOSSES[id];
        const [bw, bh] = [d.size[0] * U, d.size[1] * U];
        boss = { id, x: (w - bw) / 2, y: top + lh * 1.2, w: bw, h: bh, hp: d.hp, max: d.hp, vx: d.speed * U, cd: 2, turn: 0 };
      } else {
        const rows = 3 + Math.floor((level - 1) / 4);
        const gx = ES + 22 * U;
        const cols = Math.max(4, Math.min(10, Math.floor((w * 0.72) / gx)));
        const x0 = (w - (cols - 1) * gx - ES) / 2;
        for (let r = 0; r < rows; r++) for (let c = 0; c < cols; c++) {
          enemies.push({ x: x0 + c * gx, y: top + lh * 0.6 + r * (ES + 14 * U), w: ES, h: ES, app: (level * 3 + r) % APPS.length, hp: (level >= 7 && r === 0) || (level >= 10 && r === 1) ? 2 : 1, pts: (rows - r) * 10 + level * 2, flash: 0 });
        }
      }
      total = enemies.length || 1;
      mode = 'banner';
      timer = 2;
      sfx.play(id ? 'boss' : 'level');
    }

    function reset() {
      level = 1; score = 0; lives = 3; nextLife = 15000; px = w / 2; inv = 0; shield = false; dbl = 0; rapid = 0; sparks = [];
      startLevel();
    }

    function hurt() {
      if (inv > 0 || mode !== 'play') return;
      if (shield) { shield = false; inv = 1; sfx.play('shield'); burst(px, py, p.cyan, 8, 'o'); return; }
      lives--;
      burst(px, py + PH / 2, p.red, 24, '#');
      sfx.play('boom');
      shots = shots.filter((s) => s.mine);
      beam = null;
      dbl = rapid = 0;
      if (lives <= 0) { mode = 'over'; sfx.play('over'); if (score > hi) { hi = score; put('winvaders-hi', String(hi)); } return; }
      mode = 'dead';
      timer = 1.3;
    }

    function bossAttack(b: Boss) {
      const cx = b.x + b.w / 2, by = b.y + b.h;
      const angry = b.hp < b.max / 2;
      b.turn++;
      switch (b.id) {
        case 'clippy':
          if (b.turn % 2) spread(cx, by, angry ? 5 : 3, 0.9, 170, '?', p.yellow);
          else fire(cx, by, px, py, 210, '@', p.text);
          break;
        case 'update':
          for (let i = 0; i < (angry ? 6 : 4); i++) shots.push({ x: rand(cw, w - cw), y: top, vx: 0, vy: rand(90, 140) * U, g: '%', c: p.cyan, mine: false });
          fire(cx, by, px, py, 200, 'o', p.c1L);
          break;
        case 'bsod':
          if (b.turn % 2) for (let i = -1; i <= 1; i++) fire(cx, by, px + i * cw * 3, py, 280, ':(', p.text);
          else spread(cx, by, angry ? 9 : 6, 1.6, 190, 'x', p.c1L);
          break;
        case 'recall':
          if (b.turn % 3 === 0) { beam = { x: px, t: 0 }; sfx.play('warn'); }
          else spread(cx, by, angry ? 11 : 7, angry ? 2.4 : 1.8, 180, '*', p.c3L);
          break;
      }
      b.cd = BOSSES[b.id].cd * (angry ? 0.7 : 1);
    }

    function update(dt: number) {
      clock += dt;
      for (const s of stars) { s.y += s.v * dt; if (s.y > h) { s.y = 0; s.x = rand(0, w); } }
      sparks = sparks.filter((s) => { s.x += s.vx * dt; s.y += s.vy * dt; s.vy += 120 * U * dt; s.life -= dt; return s.life > 0; });
      if (mode === 'over' || mode === 'won') return;
      const speed = 420 * U * dt;
      if (keys.has('ArrowLeft') || keys.has('a')) px -= speed;
      if (keys.has('ArrowRight') || keys.has('d')) px += speed;
      px = Math.max(PW, Math.min(w - PW, px));
      if (mode === 'banner') { timer -= dt; if (timer <= 0) mode = 'play'; return; }
      if (mode === 'dead') { timer -= dt; if (timer <= 0) { mode = 'play'; inv = 2; } }
      inv -= dt; dbl -= dt; rapid -= dt; cool -= dt;

      if (mode === 'play' && keys.has(' ') && cool <= 0 && shots.filter((s) => s.mine).length < (rapid > 0 ? 8 : 3)) {
        cool = rapid > 0 ? 0.13 : 0.32;
        const xs = dbl > 0 ? [px - PW * 0.35, px + PW * 0.35] : [px];
        for (const x of xs) shots.push({ x, y: py - lh * 0.4, vx: 0, vy: -640 * U, g: '|', c: p.accentL, mine: true });
        sfx.play('shoot');
      }

      for (const s of shots) { s.oy = s.y; s.x += s.vx * dt; s.y += s.vy * dt; }
      shots = shots.filter((s) => s.y > top - lh && s.y < h && s.x > 0 && s.x < w);
      for (const it of items) it.y += 110 * U * dt;
      items = items.filter((it) => it.y < h);

      if (enemies.length) {
        const sp = (16 + level * 5) * U * (1 + (1 - enemies.length / total) * 2);
        let lo = Infinity, hiX = -Infinity, low = 0;
        for (const e of enemies) { lo = Math.min(lo, e.x); hiX = Math.max(hiX, e.x + e.w); low = Math.max(low, e.y + e.h); }
        if ((dir > 0 && hiX + sp * dt > w - cw) || (dir < 0 && lo - sp * dt < cw)) { dir = -dir; for (const e of enemies) e.y += lh * 0.5; }
        else for (const e of enemies) e.x += dir * sp * dt;
        if (low >= py - lh * 0.2) { hurt(); for (const e of enemies) e.y -= lh * 4; }
        fireAcc += dt * (0.5 + level * 0.2);
        while (fireAcc >= 1) {
          fireAcc -= 1;
          const pickE = pick(enemies);
          const shooter = enemies.filter((e) => Math.abs(e.x - pickE.x) < cw).reduce((a, b) => (b.y > a.y ? b : a));
          shots.push({ x: shooter.x + shooter.w / 2, y: shooter.y + shooter.h, vx: 0, vy: (150 + level * 12) * U, g: '!', c: p.red, mine: false });
        }
      }

      if (boss) {
        const b = boss;
        b.x += b.vx * (b.hp < b.max / 2 ? 1.4 : 1) * dt;
        if (b.x < cw) { b.x = cw; b.vx = Math.abs(b.vx); }
        if (b.x + b.w > w - cw) { b.x = w - cw - b.w; b.vx = -Math.abs(b.vx); }
        b.cd -= dt;
        if (b.cd <= 0 && mode === 'play') bossAttack(b);
      }
      if (beam) {
        beam.t += dt;
        if (beam.t > 0.9 && beam.t < 1.5 && Math.abs(px - beam.x) < PW * 0.6) hurt();
        if (beam && beam.t >= 1.5) beam = null;
      }

      for (const s of shots) {
        if (!s.mine) {
          if (mode === 'play' && hitBox(s, { x: px - PW * 0.4, y: py + PH * 0.15, w: PW * 0.8, h: PH * 0.85 })) { s.y = h + 1; hurt(); }
          continue;
        }
        const e = enemies.find((en) => hitBox(s, en));
        if (e) {
          s.y = -h;
          if (--e.hp > 0) { e.flash = 0.12; sfx.play('bhit'); continue; }
          enemies.splice(enemies.indexOf(e), 1);
          addScore(e.pts);
          burst(e.x + e.w / 2, e.y + e.h / 2, APPS[e.app].map[Object.keys(APPS[e.app].map)[0]]);
          sfx.play('hit');
          if (Math.random() < 0.08) items.push({ x: e.x, y: e.y, k: Math.random() < 0.1 ? 'life' : pick<Drop>(['dbl', 'rapid', 'shield']) });
          continue;
        }
        if (boss && hitBox(s, boss)) {
          s.y = -h;
          boss.hp--;
          addScore(5);
          sfx.play('bhit');
          burst(s.x, s.y + lh, BOSS_COLOR(boss.id), 2);
          if (boss.hp <= 0) {
            const b = boss;
            addScore(1000 * (level / 3));
            for (let i = 0; i < 6; i++) burst(rand(b.x, b.x + b.w), rand(b.y, b.y + b.h), pick([p.c1L, p.c2L, p.c3L, p.yellow]), 14, '#');
            items.push({ x: b.x + b.w / 2, y: b.y + b.h, k: 'life' });
            sfx.play('boom');
            boss = null;
            beam = null;
            shots = shots.filter((sh) => sh.mine);
          }
        }
      }
      shots = shots.filter((s) => s.y > -h / 2 && s.y <= h);

      for (const it of items) {
        if (Math.abs(it.x + cw * 2 - px) < cw * 2 + PW / 2 && it.y + lh > py && it.y < py + PH) {
          it.y = h + 1;
          if (it.k === 'life') { lives++; sfx.play('life'); }
          else if (it.k === 'shield') { shield = true; sfx.play('shield'); }
          else { if (it.k === 'dbl') dbl = 10; else rapid = 10; sfx.play('power'); }
          addScore(50);
        }
      }

      if (mode === 'play' && !boss && !enemies.length && !items.length) {
        addScore(level * 100);
        if (level === LEVELS) {
          mode = 'won';
          sfx.play('win');
          if (score > hi) { hi = score; put('winvaders-hi', String(hi)); }
        } else { level++; startLevel(); }
      }
    }

    const beamTop = () => (boss ? boss.y + boss.h : top);

    const look = (cx: number, cy: number, r: number) => {
      const dx = px - cx, dy = py - cy, d = Math.hypot(dx, dy) || 1;
      return [cx + (dx / d) * r, cy + (dy / d) * r];
    };

    function drawBoss(b: Boss, pct: number) {
      const u = U, x = b.x, y = b.y, angry = b.hp < b.max / 2;
      ctx.save();
      ctx.lineCap = 'round';
      ctx.lineJoin = 'round';
      if (b.id === 'clippy') {
        const X = (n: number) => x + (n + 5) * u, Y = (n: number) => y + (n + 12) * u;
        const wire = () => {
          ctx.beginPath();
          ctx.moveTo(X(30), Y(115)); ctx.lineTo(X(30), Y(45)); ctx.arc(X(45), Y(45), 15 * u, Math.PI, 0);
          ctx.lineTo(X(60), Y(128)); ctx.arc(X(35), Y(128), 25 * u, 0, Math.PI);
          ctx.lineTo(X(10), Y(30)); ctx.arc(X(45), Y(30), 35 * u, Math.PI, 0); ctx.lineTo(X(80), Y(110));
          ctx.stroke();
        };
        ctx.strokeStyle = '#7d8594'; ctx.lineWidth = 9 * u; wire();
        ctx.strokeStyle = '#d9dee6'; ctx.lineWidth = 5 * u; wire();
        for (const ex of [28, 62]) {
          const cx = X(ex), cy = Y(42);
          ctx.fillStyle = '#ffffff'; ctx.strokeStyle = '#2a2a2a'; ctx.lineWidth = 2 * u;
          ctx.beginPath(); ctx.ellipse(cx, cy, 11 * u, 13 * u, 0, 0, Math.PI * 2); ctx.fill(); ctx.stroke();
          const [lx, ly] = look(cx, cy, 5 * u);
          ctx.fillStyle = '#111111'; ctx.beginPath(); ctx.arc(lx, ly, 4.5 * u, 0, Math.PI * 2); ctx.fill();
          const tilt = (ex < 45 ? 1 : -1) * (angry ? 6 : -3) * u;
          ctx.strokeStyle = '#2a2a2a'; ctx.lineWidth = 3.5 * u;
          ctx.beginPath(); ctx.moveTo(cx - 11 * u, cy - 19 * u - tilt); ctx.lineTo(cx + 11 * u, cy - 19 * u + tilt); ctx.stroke();
        }
      } else if (b.id === 'update') {
        ctx.fillStyle = '#0b2a52'; ctx.strokeStyle = '#3aa0ff'; ctx.lineWidth = 2 * u;
        ctx.beginPath(); ctx.roundRect(x, y, b.w, b.h, 10 * u); ctx.fill(); ctx.stroke();
        const cx = x + b.w / 2, cy = y + 30 * u;
        for (let i = 0; i < 6; i++) {
          const a = clock * 4 - i * 0.45;
          ctx.globalAlpha = 1 - i * 0.15;
          ctx.fillStyle = '#ffffff';
          ctx.beginPath(); ctx.arc(cx + Math.cos(a) * 14 * u, cy + Math.sin(a) * 14 * u, 2.6 * u, 0, Math.PI * 2); ctx.fill();
        }
        ctx.globalAlpha = 1;
        const t = (s: string, ty: number, size: number) => { ctx.font = `600 ${size * u}px Inter, sans-serif`; ctx.fillStyle = '#ffffff'; ctx.fillText(s, cx - ctx.measureText(s).width / 2, ty); };
        t(`Working on updates  ${pct}% complete`, y + 56 * u, 13);
        t("Don't turn off your PC. This will take a while.", y + 76 * u, 10);
        ctx.fillStyle = '#1d4677'; ctx.fillRect(x + 24 * u, y + 102 * u, b.w - 48 * u, 8 * u);
        ctx.fillStyle = '#3aa0ff'; ctx.fillRect(x + 24 * u, y + 102 * u, ((b.w - 48 * u) * pct) / 100, 8 * u);
      } else if (b.id === 'bsod') {
        ctx.fillStyle = '#0a5ed7'; ctx.fillRect(x, y, b.w, b.h);
        ctx.fillStyle = '#ffffff';
        ctx.font = `400 ${46 * u}px Inter, sans-serif`; ctx.fillText(':(', x + 18 * u, y + 10 * u);
        ctx.font = `500 ${11 * u}px Inter, sans-serif`;
        ctx.fillText('Your PC ran into a problem and needs to', x + 18 * u, y + 70 * u);
        ctx.fillText(`restart. ${pct}% complete`, x + 18 * u, y + 86 * u);
        const q = 5 * u, qx = x + 18 * u, qy = y + 110 * u;
        for (let i = 0; i < 49; i++) if ((i * 37 + (i >> 3) * 11) % 5 < 3 || i % 8 === 0) ctx.fillRect(qx + (i % 7) * q, qy + ((i / 7) | 0) * q, q, q);
        ctx.font = `500 ${9 * u}px Inter, sans-serif`;
        ctx.fillText('Stop code: CRITICAL_PROCESS_DIED', x + 62 * u, y + 118 * u);
        ctx.fillText(angry ? 'Collecting error info... a lot of it' : 'For more info, search online later', x + 62 * u, y + 134 * u);
      } else {
        const cx = x + b.w / 2, cy = y + b.h / 2, rx = b.w / 2 - 6 * u, ry = b.h / 2 - 14 * u;
        const almond = () => { ctx.beginPath(); ctx.moveTo(cx - rx, cy); ctx.quadraticCurveTo(cx, cy - ry * 2, cx + rx, cy); ctx.quadraticCurveTo(cx, cy + ry * 2, cx - rx, cy); ctx.closePath(); };
        ctx.strokeStyle = p.c3L; ctx.lineWidth = 3 * u;
        for (let i = 0; i < 7; i++) {
          const t = (i + 1) / 8, lx = cx - rx + t * rx * 2, ly = cy - ry * 2 * 2 * t * (1 - t) * 0.98;
          ctx.beginPath(); ctx.moveTo(lx, ly); ctx.lineTo(lx + (t - 0.5) * 18 * u, ly - 14 * u); ctx.stroke();
        }
        almond(); ctx.fillStyle = '#eef0ff'; ctx.fill();
        ctx.save(); almond(); ctx.clip();
        const [ix, iy] = look(cx, cy, 22 * u);
        const charging = !!beam && beam.t < 1.5;
        const g = ctx.createRadialGradient(ix, iy, 4 * u, ix, iy, 30 * u);
        g.addColorStop(0, charging ? '#ffd0d0' : p.c2L); g.addColorStop(1, charging ? '#e02040' : p.c3);
        ctx.fillStyle = g; ctx.beginPath(); ctx.arc(ix, iy, 30 * u, 0, Math.PI * 2); ctx.fill();
        ctx.fillStyle = '#0a0a12'; ctx.beginPath(); ctx.arc(ix, iy, (charging ? 8 : 13) * u, 0, Math.PI * 2); ctx.fill();
        ctx.fillStyle = '#ffffff'; ctx.beginPath(); ctx.arc(ix - 8 * u, iy - 8 * u, 4 * u, 0, Math.PI * 2); ctx.fill();
        ctx.restore();
        almond(); ctx.strokeStyle = p.c3L; ctx.lineWidth = 4 * u; ctx.stroke();
        if (Math.floor(clock * 2) % 2) { ctx.fillStyle = '#ff3b4e'; ctx.beginPath(); ctx.arc(x + 10 * u, y + 10 * u, 5 * u, 0, Math.PI * 2); ctx.fill(); }
        ctx.font = `700 ${10 * u}px 'JetBrains Mono', monospace`; ctx.fillStyle = '#ff3b4e'; ctx.fillText('REC', x + 20 * u, y + 5 * u);
      }
      ctx.restore();
    }

    function draw() {
      ctx.clearRect(0, 0, w, h);
      ctx.textBaseline = 'top';
      ctx.fillStyle = p.dim;
      for (const s of stars) ctx.fillRect(s.x, s.y, U * (s.v > 25 * U ? 2 : 1), U * (s.v > 25 * U ? 2 : 1));

      const blink = Math.floor(clock * 2) % 2;
      enemies.forEach((e, i) => {
        e.flash -= 1 / 60;
        const bob = (i + (blink ? 1 : 0)) % 2 ? S : 0;
        if (e.hp > 1) { ctx.strokeStyle = p.text; ctx.lineWidth = U * 1.5; ctx.strokeRect(e.x - 2 * U, e.y + bob - 2 * U, e.w + 4 * U, e.h + 4 * U); }
        ctx.globalAlpha = e.flash > 0 ? 0.35 : 1;
        ctx.drawImage(ICONS[e.app], e.x, e.y + bob);
        ctx.globalAlpha = 1;
      });

      if (boss) {
        const d = BOSSES[boss.id];
        const pct = Math.round((1 - boss.hp / boss.max) * 100);
        drawBoss(boss, pct);
        const barW = Math.min(w * 0.5, cw * 40);
        const bx = (w - barW) / 2, bt = top - lh * 0.1;
        center(`${d.name}`, bt - lh * 1.1, BOSS_COLOR(boss.id));
        ctx.fillStyle = p.dim; ctx.fillRect(bx, bt, barW, U * 5);
        ctx.fillStyle = p.red; ctx.fillRect(bx, bt, (barW * boss.hp) / boss.max, U * 5);
        const say = d.taunts[Math.floor(clock / 3) % d.taunts.length];
        ctx.font = font(Math.round(F * 0.8));
        const sw = ctx.measureText(say).width;
        text(say, Math.max(cw, Math.min(w - cw - sw, boss.x + boss.w / 2 - sw / 2)), boss.y + boss.h + lh * 0.4, p.text2, Math.round(F * 0.8));
      }

      if (beam) {
        if (beam.t < 0.9) { if (Math.floor(beam.t * 10) % 2) for (let y = beamTop(); y < h - lh; y += lh) text(':', beam.x - cw / 2, y, p.c3L); }
        else { ctx.fillStyle = p.c3L; ctx.globalAlpha = 0.75; ctx.fillRect(beam.x - PW * 0.4, beamTop(), PW * 0.8, h); ctx.globalAlpha = 1; }
      }

      for (const s of shots) text(s.g, s.x - (cw * s.g.length) / 2, s.y, s.c);
      for (const it of items) text(DROPS[it.k], it.x, it.y, it.k === 'life' ? p.green : p.yellow);

      if (mode !== 'over' && mode !== 'dead' && !(inv > 0 && Math.floor(clock * 12) % 2)) {
        ctx.drawImage(SHIP, px - PW / 2, py);
        ctx.fillStyle = blink ? p.yellow : p.c3L;
        ctx.fillRect(px - S, py + PH, S * 2, S * (blink ? 2 : 1));
        if (shield) { ctx.strokeStyle = p.cyan; ctx.lineWidth = 2 * U; ctx.beginPath(); ctx.ellipse(px, py + PH / 2, PW * 0.8, PH * 0.9, 0, 0, Math.PI * 2); ctx.stroke(); }
      }

      for (const s of sparks) { ctx.globalAlpha = Math.min(1, s.life * 2); text(s.g, s.x, s.y, s.c); }
      ctx.globalAlpha = 1;

      const pad = cw;
      text(`SCORE ${String(score).padStart(6, '0')}`, pad, lh * 0.4, p.text);
      center(`LEVEL ${String(level).padStart(2, '0')}/${LEVELS}   HI ${String(Math.max(hi, score)).padStart(6, '0')}`, lh * 0.4, p.text2);
      const lv = `${'♥'.repeat(Math.min(lives, 6))}${lives > 6 ? `+${lives - 6}` : ''}`;
      ctx.font = font(F);
      text(lv, w - pad - ctx.measureText(lv).width, lh * 0.4, p.red);
      const pw = [dbl > 0 ? `2X ${Math.ceil(dbl)}s` : '', rapid > 0 ? `RAPID ${Math.ceil(rapid)}s` : '', shield ? 'SHIELD' : '', sfx.muted ? 'MUTED' : ''].filter(Boolean).join('   ');
      if (pw) text(pw, pad, lh * 1.3, p.yellow, Math.round(F * 0.8));
      center('← → move   space fire   P pause   M mute   Esc quit', h - lh * 1.2, p.dim, Math.round(F * 0.75));

      const mid = h * 0.42;
      if (mode === 'banner') {
        const id = bossFor(level);
        center(id ? `BOSS: ${BOSSES[id].name}` : `LEVEL ${level}`, mid, id ? p.c3L : p.accentL, F * 2);
        center(id ? 'Warning: incoming mandatory update' : `${enemies.length} apps want to run at startup`, mid + lh * 2.2, p.text2);
      } else if (mode === 'over') {
        center('GAME OVER', mid, p.red, F * 2.4);
        center(`Windows won this time. Score ${score}`, mid + lh * 2.4, p.text);
        center('Enter to try again   Esc to quit', mid + lh * 3.6, p.dim);
      } else if (mode === 'won') {
        center('WINDOWS UNINSTALLED', mid, p.green, F * 2.2);
        center(`You switched to Arch, btw. Score ${score}`, mid + lh * 2.4, p.text);
        center('Enter to play again   Esc to quit', mid + lh * 3.6, p.dim);
      } else if (paused) center('PAUSED', mid, p.yellow, F * 2);
    }

    const GAME = new Set(['ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown', ' ', 'Enter', 'Tab', 'Backspace']);
    const down = (ev: KeyboardEvent) => {
      if (ev.key === 'Escape' || ev.ctrlKey || ev.metaKey || ev.altKey || (ev.key.length > 1 && !GAME.has(ev.key))) return;
      ev.preventDefault();
      ev.stopPropagation();
      const k = ev.key.length === 1 ? ev.key.toLowerCase() : ev.key;
      if (k === 'p' && (mode === 'play' || mode === 'dead')) paused = !paused;
      else if (k === 'm') sfx.muted = !sfx.muted;
      else if ((k === 'Enter' || k === 'r') && (mode === 'over' || mode === 'won')) reset();
      keys.add(k);
    };
    const up = (ev: KeyboardEvent) => { keys.delete(ev.key.length === 1 ? ev.key.toLowerCase() : ev.key); };
    const blur = () => keys.clear();
    window.addEventListener('keydown', down, true);
    window.addEventListener('keyup', up, true);
    window.addEventListener('blur', blur);

    startLevel();
    let last = performance.now();
    const frame = () => {
      const now = performance.now();
      const dt = Math.min(0.05, (now - last) / 1000);
      last = now;
      if (!paused) update(dt);
      draw();
    };
    const dispose = () => {
      window.removeEventListener('keydown', down, true);
      window.removeEventListener('keyup', up, true);
      window.removeEventListener('blur', blur);
      sfx.close();
    };
    return Object.assign(frame, { dispose });
  };
}
