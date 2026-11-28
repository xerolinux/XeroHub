// Live mirror of one Discord channel as JSON for the Announcements page.
// Nothing is stored: Discord stays the source, so edits and deletes carry over,
// and every response hands out freshly signed (expiring) attachment URLs.

import { toPosts } from './convert.js';

const API = 'https://discord.com/api/v10';

const json = (body, status, ttl) =>
  new Response(JSON.stringify(body), {
    status,
    headers: {
      'content-type': 'application/json; charset=utf-8',
      'access-control-allow-origin': '*',
      ...(ttl && { 'cache-control': `public, max-age=${ttl}` }),
    },
  });

async function discord(env, path) {
  const res = await fetch(`${API}${path}`, {
    headers: {
      authorization: `Bot ${env.DISCORD_TOKEN}`,
      'user-agent': 'DiscordBot (https://xerolinux.xyz, 1.0)',
    },
  });
  if (!res.ok) throw new Error(`discord ${path.split('?')[0]} ${res.status}`);
  return res.json();
}

export default {
  async fetch(request, env, ctx) {
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        headers: {
          'access-control-allow-origin': '*',
          'access-control-allow-methods': 'GET, OPTIONS',
          'access-control-max-age': '86400',
        },
      });
    }
    if (request.method !== 'GET') return json({ error: 'method not allowed' }, 405);

    const ttl = Number(env.CACHE_TTL) || 60;
    const cache = caches.default;
    const key = new Request(new URL('/', request.url).toString());
    const cached = await cache.match(key);
    if (cached) return cached;

    try {
      const [messages, guild, channels] = await Promise.all([
        discord(env, `/channels/${env.CHANNEL_ID}/messages?limit=50`),
        discord(env, `/guilds/${env.GUILD_ID}`),
        discord(env, `/guilds/${env.GUILD_ID}/channels`),
      ]);
      const authors = new Set(env.AUTHOR_IDS ? env.AUTHOR_IDS.split(',').map((s) => s.trim()) : [guild.owner_id]);
      const posts = toPosts(messages, {
        authors,
        roles: new Map(guild.roles.map((r) => [r.id, r.name])),
        channels: new Map(channels.map((c) => [c.id, c.name])),
      });
      const channel = channels.find((c) => c.id === env.CHANNEL_ID)?.name ?? '';
      const response = json({ channel, posts, fetchedAt: Date.now() }, 200, ttl);
      ctx.waitUntil(cache.put(key, response.clone()));
      return response;
    } catch (err) {
      return json({ error: String(err?.message ?? err) }, 502);
    }
  },
};
