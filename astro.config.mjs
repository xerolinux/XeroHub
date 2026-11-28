// @ts-check
import { defineConfig } from 'astro/config';
import tailwindcss from '@tailwindcss/vite';
import sitemap from '@astrojs/sitemap';

export default defineConfig({
  site: 'https://xerolinux.xyz',
  output: 'static',
  // Old site URLs that still get traffic from search and bookmarks.
  redirects: {
    '/updates/age-attestation': '/',
    '/updates/browser-situation': '/',
    '/updates/help-needed': '/',
    '/updates/iso-price-update': '/',
    '/updates/iso-releases': '/',
    '/updates/six-year-anniversary': '/',
    '/updates/xero-reviews': '/',
    '/updates/xero-wayland': '/',
    '/updates/xerodora': '/',
    '/updates/xerolinux-changes': '/',
    '/updates/xerolinux-team': '/',
    '/crypto': '/support/',
    '/videos': '/',
  },
  integrations: [sitemap({ filter: (page) => !page.includes('/access/') })],
  vite: {
    plugins: [tailwindcss()],
  },
});
