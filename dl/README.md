# xero-dl

Download service for `dl.xerolinux.xyz`. It replaces the VPS portal at `iso.xerolinux.xyz` once the ISO is free.

It follows the same `"free"` flag in `public/settings.json` that the site reads:
- `"free": false`: downloads answer 403. The site shows the paid flow, which still uses the VPS.
- `"free": true`: downloads open. The site's Download page reads `/stats` and its buttons link to `/dl/<edition>`.

Staff can download in either state.

## Endpoints

| Route | What it does |
| --- | --- |
| `GET /stats` | Per-edition file, version, size, date, checksums, release and total counts. |
| `GET /dl/<edition>?dl=<file>` | Checks the file against the catalog, takes 1 of the visitor's 5 lifetime links, counts the download, then redirects (302) to an R2 link that lasts 45 minutes. |
| `GET` / `POST /staff` | Enter the staff key once to set a cookie for a year. Staff downloads skip the free switch, the limit and the counter. Changing `STAFF_KEY` invalidates every cookie. |
| `POST /admin/register` | Same JSON input and validation as `register-iso.py` (`query` / `register`). Needs `Authorization: Bearer <ADMIN_TOKEN>`. |
| `POST /admin/import` | One-time import of the VPS data, `{ "catalog": <catalog.json>, "counts": { "std": <downloads.json>, "nvidia": <downloads.json> } }`. It refuses once any data exists. |

Visitors are keyed by HMAC-SHA256 of their IP: IPv4 as is, IPv6 by its /64. Raw IPs are never stored.

## Local

```sh
npm install
npm test
cp .dev.vars.example .dev.vars   # fill in throwaway values
npx wrangler d1 migrations apply xero-dl --local
npm run dev
```

## Go-live (in this order)

1. **Create the database:** `npx wrangler d1 create xero-dl`, then put the printed id in `wrangler.toml`.
2. **Create the tables:** `npx wrangler d1 migrations apply xero-dl --remote`
3. **Set the R2 vars:** in `wrangler.toml`, set `R2_ENDPOINT` (`https://<account>.r2.cloudflarestorage.com`) and `R2_BUCKET`.
4. **Add the secrets:** use a read-only R2 token scoped to the bucket.
   ```sh
   npx wrangler secret put R2_ACCESS_KEY_ID
   npx wrangler secret put R2_SECRET_ACCESS_KEY
   npx wrangler secret put SALT
   npx wrangler secret put STAFF_KEY
   npx wrangler secret put ADMIN_TOKEN
   ```
5. **Deploy:** `npx wrangler deploy` creates the `dl.xerolinux.xyz` custom domain. While `"free"` is still `false`, nothing is public yet.
6. **Import the VPS data:** copy `r2lib/catalog.json` and `KDEPlasma/{std,nvidia}/downloads.json` from the VPS, then run:
   ```sh
   jq -n --slurpfile c catalog.json --slurpfile s std.json --slurpfile n nvidia.json \
     '{catalog: $c[0], counts: {std: $s[0], nvidia: $n[0]}}' > import.json
   curl -X POST https://dl.xerolinux.xyz/admin/import \
     -H "Authorization: Bearer $ADMIN_TOKEN" --data-binary @import.json
   ```
7. **Switch the uploader:** point XeroISO Uploader at `POST /admin/register` instead of `register-iso.py`.
8. **Test as staff:** log in at `/staff` and download each edition.
9. **Go free:** set `"free": true` in `public/settings.json` and push. The site and this Worker switch together.
10. **Retire the VPS:** once downloads and counts look right, it's no longer needed.
