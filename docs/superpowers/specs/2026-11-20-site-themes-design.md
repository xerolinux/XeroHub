# Site themes

## Intent

Let visitors reskin the whole site with a named colour scheme, switched from the terminal with `theme <name>` (Catppuccin, Dracula, Nord and so on), in the spirit of linuxgamerlife.net. The current Layan look stays the default. A theme must make everything work together: page, background, terminal and canvas toys all share one palette, with nothing left in the old purple-blue.

## Goals

- One source of truth for every theme's colours.
- Every themed surface follows the active theme: page tokens, background orbs, grid, scanlines, sweep, heading gradient, Ko-fi bar gradient, card glows, terminal prompt segments, help table group colours, cmatrix, pipes, btop, neofetch colour blocks, code chips, scrollbars, `theme-color` meta.
- No flash of the wrong theme on load or on ClientRouter navigation.
- Adding a theme later is one entry in one file.

## Non-goals

- No per-theme layout, font or structure changes. Themes are colour only (plus colour-driven effect strength such as scanline opacity).
- No server-side state; choice lives in the visitor's browser.
- No light themes. Every theme is a dark scheme (decided by the owner), so all effects keep their dark-page assumptions: white scanlines, black shadows, dark glass, canvases over dark `--termbg`.

## Anti-goals

- Any element still showing Layan colours under another theme.
- Unreadable text in any theme. All text, including labels, kickers, dim and prompt text, must meet WCAG AA (4.5:1) against what it sits on.
- Breaking the Ko-fi bar behaviour, sale system, or matrix/scroll effects listed in CLAUDE.md "Do Not Touch". Only their colours become themeable.

## Constraints

- Brand colours stay fixed in every theme: Intel `#4285f4`, AMD `#ee3939`, nVidia `#2bd05a` (edition labels and discs), Ko-fi heart `#ff5e5b`, QR code white background.
- Astro 7 static build, ClientRouter with persisted background. No new dependencies.
- No em dashes; minimal comments; remove dead code made unreachable (for example the base `.root` orb vars that `.c-xero` always overrides).

## Approaches

1. **Themes data file, CSS generated at build (picked).** `src/data/themes.ts` exports each theme as a fixed set of named colours. Shell emits one `:root[data-theme="<id>"]{...}` block per theme from it; terminal canvases import the same object. Single source, no drift, no flash.
2. Hand-written CSS block per theme, JS reads computed styles for canvases. Rejected: colours split between CSS and JS readback, easy to drift.
3. Separate stylesheet per theme loaded on demand. Rejected: flash on switch, more files, flexibility not needed since layout is shared.

## Design

### Palette shape

Each theme defines the same keys (names indicative, builder may refine):

- `bg`, `surface` (glass base), `text`, `text2`, `dim`
- `accent`, `accentL`, plus three effect colours `c1`, `c2`, `c3` (today blue `#4a6cf7`, purple `#7b5cd6`, pink `#c2286f`) and their light variants `c1L`, `c2L`, `c3L`
- ANSI-style `green`, `red`, `yellow`, `cyan`
- `dim` strength for `.bgdim` (today Layan grey uses `.24`, Layan near-black `.7`).
- Effect tuning where a palette needs it: orb opacity, scan opacity.

Derived values (`--line`, `--soft`, `--glass`, `--glassSolid`, `--termbg`, `--edge`, `--halo`, translucent glows) are computed in the generator from the base colours, so themes only list base colours.

### Themes shipped

`layan` (current default grey look), `layan-dark` (current near-black), `catppuccin-mocha`, `dracula`, `nord`, `gruvbox`, `tokyo-night`, `rose-pine`, `everforest`, `kanagawa`. Values taken from each scheme's official dark palette. Where an official swatch fails WCAG AA for `text` or `text2` on that theme's `bg`, use the nearest lighter official swatch from the same scheme; if none passes, nudge lightness only (builder's call, recorded in a short note beside the entry). `dim` must also pass AA when used as text.

### Applying

- `document.documentElement.dataset.theme = id`; `layan` is the default and needs no attribute.
- Storage key stays `theme`. Layan and Layan Dark are standalone themes like the rest. Old stored values `dark`/`light` silently map to `layan-dark`/`layan`; unknown ids fall back to `layan`.
- The existing inline head script and the `astro:after-swap` handler read the id and set it, so no flash.
- On change, dispatch a `xero-theme` event; running canvas toys (cmatrix, pipes, btop) re-read the palette.
- `<meta name="theme-color">` updated to the theme's accent.

### Terminal

- `theme` alone: list themes with a swatch row each, current one marked.
- `theme <id>`: switch to any listed theme; `theme random`. No `dark|light` aliases.
- Tab completion of theme ids.
- neofetch "Theme" line shows the active theme name.
- Help entry updated.

### Footer Theme picker

The existing Theme button in the footer bar (`Shell.astro:115`) opens a small popover picker listing every theme with a swatch row and its name; the active one is marked; clicking switches and closes. Closes on Escape and outside click, keyboard navigable, works on mobile. Replaces the dark/light toggle in `site.ts:219`. Styled with the theme tokens like the rest of the glass UI.

### Colour migration

Replace hard-coded colours with theme vars in `global.css`, `terminal.ts` (THEME list, BT table, heat/meter/graph colours), `DownloadFree.astro`, `DownloadPaid.astro`, `access.astro`, `Shell.astro`, `support`/`about`/`tools`/`Changelog` where themed. Leave the brand colours above.

## Left to the builder

- Exact key names and the derivation formulas for translucent tokens.
- Exact hex values per theme, within each scheme's official palette.
- Swatch rendering in the `theme` list.
- How canvases subscribe to the change event.

## Verification

- `npm run check` and `npm run build` clean.
- Playwright: for each theme, load home, download, tools and open the terminal running cmatrix/btop; grep computed styles and canvas pixels for leftover Layan hexes; check body text contrast; no page errors; no flash on reload (attribute present before first paint).
