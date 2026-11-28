import test from 'node:test';
import assert from 'node:assert/strict';
import { cleanText, toPosts } from '../announce/src/convert.js';

const ctx = {
  authors: new Set(['1']),
  channels: new Map([['55', 'help']]),
  roles: new Map([['77', 'Testers']]),
};
const msg = (o) => ({ id: '9', type: 0, author: { id: '1' }, content: '', attachments: [], mentions: [], timestamp: '2026-11-28T14:32:00.000+00:00', edited_timestamp: null, ...o });

test('drops @everyone, @here and custom emoji', () => {
  assert.equal(cleanText('@everyone **Out now!** <:xero:123> <a:party:456>', [], ctx), '**Out now!**');
  assert.equal(cleanText('@here\nHi', [], ctx), 'Hi');
});

test('resolves user, role and channel mentions', () => {
  const mentions = [{ id: '42', username: 'jdoe', global_name: 'Jane' }];
  assert.equal(cleanText('Thanks <@42> and <@!42> in <#55> for <@&77>', mentions, ctx), 'Thanks @Jane and @Jane in #help for @Testers');
  assert.equal(cleanText('Hi <@99> in <#66>', [], ctx), 'Hi in');
});

test('unwraps suppressed links and formats timestamps', () => {
  assert.equal(cleanText('See <https://xerolinux.xyz/>', [], ctx), 'See https://xerolinux.xyz/');
  assert.equal(cleanText('At <t:1795852800:F>', [], ctx), 'At 2026-11-28 08:00 UTC');
});

test('collapses blank lines left behind', () => {
  assert.equal(cleanText('@everyone\n\n\n\nLine one\n   \n\nLine two', [], ctx), 'Line one\n\nLine two');
});

test('keeps only real messages from the allowed authors', () => {
  const posts = toPosts([
    msg({ id: '1', content: 'mine' }),
    msg({ id: '2', content: 'someone else', author: { id: '2' } }),
    msg({ id: '3', type: 6, content: 'pinned a message' }),
    msg({ id: '4', content: '@everyone' }),
    msg({ id: '5', type: 19, content: 'a reply' }),
  ], ctx);
  assert.deepEqual(posts.map((p) => p.id), ['1']);
});

test('images keep their order, other files become links', () => {
  const [p] = toPosts([msg({
    content: 'Shots',
    edited_timestamp: '2026-11-28T15:00:00.000+00:00',
    attachments: [
      { filename: 'image.png', url: 'https://cdn.discordapp.com/a/image.png?ex=1', content_type: 'image/png' },
      { filename: 'demo.gif', url: 'https://cdn.discordapp.com/a/demo.gif', content_type: 'image/gif' },
      { filename: 'log.txt', url: 'https://cdn.discordapp.com/a/log.txt', content_type: 'text/plain' },
    ],
  })], ctx);
  assert.deepEqual(p, {
    id: '9', ts: '2026-11-28T14:32:00.000+00:00', edited: '2026-11-28T15:00:00.000+00:00', text: 'Shots',
    images: ['https://cdn.discordapp.com/a/image.png?ex=1', 'https://cdn.discordapp.com/a/demo.gif'],
    files: [{ name: 'log.txt', url: 'https://cdn.discordapp.com/a/log.txt' }],
  });
});

test('image links in the text move to the image list', () => {
  const [p] = toPosts([msg({ content: 'New look https://i.imgur.com/abc.webp and repo https://github.com/xerolinux/xpm' })], ctx);
  assert.equal(p.text, 'New look and repo https://github.com/xerolinux/xpm');
  assert.deepEqual(p.images, ['https://i.imgur.com/abc.webp']);
});

test('an image-only post is kept', () => {
  const posts = toPosts([msg({ attachments: [{ filename: 'image.webp', url: 'https://cdn.discordapp.com/a.webp', content_type: 'image/webp' }] })], ctx);
  assert.equal(posts.length, 1);
  assert.equal(posts[0].text, '');
});
