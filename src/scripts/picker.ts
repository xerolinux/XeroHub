import type { ThemeId } from '../data/themes';
import { currentTheme, setTheme } from './theme';

const pop = document.getElementById('theme-pop');
const btn = document.querySelector<HTMLButtonElement>('[data-theme-toggle]');
const options = () => [...(pop?.querySelectorAll<HTMLButtonElement>('[data-theme-id]') ?? [])];

function sync() {
  const cur = currentTheme();
  for (const o of options()) o.setAttribute('aria-selected', String(o.dataset.themeId === cur));
}

function place() {
  if (!pop || !btn) return;
  const r = btn.getBoundingClientRect();
  const w = pop.offsetWidth;
  const h = pop.offsetHeight;
  pop.style.left = `${Math.max(16, Math.min(r.right - w, innerWidth - w - 16))}px`;
  pop.style.top = `${Math.max(8, r.top - h - 8)}px`;
}

if (pop && btn) {
  sync();
  pop.addEventListener('toggle', (ev) => {
    const open = (ev as ToggleEvent).newState === 'open';
    btn.setAttribute('aria-expanded', String(open));
    if (!open) return;
    sync();
    place();
    options().find((o) => o.getAttribute('aria-selected') === 'true')?.focus();
  });
  pop.addEventListener('click', (ev) => {
    const o = (ev.target as Element).closest<HTMLButtonElement>('[data-theme-id]');
    if (!o) return;
    setTheme(o.dataset.themeId as ThemeId);
    pop.hidePopover();
    btn.focus();
  });
  pop.addEventListener('keydown', (ev) => {
    if (ev.key !== 'ArrowDown' && ev.key !== 'ArrowUp') return;
    ev.preventDefault();
    const list = options();
    const i = list.indexOf(document.activeElement as HTMLButtonElement);
    list[(i + (ev.key === 'ArrowDown' ? 1 : -1) + list.length) % list.length].focus();
  });
  const replace = () => { if (pop.matches(':popover-open')) place(); };
  window.addEventListener('resize', replace);
  window.addEventListener('scroll', replace, { passive: true, capture: true });
  document.addEventListener('xero-theme', sync);
}
