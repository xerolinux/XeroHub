import rss from '@astrojs/rss';
import { getCollection } from 'astro:content';
import type { APIContext } from 'astro';
import { unified } from 'unified';
import remarkParse from 'remark-parse';
import remarkGfm from 'remark-gfm';
import remarkRehype from 'remark-rehype';
import rehypeStringify from 'rehype-stringify';

async function markdownToHtml(md: string): Promise<string> {
  const result = await unified()
    .use(remarkParse)
    .use(remarkGfm)
    .use(remarkRehype)
    .use(rehypeStringify)
    .process(md);
  return String(result);
}

function visitButton(url: string): string {
  return `
<table width="100%" cellpadding="0" cellspacing="0" border="0" style="margin:40px 0 8px;">
  <tr>
    <td align="center">
      <a href="${url}"
         style="display:inline-block;padding:12px 32px;background:#a06af0;color:#ffffff;font-family:sans-serif;font-size:14px;font-weight:600;text-decoration:none;border-radius:8px;letter-spacing:0.04em;">
        Visit Site
      </a>
    </td>
  </tr>
</table>`;
}

export async function GET(context: APIContext) {
  const updates = await getCollection('updates', ({ data }) => !data.draft);
  const sorted = updates.sort((a, b) => b.data.date.valueOf() - a.data.date.valueOf());

  const items = await Promise.all(sorted.map(async item => {
    const html = await markdownToHtml(item.body ?? '');
    const link = `${context.site}updates/${item.id}/`;
    const content = `
<div style="font-family:sans-serif;font-size:15px;line-height:1.7;color:#1a1a1a;max-width:680px;margin:0 auto;">
  ${html}
  ${visitButton(link)}
</div>`;

    return {
      title: item.data.title,
      pubDate: item.data.date,
      description: item.data.description || '',
      link: `/updates/${item.id}/`,
      content,
    };
  }));

  return rss({
    title: 'XeroLinux',
    description: 'Our Base Of Operations...',
    site: context.site!,
    items,
    customData: '<language>en-us</language>',
  });
}
