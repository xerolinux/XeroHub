import { visit } from 'unist-util-visit';

export function remarkBaseUrl(base = '') {
  return () => (tree) => {
    if (!base) return;
    visit(tree, 'image', (node) => {
      if (node.url && node.url.startsWith('/') && !node.url.startsWith('//')) {
        node.url = base + node.url;
      }
    });
    visit(tree, 'html', (node) => {
      if (node.value) {
        node.value = node.value.replace(/src="\/(?!\/)/g, `src="${base}/`);
      }
    });
  };
}
