import { STACKED as MOBILE } from './layout';
import { THEMES, THEME_IDS, type ThemeId } from '../data/themes';
import { activePalette, currentTheme, setTheme } from './theme';
import { FESTIVE_IDS, FESTIVITIES, type FestiveId } from '../data/festive';
import { festiveState, forceFestive, setFestiveOn } from './festive';
import { navigate } from 'astro:transitions/client';

interface TermData {
  changelog: { date: string; iso: string[]; tui: string[] }[];
  editions: { name: string; file: string; sizeGB: string; sha256: string; release: number; total: number }[];
  path: string;
}
interface Line { t: string; c?: string; kind?: 'fetch' | 'help' | 'cmd' | 'themes'; p?: string; at?: number }

const KEY = 'xero-term';
const PAGES: Record<string, string> = { '': '/', about: '/about/', gear: '/gear/', tools: '/tools/', support: '/support/', download: '/download/' };
const FORTUNES = [
  'Your desktop, your rules, we just provide the toolkit.',
  'Point. Click. Rice. No config files harmed.',
  'Because editing dotfiles at 3am gets old.',
  'All the customization, none of the dependency rabbit holes.',
  'Rice responsibly. Or don\'t. We won\'t judge.',
  'Because pacman -Syu deserves a face.',
  'Managing packages should not require a man page.',
  'Built in Rust. No Electron. No regrets.',
  'Arch Linux package management, finally civilised.',
];
const COMMANDS = ['help', 'ls', 'cd', 'pwd', 'clear', 'exit', 'history', 'whoami', 'neofetch', 'fastfetch', 'btop', 'htop', 'top', 'theme', 'changelog', 'download', 'sha256sum', 'pacman', 'checkupdates', 'reflector', 'uname', 'archinstall', 'cmatrix', 'matrix', 'pipes', 'fortune', 'cowsay', 'btw', 'vim', 'emacs', 'nano', 'sudo', 'yay', 'paru', 'make'];
const LOGO = [
  '\\\\\\\\        ////',
  ' \\\\\\\\      //// ',
  '  \\\\\\\\    ////  ',
  '   \\\\\\\\  ////   ',
  '    \\\\\\\\////    ',
  '    ////\\\\\\\\    ',
  '   ////  \\\\\\\\   ',
  '  ////    \\\\\\\\  ',
  ' ////      \\\\\\\\ ',
  '////        \\\\\\\\',
];
const LOGO_COLORS = ['c-blue', 'c-blue', 'c-blue', 'c-purple', 'c-purple', 'c-purple', 'c-purple', 'c-pink', 'c-pink', 'c-pink'];
const RIG = { host: 'StationXero', cpu: 'AMD Ryzen 9 5950X', gpu: 'AMD Radeon RX 7800XT', ram: '32 GB DDR4 @ 3200 MT/s' };
const LGL = 'https://linuxgamerlife.net/';
const HELP: [string, [string, string][]][] = [
  ['Navigation', [
    ['ls', 'List site pages'],
    ['cd <page>', 'Open a page, e.g. cd ~/gear (cd ~ for home)'],
    ['pwd', 'Print the current page path'],
    ['history', 'Show commands typed this session'],
    ['clear', 'Clear the screen (Ctrl+L)'],
    ['exit', 'Close the terminal (Esc)'],
  ]],
  ['System', [
    ['fastfetch', 'System info with StationXero specs (alias: neofetch)'],
    ['btop', 'Live browser monitor (aliases: htop, top), q to quit'],
    ['whoami', 'Print the current user'],
    ['theme [name|random]', 'List or switch site themes'],
  ]],
  ['XeroLinux', [
    ['changelog', 'Notes for the current release'],
    ['download', 'ISO editions, file names and sizes'],
    ['sha256sum <file>', 'Checksum of an ISO file'],
  ]],
  ['Arch', [
    ['sudo pacman -Syu', 'Full system upgrade, then reloads the page'],
    ['sudo pacman -S <pkg>', 'Install a package'],
    ['sudo pacman -R <pkg>', 'Remove a package (-Rns works too)'],
    ['pacman -Ss <query>', 'Search the repos'],
    ['pacman -Q', 'List installed packages'],
    ['sudo pacman -Sc', 'Clean the package cache'],
    ['checkupdates', 'List pending updates'],
    ['sudo reflector', 'Rate mirrors and save the mirrorlist'],
    ['uname -a', 'Kernel and system info'],
    ['archinstall', 'Install Arch the hard way'],
  ]],
  ['Screensavers', [
    ['cmatrix', 'Matrix rain (alias: matrix), any key to stop'],
    ['pipes', 'The pipes.sh screensaver, any key to stop'],
  ]],
  ['Fun', [
    ['fortune', 'A random XeroLinux one-liner'],
    ['cowsay <text>', 'A cow says your text'],
    ['btw', 'You know what this does'],
    ['vim', 'Opens vim. Good luck leaving'],
    ['emacs, nano', 'Wrong editor'],
    ['sudo <cmd>', 'Run as root (pacman and reflector only)'],
    ['yay, paru', 'AUR helpers'],
    ['make me a sandwich', 'Try it, then try it with sudo'],
  ]],
];
const strip = (s: string) => s.replace(/<[^>]+>/g, '');
const fmt = (n: number) => n.toLocaleString('en-US');

interface State { lines: Line[]; hist: string[]; vim: boolean; inst?: string[] }
function load(): State {
  try {
    const s = JSON.parse(sessionStorage.getItem(KEY) ?? 'null') as State | null;
    if (s) return s;
  } catch { /* storage blocked */ }
  return { lines: [], hist: [], vim: false };
}

let state = load();
let saverStop: (() => void) | null = null;
let clockTimer = 0;

function save() {
  try { sessionStorage.setItem(KEY, JSON.stringify({ ...state, lines: state.lines.slice(-300) })); } catch { /* storage blocked */ }
}

function els() {
  const term = document.querySelector<HTMLElement>('[data-term]');
  if (!term) return null;
  return {
    term,
    out: term.querySelector<HTMLElement>('[data-term-out]')!,
    input: term.querySelector<HTMLInputElement>('[data-term-in]')!,
    prompt: term.querySelector<HTMLElement>('[data-term-prompt]')!,
    btn: document.querySelector<HTMLButtonElement>('[data-term-open]'),
    data: JSON.parse(document.getElementById('term-data')?.textContent ?? '{}') as TermData,
  };
}

function cwd(data: TermData) {
  const seg = data.path.replace(/^\/|\/$/g, '');
  return seg ? `~/${seg}` : '~';
}

function paint(e: NonNullable<ReturnType<typeof els>>) {
  e.out.replaceChildren(...state.lines.map((l) => {
    if (l.kind === 'fetch') return fastfetch(e.data);
    if (l.kind === 'help') return helpTable();
    if (l.kind === 'themes') return themeList();
    if (l.kind === 'cmd') return echo(l.p ?? '~', l.t, l.at);
    const div = document.createElement('div');
    div.textContent = l.t;
    if (l.c) div.className = l.c;
    return div;
  }));
  e.prompt.replaceChildren(state.vim ? document.createTextNode(':') : posh(cwd(e.data)));
  e.out.scrollTop = e.out.scrollHeight;
}

const ICO: Record<string, string> = {
  term: '<path d="m4 17 6-5-6-5"/><path d="M12 19h8"/>',
  link: '<path d="M10 13a5 5 0 0 0 7.5.5l3-3a5 5 0 0 0-7-7l-1.7 1.7"/><path d="M14 11a5 5 0 0 0-7.5-.5l-3 3a5 5 0 0 0 7 7l1.7-1.7"/>',
  clock: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
  cal: '<rect x="3" y="5" width="18" height="16" rx="2"/><path d="M16 3v4M8 3v4M3 11h18"/>',
  user: '<circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/>',
  host: '<rect x="3" y="4" width="18" height="12" rx="2"/><path d="M8 20h8M12 16v4"/>',
  home: '<path d="m3 11 9-8 9 8"/><path d="M5 10v10h14V10"/>',
  dir: '<path d="M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>',
  caret: '<path d="m9 6 6 6-6 6"/>',
};
const ico = (n: string) => `<svg class="pico" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${ICO[n]}</svg>`;

function posh(path: string, at?: number) {
  const div = document.createElement('div');
  div.className = 'tposh';
  div.innerHTML = `<div class="pl1"><span class="seg s1"><img src="/logos/xero-icon.webp" alt="" />XERO</span><span class="seg s2">${ico('term')}xsh</span><a class="seg s3" href="${LGL}" target="_blank" rel="noopener noreferrer">${ico('link')}inspired by LinuxGamerLife.net</a></div>`
    + `<div class="ptree"><div class="prow c-pink">${ico('clock')}<span data-pclock></span><i>|</i>${ico('cal')}<span data-pdate></span></div>`
    + `<div class="prow c-blue">${ico('user')}<span>darkxero</span><i>|</i>${ico('host')}<span>StationXero</span></div>`
    + `<div class="prow c-green">${ico(path === '~' ? 'home' : 'dir')}<span data-ppath></span></div></div>`;
  div.querySelector('[data-ppath]')!.textContent = path === '~' ? '' : path;
  stamp(div, at);
  return div;
}

function stamp(root: ParentNode, at?: number) {
  const now = at ? new Date(at) : new Date();
  const clock = root.querySelector('[data-pclock]');
  const date = root.querySelector('[data-pdate]');
  if (clock) clock.textContent = now.toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit', second: '2-digit' });
  if (date) date.textContent = now.toLocaleDateString(undefined, { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' });
}

function echo(path: string, cmd: string, at?: number) {
  const div = posh(path, at);
  div.classList.add('techo');
  const row = document.createElement('div');
  row.className = 'tin';
  row.innerHTML = `<span class="tcorner" aria-hidden="true"></span>${ico('caret').replace('pico', 'pico tcaret')}<span class="tcmd"></span>`;
  row.querySelector('.tcmd')!.textContent = cmd;
  div.append(row);
  return div;
}

function helpTable() {
  const table = document.createElement('table');
  table.className = 'thelp';
  HELP.forEach(([group, rows], g) => {
    const head = table.insertRow();
    head.className = `hg g${g % 6}`;
    const th = document.createElement('th');
    th.colSpan = 2;
    const chip = document.createElement('span');
    chip.textContent = group;
    th.append(chip);
    head.append(th);
    for (const [cmd, desc] of rows) {
      const tr = table.insertRow();
      tr.className = `g${g % 6}`;
      tr.insertCell().textContent = cmd;
      tr.insertCell().textContent = desc;
    }
  });
  const note = table.createTFoot().insertRow().insertCell();
  note.colSpan = 2;
  note.textContent = 'Tab completes, Up/Down for history, chain with && (e.g. clear && fastfetch)';
  return table;
}

function print(text: string | string[], c?: string) {
  for (const t of Array.isArray(text) ? text : text.split('\n')) state.lines.push({ t, c });
}

function cowsay(text: string) {
  const msg = text || 'moo';
  const bar = '-'.repeat(msg.length + 2);
  return [` ${'_'.repeat(msg.length + 2)}`, `< ${msg} >`, ` ${bar}`, '        \\   ^__^', '         \\  (oo)\\_______', '            (__)\\       )\\/\\', '                ||----w |', '                ||     ||'];
}

function row(parts: [string, string?][]) {
  const div = document.createElement('div');
  for (const [t, c] of parts) {
    const span = document.createElement('span');
    span.textContent = t;
    if (c) span.className = c;
    div.append(span);
  }
  return div;
}

function fastfetch(data: TermData) {
  const all = data.editions.reduce((n, x) => n + x.total, 0);
  const rel = data.editions.reduce((n, x) => n + x.release, 0);
  const ver = data.editions[0]?.file.match(/\d{4}\.\d{2}/)?.[0] ?? '';
  const info: [string, string][] = [
    ['OS', 'XeroLinux x86_64'],
    ['Host', RIG.host],
    ['Base', 'Arch Linux'],
    ['DE', 'KDE Plasma 6'],
    ['WM', 'KWin (Wayland)'],
    ['CPU', RIG.cpu],
    ['GPU', RIG.gpu],
    ['Memory', RIG.ram],
    ['ISO', `${ver} (Intel/AMD, nVidia)`],
    ['Downloads', `${fmt(all)} all-time, ${fmt(rel)} this release`],
    ['Uptime', `${new Date().getFullYear() - 2020} years (since 2020)`],
    ['Shell', 'xsh 1.0'],
    ['Theme', `${activePalette().name} [Xero]`],
  ];
  const labels = ['c-blue', 'c-purple', 'c-pink'];
  const rows: [string, string?][][] = [
    [['darkxero', 'c-pink'], ['@', 'tdim'], ['StationXero', 'c-blue']],
    [['-'.repeat(20), 'tdim']],
    ...info.map(([k, v], i): [string, string?][] => [[`${k}: `, labels[i % 3]], [v]]),
    [],
    ['b1', 'b2', 'b3', 'b4', 'b5', 'b6', 'b7', 'b8'].map((c): [string, string] => ['   ', `tblk ${c}`]),
  ];
  const wrap = document.createElement('div');
  wrap.className = 'tff';
  const logo = document.createElement('div');
  logo.className = 'tfflogo';
  logo.setAttribute('aria-hidden', 'true');
  logo.append(...LOGO.map((l, i) => row([[l, LOGO_COLORS[i]]])));
  const list = document.createElement('div');
  list.className = 'tffinfo';
  list.append(...rows.map(row));
  wrap.append(logo, list);
  return wrap;
}

type Saver = (ctx: CanvasRenderingContext2D, w: number, h: number, dpr: number) => () => void;

const themeColors = () => { const p = activePalette(); return [p.c1, p.c1L, p.c2, p.c2L, p.c3, p.c3L]; };
let THEME: string[];

function themeList() {
  const cur = currentTheme();
  const wrap = document.createElement('div');
  for (const id of THEME_IDS) {
    const p = THEMES[id];
    const line = row([[id === cur ? '* ' : '  ', 'tok'], [id.padEnd(18), id === cur ? 'tok' : 'tcmd']]);
    for (const c of [p.bg, p.c1, p.c2, p.c3, p.c1L, p.c2L, p.c3L, p.green]) {
      const sw = document.createElement('span');
      sw.className = 'tblk';
      sw.style.background = c;
      sw.textContent = '  ';
      line.append(sw);
    }
    line.append(Object.assign(document.createElement('span'), { className: 'tdim', textContent: `  ${p.name}` }));
    wrap.append(line);
  }
  return wrap;
}

function glyphAtlas(chars: string[], colors: string[], size: number, dpr: number) {
  const cw = Math.ceil(size * 0.62 * dpr);
  const ch = Math.ceil(size * 1.2 * dpr);
  const atlas = document.createElement('canvas');
  atlas.width = cw * chars.length;
  atlas.height = ch * colors.length;
  const a = atlas.getContext('2d')!;
  a.font = `700 ${size * dpr}px 'JetBrains Mono', monospace`;
  a.textBaseline = 'top';
  colors.forEach((c, row) => {
    a.fillStyle = c;
    chars.forEach((g, col) => a.fillText(g, col * cw, row * ch));
  });
  return { atlas, cw, ch };
}

const cmatrix: Saver = (ctx, w, h, dpr) => {
  const size = 16;
  const chars = '0123456789ABCDEFXEROLINUX<>/{}[]#$%&*+=?'.split('');
  const colors = [...THEME, activePalette().text];
  const head = colors.length - 1;
  const { atlas, cw, ch } = glyphAtlas(chars, colors, size, dpr);
  const cols = Math.floor(w / cw);
  const rows = Math.ceil(h / ch);
  const y = Array.from({ length: cols }, () => -Math.floor(Math.random() * rows));
  const tint = Array.from({ length: cols }, (_, i) => Math.min(THEME.length - 1, Math.floor((i / cols) * THEME.length)));
  const speed = Array.from({ length: cols }, () => 0.18 + Math.random() * 0.37);
  const acc = new Float32Array(cols);
  const TRAIL = 26;
  const glyph = (col: number, row: number, color: number) => {
    const g = (Math.random() * chars.length) | 0;
    ctx.clearRect(col * cw, row * ch, cw, ch);
    ctx.drawImage(atlas, g * cw, color * ch, cw, ch, col * cw, row * ch, cw, ch);
  };
  return () => {
    ctx.globalCompositeOperation = 'destination-out';
    ctx.fillStyle = 'rgba(0,0,0,0.09)';
    ctx.fillRect(0, 0, w, h);
    ctx.globalCompositeOperation = 'source-over';
    for (let i = 0; i < cols; i++) {
      acc[i] += speed[i];
      if (acc[i] < 1) continue;
      acc[i] -= 1;
      const r = y[i];
      if (r > 0 && r - 1 < rows) glyph(i, r - 1, tint[i]);
      if (r >= 0 && r < rows) glyph(i, r, head);
      const tail = r - TRAIL;
      if (tail >= 0 && tail < rows) ctx.clearRect(i * cw, tail * ch, cw, ch);
      y[i] = r > rows + TRAIL && Math.random() > 0.9 ? -Math.floor(Math.random() * 10) : r + 1;
    }
  };
};

const pipes: Saver = (ctx, w, h, dpr) => {
  const cell = 18 * dpr;
  const cols = Math.floor(w / cell);
  const rows = Math.floor(h / cell);
  const step = [[0, -1], [1, 0], [0, 1], [-1, 0]];
  const spawn = () => ({ x: (Math.random() * cols) | 0, y: (Math.random() * rows) | 0, d: (Math.random() * 4) | 0, c: THEME[(Math.random() * THEME.length) | 0] });
  let list = Array.from({ length: 4 }, spawn);
  let drawn = 0;
  const mid = (n: number) => n * cell + cell / 2;
  ctx.lineWidth = 5 * dpr;
  ctx.lineCap = 'square';
  return () => {
    for (const p of list) {
      if (Math.random() < 0.18) p.d = (p.d + (Math.random() < 0.5 ? 1 : 3)) % 4;
      const nx = p.x + step[p.d][0];
      const ny = p.y + step[p.d][1];
      if (nx < 0 || nx >= cols || ny < 0 || ny >= rows) { Object.assign(p, spawn()); continue; }
      ctx.strokeStyle = p.c;
      ctx.beginPath();
      ctx.moveTo(mid(p.x), mid(p.y));
      ctx.lineTo(mid(nx), mid(ny));
      ctx.stroke();
      p.x = nx;
      p.y = ny;
    }
    drawn += list.length;
    if (drawn > cols * rows * 1.5) { ctx.clearRect(0, 0, w, h); drawn = 0; list = Array.from({ length: 4 }, spawn); }
  };
};

function screensaver(e: NonNullable<ReturnType<typeof els>>, saver: Saver, frameMs: number, quit?: string[]) {
  const canvas = document.createElement('canvas');
  canvas.className = 'tmatrix';
  canvas.setAttribute('aria-hidden', 'true');
  e.term.append(canvas);
  e.term.classList.add('saver');
  THEME = themeColors();
  BT = btColors();
  const dpr = Math.min(window.devicePixelRatio || 1, 2);
  canvas.width = Math.round(canvas.clientWidth * dpr);
  canvas.height = Math.round(canvas.clientHeight * dpr);
  const frame = saver(canvas.getContext('2d')!, canvas.width, canvas.height, dpr);
  frame();
  let last = performance.now();
  let raf = 0;
  const loop = (ts: number) => {
    raf = requestAnimationFrame(loop);
    if (ts - last < frameMs) return;
    last = ts;
    frame();
  };
  raf = requestAnimationFrame(loop);
  const stop = () => {
    cancelAnimationFrame(raf);
    canvas.remove();
    e.term.classList.remove('saver');
    window.removeEventListener('keydown', onKey, true);
    canvas.removeEventListener('click', stop);
    document.removeEventListener('xero-theme', restart);
    saverStop = null;
    e.input.focus();
  };
  const onKey = (ev: KeyboardEvent) => {
    if (quit && !quit.includes(ev.key)) return;
    ev.preventDefault();
    ev.stopPropagation();
    stop();
  };
  const restart = () => { stop(); screensaver(e, saver, frameMs, quit); };
  window.addEventListener('keydown', onKey, true);
  document.addEventListener('xero-theme', restart);
  if (!quit) canvas.addEventListener('click', stop);
  saverStop = stop;
}

const btColors = () => {
  const p = activePalette();
  return { text: p.text2, dim: mix(p.term, p.dim, 0.3), mid: p.dim, hi: p.text, cpu: p.c2L, mem: p.green, net: p.red, proc: p.cyan, blue: p.c1L, pink: p.c3L, c1: p.c1, c3: p.c3, hot: p.red, ink: p.term, memDim: mix(p.green, '#000000', 0.45) };
};
let BT: ReturnType<typeof btColors>;
const BT_PROCS: [string, string, number, number][] = [
  ['cs2', '/home/darkxero/.local/share/Steam/steamapps/common/cs2/cs2', 14, 3900],
  ['firefox', '/usr/lib/firefox/firefox', 6, 1650],
  ['obs', '/usr/bin/obs --startreplaybuffer', 5, 690],
  ['kwin_wayland', '/usr/bin/kwin_wayland --wayland-fd 7', 4, 410],
  ['Isolated Web', '/usr/lib/firefox/firefox -contentproc', 4, 780],
  ['plasmashell', '/usr/bin/plasmashell --no-respawn', 3.5, 520],
  ['code', '/opt/visual-studio-code/code --ozone-platform=wayland', 2.2, 930],
  ['steam', '/home/darkxero/.local/share/Steam/ubuntu12_32/steam', 2, 640],
  ['discord', '/opt/discord/Discord --enable-features=UseOzonePlatform', 1.5, 560],
  ['Xwayland', '/usr/bin/Xwayland :0 -rootless', 0.9, 150],
  ['btop', 'btop', 0.8, 9],
  ['pipewire', '/usr/bin/pipewire', 0.7, 24],
  ['konsole', '/usr/bin/konsole', 0.6, 120],
  ['scx_lavd', '/usr/bin/scx_lavd --performance', 0.6, 18],
  ['baloo_file', '/usr/lib/baloo_file', 0.5, 88],
  ['xpackagemana', '/usr/bin/xpackagemanager', 0.4, 96],
  ['dolphin', '/usr/bin/dolphin', 0.3, 210],
  ['wireplumber', '/usr/bin/wireplumber', 0.3, 38],
  ['kdeconnectd', '/usr/lib/kdeconnectd', 0.2, 64],
  ['spectacle', '/usr/bin/spectacle -b', 0.1, 180],
  ['zsh', '/usr/bin/zsh', 0.1, 12],
  ['systemd', '/usr/lib/systemd/systemd --user', 0.1, 14],
];

const clamp = (v: number, lo: number, hi: number) => Math.max(lo, Math.min(hi, v));
const walk = (v: number, target: number, k: number, noise: number, lo = 0, hi = 100) => clamp(v + (target - v) * k + (Math.random() - 0.5) * noise, lo, hi);
const mix = (a: string, b: string, t: number) => {
  const p = (h: string, i: number) => parseInt(h.slice(1 + i * 2, 3 + i * 2), 16);
  return `#${[0, 1, 2].map((i) => Math.round(p(a, i) + (p(b, i) - p(a, i)) * t).toString(16).padStart(2, '0')).join('')}`;
};
const heat = (t: number) => (t < 0.5 ? mix(BT.c1, BT.cpu, t * 2) : mix(BT.cpu, BT.hot, (t - 0.5) * 2));
const human = (kib: number) => (kib >= 1024 ? `${(kib / 1024).toFixed(2)} MiB/s` : `${kib.toFixed(2)} KiB/s`);

const btopSaver: Saver = (ctx, w, h, dpr) => {
  ctx.scale(dpr, dpr);
  const W = w / dpr;
  const H = h / dpr;
  const fs = clamp(Math.floor(Math.min(W / 112 / 0.6, H / 40)), 10, 15);
  const font = (b = false) => `${b ? '700 ' : ''}${fs}px 'JetBrains Mono', monospace`;
  ctx.font = font();
  const cw = ctx.measureText('M').width;
  const lh = Math.round(fs * 1.38);
  const C = Math.floor(W / cw);
  const R = Math.floor(H / lh);
  const ox = (W - C * cw) / 2;
  const oy = (H - R * lh) / 2;
  const X = (c: number) => ox + c * cw;
  const Y = (r: number) => oy + r * lh;
  ctx.textBaseline = 'middle';

  const txt = (c: number, r: number, str: string, col: string, bold = false) => {
    ctx.font = font(bold);
    ctx.fillStyle = col;
    ctx.fillText(str, X(c), Y(r) + lh / 2);
  };
  const rtxt = (end: number, r: number, str: string, col: string, bold = false) => txt(end - str.length, r, str, col, bold);
  type Title = { c: number; s: string; col?: string; bottom?: boolean };
  const box = (c: number, r: number, bw: number, bh: number, col: string, titles: Title[] = []) => {
    const x0 = X(c) + cw / 2;
    const x1 = X(c + bw - 1) + cw / 2;
    const y0 = Y(r) + lh / 2;
    const y1 = Y(r + bh - 1) + lh / 2;
    const rad = Math.min(6, cw);
    const edge = (y: number, bottom: boolean) => {
      const gaps = titles.filter((t) => !!t.bottom === bottom).map((t) => [X(t.c) - cw * 0.5, X(t.c + t.s.length) + cw * 0.5]).sort((a, b) => a[0] - b[0]);
      let x = x0 + rad;
      for (const [g0, g1] of gaps) {
        if (g0 > x) { ctx.moveTo(x, y); ctx.lineTo(g0, y); }
        x = Math.max(x, g1);
      }
      if (x < x1 - rad) { ctx.moveTo(x, y); ctx.lineTo(x1 - rad, y); }
    };
    ctx.strokeStyle = col;
    ctx.lineWidth = 1.2;
    ctx.beginPath();
    edge(y0, false);
    edge(y1, true);
    ctx.moveTo(x0, y0 + rad); ctx.lineTo(x0, y1 - rad);
    ctx.moveTo(x1, y0 + rad); ctx.lineTo(x1, y1 - rad);
    ctx.moveTo(x0 + rad, y0); ctx.arcTo(x0, y0, x0, y0 + rad, rad);
    ctx.moveTo(x1 - rad, y0); ctx.arcTo(x1, y0, x1, y0 + rad, rad);
    ctx.moveTo(x0, y1 - rad); ctx.arcTo(x0, y1, x0 + rad, y1, rad);
    ctx.moveTo(x1, y1 - rad); ctx.arcTo(x1, y1, x1 - rad, y1, rad);
    ctx.stroke();
    for (const t of titles) txt(t.c, t.bottom ? r + bh - 1 : r, t.s, t.col ?? BT.hi, true);
  };
  const dot = Math.max(1.6, fs / 7.5);
  const graph = (c: number, r: number, cells: number, rows: number, data: number[], down = false, color = heat) => {
    const levels = rows * 4;
    const samples = data.slice(-cells * 2);
    const start = cells * 2 - samples.length;
    samples.forEach((v, k) => {
      const i = start + k;
      const n = Math.round(clamp(v, 0, 1) * levels);
      const x = X(c + (i >> 1)) + ((i & 1) + 0.5) * (cw / 2) - dot / 2;
      for (let d = 0; d < n; d++) {
        const row = down ? r + (d >> 2) : r + rows - 1 - (d >> 2);
        const sub = down ? d & 3 : 3 - (d & 3);
        ctx.fillStyle = color(d / levels);
        ctx.fillRect(x, Y(row) + (sub + 0.5) * (lh / 4) - dot / 2, dot, dot);
      }
    });
  };
  const meter = (c: number, r: number, cells: number, frac: number, a: string, b: string) => {
    const y = Y(r) + lh * 0.3;
    const bh = lh * 0.4;
    ctx.fillStyle = BT.dim;
    ctx.fillRect(X(c), y, cells * cw, bh);
    const n = clamp(frac, 0, 1) * cells * cw;
    const g = ctx.createLinearGradient(X(c), 0, X(c + cells), 0);
    g.addColorStop(0, a);
    g.addColorStop(1, b);
    ctx.fillStyle = g;
    ctx.fillRect(X(c), y, n, bh);
  };

  const CORES = 16;
  let L = 22;
  let target = 22;
  let hold = 0;
  const wt = Array.from({ length: CORES }, () => 0.5 + Math.random());
  const core = Array(CORES).fill(10);
  const coreHist = core.map(() => [] as number[]);
  const total: number[] = [];
  const totalMini: number[] = [];
  let gpu = 12;
  let used = 10.2;
  let cached = 5.1;
  let down = 40;
  let up = 8;
  const downH: number[] = [];
  const upH: number[] = [];
  let downTop = 1;
  let upTop = 1;
  let downTot = 787 * 1024;
  let upTot = 238 * 1024;
  let l1 = 2;
  let l5 = 1.8;
  let l15 = 1.6;
  let uptime = 6400 + Math.floor(Math.random() * 30000);
  const procs = BT_PROCS.map(([name, cmd, base, mem]) => ({ name, cmd, base, mem, cpu: base, pid: 1000 + Math.floor(Math.random() * 900000), hist: [] as number[] }));
  const push = (a: number[], v: number, n: number) => { a.push(v); if (a.length > n) a.shift(); };

  const step = () => {
    if (--hold <= 0) {
      const r = Math.random();
      target = r < 0.55 ? 6 + Math.random() * 20 : r < 0.88 ? 25 + Math.random() * 30 : 60 + Math.random() * 35;
      hold = 3 + Math.floor(Math.random() * 9);
    }
    L = walk(L, target, 0.35, 9, 1, 99);
    for (let i = 0; i < CORES; i++) {
      wt[i] = walk(wt[i], 0.4 + Math.random() * 1.3, 0.15, 0.25, 0.05, 2.2);
      core[i] = clamp(L * wt[i] + (Math.random() - 0.5) * 14 + (Math.random() < 0.04 ? 40 : 0), 0, 100);
      push(coreHist[i], core[i] / 100, 40);
    }
    const tot = core.reduce((n, v) => n + v, 0) / CORES;
    push(total, tot / 100, 400);
    push(totalMini, tot / 100, 40);
    gpu = walk(gpu, L > 45 ? 70 : 10, 0.25, 10, 0, 100);
    used = walk(used, 9 + L / 12, 0.2, 0.25, 6, 26);
    cached = walk(cached, 5.2, 0.1, 0.1, 3, 8);
    down = Math.random() < 0.12 ? 2000 + Math.random() * 9000 : walk(down, 30, 0.4, 40, 0, 20000);
    up = Math.random() < 0.08 ? 300 + Math.random() * 1500 : walk(up, 6, 0.4, 10, 0, 5000);
    downTop = Math.max(downTop * 0.995, down);
    upTop = Math.max(upTop * 0.995, up);
    downTot += down;
    upTot += up;
    push(downH, down, 400);
    push(upH, up, 400);
    const load = (tot / 100) * 32;
    l1 += (load - l1) * 0.08;
    l5 += (load - l5) * 0.016;
    l15 += (load - l15) * 0.0055;
    uptime++;
    for (const p of procs) {
      p.cpu = walk(p.cpu, p.base * (0.4 + L / 30) * (Math.random() < 0.05 ? 3 : 1), 0.4, p.base * 0.6 + 0.2, 0, 100);
      p.mem = walk(p.mem, p.mem, 0, p.mem * 0.01, 1, 32000);
      push(p.hist, p.cpu / 100, 10);
    }
  };
  for (let i = 0; i < 400; i++) step();

  return () => {
    step();
    ctx.clearRect(0, 0, W, H);
    const cpuH = Math.max(11, Math.floor(R * 0.44));
    const botH = R - cpuH;
    const leftW = Math.floor(C * 0.45);
    const rightW = C - leftW;
    const memH = Math.max(8, Math.floor(botH * 0.56));
    const netH = botH - memH;
    const now = new Date().toLocaleTimeString('en-GB');
    const tot = Math.round(total[total.length - 1] * 100);

    box(0, 0, C, cpuH, BT.cpu, [{ c: 2, s: 'cpu' }, { c: 7, s: 'menu', col: BT.mid }, { c: 13, s: 'preset *', col: BT.mid }, { c: Math.floor(C / 2) - 4, s: now }, { c: C - 10, s: '1000ms', col: BT.mid }]);
    const iw = Math.min(66, Math.floor(C * 0.52));
    const ic = C - iw - 2;
    const ih = cpuH - 2;
    const ghz = (3.4 + (tot / 100) * 1.5).toFixed(1);
    box(ic, 1, iw, ih, BT.cpu, [{ c: ic + 2, s: 'Ryzen 9 5950X' }, { c: ic + iw - 10, s: `${ghz} GHz` }]);
    const end = ic + iw - 2;
    txt(ic + 2, 2, 'CPU', BT.cpu, true);
    const mw = Math.max(6, iw - 32);
    meter(ic + 6, 2, mw, tot / 100, BT.c1, heat(tot / 100));
    rtxt(ic + 6 + mw + 5, 2, `${tot}%`, BT.hi);
    graph(ic + 6 + mw + 6, 2, 6, 1, totalMini);
    rtxt(end, 2, `${Math.round(45 + tot * 0.42)}°C ${Math.round(70 + tot * 1.4)}W`, BT.pink);
    const rows = clamp(ih - 5, 1, 8);
    const colW = Math.floor((iw - 4) / 2);
    for (let i = 0; i < Math.min(CORES, rows * 2); i++) {
      const cx = ic + 2 + (i >= rows ? colW + 1 : 0);
      const ry = 3 + (i % rows);
      txt(cx, ry, `C${i}`, BT.text);
      graph(cx + 4, ry, colW - 10, 1, coreHist[i]);
      rtxt(cx + colW - 1, ry, `${Math.round(core[i])}%`, heat(core[i] / 100));
    }
    rtxt(end, 3 + rows, `Load avg: ${l1.toFixed(2)} ${l5.toFixed(2)} ${l15.toFixed(2)}`, BT.text, true);
    const gy = ih - 1;
    txt(ic + 2, gy, 'GPU', BT.cpu, true);
    meter(ic + 6, gy, mw, gpu / 100, BT.c1, heat(gpu / 100));
    rtxt(ic + 6 + mw + 5, gy, `${Math.round(gpu)}%`, BT.hi);
    rtxt(end, gy, `${(2 + gpu * 0.09).toFixed(1)}G/16G ${Math.round(38 + gpu * 0.42)}°C`, BT.pink);
    graph(1, 1, ic - 2, cpuH - 3, total);
    const hh = Math.floor(uptime / 3600);
    const mm = Math.floor((uptime % 3600) / 60);
    const ss = uptime % 60;
    txt(2, cpuH - 2, `up ${String(hh).padStart(2, '0')}:${String(mm).padStart(2, '0')}:${String(ss).padStart(2, '0')}`, BT.text);

    const half = Math.floor(leftW / 2);
    box(0, cpuH, leftW, memH, BT.mem, [{ c: 2, s: 'mem' }, { c: half + 2, s: 'disks' }]);
    const free = 31.3 - used - cached;
    const mrows: [string, number, string][] = [['Used:', used, BT.pink], ['Available:', 31.3 - used, BT.mem], ['Cached:', cached, BT.blue], ['Free:', free, BT.cpu]];
    txt(2, cpuH + 1, 'Total:', BT.hi, true);
    rtxt(half - 1, cpuH + 1, '31.3 GiB', BT.hi, true);
    const tall = memH - 3 >= mrows.length * 2;
    mrows.forEach(([label, v, col], i) => {
      const r = cpuH + 2 + i * (tall ? 2 : 1);
      if (r >= cpuH + memH - 1) return;
      txt(2, r, label, BT.text);
      rtxt(half - 1, r, `${v.toFixed(2)} GiB`, BT.hi);
      if (tall) {
        meter(2, r + 1, half - 9, v / 31.3, mix(col, BT.ink, 0.4), col);
        rtxt(half - 1, r + 1, `${Math.round((v / 31.3) * 100)}%`, col);
      }
    });
    const disks: [string, number, number][] = [['root', 1863, 612 + uptime / 9000], ['home', 3726, 2140], ['efi', 1, 0.3]];
    let dr = cpuH + 1;
    for (const [name, size, u] of disks) {
      if (dr + 2 >= cpuH + memH - 1) break;
      const fmtS = (g: number) => (g >= 1000 ? `${(g / 1024).toFixed(1)}T` : `${g.toFixed(g < 10 ? 1 : 0)}G`);
      txt(half + 1, dr, name, BT.hi, true);
      rtxt(leftW - 2, dr, fmtS(size), BT.hi, true);
      const bw = leftW - half - 10;
      txt(half + 1, dr + 1, 'U', BT.text);
      meter(half + 3, dr + 1, bw, u / size, BT.memDim, BT.mem);
      rtxt(leftW - 2, dr + 1, fmtS(u), BT.text);
      txt(half + 1, dr + 2, 'F', BT.text);
      meter(half + 3, dr + 2, bw, 1 - u / size, BT.c3, BT.pink);
      rtxt(leftW - 2, dr + 2, fmtS(size - u), BT.text);
      dr += 3;
    }

    const nr = cpuH + memH;
    box(0, nr, leftW, netH, BT.net, [{ c: 2, s: 'net' }, { c: leftW - 24, s: 'sync', col: BT.mid }, { c: leftW - 18, s: 'auto', col: BT.mid }, { c: leftW - 12, s: 'enp6s0' }]);
    const sw = Math.min(26, leftW - 12);
    const gw = leftW - sw - 3;
    const ghalf = Math.max(1, Math.floor((netH - 2) / 2));
    const dmax = Math.max(...downH.slice(-gw * 2), 1);
    const umax = Math.max(...upH.slice(-gw * 2), 1);
    graph(1, nr + 1, gw, ghalf, downH.map((v) => v / dmax), false, (t) => mix(BT.c1, BT.cpu, t));
    graph(1, nr + 1 + ghalf, gw, ghalf, upH.map((v) => v / umax), true, (t) => mix(BT.c3, BT.pink, t));
    const sx = leftW - sw - 1;
    const lines: [string, string, string][] = [['v', human(down), BT.blue], ['v Top:', human(downTop), BT.text], ['v Total:', `${(downTot / 1024).toFixed(0)} MiB`, BT.text], ['^', human(up), BT.pink], ['^ Top:', human(upTop), BT.text], ['^ Total:', `${(upTot / 1024).toFixed(0)} MiB`, BT.text]];
    txt(sx, nr + 1, 'download', BT.hi, true);
    lines.forEach(([k, v, col], i) => {
      const r = nr + 2 + i + (i >= 3 ? 1 : 0);
      if (r >= nr + netH - 1) return;
      txt(sx, r, k, col);
      rtxt(leftW - 2, r, v, col);
    });
    if (nr + 9 < nr + netH - 1) txt(sx, nr + 5, 'upload', BT.hi, true);

    const pc = leftW;
    box(pc, cpuH, rightW, botH, BT.proc, [{ c: pc + 2, s: 'proc' }, { c: pc + 8, s: 'filter', col: BT.mid }, { c: pc + rightW - 22, s: 'tree', col: BT.mid }, { c: pc + rightW - 12, s: 'cpu lazy' }, { c: pc + 3, s: 'select', bottom: true, col: BT.mid }, { c: pc + 11, s: 'info', bottom: true, col: BT.mid }, { c: pc + 17, s: 'kill', bottom: true, col: BT.mid }, { c: pc + 23, s: 'signals', bottom: true, col: BT.mid }, { c: pc + rightW - 9, s: `0/${312 + procs.length}`, bottom: true }]);
    const pend = pc + rightW - 2;
    const colCpu = pend;
    const colG = pend - 11;
    const colMem = colG - 1;
    const colUser = colMem - 15;
    const colProg = pc + 9;
    const colCmd = colProg + 14;
    const cmdW = colUser - colCmd - 1;
    const hr = cpuH + 1;
    rtxt(pc + 7, hr, 'Pid:', BT.hi, true);
    txt(colProg, hr, 'Program:', BT.hi, true);
    if (cmdW > 6) txt(colCmd, hr, 'Command:', BT.hi, true);
    txt(colUser, hr, 'User:', BT.hi, true);
    rtxt(colMem, hr, 'MemB', BT.hi, true);
    rtxt(colCpu, hr, 'Cpu%', BT.hi, true);
    const list = [...procs].sort((a, b) => b.cpu - a.cpu).slice(0, botH - 3);
    list.forEach((p, i) => {
      const r = hr + 1 + i;
      const fade = clamp(1 - i / (list.length * 1.4), 0.35, 1);
      const f = (col: string) => mix(BT.ink, col.startsWith('#') ? col : BT.text, fade);
      rtxt(pc + 7, r, String(p.pid), f(BT.text));
      txt(colProg, r, p.name.slice(0, 13), f(BT.mem));
      if (cmdW > 6) txt(colCmd, r, p.cmd.slice(0, cmdW), f(BT.mid));
      txt(colUser, r, 'darkxero', f(BT.text));
      rtxt(colMem, r, p.mem >= 1024 ? `${(p.mem / 1024).toFixed(1)}G` : `${Math.round(p.mem)}M`, f(BT.proc));
      graph(colG, r, 5, 1, p.hist);
      rtxt(colCpu, r, p.cpu.toFixed(1), f(p.cpu > 20 ? BT.pink : BT.hi));
    });
  };
};

function run(e: NonNullable<ReturnType<typeof els>>, raw: string) {
  const line = raw.trim();
  if (!state.vim && line.includes('&&')) {
    state.lines.push({ t: line, kind: 'cmd', p: cwd(e.data), at: Date.now() });
    state.hist.push(line);
    for (const part of line.split('&&').map((x) => x.trim()).filter(Boolean)) {
      if (exec(e, part) === 'stop') return;
    }
    return;
  }
  if (state.vim) {
    print(`:${line}`, 'tdim');
    if (/^q!?$|^wq!?$|^x$/.test(line)) {
      state.vim = false;
      print('You escaped vim. Achievement unlocked.', 'tok');
    } else {
      print('E492: Not an editor command. Try :q!', 'terr');
    }
    return;
  }
    state.lines.push({ t: line, kind: 'cmd', p: cwd(e.data), at: Date.now() });
  if (!line) return;
  state.hist.push(line);
  exec(e, line);
}

type Term = NonNullable<ReturnType<typeof els>>;
type Pkg = [repo: string, name: string, ver: string, desc: string];

const PKGS: Pkg[] = [
  ['core', 'base', '3-2', 'Minimal package set to define a basic Arch Linux installation'],
  ['core', 'linux', '6.17.8.arch1-1', 'The Linux kernel and modules'],
  ['core', 'pacman', '7.1.0-3', 'A library-based package manager with dependency support'],
  ['core', 'systemd', '258.2-1', 'system and service manager'],
  ['extra', 'plasma-desktop', '6.5.3-1', 'KDE Plasma Desktop'],
  ['extra', 'kwin', '6.5.3-1', 'An easy to use, but flexible, Wayland compositor'],
  ['extra', 'konsole', '25.08.3-1', 'KDE terminal emulator'],
  ['extra', 'firefox', '145.0.1-1', 'Fast, Private & Safe Web Browser'],
  ['extra', 'fastfetch', '2.55.0-1', 'A feature-rich and performance oriented neofetch like system information tool'],
  ['extra', 'btop', '1.4.5-1', 'A monitor of system resources, bpytop ported to C++'],
  ['extra', 'neovim', '0.11.5-1', 'Fork of Vim aiming to improve user experience, plugins, and GUIs'],
  ['extra', 'flatpak', '1.16.1-1', 'Linux application sandboxing and distribution framework'],
  ['multilib', 'steam', '1.0.0.85-1', "Valve's digital software delivery system"],
  ['multilib', 'lib32-mesa', '1:25.2.7-1', 'Open-source OpenGL drivers - 32-bit'],
  ['chaotic-aur', 'linux-cachyos', '6.17.8-2', 'Linux BORE + LTO + AutoFDO + Propeller Cachyos-Kernel'],
  ['chaotic-aur', 'brave-bin', '1:1.84.139-1', 'Web browser that blocks ads and trackers by default'],
  ['xerolinux', 'xpackagemanager', '1.4.2-1', 'Rust + Qt6 GUI for pacman and Flatpak'],
  ['xerolinux', 'xero-ibr', '1.2.0-1', 'iBackup/Restore for configs and package lists'],
  ['xerolinux', 'xero-howdy-qt', '1.1.0-1', 'Qt front end for Howdy face unlock'],
  ['xerolinux', 'xfprintd-gui', '0.1.5-1', 'GTK4 GUI to manage fingerprint enrollment and PAM integration'],
  ['xerolinux', 'xsb-gui', '0.1.4-1', 'XeroLinux Limine/SecureBoot Enabler'],
  ['xerolinux', 'xero-wallpapers-gui', '1.0.3-1', 'Browse and apply XeroLinux wallpapers'],
  ['xerolinux', 'xspeedtest', '0.1.2-1', 'Qt 6 / QML front-end for speedtest-cli with a Plasma 6 widget'],
];
const BASE_INST = ['base', 'linux', 'pacman', 'systemd', 'plasma-desktop', 'kwin', 'konsole', 'firefox', 'fastfetch', 'flatpak', 'linux-cachyos', 'xpackagemanager'];
const PROTECTED = ['base', 'linux', 'pacman', 'systemd'];
const UPDATES: [string, string, string][] = [['plasma-workspace', '6.5.2-1', '6.5.3-1'], ['layan-gtk-theme', '2026.10-1', '2026.11-1'], ['xerolinux-site', '1.9-1', '2.0-1']];
const REPOS: [string, string][] = [['core', '132.4 KiB'], ['extra', '8.4 MiB'], ['multilib', '140.2 KiB'], ['chaotic-aur', '612.5 KiB'], ['xerolinux', '18.1 KiB']];
const ROOT_ONLY = 'error: you cannot perform this operation unless you are root.';

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));
const installed = () => new Set(state.inst ?? BASE_INST);
const findPkg = (n: string) => PKGS.find((x) => x[1] === n);

function barLine(label: string, size: string, pct: number) {
  const n = 22;
  const f = Math.round((pct / 100) * n);
  return ` ${label.padEnd(26).slice(0, 26)} ${size.padStart(10)}  [${'#'.repeat(f)}${'-'.repeat(n - f)}] ${String(pct).padStart(3)}%`;
}

async function bar(e: Term, label: string, size: string) {
  const line: Line = { t: barLine(label, size, 0), c: 'tbar' };
  state.lines.push(line);
  for (let p = 0; p <= 100; p += 20) {
    line.t = barLine(label, size, p);
    paint(e);
    await sleep(45);
  }
}

async function say(e: Term, t: string, c?: string, ms = 140) {
  print(t, c);
  paint(e);
  await sleep(ms);
}

async function job(e: Term, fn: () => Promise<void>) {
  e.term.classList.add('busy');
  e.input.disabled = true;
  try { await fn(); } finally {
    e.term.classList.remove('busy');
    e.input.disabled = false;
    paint(e);
    save();
    if (!e.term.hidden) e.input.focus();
  }
}

function pacman(e: Term, args: string[], root: boolean): 'stop' | void {
  const op = args[0] ?? '';
  const targets = args.slice(1);
  if (!op) {
    print(['usage:  pacman <operation> [...]', 'operations:', '    pacman -Syu            full system upgrade', '    pacman -S <package>    install', '    pacman -R <package>    remove', '    pacman -Ss <query>     search', '    pacman -Q              list installed', '    pacman -Sc             clean cache'], 'tdim');
    return;
  }
  if (op === '-Ss') {
    const q = targets.join(' ').toLowerCase();
    const inst = installed();
    const hits = PKGS.filter((x) => !q || x[1].includes(q) || x[3].toLowerCase().includes(q));
    if (!hits.length) return;
    for (const [repo, name, ver, desc] of hits) {
      state.lines.push({ t: `${repo}/${name} ${ver}${inst.has(name) ? ' [installed]' : ''}`, c: 'tpkg' });
      print(`    ${desc}`, 'tdim');
    }
    return;
  }
  if (op === '-Q') {
    const inst = installed();
    print(PKGS.filter((x) => inst.has(x[1])).map((x) => `${x[1]} ${x[2]}`));
    return;
  }
  if (op === '-Sy') { print('warning: partial upgrades are unsupported on Arch. Use pacman -Syu.', 'terr'); return; }
  if (!['-Syu', '-S', '-R', '-Rns', '-Sc'].includes(op)) { print(`error: invalid option '${op}'`, 'terr'); return; }
  if (!root) { print(ROOT_ONLY, 'terr'); return; }

  if (op === '-Sc') {
    print(['Packages to keep:', '  All locally installed packages', '', 'Cache directory: /var/cache/pacman/pkg/', ':: Do you want to remove all other packages from cache? [Y/n] Y', 'removing old packages from cache...', 'freed 1.42 GiB of disk space'], 'tdim');
    return;
  }
  if (op === '-S' || op === '-R' || op === '-Rns') {
    if (!targets.length) { print('error: no targets specified (use -h for help)', 'terr'); return; }
    const inst = installed();
    if (op !== '-S') {
      const bad = targets.find((t) => PROTECTED.includes(t));
      if (bad) { print(['checking dependencies...', 'error: failed to prepare transaction (could not satisfy dependencies)', `:: removing ${bad} breaks dependency '${bad}' required by your entire system. Nice try.`], 'terr'); return; }
      const missing = targets.find((t) => !inst.has(t));
      if (missing) { print(`error: target not found: ${missing}`, 'terr'); return; }
    } else {
      const missing = targets.find((t) => !findPkg(t));
      if (missing) { print(`error: target not found: ${missing}`, 'terr'); return; }
    }
    void job(e, async () => {
      if (op === '-S') {
        for (const t of targets) if (inst.has(t)) await say(e, `warning: ${t}-${findPkg(t)![2]} is up to date -- reinstalling`, 'tyel');
        await say(e, 'resolving dependencies...');
        await say(e, 'looking for conflicting packages...');
        await say(e, `Packages (${targets.length}) ${targets.map((t) => `${t}-${findPkg(t)![2]}`).join('  ')}`, 'tpkg', 200);
        await say(e, ':: Proceed with installation? [Y/n] Y', 'tq', 300);
        for (const t of targets) await bar(e, t, `${(2 + t.length * 1.7).toFixed(1)} MiB`);
        await bar(e, `(${targets.length}/${targets.length}) checking keys in keyring`, '');
        await bar(e, `(${targets.length}/${targets.length}) installing`, '');
        targets.forEach((t) => inst.add(t));
      } else {
        await say(e, 'checking dependencies...');
        await say(e, `Packages (${targets.length}) ${targets.map((t) => `${t}-${findPkg(t)?.[2] ?? '1.0-1'}`).join('  ')}`, 'tpkg', 200);
        await say(e, ':: Do you want to remove these packages? [Y/n] Y', 'tq', 300);
        await bar(e, `(${targets.length}/${targets.length}) removing`, '');
        targets.forEach((t) => inst.delete(t));
      }
      state.inst = [...inst];
      await say(e, ':: Running post-transaction hooks...');
      await say(e, '(1/1) Arming ConditionNeedsUpdate...', 'tok');
    });
    return 'stop';
  }

  void job(e, async () => {
    await say(e, ':: Synchronizing package databases...', 'tq');
    for (const [r, size] of REPOS) await bar(e, r, size);
    await say(e, ':: Starting full system upgrade...', 'tq');
    await say(e, 'resolving dependencies...');
    await say(e, 'looking for conflicting packages...');
    await say(e, `Packages (${UPDATES.length}) ${UPDATES.map(([n, , v]) => `${n}-${v}`).join('  ')}`, 'tpkg');
    await say(e, 'Total Download Size:   42.18 MiB');
    await say(e, 'Total Installed Size:  168.40 MiB', undefined, 200);
    await say(e, ':: Proceed with installation? [Y/n] Y', 'tq', 300);
    for (const [n, , v] of UPDATES) await bar(e, `${n}-${v}`, `${(n.length * 1.9).toFixed(1)} MiB`);
    for (const step of ['checking keys in keyring', 'checking package integrity', 'loading package files', 'checking for file conflicts']) await bar(e, `(3/3) ${step}`, '');
    for (const [i, [n]] of UPDATES.entries()) await bar(e, `(${i + 1}/3) upgrading ${n}`, '');
    await say(e, ':: Running post-transaction hooks...', 'tq');
    await say(e, '(1/2) Arming ConditionNeedsUpdate...');
    await say(e, '(2/2) Updating xerolinux.xyz...');
    await say(e, ':: xerolinux-site was upgraded. Reloading the page to apply it...', 'tyel', 500);
    for (const n of [3, 2, 1]) await say(e, `   reloading in ${n}...`, 'tdim', 700);
    print('System is up to date. Page reloaded. :)', 'tok');
    save();
    location.reload();
    await sleep(10_000);
  });
  return 'stop';
}

async function reflector(e: Term) {
  await job(e, async () => {
    await say(e, '[2026-11-19 17:52:01] INFO: Retrieving mirror status from https://archlinux.org/mirrors/status/json/', 'tdim', 600);
    for (const m of ['mirror.f4st.host', 'de.arch.mirror.kescher.at', 'mirror.moson.org', 'arch.mirror.constant.com', 'mirrors.kernel.org']) {
      await say(e, `  rating https://${m}/archlinux/   ${(Math.random() * 40 + 20).toFixed(1)} MiB/s`, undefined, 220);
    }
    await say(e, 'Saved 5 mirrors to /etc/pacman.d/mirrorlist', 'tok');
  });
}

function exec(e: Term, line: string, root = false): 'stop' | void {
  const [cmd, ...args] = line.split(/\s+/);
  const rest = args.join(' ');

  switch (cmd) {
    case 'help':
      state.lines.push({ t: '', kind: 'help' });
      break;
    case 'ls':
      print(Object.keys(PAGES).filter(Boolean).map((p) => `${p}/`).join('  '), 'tdir');
      break;
    case 'pwd':
      print(`/home/xero${cwd(e.data).slice(1)}`);
      break;
    case 'cd': {
      const target = (args[0] ?? '~').replace(/^~\/?/, '').replace(/^\.\.?\/?$/, '').replace(/\/$/, '');
      if (!(target in PAGES)) { print(`cd: no such file or directory: ${args[0]}`, 'terr'); break; }
      close(e);
      navigate(PAGES[target]);
      return 'stop';
    }
    case 'clear':
      state.lines = [];
      break;
    case 'exit':
      close(e);
      return 'stop';
    case 'whoami':
      print('darkxero');
      break;
    case 'history':
      print(state.hist.map((h, i) => `${String(i + 1).padStart(4)}  ${h}`));
      break;
    case 'neofetch':
    case 'fastfetch':
      state.lines = [{ t: '', kind: 'fetch' }];
      break;
    case 'changelog': {
      const r = e.data.changelog[0];
      if (!r) break;
      print([`XeroLinux ${r.date}`, '[ISO]', ...r.iso.map((i) => `  + ${strip(i)}`), '[T.U.I]', ...r.tui.map((i) => `  + ${strip(i)}`)]);
      break;
    }
    case 'download':
      print([...e.data.editions.map((x) => `${x.name.padEnd(12)} ${x.file}  (${x.sizeGB})`), '', 'Run: cd ~/download'], undefined);
      break;
    case 'sha256sum': {
      if (!rest) { print('usage: sha256sum <file>', 'terr'); break; }
      const ed = e.data.editions.find((x) => x.file === rest);
      print(ed ? `${ed.sha256}  ${ed.file}` : `sha256sum: ${rest}: No such file or directory`, ed ? undefined : 'terr');
      break;
    }
    case 'theme': {
      let t = args[0];
      if (!t) { state.lines.push({ t: '', kind: 'themes' }); print('usage: theme <name> | theme random', 'tdim'); break; }
      if (t === 'random') { const others = THEME_IDS.filter((id) => id !== currentTheme()); t = others[Math.floor(Math.random() * others.length)]; }
      if (!(THEME_IDS as string[]).includes(t)) { print(`theme: unknown theme '${t}' (run theme to list)`, 'terr'); break; }
      setTheme(t as ThemeId);
      print(`Theme set to ${THEMES[t as ThemeId].name}.`, 'tok');
      break;
    }
    case 'festive': {
      const t = args[0];
      const st = festiveState();
      if (t === 'on' || t === 'off') {
        if (!st.id) { print('festive: nothing to celebrate today', 'tdim'); break; }
        setFestiveOn(t === 'on');
        print(`${FESTIVITIES[st.id].name} decorations ${t}.`, 'tok');
      } else if (t && (t === 'auto' || (FESTIVE_IDS as string[]).includes(t))) {
        forceFestive(t === 'auto' ? null : (t as FestiveId));
        print(t === 'auto' ? 'festive: back to the calendar' : `festive: forcing ${FESTIVITIES[t as FestiveId].name} (this browser only)`, 'tok');
      } else if (t) {
        print('usage: festive [on|off|auto|<name>]', 'terr');
      } else {
        print(st.id ? `${FESTIVITIES[st.id].name}: decorations ${st.on ? 'on' : 'off'}${st.forced ? ' (forced)' : ''}` : 'No festivity today.', st.id ? 'tok' : 'tdim');
        print(`festive <name>|auto  (${FESTIVE_IDS.join(' ')})`, 'tdim');
      }
      break;
    }
    case 'fortune':
      print(FORTUNES[Math.floor(Math.random() * FORTUNES.length)]);
      break;
    case 'cowsay':
      print(cowsay(rest));
      break;
    case 'btw':
      print('I use Arch, btw.');
      break;
    case 'vim':
    case 'vi':
      state.vim = true;
      print(['~', '~', '~', '~', '-- welcome to vim. good luck leaving. --'], 'tdim');
      break;
    case 'emacs':
    case 'nano':
      print(`${cmd}: wrong editor. Try vim (good luck leaving).`, 'terr');
      break;
    case 'matrix':
    case 'cmatrix':
      print('Wake up, Neo... (press any key)', 'tdim');
      paint(e);
      screensaver(e, cmatrix, 33);
      return 'stop';
    case 'btop':
    case 'htop':
    case 'top':
      paint(e);
      screensaver(e, btopSaver, 1000, ['q', 'Escape']);
      return 'stop';
    case 'pipes':
    case 'pipes.sh':
      print('pipes.sh (press any key)', 'tdim');
      paint(e);
      screensaver(e, pipes, 33);
      return 'stop';
    case 'pacman':
      return pacman(e, args, root);
    case 'checkupdates':
      print(UPDATES.map(([n, a, b]) => `${n} ${a} -> ${b}`));
      break;
    case 'reflector':
      if (!root) { print('error: must be root to write /etc/pacman.d/mirrorlist', 'terr'); break; }
      void reflector(e);
      return 'stop';
    case 'uname':
      print(args.includes('-a') ? 'Linux StationXero 7.3.5-2-cachyos #1 SMP PREEMPT_DYNAMIC x86_64 GNU/Linux' : args.includes('-r') ? '7.3.5-2-cachyos' : 'Linux');
      break;
    case 'archinstall':
      print(['You are already running XeroLinux, Arch with the sharp edges filed off.', 'Want it on another machine? cd ~/download'], 'tdim');
      break;
    case 'yay':
    case 'paru':
      print('No AUR helper here. Chaotic-AUR has you covered.', 'tdim');
      break;
    case 'make':
      print(rest === 'me a sandwich' ? 'What? Make it yourself.' : `make: *** No rule to make target '${rest}'.`, 'terr');
      break;
    case 'sudo':
      if (/^rm\s+-[a-z]*r[a-z]*f?[a-z]*\s+\/(\s|$|\*)/.test(rest) || rest === 'rm -rf /') print('rm: refusing to remove \'/\'. Nice try.', 'terr');
      else if (rest === 'make me a sandwich') print('Okay.', 'tok');
      else if (!rest) print('usage: sudo <command>', 'terr');
      else if (args[0] === 'pacman' || args[0] === 'reflector') return exec(e, rest, true);
      else print('darkxero is not in the sudoers file. This incident will be reported.', 'terr');
      break;
    default:
      print(`xsh: command not found: ${cmd}`, 'terr');
  }
}

function open(e: NonNullable<ReturnType<typeof els>>) {
  if (window.matchMedia(MOBILE).matches) return;
  const bar = e.term.parentElement?.querySelector<HTMLElement>('[data-winbar]');
  e.term.style.setProperty('--tbh', `${bar?.offsetHeight ?? 0}px`);
  e.term.hidden = false;
  if (!state.lines.length) print(['XeroLinux xsh 1.0. Type "help" to get started.', '']);
  paint(e);
  clearInterval(clockTimer);
  clockTimer = window.setInterval(() => stamp(e.prompt), 1000);
  save();
  e.input.focus();
}

function close(e: NonNullable<ReturnType<typeof els>>) {
  saverStop?.();
  clearInterval(clockTimer);
  e.term.hidden = true;
  save();
  e.btn?.focus();
}

export function initTerminal() {
  const e = els();
  if (!e) return;
  let hi = state.hist.length;

  e.term.addEventListener('click', (ev) => { if (!(ev.target as HTMLElement).closest('a, button')) e.input.focus(); });
  e.input.addEventListener('keydown', (ev) => {
    if (ev.key === 'Enter') {
      ev.preventDefault();
      run(e, e.input.value);
      e.input.value = '';
      hi = state.hist.length;
      if (!e.term.hidden) { paint(e); save(); }
    } else if (ev.key === 'ArrowUp' || ev.key === 'ArrowDown') {
      ev.preventDefault();
      hi = Math.max(0, Math.min(state.hist.length, hi + (ev.key === 'ArrowUp' ? -1 : 1)));
      e.input.value = state.hist[hi] ?? '';
    } else if (ev.key === 'Tab') {
      ev.preventDefault();
      const [cmd, ...more] = e.input.value.split(' ');
      if (!more.length) {
        const hits = COMMANDS.filter((c) => c.startsWith(cmd));
        if (hits.length === 1) e.input.value = `${hits[0]} `;
        else if (hits.length > 1) { print(hits.join('  '), 'tdim'); paint(e); }
      } else if (cmd === 'theme') {
        const hits = [...THEME_IDS, 'random'].filter((id) => id.startsWith(more.join(' ')));
        if (hits.length === 1) e.input.value = `theme ${hits[0]}`;
        else if (hits.length > 1) { print(hits.join('  '), 'tdim'); paint(e); }
      } else if (cmd === 'festive') {
        const opts = ['on', 'off', 'auto', ...FESTIVE_IDS];
        const hits = opts.filter((o) => o.startsWith(more.join(' ')));
        if (hits.length === 1) e.input.value = `festive ${hits[0]}`;
        else if (hits.length > 1) { print(hits.join('  '), 'tdim'); paint(e); }
      } else if (cmd === 'cd') {
        const hits = Object.keys(PAGES).filter((p) => p && p.startsWith(more.join(' ').replace(/^~\//, '')));
        if (hits.length === 1) e.input.value = `cd ~/${hits[0]}`;
      }
    } else if (ev.key === 'l' && ev.ctrlKey) {
      ev.preventDefault();
      state.lines = [];
      paint(e);
    } else if (ev.key === 'Escape') {
      close(e);
    }
  });

}

export function toggleTerminal() {
  const e = els();
  if (!e || window.matchMedia(MOBILE).matches) return;
  if (e.term.hidden) open(e);
  else close(e);
}
