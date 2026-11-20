import { DEFAULT_THEME, THEMES, resolveTheme, type Palette, type ThemeId } from '../data/themes';

const KEY = 'theme';

export function currentTheme(): ThemeId {
  try { return resolveTheme(localStorage.getItem(KEY)); } catch { return DEFAULT_THEME; }
}

export function applyTheme(id: ThemeId) {
  const root = document.documentElement;
  if (id === DEFAULT_THEME) delete root.dataset.theme;
  else root.dataset.theme = id;
  document.querySelector('meta[name="theme-color"]')?.setAttribute('content', THEMES[id].accent);
}

export function setTheme(id: ThemeId) {
  applyTheme(id);
  try { localStorage.setItem(KEY, id); } catch { /* storage blocked */ }
  document.dispatchEvent(new CustomEvent('xero-theme', { detail: id }));
}

export const activePalette = (): Palette => THEMES[resolveTheme(document.documentElement.dataset.theme ?? null)];
