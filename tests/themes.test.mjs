import test from 'node:test';
import assert from 'node:assert/strict';
import { THEMES, THEME_IDS, contrast, resolveTheme, themeCss } from '../src/data/themes.ts';

const IDS = ['layan', 'layan-dark', 'catppuccin-mocha', 'dracula', 'nord', 'gruvbox', 'tokyo-night', 'rose-pine', 'everforest', 'kanagawa'];
const TEXT = ['text', 'text2', 'dim', 'accentL', 'green', 'red', 'yellow', 'cyan', 'c1L', 'c2L', 'c3L'];
const FILLS = ['accent', 'btn1', 'btn2', 'c1', 'c2', 'c3'];
const KEYS = ['bg', 'surface', 'term', 'line', 'text', 'text2', 'dim', 'accent', 'accentL', 'btn1', 'btn2', 'c1', 'c2', 'c3', 'c1L', 'c2L', 'c3L', 'green', 'red', 'yellow', 'cyan'];

test('ids in order', () => assert.deepEqual(THEME_IDS, IDS));

test('every palette is complete', () => {
  for (const id of IDS) for (const k of KEYS) assert.match(THEMES[id][k], /^#[0-9a-f]{6}$/, `${id}.${k}`);
});

test('contrast formula', () => {
  assert.ok(Math.abs(contrast('#ffffff', '#000000') - 21) < 0.01);
  assert.ok(Math.abs(contrast('#777777', '#ffffff') - 4.48) < 0.01);
});

test('all text passes AA on bg and surface', () => {
  for (const id of IDS) {
    const p = THEMES[id];
    for (const k of TEXT) for (const on of ['bg', 'surface', 'term']) {
      const c = contrast(p[k], p[on]);
      assert.ok(c >= 4.5, `${id}.${k} on ${on}: ${c.toFixed(2)}`);
    }
  }
});

test('white text passes AA on filled colours', () => {
  for (const id of IDS) for (const k of FILLS) {
    const c = contrast('#ffffff', THEMES[id][k]);
    assert.ok(c >= 4.5, `${id}.${k}: ${c.toFixed(2)}`);
  }
});

test('dark text passes AA on light accents', () => {
  for (const id of IDS) {
    const c = contrast(THEMES[id].term, THEMES[id].c3L);
    assert.ok(c >= 4.5, `${id} term on c3L: ${c.toFixed(2)}`);
  }
});

test('resolveTheme', () => {
  assert.equal(resolveTheme('dark'), 'layan-dark');
  assert.equal(resolveTheme('light'), 'layan');
  assert.equal(resolveTheme(null), 'layan');
  assert.equal(resolveTheme('nope'), 'layan');
  assert.equal(resolveTheme('nord'), 'nord');
});

test('themeCss blocks', () => {
  const css = themeCss();
  assert.match(css, /:root\{[^}]*--bg:#272a31/);
  assert.match(css, /:root\[data-theme="layan-dark"\]\{[^}]*--bg:#010103/);
  for (const id of IDS.slice(1)) assert.ok(css.includes(`:root[data-theme="${id}"]{`), id);
  assert.match(css, /:root\{[^}]*--line:rgba\(96,97,248,0\.36\)/);
  assert.match(css, /:root\{[^}]*--glass:rgba\(42,44,52,0\.5\)/);
});
