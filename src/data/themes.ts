export type ThemeId = 'layan' | 'layan-dark' | 'catppuccin-mocha' | 'dracula' | 'nord' | 'gruvbox' | 'tokyo-night' | 'rose-pine' | 'everforest' | 'kanagawa';

export interface Palette {
  name: string;
  bg: string; surface: string; term: string; line: string;
  text: string; text2: string; dim: string;
  accent: string; accentL: string; btn1: string; btn2: string;
  c1: string; c2: string; c3: string; c1L: string; c2L: string; c3L: string;
  green: string; red: string; yellow: string; cyan: string;
  alpha?: Partial<Alpha>;
}

interface Alpha { line: number; soft: number; glass: number; solid: number; term: number; dim: number; orb: number; tint: number }

const ALPHA: Alpha = { line: 0.4, soft: 0.2, glass: 0.82, solid: 0.97, term: 0.85, dim: 0.62, orb: 0.9, tint: 1 };

// Filled colours (accent, btn*, c1-c3) carry white text, so several are darker than the scheme's official swatch.
export const THEMES: Record<ThemeId, Palette> = {
  layan: {
    name: 'Layan', bg: '#272a31', surface: '#2a2c34', term: '#1a1c24', line: '#6061f8',
    text: '#f0f0f2', text2: '#e2e2e6', dim: '#9a9cb8', accent: '#5d5ef7', accentL: '#9192ff', btn1: '#3d5bd0', btn2: '#6a44c2',
    c1: '#4a62e0', c2: '#7b5cd6', c3: '#c2286f', c1L: '#7e9bff', c2L: '#a98bf0', c3L: '#e07aa8',
    green: '#5fd38a', red: '#ee7a9a', yellow: '#f5c451', cyan: '#5ed3e6',
    alpha: { line: 0.36, glass: 0.5, term: 0.6, dim: 0.24, orb: 1, tint: 0 },
  },
  'layan-dark': {
    name: 'Layan Dark', bg: '#010103', surface: '#020205', term: '#010103', line: '#5a5be0',
    text: '#e4e4e8', text2: '#a6a6b0', dim: '#9a9cb8', accent: '#5a5be0', accentL: '#8385f5', btn1: '#3d5bd0', btn2: '#6a44c2',
    c1: '#4a62e0', c2: '#7b5cd6', c3: '#c2286f', c1L: '#7e9bff', c2L: '#a98bf0', c3L: '#e07aa8',
    green: '#5fd38a', red: '#ee7a9a', yellow: '#f5c451', cyan: '#5ed3e6',
    alpha: { line: 0.26, soft: 0.13, glass: 0.74, solid: 0.97, term: 0.72, dim: 0.7, orb: 0.35, tint: 0 },
  },
  'catppuccin-mocha': {
    name: 'Catppuccin Mocha', bg: '#1e1e2e', surface: '#181825', term: '#11111b', line: '#b4befe',
    text: '#cdd6f4', text2: '#bac2de', dim: '#a6adc8', accent: '#8839ef', accentL: '#cba6f7', btn1: '#1e66f5', btn2: '#8839ef',
    c1: '#1e5fe0', c2: '#8839ef', c3: '#d20f39', c1L: '#89b4fa', c2L: '#cba6f7', c3L: '#f38ba8',
    green: '#a6e3a1', red: '#f38ba8', yellow: '#f9e2af', cyan: '#94e2d5',
    alpha: { line: 0.3, soft: 0.16 },
  },
  dracula: {
    name: 'Dracula', bg: '#282a36', surface: '#21222c', term: '#191a21', line: '#bd93f9',
    text: '#f8f8f2', text2: '#e2e2dc', dim: '#a4afd6', accent: '#7344d6', accentL: '#bd93f9', btn1: '#7344d6', btn2: '#b02f78',
    c1: '#7344d6', c2: '#b02f78', c3: '#1d6f87', c1L: '#bd93f9', c2L: '#ff79c6', c3L: '#8be9fd',
    green: '#50fa7b', red: '#ff6e6e', yellow: '#f1fa8c', cyan: '#8be9fd',
  },
  nord: {
    name: 'Nord', bg: '#2e3440', surface: '#3b4252', term: '#242933', line: '#88c0d0',
    text: '#eceff4', text2: '#e5e9f0', dim: '#b4bccc', accent: '#4c6c94', accentL: '#88c0d0', btn1: '#4c6c94', btn2: '#7a5577',
    c1: '#4c6c94', c2: '#7a5577', c3: '#a0434c', c1L: '#88c0d0', c2L: '#c9a6c3', c3L: '#e3a28a',
    green: '#a3be8c', red: '#eda0a6', yellow: '#ebcb8b', cyan: '#8fbcbb',
  },
  gruvbox: {
    name: 'Gruvbox', bg: '#282828', surface: '#32302f', term: '#1d2021', line: '#fabd2f',
    text: '#ebdbb2', text2: '#d5c4a1', dim: '#bdae93', accent: '#af3a03', accentL: '#fabd2f', btn1: '#076678', btn2: '#af3a03',
    c1: '#076678', c2: '#8f3f71', c3: '#9d0006', c1L: '#83a598', c2L: '#d3869b', c3L: '#fe8019',
    green: '#b8bb26', red: '#fd7a6c', yellow: '#fabd2f', cyan: '#8ec07c',
    alpha: { line: 0.28, soft: 0.14 },
  },
  'tokyo-night': {
    name: 'Tokyo Night', bg: '#1a1b26', surface: '#16161e', term: '#13141c', line: '#7aa2f7',
    text: '#c0caf5', text2: '#a9b1d6', dim: '#9aa5ce', accent: '#3d59a1', accentL: '#7aa2f7', btn1: '#3d59a1', btn2: '#7651b8',
    c1: '#3d59a1', c2: '#7651b8', c3: '#b8325a', c1L: '#7aa2f7', c2L: '#bb9af7', c3L: '#f7768e',
    green: '#9ece6a', red: '#f7768e', yellow: '#e0af68', cyan: '#7dcfff',
  },
  'rose-pine': {
    name: 'Rosé Pine', bg: '#191724', surface: '#1f1d2e', term: '#13111c', line: '#c4a7e7',
    text: '#e0def4', text2: '#cdcbe6', dim: '#a8a4c4', accent: '#6d4fa3', accentL: '#c4a7e7', btn1: '#286983', btn2: '#6d4fa3',
    c1: '#286983', c2: '#6d4fa3', c3: '#a14f67', c1L: '#9ccfd8', c2L: '#c4a7e7', c3L: '#eb6f92',
    green: '#9ccfd8', red: '#eb6f92', yellow: '#f6c177', cyan: '#ebbcba',
    alpha: { line: 0.3, soft: 0.16 },
  },
  everforest: {
    name: 'Everforest', bg: '#2d353b', surface: '#343f44', term: '#232a2e', line: '#a7c080',
    text: '#d3c6aa', text2: '#c5b9a0', dim: '#b2bcb3', accent: '#4e6b2f', accentL: '#a7c080', btn1: '#2f6f8f', btn2: '#4e6b2f',
    c1: '#2f6f8f', c2: '#8a4a78', c3: '#a83f3c', c1L: '#7fbbb3', c2L: '#d699b6', c3L: '#e69899',
    green: '#a7c080', red: '#ec9a9b', yellow: '#dbbc7f', cyan: '#83c092',
    alpha: { line: 0.3, soft: 0.16 },
  },
  kanagawa: {
    name: 'Kanagawa', bg: '#1f1f28', surface: '#2a2a37', term: '#16161d', line: '#7e9cd8',
    text: '#dcd7ba', text2: '#c8c093', dim: '#a6a69c', accent: '#2d4f67', accentL: '#7e9cd8', btn1: '#2d4f67', btn2: '#6a4c9c',
    c1: '#2d4f67', c2: '#6a4c9c', c3: '#a33a45', c1L: '#7fb4ca', c2L: '#a48ec7', c3L: '#e87a86',
    green: '#98bb6c', red: '#e87a86', yellow: '#e6c384', cyan: '#7aa89f',
  },
};

export const THEME_IDS = Object.keys(THEMES) as ThemeId[];
export const DEFAULT_THEME: ThemeId = 'layan';

export function resolveTheme(stored: string | null): ThemeId {
  if (stored === 'dark') return 'layan-dark';
  return stored && stored in THEMES ? (stored as ThemeId) : DEFAULT_THEME;
}

const rgb = (hex: string) => [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16));
const rgba = (hex: string, a: number) => `rgba(${rgb(hex).join(',')},${a})`;

function luminance(hex: string) {
  const [r, g, b] = rgb(hex).map((v) => {
    const c = v / 255;
    return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
  });
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

export function contrast(a: string, b: string) {
  const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x);
  return (hi + 0.05) / (lo + 0.05);
}

const COLOR_KEYS = ['bg', 'text', 'text2', 'dim', 'accent', 'accentL', 'btn1', 'btn2', 'c1', 'c2', 'c3', 'c1L', 'c2L', 'c3L', 'green', 'red', 'yellow', 'cyan', 'term'] as const;

function vars(p: Palette) {
  const a = { ...ALPHA, ...p.alpha };
  const out = COLOR_KEYS.map((k) => `--${k}:${p[k]}`);
  out.push(
    `--line:${rgba(p.line, a.line)}`, `--soft:${rgba(p.line, a.soft)}`,
    `--glass:${rgba(p.surface, a.glass)}`, `--glassSolid:${rgba(p.surface, a.solid)}`,
    `--termbg:${rgba(p.term, a.term)}`, `--bgdim:${a.dim}`, `--dimc:${p.alpha?.tint === 0 ? '#000000' : p.bg}`, `--orb:${a.orb}`, `--tint:${a.tint}`,
  );
  return out.join(';');
}

export function themeCss() {
  return THEME_IDS.map((id) => `${id === DEFAULT_THEME ? ':root' : `:root[data-theme="${id}"]`}{${vars(THEMES[id])}}`).join('\n');
}
