// Ko-Fi Goal Overlay → JSON proxy.
// Fetches the Ko-Fi goal overlay HTML, parses the embedded Vue data block,
// returns CORS-friendly JSON. Cached at the CF edge for CACHE_TTL seconds.

const KOFI_URL =
  'https://ko-fi.com/streamalerts/goaloverlay/sa_15ba9acd-650c-42b5-a225-c7a85489118a';
const CACHE_TTL = 60;

export default {
  async fetch(request, _env, ctx) {
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        headers: {
          'access-control-allow-origin': '*',
          'access-control-allow-methods': 'GET, OPTIONS',
          'access-control-max-age': '86400',
        },
      });
    }

    const cache = caches.default;
    const cacheKey = new Request(new URL(request.url).toString(), { method: 'GET' });
    let cached = await cache.match(cacheKey);
    if (cached) return cached;

    try {
      const res = await fetch(KOFI_URL, {
        headers: { 'user-agent': 'Mozilla/5.0 (kofi-goal-proxy)' },
        cf: { cacheTtl: CACHE_TTL, cacheEverything: true },
      });
      if (!res.ok) throw new Error(`upstream ${res.status}`);
      const html = await res.text();

      const pct   = /percentage:\s*'([^']*)'/.exec(html)?.[1];
      const amt   = /amount:\s*'([^']*)'/.exec(html)?.[1];
      const cur   = /currency:\s*'([^']*)'/.exec(html)?.[1];
      const title = /title:\s*'([^']*)'/.exec(html)?.[1];

      const percentage = pct != null && pct !== '' ? Number(pct) : null;
      const targetEUR  = amt != null && amt !== '' ? Number(amt) : null;
      const currentEUR =
        percentage != null && targetEUR != null
          ? Math.round((percentage / 100) * targetEUR)
          : null;

      const body = JSON.stringify({
        percentage,
        targetEUR,
        currentEUR,
        currency: cur || '€',
        title: title || null,
        fetchedAt: Date.now(),
      });

      const response = new Response(body, {
        headers: {
          'content-type': 'application/json; charset=utf-8',
          'access-control-allow-origin': '*',
          'cache-control': `public, max-age=${CACHE_TTL}`,
        },
      });
      ctx.waitUntil(cache.put(cacheKey, response.clone()));
      return response;
    } catch (err) {
      return new Response(
        JSON.stringify({ error: String(err && err.message ? err.message : err) }),
        {
          status: 502,
          headers: {
            'content-type': 'application/json; charset=utf-8',
            'access-control-allow-origin': '*',
          },
        }
      );
    }
  },
};
