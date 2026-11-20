import type { FestiveId } from '../data/festive';

export type Fall = 'snow' | 'hearts' | 'clovers';

interface Decor {
  center?: () => string;
  hat?: string;
  foot?: string;
  corner?: string;
  caps?: boolean;
  lights?: boolean;
  icicles?: boolean;
  toran?: boolean;
  lanterns?: boolean;
  spider?: boolean;
  fall?: Fall;
}

const svg = (vb: string, body: string, cls = '') => `<svg class="${cls}" viewBox="${vb}" aria-hidden="true">${body}</svg>`;

const reindeer = (x: number, nose = false, d = 0) => `<g transform="translate(${x} 9)"><g class="fxdeer" style="animation-delay:${d}s">
  <path d="M4 14l-3-2" stroke="#c9a27a" stroke-width="2" stroke-linecap="round"/>
  <path class="fxlegb" style="animation-delay:${d}s" d="M10 19l-6 6M13 20l-3 8" stroke="#6b4429" stroke-width="2.2" stroke-linecap="round"/>
  <path class="fxlegf" style="animation-delay:${d}s" d="M30 19l6 7M27 20l4 8" stroke="#6b4429" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M4 15q2-8 14-8h10q8 0 10 6q1 5-4 7H10q-6 0-6-5z" fill="#8a5a3c"/>
  <path d="M12 19h16" stroke="#c9a27a" stroke-width="2"/>
  <path d="M30 9q2-6 6-8q4 0 6 3l-1 3-5 1q-2 3-4 4z" fill="#8a5a3c"/>
  <ellipse cx="41.5" cy="5.6" rx="3" ry="2" fill="#9b6a48"/>
  <circle cx="37" cy="3.4" r=".9" fill="#111"/><path d="M34 2l-3-3 1 4z" fill="#6b4429"/>
  <path d="M35 1q-2-6-6-7M32-3l-3 0M36 0q1-6 5-8M38-5l3-1" stroke="#e2c49a" stroke-width="1.3" fill="none" stroke-linecap="round"/>
  <path d="M26 8v11" stroke="#c8102e" stroke-width="2"/><circle cx="26" cy="19.5" r="1.5" fill="#f5c451"/>
  ${nose ? '<circle class="fxnose" cx="44.4" cy="5.6" r="2.4" fill="#ff3b3b"/>' : '<circle cx="44" cy="5.6" r="1.1" fill="#2b1a10"/>'}
</g></g>`;

const santa = () => svg('0 0 256 46', `
  <g class="fxtrail">${[0, 1, 2, 3, 4, 5].map((i) => `<circle cx="${28 - i * 5}" cy="${38 + (i % 2) * 3}" r="${1.7 - i * 0.22}" fill="#ffe08a"/>`).join('')}</g>
  <path d="M87 22Q115 30 142 23M87 22Q140 32 186 23M87 22Q170 34 230 23" stroke="#d4af37" stroke-width=".9" fill="none"/>
  ${reindeer(116, false, -0.4)}${reindeer(160, false, -0.2)}${reindeer(204, true)}
  <g transform="translate(30 6)">
    <path d="M6 8q-5-11 9-13q13 0 11 13z" fill="#7a5230"/><rect x="9" y="-7" width="7" height="7" rx="1" fill="#22a05a"/><rect x="12" y="-7" width="1.6" height="7" fill="#f5c451"/><rect x="17" y="-5" width="6" height="6" rx="1" fill="#3a6ff7"/>
    <path d="M30 22q-2-14 10-16q10 2 8 16z" fill="#c8102e"/><rect x="30" y="15" width="18" height="2.6" fill="#1d1d22"/><rect x="38" y="14.6" width="3.4" height="3.4" fill="#f5c451"/>
    <circle cx="40" cy="2" r="5" fill="#f2c9a0"/><path d="M35 3q5 10 10 0q-2 4-5 4t-5-4z" fill="#fff"/><circle cx="42" cy="1" r=".8" fill="#222"/>
    <path d="M45 0q-3-9-12-4l-5 6 5-1z" fill="#c8102e"/><circle cx="27.6" cy="2.4" r="2" fill="#fff"/><rect x="34" y="-1.6" width="12" height="2.6" rx="1.3" fill="#fff"/>
    <path d="M46 12l10 3" stroke="#c8102e" stroke-width="3.6" stroke-linecap="round"/><circle cx="57" cy="15.6" r="2.2" fill="#2f5a2f"/>
    <path d="M2 18h54q7 0 9-7l5-3q3 15-9 20H8q-8 0-6-10z" fill="#b3122a"/>
    <path d="M5 21h54M66 10q5-6 8 0" stroke="#d4af37" stroke-width="1.6" fill="none"/><path d="M10 25q8-4 14 0t14 0" stroke="#d4af37" stroke-width="1.1" fill="none"/>
    <path d="M14 28v6M48 28v6" stroke="#d4af37" stroke-width="2"/>
    <path d="M-2 34h62q10 0 12-8q2-4-1-6" stroke="#d4af37" stroke-width="2.4" fill="none" stroke-linecap="round"/>
  </g>`, 'fxsanta');

const tree = (cls: string) => svg('0 0 40 46', `
  <rect x="18" y="39" width="4" height="7" fill="#6b4429"/>
  <path d="M20 5L9 20h6L6 31h7L3 41h34l-10-10h7l-9-11h6z" fill="#1f7a3a"/>
  <path d="M15 20h4M13 31h5M24 31h4M8 41h6M26 41h6" stroke="#f4f8ff" stroke-width="1.6" stroke-linecap="round"/>
  <path d="M12 17q8 5 16 0M9 27q11 6 22 0M6 37q14 6 28 0" stroke="#f5c451" stroke-width="1" fill="none"/>
  ${[[15, 19, '#ef4444'], [25, 18, '#60a5fa'], [12, 29, '#facc15'], [21, 30, '#ef4444'], [29, 28, '#e879f9'], [9, 39, '#60a5fa'], [18, 40, '#facc15'], [27, 39, '#ef4444'], [33, 38, '#22d3ee']].map(([x, y, c], i) => `<circle class="fxorn" style="animation-delay:${-i * 0.37}s" cx="${x}" cy="${y}" r="1.7" fill="${c}"/>`).join('')}
  <path class="fxstar" d="M20 0l1.6 3.3 3.6.5-2.6 2.5.6 3.6-3.2-1.7-3.2 1.7.6-3.6-2.6-2.5 3.6-.5z" fill="#ffd95e"/>`, cls);

const xmas = () => `${tree('fxtree l')}${santa()}${tree('fxtree r')}${svg('0 0 100 6', '<path d="M0 6V3Q12 0 25 3T50 3T75 3T100 3V6z" fill="#f4f8ff"/>', 'fxdrift').replace('<svg ', '<svg preserveAspectRatio="none" ')}`;

const LIGHTS = ['#ef4444', '#facc15', '#22c55e', '#60a5fa', '#e879f9', '#fb923c'];
const lights = (n = 36) => `${svg(`0 0 ${n * 10} 12`, `<path d="M0 2${Array.from({ length: n }, () => 'q5 8 10 0').join('')}" stroke="#2f4a2b" stroke-width="1.2" fill="none" vector-effect="non-scaling-stroke"/>`, 'fxwire').replace('<svg ', '<svg preserveAspectRatio="none" ')}${Array.from({ length: n }, (_, i) => `<i style="left:${((i + 0.5) / n) * 100}%;--c:${LIGHTS[i % LIGHTS.length]};animation-delay:${-((i * 0.53) % 2.4).toFixed(2)}s"></i>`).join('')}`;

const firework = (left: number, colors: string[], d: number, size = 1) => {
  const sparks = Array.from({ length: 14 }, (_, i) => {
    const a = (i / 14) * Math.PI * 2;
    const c = colors[i % colors.length];
    return `<line x1="${25 + Math.cos(a) * 3}" y1="${16 + Math.sin(a) * 3}" x2="${25 + Math.cos(a) * 13}" y2="${16 + Math.sin(a) * 13}" stroke="${c}" stroke-width="1.3" stroke-linecap="round"/><circle cx="${25 + Math.cos(a) * 15}" cy="${16 + Math.sin(a) * 15}" r="1.3" fill="${c}"/>`;
  }).join('');
  const glitter = Array.from({ length: 8 }, (_, i) => { const a = (i / 8) * Math.PI * 2 + 0.3; return `<circle cx="${25 + Math.cos(a) * 8}" cy="${16 + Math.sin(a) * 8}" r=".9" fill="#fff"/>`; }).join('');
  return svg('0 0 50 46', `<line class="fxrocket" style="animation-delay:${d}s" x1="25" y1="46" x2="25" y2="18" stroke="${colors[0]}" stroke-width="1.4" stroke-dasharray="28" stroke-linecap="round"/><g class="fxexpl" style="animation-delay:${d}s">${sparks}${glitter}</g>`, 'fxfwk').replace('<svg ', `<svg style="left:${left}%;height:${46 * size}px;width:${50 * size}px" `);
};
// Bursts stay in the outer 38% on each side so the centrepiece is never crossed.
const show = (palette: string[][], n: number) => Array.from({ length: n }, (_, i) => {
  const side = i % 2;
  const k = Math.floor(i / 2) / Math.max(1, Math.ceil(n / 2) - 1);
  const left = side ? 62 + k * 32 : 2 + k * 32;
  return firework(left, palette[i % palette.length], -((i * 1.37) % 3.2), 0.75 + ((i * 29) % 30) / 100);
}).join('');

const flag = () => {
  const stripes = Array.from({ length: 13 }, (_, i) => `<rect y="${(i * 34) / 13}" width="60" height="${34 / 13 + 0.05}" fill="${i % 2 ? '#fff' : '#b22234'}"/>`).join('');
  const dots = Array.from({ length: 30 }, (_, i) => `<circle cx="${2.4 + (i % 6) * 4 + (Math.floor(i / 6) % 2) * 2}" cy="${2.2 + Math.floor(i / 6) * 3.4}" r=".8" fill="#fff"/>`).join('');
  const img = `url(data:image/svg+xml,${encodeURIComponent(`<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 60 34' width='60' height='34'>${stripes}<rect width='26' height='18.3' fill='#3c3b6e'/>${dots}</svg>`).replace(/'/g, '%27')})`;
  const slices = Array.from({ length: 12 }, (_, i) => `<i style="background-image:${img};background-position:${-i * 5}px 0;animation-delay:${-i * 0.11}s"></i>`).join('');
  return `${show([['#e63946', '#fff'], ['#4d7cff', '#fff'], ['#f1faee', '#e63946'], ['#e63946', '#4d7cff']], 8)}<div class="fxflagwrap"><div class="fxpole"><b></b></div><div class="fxflag">${slices}</div></div>`;
};

const bat = (cls: string, d: number) => `<g class="${cls}" style="animation-delay:${d}s"><g class="fxwing" style="animation-delay:${d}s"><path d="M0 0q-4-5-11-2q3 2 2 5q-3-1-5 1q4 1 6 4q3-3 8-3zM0 0q4-5 11-2q-3 2-2 5q3-1 5 1q-4 1-6 4q-3-3-8-3z" fill="#120d18" stroke="rgba(255,190,110,.75)" stroke-width=".7"/></g><circle r="2.2" fill="#120d18" stroke="rgba(255,190,110,.75)" stroke-width=".7"/></g>`;

const moon = () => svg('0 0 120 46', `
  <defs><radialGradient id="fxmg"><stop offset="0" stop-color="#fff6d5"/><stop offset=".7" stop-color="#f6d77a"/><stop offset="1" stop-color="#e9b949"/></radialGradient></defs>
  <circle cx="60" cy="23" r="21" fill="#f6d77a" opacity=".18"/>
  <circle cx="60" cy="23" r="16" fill="url(#fxmg)"/>
  <circle cx="54" cy="19" r="2.6" fill="#e2b85a" opacity=".6"/><circle cx="65" cy="28" r="3.4" fill="#e2b85a" opacity=".5"/>
  <g transform="translate(60 23)">${bat('fxbat', 0)}${bat('fxbat', -2.4)}${bat('fxbat', -4.8)}</g>`, 'fxmoon');

const heartPath = (s: number, c: string, x = 0, y = 0) => `<path transform="translate(${x} ${y}) scale(${s})" d="M0 6C-10-1-5-9 0-3C5-9 10-1 0 6Z" fill="${c}"/>`;

const cupid = () => svg('0 0 80 46', `
  ${[0, 1, 2, 3].map((i) => `<g class="fxrise" style="animation-delay:${-i * 0.9}s">${heartPath(0.45, i % 2 ? '#ff8fab' : '#ff5d8f', 22 + i * 12, 40)}</g>`).join('')}
  <g class="fxbeat" style="transform-origin:40px 22px">${heartPath(2.2, '#e63946', 40, 22)}${heartPath(1.4, '#ff5d8f', 40, 21)}</g>
  <path d="M14 34L66 10" stroke="#d4af37" stroke-width="1.8"/><path d="M66 10l-7 1 3 3z" fill="#d4af37"/><path d="M14 34l-4-1m4 1l-1 4m3-3l-4-1m4 1l-1 4" stroke="#fff" stroke-width="1.4"/>`, 'fxcupid');

const rainbow = () => svg('0 0 140 46', `
  ${['#e63946', '#f4a261', '#f9e45b', '#52b788', '#4d96ff', '#5e60ce', '#9d4edd'].map((c, i) => `<path d="M${12 + i * 3} 44A${58 - i * 3} ${40 - i * 3} 0 0 1 ${128 - i * 3} 44" stroke="${c}" stroke-width="3" fill="none" opacity=".85"/>`).join('')}
  <g transform="translate(6 30)"><circle cx="6" cy="8" r="6" fill="#fff"/><circle cx="14" cy="6" r="7" fill="#fff"/><circle cx="22" cy="9" r="5" fill="#fff"/></g>
  <g transform="translate(112 26)"><ellipse cx="12" cy="6" rx="11" ry="3.5" fill="#f5c451"/>${[4, 9, 14, 19].map((x, i) => `<circle class="fxcoin" style="animation-delay:${-i * 0.4}s" cx="${x + 1}" cy="${4 - (i % 2) * 2}" r="2.6" fill="#ffd95e"/>`).join('')}<path d="M0 7h24l-3 13H3z" fill="#1c1c22"/><rect x="-1" y="6" width="26" height="3" rx="1.5" fill="#2b2b33"/></g>`, 'fxrainbow');

const bunny = () => `<div class="fxhopper">${svg('0 0 44 44', `
  <ellipse cx="22" cy="30" rx="11" ry="9" fill="#f4f1ec"/><circle cx="12" cy="31" r="4" fill="#fff"/>
  <circle cx="31" cy="21" r="7" fill="#f4f1ec"/>
  <path d="M28 15q-3-14 1-14q3 1 2 14z" fill="#f4f1ec"/><path d="M29 14q-1-10 1-11" stroke="#ffb3c7" stroke-width="2"/>
  <path d="M33 15q2-14 6-12q2 3-3 13z" fill="#f4f1ec"/><path d="M35 14q1-9 3-10" stroke="#ffb3c7" stroke-width="2"/>
  <circle cx="34" cy="20" r="1.3" fill="#3a2a2a"/><circle cx="37.5" cy="23" r="1.2" fill="#ff8fab"/>
  <path d="M15 38h6M26 38h6" stroke="#e6ded3" stroke-width="3" stroke-linecap="round"/>`, 'fxbunny')}</div>
  ${svg('0 0 300 14', `<path d="M0 14V9${Array.from({ length: 50 }, (_, i) => `l3 -${4 + (i % 3) * 2}l3 ${4 + (i % 3) * 2}`).join('')}V14z" fill="#4c9a52"/>`, 'fxgrass').replace('<svg ', '<svg preserveAspectRatio="none" ')}
  ${['#ffc8dd', '#bde0fe', '#fff1a8', '#caffbf', '#e4c1f9'].map((c, i) => `<svg class="fxegg" style="left:${10 + i * 19}%" viewBox="0 0 10 13" aria-hidden="true"><ellipse cx="5" cy="6.5" rx="4.5" ry="6" fill="${c}"/><path d="M1 6.5q4-2.5 8 0" stroke="#fff" stroke-width="1" fill="none"/></svg>`).join('')}`;

const flame = (x: number, y: number) => `<path class="flame" d="M${x} ${y}q3.5 4.5 0 9q-3.5-4.5 0-9z" fill="#ffd166"/>`;
const diya = (x: number, y: number) => `<g><path d="M${x - 8} ${y}q8 8 16 0z" fill="#c2410c"/><path d="M${x - 8} ${y}h16" stroke="#fbbf24" stroke-width="1.4"/>${flame(x, y - 10)}</g>`;

const rangoli = () => svg('0 0 140 46', `
  ${diya(16, 34)}${diya(124, 34)}
  <g class="fxspin" style="transform-origin:70px 23px">
    ${Array.from({ length: 12 }, (_, i) => `<ellipse cx="70" cy="9" rx="4" ry="9" fill="${['#f97316', '#e11d48', '#facc15', '#a855f7'][i % 4]}" transform="rotate(${i * 30} 70 23)"/>`).join('')}
    ${Array.from({ length: 8 }, (_, i) => `<ellipse cx="70" cy="15" rx="3" ry="5" fill="${i % 2 ? '#22c55e' : '#38bdf8'}" transform="rotate(${i * 45 + 22} 70 23)"/>`).join('')}
    <circle cx="70" cy="23" r="5" fill="#fde047"/><circle cx="70" cy="23" r="2.2" fill="#e11d48"/>
  </g>`, 'fxrangoli');

const liveTurkey = () => svg('0 0 60 46', `
  <g class="fxfan" style="transform-origin:22px 26px">${['#5a3420', '#8c4a2f', '#b5452b', '#d9631e', '#e3a33b', '#d9631e', '#b5452b', '#8c4a2f', '#5a3420'].map((c, i) => `<g transform="rotate(${-80 + i * 20} 22 26)"><ellipse cx="22" cy="12" rx="4.4" ry="12" fill="${c}"/><ellipse cx="22" cy="3.6" rx="2.6" ry="2.6" fill="#f2c94c"/><circle cx="22" cy="3.6" r="1.2" fill="#2b1a10"/></g>`).join('')}</g>
  <g class="fxstep a"><path d="M24 34l-1 9M23 43l-3 1M23 43l2 1" stroke="#e8a03a" stroke-width="1.8" stroke-linecap="round"/></g>
  <g class="fxstep b"><path d="M31 34l1 9M32 43l-2 1M32 43l3 1" stroke="#e8a03a" stroke-width="1.8" stroke-linecap="round"/></g>
  <ellipse cx="27" cy="27" rx="12.5" ry="10" fill="#5e3a22"/>
  <path d="M17 24q6 9 18 5" stroke="#8a5a3c" stroke-width="2.4" fill="none"/><path d="M20 22q5 5 12 3" stroke="#7a4a2c" stroke-width="1.6" fill="none"/>
  <ellipse cx="34" cy="28" rx="5.5" ry="7" fill="#7a4a2c"/>
  <g class="fxgobble" style="transform-origin:36px 22px">
    <path d="M35 24q-1-9 4-12q4-1 5 3q1 3-2 5q-2 2-3 5z" fill="#c9b49a"/>
    <circle cx="41" cy="12.4" r="3.4" fill="#d9c6ad"/><circle cx="42.2" cy="11.6" r=".9" fill="#111"/>
    <path d="M44 12.4l3.4 1-3.4 1.2z" fill="#f5b500"/>
    <path d="M43.6 10.4q2.4 2 .4 6" stroke="#e63946" stroke-width="1.8" fill="none" stroke-linecap="round"/>
    <path d="M41.6 15q1.4 3.6-1.2 6.4" stroke="#e63946" stroke-width="2.4" fill="none" stroke-linecap="round"/>
  </g>`, 'fxlive');

const platter = () => svg('0 0 96 46', `<ellipse cx="48" cy="40" rx="45" ry="6" fill="#d9d4ca"/><ellipse cx="48" cy="39" rx="41" ry="4.6" fill="#f4f1ea"/>
  ${[[10, 37], [17, 40], [80, 40], [87, 37], [24, 42], [72, 42]].map(([x, y]) => `<ellipse cx="${x}" cy="${y}" rx="5" ry="2.6" fill="#4c9a52"/>`).join('')}
  ${[[13, 36], [84, 36], [21, 40], [76, 40]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="2.2" fill="#e5383b"/><circle cx="${x - 0.6}" cy="${y - 0.7}" r=".6" fill="#fff" opacity=".6"/>`).join('')}
  ${[[30, 42], [66, 42]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="3" fill="#f59e0b"/><path d="M${x - 3} ${y}h6M${x} ${y - 3}v6" stroke="#fde68a" stroke-width=".6"/>`).join('')}`, 'fxplatter');

const roast = () => svg('0 0 96 46', `<defs>
    <radialGradient id="fxskin" cx=".42" cy=".32" r=".75"><stop offset="0" stop-color="#f6c06a"/><stop offset=".45" stop-color="#d98a32"/><stop offset="1" stop-color="#8f4512"/></radialGradient>
    <radialGradient id="fxleg" cx=".4" cy=".35" r=".8"><stop offset="0" stop-color="#f2b25c"/><stop offset="1" stop-color="#9a4f16"/></radialGradient>
  </defs>
  ${[0, 1, 2].map((i) => `<path class="fxsteam" style="animation-delay:${-i * 0.9}s" d="M${38 + i * 9} 12q-3-4 0-7t0-7" stroke="rgba(255,255,255,.55)" stroke-width="1.6" fill="none" stroke-linecap="round"/>`).join('')}
  <path d="M22 37q-4-16 12-22q14-5 28 0q16 6 12 22z" fill="url(#fxskin)"/>
  <path d="M30 24q8-6 20-5M28 30q10-4 24-3" stroke="#a4561a" stroke-width="1" fill="none" opacity=".55"/>
  <ellipse cx="42" cy="21" rx="9" ry="3.6" fill="#fff" opacity=".28"/>
  <g transform="rotate(-28 26 30)"><ellipse cx="26" cy="30" rx="7" ry="9.5" fill="url(#fxleg)"/><rect x="24.6" y="16" width="2.8" height="7" rx="1.4" fill="#f4ead6"/><path d="M23 16l1-2 1 2 1-2 1 2 1-2 1 2" stroke="#fff" stroke-width="1.2" fill="none"/></g>
  <g transform="rotate(28 70 30)"><ellipse cx="70" cy="30" rx="7" ry="9.5" fill="url(#fxleg)"/><rect x="68.6" y="16" width="2.8" height="7" rx="1.4" fill="#f4ead6"/><path d="M67 16l1-2 1 2 1-2 1 2 1-2 1 2" stroke="#fff" stroke-width="1.2" fill="none"/></g>
  <ellipse cx="68" cy="22" rx="3" ry=".9" fill="#fff" opacity=".35" transform="rotate(28 70 30)"/>`, 'fxroast');

const poof = () => svg('0 0 96 46', `${[[36, 26, 9], [50, 20, 11], [62, 27, 9], [44, 32, 8], [56, 33, 8]].map(([x, y, r]) => `<circle cx="${x}" cy="${y}" r="${r}" fill="#f4f1ea" opacity=".92"/>`).join('')}${[[24, 14], [74, 12], [30, 38], [70, 38], [48, 6]].map(([x, y]) => `<path d="M${x} ${y - 3}l1 2 2 1-2 1-1 2-1-2-2-1 2-1z" fill="#ffd95e"/>`).join('')}`, 'fxpoof');

const farm = () => `${svg('0 0 300 10', `<path d="M0 10V5${Array.from({ length: 60 }, (_, i) => `l2.5 -${2 + (i % 3)}l2.5 ${2 + (i % 3)}`).join('')}V10z" fill="#7a6a2e"/>${Array.from({ length: 22 }, (_, i) => `<path transform="translate(${6 + i * 13.5} ${4 + (i % 3)}) rotate(${i * 47})" d="M0-2.6Q2.2 0 0 2.6Q-2.2 0 0-2.6Z" fill="${['#d9631e', '#b5452b', '#e3a33b', '#8c4a2f'][i % 4]}"/>`).join('')}`, 'fxground').replace('<svg ', '<svg preserveAspectRatio="none" ')}
  ${svg('0 0 50 30', '<rect x="2" y="10" width="30" height="18" rx="3" fill="#d9b25b"/><path d="M4 15h26M4 21h26M4 26h26" stroke="#b8913f" stroke-width="1"/><path d="M10 10v18M24 10v18" stroke="#8c6234" stroke-width="1.4"/><ellipse cx="40" cy="23" rx="8" ry="6.5" fill="#e3843b"/><ellipse cx="40" cy="23" rx="3" ry="6.5" fill="#f0a35a"/><path d="M40 16.5q1-4 4-4" stroke="#4d7a2a" stroke-width="1.6" fill="none"/><ellipse cx="16" cy="8" rx="5" ry="4" fill="#d9631e"/><path d="M16 4q0-3 2-3" stroke="#4d7a2a" stroke-width="1.4" fill="none"/>', 'fxhay')}
  ${platter()}${roast()}<div class="fxstrut">${liveTurkey()}</div>${poof()}`;

const newYear = () => {
  const now = new Date();
  const year = now.getMonth() >= 6 ? now.getFullYear() + 1 : now.getFullYear();
  const flute = (x: number, cls: string, tilt: number) => `<g transform="rotate(${tilt} ${x} 44)"><g class="${cls}" style="transform-origin:${x}px 44px"><path d="M${x - 5} 6h10l-1.4 16q-3.6 3-7.2 0z" fill="#ffe08a" opacity=".9"/><path d="M${x - 5} 6h10" stroke="#fff" stroke-width="1"/><circle class="fxbub" cx="${x - 1}" cy="16" r=".9" fill="#fff"/><circle class="fxbub" style="animation-delay:-.8s" cx="${x + 1.5}" cy="19" r=".7" fill="#fff"/><path d="M${x} 24v16M${x - 5} 42h10" stroke="#e8e8f0" stroke-width="1.6" stroke-linecap="round"/></g></g>`;
  return `${show([['#f5c451', '#fff3c4'], ['#ff5d8f', '#f5c451'], ['#7e9bff', '#fff'], ['#5fd38a', '#f5c451'], ['#e879f9', '#fff']], 9)}<div class="fxny">${svg('0 0 44 46', flute(12, 'fxclinkL', 10) + flute(32, 'fxclinkR', -10) + '<path class="fxclinks" d="M22 1l1.2 2.6 2.8.4-2 2 .5 2.8-2.5-1.3-2.5 1.3.5-2.8-2-2 2.8-.4z" fill="#fff3c4"/>', 'fxglasses')}<b class="fxyear">${year}</b></div>`;
};

const fu = () => svg('0 0 120 46', `
  ${[16, 104].map((x, k) => `<g class="fxswing" style="transform-origin:${x}px 0;animation-delay:${-k * 1.5}s"><line x1="${x}" y1="0" x2="${x}" y2="10" stroke="#f5c451"/><ellipse cx="${x}" cy="20" rx="9" ry="10" fill="#d7263d"/><path d="M${x - 5} 11h10M${x - 5} 29h10" stroke="#f5c451" stroke-width="2"/><path d="M${x} 30v10" stroke="#f5c451"/></g>`).join('')}
  <g class="fxswing" style="transform-origin:60px 0"><line x1="60" y1="0" x2="60" y2="6" stroke="#f5c451"/><rect x="47" y="8" width="26" height="26" transform="rotate(45 60 21)" fill="#d7263d" stroke="#f5c451" stroke-width="1.6"/><text x="60" y="27" text-anchor="middle" font-size="16" font-weight="700" fill="#f5c451" transform="rotate(180 60 22)">福</text></g>
  ${[34, 86].map((x) => `<g>${[0, 1, 2, 3, 4].map((i) => `<rect class="fxcrack" style="animation-delay:${-i * 0.3}s" x="${x - 2.5}" y="${4 + i * 7}" width="5" height="6" rx="1" fill="#e63946"/>`).join('')}<line x1="${x}" y1="0" x2="${x}" y2="4" stroke="#f5c451"/></g>`).join('')}`, 'fxfu');

const HATS = {
  santa: svg('0 0 60 40', '<path d="M8 30q14-30 38-24q8 3 4 14q-4-7-12-6l4 16z" fill="#c8102e"/><rect x="4" y="28" width="44" height="8" rx="4" fill="#fff"/><circle cx="51" cy="21" r="5" fill="#fff"/>'),
  party: svg('0 0 60 40', '<path d="M18 36L30 2l12 34z" fill="#7b5cd6"/><path d="M22 26l14-8M24 33l16-8M26 16l8-5" stroke="#f5c451" stroke-width="2.4"/><circle cx="30" cy="3" r="4" fill="#ff5d8f"/>'),
  leprechaun: svg('0 0 60 40', '<rect x="16" y="6" width="28" height="24" rx="2" fill="#1f7a3a"/><rect x="6" y="28" width="48" height="7" rx="3.5" fill="#1f7a3a"/><rect x="16" y="22" width="28" height="5" fill="#111"/><rect x="26" y="20" width="8" height="9" rx="1" fill="none" stroke="#f5c451" stroke-width="2"/><g transform="translate(40 12)" fill="#5fd38a"><circle cy="-3" r="3"/><circle cx="-3" cy="1" r="3"/><circle cx="3" cy="1" r="3"/></g>'),
  ears: svg('0 0 60 40', '<path d="M18 38q-10-36 2-36q8 2 4 36z" fill="#f4f1ec"/><path d="M19 34q-5-26 1-28q3 2 1 28z" fill="#ffb3c7"/><path d="M36 38q-2-36 10-34q8 4-4 36z" fill="#f4f1ec"/><path d="M38 34q1-24 7-26q2 3-4 26z" fill="#ffb3c7"/>'),
  uncleSam: svg('0 0 60 40', '<rect x="16" y="2" width="28" height="28" rx="2" fill="#fff"/>' + [0, 1, 2].map((i) => `<rect x="${18 + i * 9}" y="2" width="4.5" height="28" fill="#b22234"/>`).join('') + '<rect x="16" y="20" width="28" height="6" fill="#3c3b6e"/><circle cx="24" cy="23" r="1.2" fill="#fff"/><circle cx="30" cy="23" r="1.2" fill="#fff"/><circle cx="36" cy="23" r="1.2" fill="#fff"/><rect x="6" y="29" width="48" height="6" rx="3" fill="#3c3b6e"/>'),
  witch: svg('0 0 60 40', '<path d="M14 32Q30 22 34 2q2 10 14 30z" fill="#2a1f3d"/><path d="M34 2q8 4 12 0" stroke="#2a1f3d" stroke-width="3" fill="none"/><ellipse cx="30" cy="33" rx="28" ry="5" fill="#2a1f3d"/><rect x="18" y="26" width="26" height="5" fill="#a855f7"/><rect x="28" y="25.5" width="6" height="6" fill="none" stroke="#f5c451" stroke-width="1.6"/>'),
  pilgrim: svg('0 0 60 40', '<path d="M18 30l3-26h18l3 26z" fill="#1d1d22"/><rect x="6" y="28" width="48" height="7" rx="3.5" fill="#1d1d22"/><rect x="18" y="22" width="24" height="5" fill="#6b4429"/><rect x="25" y="20.5" width="10" height="8" fill="none" stroke="#f5c451" stroke-width="2"/>'),
};

const FOOT = {
  christmas: svg('0 0 110 30', '<g transform="translate(0 2)"><circle cx="16" cy="21" r="8" fill="#f4f8ff"/><circle cx="16" cy="9" r="6" fill="#f4f8ff"/><circle cx="14" cy="8" r=".9" fill="#222"/><circle cx="18" cy="8" r=".9" fill="#222"/><path d="M16 10l4 1-4 1z" fill="#f97316"/><path d="M10 14h12" stroke="#c8102e" stroke-width="2.4"/><path d="M11 6h10l-2-6h-6z" fill="#222"/><rect x="9" y="5" width="14" height="2" fill="#222"/><path d="M8 18l-6-4M24 18l6-4" stroke="#6b4429" stroke-width="1.4"/></g><rect x="40" y="13" width="20" height="17" rx="1.5" fill="#d7263d"/><rect x="48" y="13" width="4" height="17" fill="#f5c451"/><path d="M50 13q-7-7-8 0M50 13q7-7 8 0" stroke="#f5c451" stroke-width="2" fill="none"/><rect x="64" y="17" width="15" height="13" rx="1.5" fill="#22a05a"/><rect x="70" y="17" width="3" height="13" fill="#f1faee"/><rect x="83" y="20" width="12" height="10" rx="1.5" fill="#3a6ff7"/><rect x="88" y="20" width="2.5" height="10" fill="#f5c451"/>'),
  'new-year': svg('0 0 110 30', `<g transform="rotate(-18 30 20)"><rect x="24" y="8" width="11" height="22" rx="4" fill="#1f4d2e"/><rect x="27" y="2" width="5" height="8" fill="#1f4d2e"/><rect x="26" y="1" width="7" height="3" fill="#d4af37"/><rect x="24" y="14" width="11" height="7" fill="#f5c451"/></g>${Array.from({ length: 14 }, (_, i) => `<rect x="${44 + ((i * 37) % 60)}" y="${18 + ((i * 13) % 11)}" width="3" height="${i % 2 ? 3 : 5}" transform="rotate(${i * 40} ${45 + ((i * 37) % 60)} ${20 + ((i * 13) % 11)})" fill="${['#f5c451', '#ff5d8f', '#7e9bff', '#5fd38a'][i % 4]}"/>`).join('')}`),
  'lunar-new-year': svg('0 0 110 30', '<g transform="translate(20 0)"><rect x="0" y="6" width="18" height="24" rx="2" fill="#d7263d"/><path d="M0 8l9 7 9-7" stroke="#f5c451" stroke-width="1.4" fill="none"/><circle cx="9" cy="20" r="3.5" fill="#f5c451"/></g>' + [52, 66, 80].map((x) => `<circle cx="${x}" cy="23" r="7" fill="#f97316"/><path d="M${x} 16q2-4 5-3" stroke="#3f8f4f" stroke-width="1.6" fill="none"/>`).join('')),
  valentines: svg('0 0 110 30', `${heartPath(1.6, '#8c1d2c', 40, 20)}${heartPath(1.4, '#c8102e', 40, 19)}<circle cx="34" cy="17" r="2" fill="#5a2d1a"/><circle cx="40" cy="20" r="2" fill="#5a2d1a"/><circle cx="46" cy="17" r="2" fill="#5a2d1a"/><path d="M72 30q2-12-1-20" stroke="#3f8f4f" stroke-width="1.8" fill="none"/><path d="M72 16q-6-2-6 4" stroke="#3f8f4f" stroke-width="1.4" fill="none"/><circle cx="71" cy="9" r="5.5" fill="#c8102e"/><path d="M68 8q3-4 6 0q-3 3-6 0" fill="#8c1d2c"/>`),
  'st-patricks': svg('0 0 110 30', '<g transform="translate(18 2)"><ellipse cx="20" cy="9" rx="13" ry="3.5" fill="#f5c451"/><circle cx="13" cy="7" r="3" fill="#ffd95e"/><circle cx="20" cy="5" r="3" fill="#ffd95e"/><circle cx="27" cy="7" r="2.6" fill="#ffd95e"/><path d="M6 10h28l-4 18H10z" fill="#1c1c22"/><rect x="5" y="9" width="30" height="3.5" rx="1.75" fill="#2b2b33"/></g><path d="M66 28v-14q0-9 9-9t9 9v14" stroke="#c0c4cc" stroke-width="4" fill="none"/><circle cx="66" cy="16" r="1" fill="#555"/><circle cx="84" cy="16" r="1" fill="#555"/>'),
  easter: svg('0 0 110 30', '<path d="M18 16h40l-5 14H23z" fill="#b8874a"/><path d="M20 20h36M22 25h32" stroke="#8c6234" stroke-width="1.4"/><path d="M20 16q18-22 36 0" stroke="#8c6234" stroke-width="2.4" fill="none"/><ellipse cx="28" cy="14" rx="5" ry="6.5" fill="#ffc8dd"/><ellipse cx="38" cy="13" rx="5" ry="6.5" fill="#bde0fe"/><ellipse cx="48" cy="14" rx="5" ry="6.5" fill="#fff1a8"/><path d="M33 13l2 1.5 3-2 3 2 2-1.5" stroke="#fff" fill="none"/><ellipse cx="78" cy="22" rx="6" ry="7.5" fill="#caffbf"/><path d="M72 22h12" stroke="#fff" stroke-width="1.6"/><ellipse cx="94" cy="23" rx="5" ry="6.5" fill="#e4c1f9"/><circle cx="92" cy="21" r="1.2" fill="#fff"/><circle cx="96" cy="25" r="1.2" fill="#fff"/>'),
  'independence-day': svg('0 0 110 30', [20, 38, 56, 74, 92].map((x, i) => `<path class="fxtw" style="animation-delay:${-i * 0.5}s" d="M${x} ${10 + (i % 2) * 6}l2 5h5.3l-4.3 3.2 1.6 5.3-4.6-3.3-4.6 3.3 1.6-5.3-4.3-3.2h5.3z" fill="${['#e63946', '#f1faee', '#4d7cff'][i % 3]}"/>`).join('')),
  halloween: svg('0 0 110 30', `${[[20, 12, 9], [50, 9, 7]].map(([x, rx, ry]) => `<ellipse cx="${x}" cy="${30 - ry}" rx="${rx}" ry="${ry}" fill="#e8741c"/><ellipse cx="${x}" cy="${30 - ry}" rx="${rx / 2.4}" ry="${ry}" fill="#f28c28"/><path d="M${x} ${30 - ry * 2}c0-3 2-4 3-5" stroke="#4d7a2a" stroke-width="2" fill="none"/><path class="fxglow" d="M${x - rx / 2} ${28 - ry * 1.3}l2.4 2.4h-4.8zM${x + rx / 2} ${28 - ry * 1.3}l-2.4 2.4h4.8zM${x - rx / 2} ${30 - ry * 0.6}q${rx / 2} ${ry / 2.2} ${rx} 0" fill="#ffd166" stroke="#ffd166"/>`).join('')}<g transform="translate(74 14) rotate(-20)"><rect x="0" y="4" width="14" height="8" rx="4" fill="#a855f7"/><path d="M0 8l-5-4v8zM14 8l5-4v8z" fill="#a855f7"/></g><g transform="translate(90 18) rotate(15)"><rect x="0" y="4" width="12" height="7" rx="3.5" fill="#22c55e"/><path d="M0 7.5l-4-3v6zM12 7.5l4-3v6z" fill="#22c55e"/></g>`),
  diwali: svg('0 0 110 30', [20, 42, 64, 86].map((x) => diya(x, 22)).join('')),
  thanksgiving: svg('0 0 110 30', '<ellipse cx="34" cy="27" rx="26" ry="3.4" fill="#d9d4ca"/><path d="M12 26L34 10l22 16z" fill="#c76a1e"/><path d="M12 26L34 10l22 16" stroke="#e9b26a" stroke-width="2.4" fill="none" stroke-linejoin="round"/><path d="M14 26h40" stroke="#a65314" stroke-width="1"/><path d="M28 13q6-6 12 0q-3 4-6 2q-3 2-6-2z" fill="#fffaf0"/><path d="M33 9q1-3 2 0" stroke="#fffaf0" stroke-width="2" stroke-linecap="round"/><g transform="translate(70 4)"><path d="M6 24q-6-12 2-22q8 10 2 22z" fill="#f2c94c"/><path d="M5 8l3 1M4 12l4 1M4 16l4 1M5 20l3 1M10 8l-2 1M11 12l-3 1M11 16l-3 1" stroke="#c99a2a" stroke-width=".8"/><path d="M6 24q-8-4-10-14q6 4 10 14zM8 24q8-4 10-14q-6 4-10 14z" fill="#9bb36a"/></g><path d="M96 28l6-12l5 9z" fill="#b5452b"/>'),
} satisfies Record<FestiveId, string>;

const CORNER = {
  web: svg('0 0 70 70', '<g stroke="rgba(230,230,240,.5)" stroke-width=".9" fill="none"><path d="M0 0L70 24M0 0L52 52M0 0L24 70M0 0L70 0M0 0L0 70"/><path d="M18 0Q15 6 0 18M36 0Q31 13 0 36M56 0Q48 22 0 56M70 9Q58 36 9 70"/></g>'),
  rose: svg('0 0 70 70', '<path d="M8 66q14-26 30-36" stroke="#3f8f4f" stroke-width="2.4" fill="none"/><path d="M20 50q-12-2-10 8q8 0 10-8zM26 42q10-10 14 0q-8 4-14 0z" fill="#4c9a52"/><circle cx="42" cy="26" r="11" fill="#c8102e"/><path d="M36 24q6-8 12 0q-6 5-12 0M38 30q4 4 8 0" stroke="#8c1d2c" stroke-width="1.6" fill="none"/>'),
  streamers: svg('0 0 70 70', '<path d="M4 4q20 4 14 14t14 14q-6 10 14 14" stroke="#f5c451" stroke-width="3" fill="none" stroke-linecap="round"/><path d="M4 10q10 14 2 22t10 18" stroke="#d9dde6" stroke-width="2.4" fill="none" stroke-linecap="round"/><path d="M10 4q14 8 26 0t18 10" stroke="#ff5d8f" stroke-width="2.4" fill="none" stroke-linecap="round"/>'),
  fan: svg('0 0 80 44', `<g transform="translate(40 0)">${Array.from({ length: 9 }, (_, i) => `<path d="M0 0L${Math.cos(Math.PI * (i / 9)) * 38} ${Math.sin(Math.PI * (i / 9)) * 38}L${Math.cos(Math.PI * ((i + 1) / 9)) * 38} ${Math.sin(Math.PI * ((i + 1) / 9)) * 38}z" fill="${['#b22234', '#fff', '#3c3b6e'][i % 3]}"/>`).join('')}<circle r="9" fill="#3c3b6e"/><path d="M0-4l1.2 3h3.2l-2.6 2 1 3.2L0 2.3-2.8 4.2l1-3.2-2.6-2h3.2z" fill="#fff" transform="translate(0 2)"/></g>`),
  leaves: svg('0 0 70 70', '<path d="M6 8q20 20 46 22" stroke="#6b4429" stroke-width="2" fill="none"/>' + [[16, 16, 30, '#d9631e'], [30, 24, -10, '#b5452b'], [44, 28, 50, '#e3a33b'], [24, 8, 80, '#8c4a2f']].map(([x, y, r, c]) => `<path transform="translate(${x} ${y}) rotate(${r})" d="M0-9Q8 0 0 9Q-8 0 0-9Z" fill="${c}"/>`).join('') + '<g transform="translate(52 34)"><ellipse cy="4" rx="4" ry="5" fill="#a0692f"/><path d="M-5 0h10q0-4-5-4t-5 4z" fill="#6b4429"/></g>'),
};

export const DECOR: Record<FestiveId, Decor> = {
  christmas: { center: xmas, hat: HATS.santa, foot: FOOT.christmas, caps: true, lights: true, icicles: true, fall: 'snow' },
  'new-year': { center: newYear, hat: HATS.party, foot: FOOT['new-year'], corner: CORNER.streamers },
  'lunar-new-year': { center: fu, foot: FOOT['lunar-new-year'], lanterns: true },
  valentines: { center: cupid, foot: FOOT.valentines, corner: CORNER.rose, fall: 'hearts' },
  'st-patricks': { center: rainbow, hat: HATS.leprechaun, foot: FOOT['st-patricks'], fall: 'clovers' },
  easter: { center: bunny, hat: HATS.ears, foot: FOOT.easter },
  'independence-day': { center: flag, hat: HATS.uncleSam, foot: FOOT['independence-day'], corner: CORNER.fan },
  halloween: { center: moon, hat: HATS.witch, foot: FOOT.halloween, corner: CORNER.web, spider: true },
  diwali: { center: rangoli, foot: FOOT.diwali, toran: true },
  thanksgiving: { center: farm, hat: HATS.pilgrim, foot: FOOT.thanksgiving, corner: CORNER.leaves },
};

const LANTERN = svg('0 0 40 90', '<line x1="20" y1="0" x2="20" y2="22" stroke="#f5c451" stroke-width="1.5"/><rect x="12" y="20" width="16" height="5" rx="1.5" fill="#f5c451"/><ellipse cx="20" cy="42" rx="17" ry="18" fill="#d7263d"/><path d="M20 24v36M11 27q-5 15 0 30M29 27q5 15 0 30" stroke="#b01e30" stroke-width="1.5" fill="none"/><rect x="12" y="58" width="16" height="5" rx="1.5" fill="#f5c451"/><path d="M16 63v20M20 63v24M24 63v20" stroke="#f5c451" stroke-width="1.5"/>', 'lan');
const SPIDER = svg('0 0 30 120', '<line x1="15" y1="0" x2="15" y2="92" stroke="rgba(230,230,240,.6)"/><g fill="#1a1422" stroke="#1a1422" stroke-width="1.6"><ellipse cx="15" cy="102" rx="6" ry="7"/><circle cx="15" cy="93" r="4"/><path d="M9 98l-7-5M9 102l-8 0M9 106l-7 5M21 98l7-5M21 102l8 0M21 106l7 5" fill="none"/></g><circle cx="13.3" cy="92" r="1" fill="#f97316"/><circle cx="16.7" cy="92" r="1" fill="#f97316"/>', 'fxspider');
const TORAN = `url("data:image/svg+xml,${encodeURIComponent(`<svg xmlns='http://www.w3.org/2000/svg' width='48' height='24' viewBox='0 0 48 24'><path d='M0 2Q24 10 48 2' stroke='#c2410c' fill='none'/>${[6, 16, 26, 36, 46].map((x, i) => `<circle cx='${x}' cy='${3 + Math.sin((x / 48) * Math.PI) * 4}' r='3.6' fill='${i % 2 ? '#fbbf24' : '#f97316'}'/>`).join('')}<path d='M24 8v8' stroke='#c2410c'/><path d='M24 15q-5 4 0 9q5-5 0-9z' fill='#3f8f4f'/></svg>`)}")`;

let resizeHat: (() => void) | null = null;

function el(html: string, cls: string) {
  const d = document.createElement('div');
  d.className = cls;
  d.dataset.fx = '';
  d.setAttribute('aria-hidden', 'true');
  d.innerHTML = html;
  return d;
}

export function clearDecor() {
  document.querySelectorAll('[data-fx]').forEach((n) => n.remove());
  if (resizeHat) window.removeEventListener('resize', resizeHat);
  resizeHat = null;
}

export function mountDecor(id: FestiveId) {
  clearDecor();
  const d = DECOR[id];
  const hdr = document.querySelector<HTMLElement>('.hdr');
  const hero = document.querySelector<HTMLElement>('.main>section:first-child');
  const panels = [...document.querySelectorAll<HTMLElement>('.hdr,.main>section,.ftr')];
  const ftr = document.querySelector<HTMLElement>('.ftr');
  const brand = hdr?.querySelector(':scope > a');
  if (d.center && brand) brand.after(el(d.center(), `fxc fxc-${id}`));
  if (d.foot && ftr) ftr.prepend(el(d.foot, 'fxfoot'));
  if (d.corner && hero) hero.prepend(el(d.corner, `fxcorner fxcorner-${id}`));
  if (d.caps) for (const p of panels) p.prepend(el('', 'fxcap'), el('', 'fxfrost'));
  if (d.lights && hdr) hdr.prepend(el(lights(), 'fxlights'));
  if (d.icicles) for (const p of panels.slice(0, -1)) p.prepend(el('', 'fxice'));
  if (d.toran && hdr) { const t = el('', 'fxtoran'); t.style.backgroundImage = TORAN; hdr.prepend(t); }
  if (d.spider && hdr) hdr.prepend(el(SPIDER, 'fxspiderwrap'));
  if (d.lanterns) document.body.append(el(LANTERN + LANTERN, 'fxlan'));
  const logo = document.querySelector<SVGElement>('.archlogo');
  if (d.hat && logo?.parentElement) {
    const hat = el(d.hat, `fxhat fxhat-${id}`);
    logo.parentElement.append(hat);
    resizeHat = () => {
      const parent = logo.parentElement!;
      const pr = parent.getBoundingClientRect();
      const lr = logo.getBoundingClientRect();
      const k = pr.width / parent.offsetWidth || 1;
      const w = lr.width / k;
      hat.style.width = `${w * 0.62}px`;
      hat.style.left = `${(lr.left - pr.left) / k + w * 0.2}px`;
      hat.style.top = `${(lr.top - pr.top) / k - w * 0.3}px`;
    };
    resizeHat();
    window.addEventListener('resize', resizeHat);
  }
}
