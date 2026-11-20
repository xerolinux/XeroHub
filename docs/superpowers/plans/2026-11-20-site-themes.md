# Site Themes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ten dark colour themes that reskin page, background, terminal and canvas toys together, switchable with `theme <id>` and a footer picker.

**Architecture:** `src/data/themes.ts` is the single source: base colours per theme plus pure helpers (contrast, derived tokens, CSS generation). Shell emits the generated CSS inline in `<head>` and sets `data-theme` before paint. All hard-coded themed colours in CSS and `terminal.ts` move to CSS variables (CSS) or `activePalette()` (canvas JS).

**Tech Stack:** Astro 7, Tailwind 4, TypeScript, `node --test` (Node 26 strips TS types natively, no new deps), Playwright (Python, chromium) for browser checks.

**Spec:** `docs/superpowers/specs/2026-11-20-site-themes-design.md`

## Global Constraints

- Theme ids, in this order: `layan`, `layan-dark`, `catppuccin-mocha`, `dracula`, `nord`, `gruvbox`, `tokyo-night`, `rose-pine`, `everforest`, `kanagawa`. All dark. `layan` is default and has no `data-theme` attribute.
- `layan` must reproduce today's default (`--bg:#272a31` etc., `global.css:3`) and `layan-dark` today's dark (`global.css:4`) pixel-for-pixel.
- Every text colour passes WCAG AA 4.5:1 against its theme `bg` and against the glass it sits on (`text`, `text2`, `dim`, `accentL`, `green`, `red`, `yellow`, `cyan`, `c1L`, `c2L`, `c3L`).
- Fixed brand colours, never themed: `#4285f4` Intel, `#ee3939` AMD, `#2bd05a` nVidia, `#ff5e5b` Ko-fi heart, `#ffffff` QR background.
- Storage key `theme`. Stored `dark` reads as `layan-dark`, `light` as `layan`, unknown as `layan`. No `theme dark|light` aliases in the terminal.
- No new dependencies. No em dashes anywhere. Comments only for non-obvious why. Remove dead code (base `.root{--o1...}` at `global.css:94` is always overridden by `.c-xero`).
- Never commit or push. Commit steps below are replaced by: stop, report, and wait for the user.
- Do not touch CLAUDE.md, Ko-fi bar behaviour, sale system, matrix/scroll effects (colours only).

## Review Focus

- Reload and ClientRouter navigation under a non-default theme: no flash of Layan before paint. Test in Task 2.
- A canvas toy (cmatrix, pipes, btop) running while the theme changes: recolours or restarts with the new palette, no stale Layan colours. Test in Task 4.
- localStorage blocked or holding garbage: page renders `layan`, no thrown errors. Test in Task 2.
- Picker on a phone-width stacked layout: fits on screen, no horizontal scroll, closes on Escape and outside tap. Test in Task 5.
- Leftover hard-coded Layan hexes on any page under a non-Layan theme. Test in Task 3.

---

### Task 1: Theme data and helpers

**Files:**
- Create: `src/data/themes.ts`
- Create: `tests/themes.test.ts`
- Modify: `package.json` (add `"test": "node --test tests/"`)

**Interfaces:**
- Produces:
  - `type ThemeId` (union of the ten ids)
  - `interface Palette { name: string; bg; surface; text; text2; dim; accent; accentL; c1; c2; c3; c1L; c2L; c3L; green; red; yellow; cyan: string; bgdim: number; orb: number }` (all colours `#rrggbb`)
  - `const THEMES: Record<ThemeId, Palette>`, `const THEME_IDS: ThemeId[]`, `const DEFAULT_THEME = 'layan'`
  - `resolveTheme(stored: string | null): ThemeId`
  - `contrast(a: string, b: string): number`
  - `themeCss(): string` emitting `:root{...}` for `layan` and `:root[data-theme="<id>"]{...}` for the rest, with base vars `--bg --text --text2 --dim --accent --accentL --c1 --c2 --c3 --c1L --c2L --c3L --green --red --yellow --cyan --bgdim --orb` plus derived `--line --soft --glass --glassSolid --termbg --edge --halo` (rgba from base colours with today's alphas from `global.css:3-4,95`).

- [ ] **Step 1: Write failing tests** in `tests/themes.test.ts` importing `../src/data/themes.ts`:
  - `THEME_IDS` equals the ten ids in order.
  - Every palette has every key and every colour matches `/^#[0-9a-f]{6}$/`.
  - `contrast('#ffffff', '#000000')` is 21 (±0.01); `contrast('#777777','#ffffff')` ≈ 4.48.
  - For every theme, each text key in Global Constraints has `contrast(key, bg) >= 4.5`.
  - `resolveTheme('dark') === 'layan-dark'`, `resolveTheme('light') === 'layan'`, `resolveTheme(null) === 'layan'`, `resolveTheme('nope') === 'layan'`, `resolveTheme('nord') === 'nord'`.
  - `themeCss()` contains `--bg:#272a31` inside the plain `:root{` block and `--bg:#010103` inside `:root[data-theme="layan-dark"]{`; contains one block per id.
- [ ] **Step 2:** `npm test` fails (module missing).
- [ ] **Step 3:** Implement `src/data/themes.ts`. Layan values come from current CSS (`c1 #4a6cf7, c2 #7b5cd6, c3 #c2286f, c1L #7e9bff, c2L #a98bf0, c3L #e07aa8, green #5fd38a, red #ee7a9a, yellow #f5c451, cyan #5ed3e6, dim #9a9cb8`). Other themes from official dark palettes (Catppuccin Mocha, Dracula, Nord, Gruvbox dark, Tokyo Night, Rosé Pine main, Everforest dark medium, Kanagawa wave); swap to a lighter official swatch or nudge lightness where AA fails.
- [ ] **Step 4:** `npm test` passes.
- [ ] **Step 5:** Stop and report.

### Task 2: Apply theme before paint and across navigation

**Files:**
- Modify: `src/layouts/Shell.astro:29,41-43` (theme-color meta, inline head script, inline `<style set:html={themeCss()}>`)
- Modify: `src/styles/global.css:3-4` (delete the two token lines, now generated)
- Create: `src/scripts/theme.ts`
- Modify: `src/scripts/site.ts:219-232` (remove dark toggle; after-swap calls `applyTheme(currentTheme())`)
- Test: `scratchpad/themes_apply.py` (Playwright)

**Interfaces:**
- Consumes: `THEMES`, `THEME_IDS`, `resolveTheme`, `themeCss` from Task 1.
- Produces in `src/scripts/theme.ts`:
  - `currentTheme(): ThemeId` (reads storage via `resolveTheme`, try/catch)
  - `setTheme(id: ThemeId): void` (sets/removes `data-theme`, stores id, updates `meta[name=theme-color]` to `accent`, dispatches `new CustomEvent('xero-theme', { detail: id })` on `document`)
  - `activePalette(): Palette`

- [ ] **Step 1:** Write Playwright test: for `nord` stored in localStorage, `data-theme` is `nord` at `DOMContentLoaded` (via `add_init_script` observer recording the attribute at first `requestAnimationFrame`); body background equals Nord `bg`; after clicking About link, still `nord`; with `localStorage` set to `garbage`, attribute absent and no page errors; with storage access throwing (init script overriding `localStorage` getter), no page errors.
- [ ] **Step 2:** Run it, expect failure.
- [ ] **Step 3:** Implement. Inline head script must resolve the stored value with the same mapping as `resolveTheme` (pass `THEME_IDS` via `define:vars`).
- [ ] **Step 4:** Test passes; screenshot `layan` and `layan-dark` home and compare to pre-change screenshots (pixel diff 0 outside animated canvas/orbs region).
- [ ] **Step 5:** Stop and report.

### Task 3: Move hard-coded CSS and markup colours onto variables

**Files:**
- Modify: `src/styles/global.css` (lines 47, 50, 62, 72, 94-96, 101, 103-121, 131-132, 137, 139, 148, 154-159, 166-210)
- Modify: `src/components/DownloadFree.astro`, `src/components/DownloadPaid.astro`, `src/pages/access.astro`, `src/pages/support.astro`, `src/pages/about.astro`, `src/pages/tools.astro`, `src/components/Changelog.astro`, `src/layouts/Shell.astro`
- Test: `scratchpad/themes_leak.py`

**Interfaces:**
- Consumes: CSS vars from Task 1.

- [ ] **Step 1:** Write Playwright leak test: with theme `dracula`, visit `/`, `/download/`, `/tools/`, `/support/`, `/access/`, `/about/`, `/gear/`; walk all elements' computed `color`, `background-color`, `background-image`, `border-color`, `box-shadow`, `fill`, `stroke`, plus pseudo `::before/::after`; fail on any of the Layan-only colours `#4a6cf7 #7b5cd6 #c2286f #7e9bff #a98bf0 #e07aa8 #5657f5 #d77aa5 #9a9cb8 #c9cbdc #8e5cf0` (and their rgb() forms). Also assert computed text contrast ≥ 4.5 for every visible text node against the nearest opaque ancestor background, blended over theme `bg`.
- [ ] **Step 2:** Run, expect many failures.
- [ ] **Step 3:** Replace colours with vars. Translucent uses: `rgb(from var(--c1) r g b / .18)` relative colour syntax. Scanlines stay white; shadows stay black. `.bgdim` uses `var(--bgdim)`, orb opacities multiply `var(--orb)`. Delete `global.css:94` and `:root[data-theme="dark"]` overrides at 107-108 (now `--bgdim`/`--orb`). Brand colours untouched.
- [ ] **Step 4:** Leak and contrast test passes for all ten themes; `npm run check` 0 errors.
- [ ] **Step 5:** Stop and report.

### Task 4: Terminal and canvas toys follow the theme

**Files:**
- Modify: `src/scripts/terminal.ts` (`THEME` at 271, cmatrix 292-298, pipes 331, `BT` 396, `heat` 428, meters/graphs 601-701, neofetch Theme row 246, `theme` case 966-973, help row 53, Tab completion 1083-1093)
- Test: `scratchpad/themes_term.py`

**Interfaces:**
- Consumes: `activePalette`, `setTheme`, `currentTheme` (Task 2), `THEMES`, `THEME_IDS` (Task 1).

- [ ] **Step 1:** Write Playwright test, theme `nord`:
  - `theme` prints one line per id with swatches, marks current.
  - `theme gruvbox` switches (`data-theme="gruvbox"`), prints confirmation.
  - `theme dark` prints usage error, theme unchanged.
  - `theme random` switches to a different id.
  - Typing `theme ro` + Tab completes `theme rose-pine`.
  - `neofetch` Theme row shows `Nord`.
  - Run `cmatrix`, call `setTheme('dracula')` mid-run, sample canvas pixels after 500ms: no Layan hues present, Dracula hues present. Same for `btop` and `pipes`.
- [ ] **Step 2:** Run, expect failure.
- [ ] **Step 3:** Implement. Replace `THEME` and `BT` constants with functions of `activePalette()`; savers listen for `xero-theme` and rebuild colour atlases. `heat`/`mix` take palette colours. Help row becomes `['theme [name|random]', 'List or switch themes']`.
- [ ] **Step 4:** Test passes.
- [ ] **Step 5:** Stop and report.

### Task 5: Footer theme picker

**Files:**
- Modify: `src/layouts/Shell.astro:115` (Theme button gets `aria-haspopup="listbox"`, `aria-expanded`; add picker element inside footer)
- Create: `src/scripts/picker.ts` (imported from `site.ts`)
- Modify: `src/styles/global.css` (picker styles, token-based, add stacked-layout rule)
- Test: `scratchpad/themes_picker.py`

**Interfaces:**
- Consumes: `THEMES`, `THEME_IDS`, `setTheme`, `currentTheme`.

- [ ] **Step 1:** Write Playwright test at 1920×1080 and 390×844:
  - Click Theme: list opens with 10 options, each with name and a 4-swatch row, current has `aria-selected="true"`.
  - ArrowDown + Enter picks next theme; Escape closes and returns focus to button; outside click closes.
  - Picker box fully inside viewport; no horizontal page scroll.
  - Switching from the terminal updates the picker's selected item.
- [ ] **Step 2:** Run, expect failure.
- [ ] **Step 3:** Implement as a popover opening upward from the footer button, glass styling from tokens. Listens to `xero-theme` to sync.
- [ ] **Step 4:** Test passes; `npm run check` and `npm run build` clean.
- [ ] **Step 5:** Stop and report with screenshots of all ten themes on `/` and `/download/` for the user to review in the running dev server.
