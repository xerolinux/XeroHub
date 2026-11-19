# XeroLinux

Site for [xerolinux.xyz](https://xerolinux.xyz). Astro + Tailwind, static output, deployed to GitHub Pages on push to `main` (`.github/workflows/deploy.yml`, which also purges the Cloudflare cache when `CF_API_TOKEN` and `CF_ZONE_ID` secrets are set).

```sh
npm install
npm run dev      # http://127.0.0.1:4321
npm run check    # type check
npm run build
```

## Settings

| What | Where | Rebuild? |
|---|---|---|
| Paid or free ISO | `public/settings.json` → `{ "free": true \| false }` | No, read in the browser |
| Price, Ko-fi links, sale window | `src/config.ts` | Yes |
| ISO editions, sizes, checksums | `src/data/editions.ts` | Yes |
| Changelog | `src/data/changelog.ts` | Yes |

Keep `"free": false` until the download Worker at `dl.xerolinux.xyz` is live; the free download buttons go through it.

## Moving parts

- **Buyer codes (paid period):** `/access/` talks to `docs/vps/api.php`, deployed on the VPS at `iso.xerolinux.xyz/KDEPlasma/api.php`.
- **Ko-fi goal bar:** `worker/` is the `kofi-goal-proxy` Cloudflare Worker (`cd worker && npm run deploy`). The site falls back to `KOFI_GOAL` in `src/config.ts` if it is unreachable.
- **Visit counter:** footer total of the `views/*` docs in the `xerolinux-6e564` Firestore project, counted once per visitor per page, only on xerolinux.xyz. Rules: `firestore.rules`.
- **Install scripts:** `public/script/` is served as-is; live install one-liners point at these URLs, so keep the paths.
- **Terminal easter egg:** `src/scripts/terminal.ts` (desktop only, `` ` `` or the `>_` button).

Design source: `docs/design/board25.dc.html`. Free-period Worker spec: `docs/superpowers/specs/2026-11-18-xerolinux-v2-site-design.md`.
