/**
 * Converts basic markdown syntax to HTML for frontmatter strings.
 * Supports: **bold**, *italic*, `code`, [text](url)
 */
export function inlineMarkdown(text: string): string {
  return text
    .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
    .replace(/\*(.+?)\*/g, '<em>$1</em>')
    .replace(/`(.+?)`/g, '<code>$1</code>')
    .replace(/\[([^\]]+)\]\(([^)]+)\)/g, (_, label, url) => {
      const isExternal = url.startsWith('http');
      return isExternal
        ? `<a href="${url}" target="_blank" rel="noopener">${label}</a>`
        : `<a href="${url}">${label}</a>`;
    });
}
