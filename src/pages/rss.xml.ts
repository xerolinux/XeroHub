import rss from '@astrojs/rss';
import { getCollection } from 'astro:content';
import type { APIContext } from 'astro';

export async function GET(context: APIContext) {
  const updates = await getCollection('updates', ({ data }) => !data.draft);
  const sorted = updates.sort((a, b) => b.data.date.valueOf() - a.data.date.valueOf());

  return rss({
    title: 'XeroLinux',
    description: 'Our Base Of Operations...',
    site: context.site!,
    items: sorted.map(item => ({
      title: item.data.title,
      pubDate: item.data.date,
      description: item.data.description || '',
      link: `/updates/${item.id}/`,
    })),
    customData: '<language>en-us</language>',
  });
}
