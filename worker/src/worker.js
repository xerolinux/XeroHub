// Ko-fi supporter count → CORS-friendly JSON. Ko-fi blocks direct scrapes from browsers and CI, but not from Workers.

const PROFILE_URL = 'https://ko-fi.com/xerolinux';
const CACHE_TTL = 600;

const json = (body, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: {
      'content-type': 'application/json; charset=utf-8',
      'access-control-allow-origin': '*',
      ...(status === 200 && { 'cache-control': `public, max-age=${CACHE_TTL}` }),
    },
  });

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
    const cached = await cache.match(cacheKey);
    if (cached) return cached;

    try {
      const res = await fetch(PROFILE_URL, {
        headers: { 'user-agent': 'Mozilla/5.0 (kofi-goal-proxy)' },
        cf: { cacheTtl: CACHE_TTL, cacheEverything: true },
      });
      if (!res.ok) throw new Error(`upstream ${res.status}`);
      const m = /([\d,]+)\s+Supporters?\b/i.exec(await res.text());
      if (!m) throw new Error('supporter count not found');

      const response = json({ supporters: Number(m[1].replace(/,/g, '')), fetchedAt: Date.now() });
      ctx.waitUntil(cache.put(cacheKey, response.clone()));
      return response;
    } catch (err) {
      return json({ error: String(err?.message ?? err) }, 502);
    }
  },
};
