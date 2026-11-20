# Festive decorations

## Intent
Subtle seasonal decorations that appear by themselves around each festivity, so the site feels alive without overwhelming visitors.

## Goals
- Auto by date on the live site; a visitor toggle (footer icon + `festive on|off`) turns them off, remembered per festivity.
- Owner can force any festivity with the hidden terminal command `festive <id>` (per browser, `festive auto` to return to the calendar); it is not listed in help or command completion.
- Very subtle: max 30 particles, small, low opacity; static for reduced-motion users; paused when the tab is hidden.
- Works with every theme.

## Non-goals / anti-goals
- No new dependencies. Nothing that blocks clicks, hurts readability or tanks performance.

## Approaches
1. One canvas, per-festivity presets in a data file (picked).
2. CSS-animated DOM particles: heavy at volume, awkward for crossing bats or bursts.
3. Particle library: new dependency for under 300 lines.

## Design
- `src/data/festive.ts`: festivity table (id, name, window, preset). Easter by computus, Thanksgiving = 4th Thursday of November (Thu to Sun), Lunar New Year and Diwali from a 2026-2035 date table (+/-2 days). `festiveFor(date)` returns the active id; overlap resolves to the shortest window.
- Falling + static: Christmas (snow), Valentine's (hearts), St Patrick's (clovers). All others static with gentle motion. Every festivity gets an animated scene in the empty header centre (between logo and nav), an accessory on the hero Arch logo where it fits (Santa hat, party hat, leprechaun hat, bunny ears, Uncle Sam hat, witch hat, pilgrim hat), small items on the footer edge, and extras: Christmas snow caps, icicles, frost and twinkling string lights; Lunar New Year edge lanterns; Halloween cobweb and dangling spider; Diwali marigold toran; corner pieces (streamers, rose, patriotic fan, autumn leaves). Firework shows (New Year, Independence Day) stay clear of the centrepiece. Nothing overlaps a link or button (tested at 1920x1080, 1366x768, 390x844).
- `src/scripts/festive.ts`: one fixed, `pointer-events:none` canvas over the stage (persisted across navigation), opacity capped so text stays readable. Sets `html[data-festive=<id>]` while showing.
- Storage: `festive-off:<id>` in localStorage. Force: `festive-force` in localStorage.

## Rulings (builder's calls)
- Owner feedback: falling particles other than snow look cheap, so all other festivities use decorations instead.
- The snow canvas sits above the page (panels are near-opaque); flakes are small and translucent.
- Lunar New Year and Diwali dates come from a fixed table that needs extending after 2035.
