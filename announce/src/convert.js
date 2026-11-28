// Discord message JSON -> site posts. Pure, so tests run it without Discord.

// Plain messages only: replies to people (type 19) and system notices stay on Discord.
const POST_TYPE = 0;
const IMAGE_URL = /https?:\/\/\S+\.(?:png|jpe?g|gif|webp|avif)(?:\?\S*)?/gi;

const utc = (unix) => `${new Date(unix * 1000).toISOString().slice(0, 16).replace('T', ' ')} UTC`;

export function cleanText(content, mentions, { channels, roles }) {
  const users = new Map(mentions.map((u) => [u.id, u.global_name || u.username]));
  const at = (name) => (name ? `@${name}` : '');
  return content
    .replace(/@(everyone|here)/g, '')
    .replace(/<a?:\w+:\d+>/g, '')
    .replace(/<@!?(\d+)>/g, (_, id) => at(users.get(id)))
    .replace(/<@&(\d+)>/g, (_, id) => at(roles.get(id)))
    .replace(/<#(\d+)>/g, (_, id) => (channels.has(id) ? `#${channels.get(id)}` : ''))
    .replace(/<t:(\d+)(?::\w)?>/g, (_, s) => utc(Number(s)))
    .replace(/<(https?:\/\/[^\s>]+)>/g, '$1')
    .split('\n')
    .map((l) => l.replace(/[ \t]{2,}/g, ' ').trim())
    .join('\n')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
}

export function toPosts(messages, ctx) {
  const posts = [];
  for (const m of messages) {
    if (m.type !== POST_TYPE || !ctx.authors.has(m.author?.id)) continue;
    const linked = (m.content ?? '').match(IMAGE_URL) ?? [];
    const text = cleanText((m.content ?? '').replace(IMAGE_URL, ''), m.mentions ?? [], ctx);
    const attached = m.attachments ?? [];
    const isImage = (a) => a.content_type?.startsWith('image/');

    const images = [...attached.filter(isImage).map((a) => a.url), ...linked];
    const files = attached.filter((a) => !isImage(a)).map((a) => ({ name: a.filename, url: a.url }));
    if (!text && !images.length && !files.length) continue;
    posts.push({ id: m.id, ts: m.timestamp, edited: m.edited_timestamp, text, images, ...(files.length && { files }) });
  }
  return posts;
}
