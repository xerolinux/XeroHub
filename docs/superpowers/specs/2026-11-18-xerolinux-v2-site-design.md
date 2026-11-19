# XeroLinux v2 site: design

Date: 2026-11-18. Status: draft for approval.

## Intent

Rebuild xerolinux.xyz as the approved "board 25" design. It stays local until March 2027. The design is a frosted-glass one-screen site. A left hero card stays fixed, and a right glass "window" swaps between pages. It replaces the current site in March 2027, which is also when ISOs become free and the VPS that serves downloads shuts down. From then on the site must be self-contained: the live download counts and the download-attempt limits keep working with no VPS.

The download count is the single most important feature. The user called it "VERY VERY VERY VERY VERY important".

## Goals

- Pixel-faithful build of board 25: https://claude.ai/artifact/Tm9dxDACmLkgYA5f9eo5Eh (file `S25-OneScreen.dc.html`).
- Static site on GitHub Pages, as today.
- A download service on Cloudflare (Worker + R2 + D1) that hands out short-lived R2 links, counts every download, and enforces attempt limits.
- The site stays local until March 2027, with no Bridge mode. The Worker is built as standalone only. In March the VPS counts and catalog are imported once, then everything goes live together.

## Non-goals

- No posts, updates, comments, RSS, Firebase or Ko-fi progress bar.
- No VPN blocking and no bot challenge (Turnstile). The download behavior copies the VPS exactly.
- No buyer codes or paid ISO flow after March.
- No changes to the live VPS or live site without the user's explicit OK, each time.

## Anti-goals (a failure even if it "works")

- Any download behavior that differs from today's VPS portal, apart from the switch from buyer codes to visitors.
- The page scrolls on 1080p or larger. Content reflows or changes shape on screens above 1080p.
- Secrets (R2 keys, the salt, the staff key, the admin token) end up in the static site or the repo.
- Downloads break when the VPS dies.

## Constraints

- Astro 7.4.13 + Tailwind 4.3.5 (already installed). Output stays `static`.
- Hosting: GitHub Pages for the site. Cloudflare already holds the domain, the R2 bucket and the existing `kofi-goal-proxy` Worker.
- The user's global rules apply: no commits or pushes, no em dashes, Wayland-first, no insecure workarounds, no dead code, minimal comments.
- This folder is local only and is never committed.

## Approaches considered

| | Approach | Trade-off | Picked |
|---|---|---|---|
| A | Astro on Cloudflare Workers (pages plus API routes in one deploy) | One deploy, but it moves the site off GitHub Pages | No: the user keeps GitHub Pages |
| B | Static site on GitHub Pages plus a separate Cloudflare Worker for downloads | Two deploy targets; the site stays where it is | **Yes** |
| C | Another server | Swaps one VPS for another | No |

## Part 1: the static site

### Pages and routing
Each window view is a real Astro page sharing one layout, so links are shareable and indexable:

| Route | Window content |
|---|---|
| `/` | Screenshot crossfade (Plasma, Calamares, Toolkit) with clickable thumbnails |
| `/about/` | Profile card plus story plus social icon grid |
| `/gear/` | Device switcher (5 devices) with photo, spec chips and description |
| `/tools/` | Dock layout. xPackageManager is first and the default. Each tool shows its screenshot (or video), category, description, 3 points, 1 command and its links |
| `/support/` | Ko-fi button, Discord note, wallet selector (BTC, USDT TRC-20, ETH) with QR codes and copy |
| `/download/` | Two edition cards (Intel/AMD, nVidia): spinning disc, downloads this release (big), all-time, file name, chips, Download, Verify checksums popup. Header shows the site-wide all-time total and this release's total |

The nav, the left hero card and the footer are shared. The nav uses real links, with the current page marked by `aria-current`. Nav icons are shown; on phones the nav shows icons only.

All copy and data come from board 25 as it stands: the text, links, wallet addresses, gear specs, the tool list and the commands. Board 25 is the source of truth. A durable copy is at `docs/design/board25.dc.html`. The media the site uses is in `public/media/`.

### Layout and scaling
- The content area fills the viewport with small margins (95.6% × 96.4%).
- When the viewport is wider than 1920px and taller than 600px, the stage is laid out at a fixed 1920×950 and scaled uniformly by `min(w/1920, h/950)`, then centered. A small script recalculates on resize.
- Sizes use container query units relative to the stage.
- From 961px to 1920px wide (for example 1366×768), the content fills the viewport fluidly and does not scale. This is the 1080p behavior the user approved.
- Below 960px wide or 600px tall, the layout stacks into one scrolling column.
- The blurred, crossfading background covers the full viewport.

### Themes
- Layan is the default. Layan Dark has the exact tokens from board 25.
- A toggle in the footer switches theme. The choice is stored in `localStorage`, with a guarded try/catch.
- Glass opacity 0.55, blur 16px.

### Interactivity (vanilla JS, no framework)
- Home: crossfade every 6s, paused when `prefers-reduced-motion` is set, with clickable thumbnails.
- Gear and Tools: selection switchers, using buttons with `aria-pressed`.
- Support: wallet switch and copy to clipboard.
- Download: the checksum popup (focus kept inside it, closes on Esc) and copy.
- Counts on `/download/`: fetched from `GET {DL_API}/stats`. If the fetch fails, the numbers baked in at build time are shown. Download buttons are plain links to `{DL_API}/dl/<edition>?dl=<file>`, as on the VPS.

### Assets
- All assets are local in `public/` or `src/assets/` (originals copied from the scratchpad, the XeroHub repo and the XeroWiki repo).
- QR codes are generated at build time from the wallet addresses, with no third-party QR service.
- The wallpaper demo is an MP4. The xPackageManager demo is an animated WebP.
- `public/script/` (install scripts) stays as it is.

## Part 2: the download service (Cloudflare Worker)

It must behave **exactly like today's VPS portal** (`r2lib/portal.php` plus `KDEPlasma/<edition>/index.php`, read on 2026-11-18). The only changes are the ones forced by free ISOs: there are no buyer codes, so "user" means the visitor, and there is no login page.

### Endpoints (on `dl.xerolinux.xyz`)
- `GET /stats` returns this public JSON for the Download page (cached about 60s):
  ```json
  {"editions": {"std": {"file": "...", "version": "2026.09", "size": 5661872128, "date": 1788378373, "md5": "...", "sha1": "...", "sha256": "...", "release": 171, "total": 1044}, "nvidia": {...}}, "allTime": 1996, "releaseTotal": 327}
  ```
- `GET /dl/:edition?dl=<file name>` is the Download button. Its steps, in the same order as the VPS:
  1. **Whitelist:** the file name must be in that edition's catalog. Otherwise it returns 404 `File not found.`
  2. **R2 setup:** if R2 isn't configured, it returns 503 `Downloads are temporarily unavailable. Please try again later.`
  3. **Take a link:** each user gets 5 links for life, shared across both editions. A user who has none left gets 403 `You have reached your download limit.` If the link store can't be read, nothing is handed out (fail closed), as on the VPS.
  4. **Count:** the file's counter goes up by 1. Staff are not counted.
  5. **Redirect:** 302 to a presigned R2 GET URL valid for **45 minutes**, with `Content-Disposition: attachment; filename="<name>"`. R2 serves the file.

### Users and staff
- **User:** VPS code `X` becomes visitor key `HMAC-SHA256(salt, IP)`. IPv4 uses the full address and IPv6 the /64. Raw IPs are never stored.
- **Staff:** the VPS has staff codes (no limit, not counted), used to test that new ISOs download correctly. The equivalent is a staff key, stored as a Worker secret.
  - `GET /staff` shows a small form. Submitting the right key (`POST /staff`) sets a signed cookie: HMAC of a fixed value with the salt, `HttpOnly; Secure; SameSite=Lax`, valid for one year. The key travels in the form body, never in the URL, so it can't end up in browser history or logs.
  - Downloads from a browser carrying a valid cookie skip the limit and the counter, exactly like a staff code.
  - Changing the staff key secret invalidates every existing cookie.
  - Visitors never see any of this.

### Data (D1, atomic SQL updates, so concurrent clicks never lose a count)
- `counts(edition TEXT, file TEXT, n INTEGER, PRIMARY KEY(edition, file))`, the same data as each edition's `downloads.json`.
  - An edition's `total` is the sum of its `.iso` rows.
  - `release` is the count for the current catalog file.
  - `allTime` and `releaseTotal` are the sums over both editions.
- `links(user TEXT PRIMARY KEY, n INTEGER)`, the same as `code-links.json`.
- **Catalog:** the same shape as `r2lib/catalog.json` (`{"std": [{name, key, size, modified, md5, sha1, sha256}], "nvidia": [...]}`), stored in Workers KV.
- **March import:** the VPS's `downloads.json` (both editions) and `catalog.json` are imported once, as is. Past downloads keep their counts.

### Catalog updates
The uploader app currently calls `register-iso.py` over SSH. In March it calls `POST /admin/register` instead, with the same JSON input and the same validation rules. The call is protected by a bearer token stored as a Worker secret. Like `register-iso.py`, it replaces the edition's single catalog entry and never deletes anything in R2.

### Download page notes kept from the VPS
- "Downloads limited to 5 attempts per user".
- The Verify checksums popup (MD5, SHA1, SHA256).
- Total downloads shown per edition.

### Secrets (Worker secrets only, never in the repo)
- The R2 S3 API key and secret (read-only, scoped to the bucket), as `r2.env` holds today.
- The IP hash salt.
- The staff key.
- The admin token.

### Rollout
- **Until March:** everything is built and tested locally, using Vitest and `wrangler dev` with a local D1 and a mocked R2. Nothing is deployed. The site shows the counts baked in at build time.
- **March:** import the VPS data, deploy the Worker, and point the site's Download buttons and stats at it.

## Things that need the user (live systems; nothing happens without an explicit OK)
1. **VPS:** in March, read-only copies of `downloads.json` and `catalog.json` for the import (over SSH; nothing on the VPS changes).
2. **Cloudflare:** create the D1 database, the Worker, the `dl.xerolinux.xyz` route, and a read-only R2 S3 token (like the one in `r2.env`).
3. **Uploader:** in March, `register-iso.py` (or its replacement) must also update the Worker's catalog.
4. **Go-live:** in March, swap the GitHub Pages content and flip the Worker to standalone.

## Left to the builder
Exact file and component structure, script bundling, how D1 migrations are written, and the test harness: Vitest with `@cloudflare/vitest-pool-workers` for the Worker, plus Playwright screenshots of the site at 1366×768, 1920×950, 2560×1305, 3440×1310 and 390×844.
