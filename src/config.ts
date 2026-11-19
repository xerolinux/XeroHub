// Download service (Cloudflare Worker). Not deployed until ISOs go free;
// until then its stats fetch fails and the counts baked into the page are shown.
export const DL_API = 'https://dl.xerolinux.xyz';

// Paid or free is read at runtime from public/settings.json ({ "free": true | false }),
// so flipping it needs no rebuild. The build-time value is only the first-paint default.
export { free as FREE_DEFAULT } from '../public/settings.json';
export const SETTINGS_URL = '/settings.json';

// Paid period.
export const ISO_PRICE_EUR = 39;
export const KOFI_ISO_URL = 'https://ko-fi.com/s/cf9def9630';
// VPS buyer API (iso.xerolinux.xyz). Codes, link limits and counting stay on the VPS until March.
export const PORTAL_API = 'https://iso.xerolinux.xyz/KDEPlasma/api.php';
// Optional read-only VPS endpoint with live counts; empty keeps the built-in numbers.
export const PAID_STATS_URL = '';

// Sale switch. Shown only while enabled and today is between start and end (checked in the browser).
export const SALE = {
  enabled: true,
  start: '2026-12-01',
  end: '2027-01-31',
  percent: 35,
  label: 'Discount',
  note: 'Limited-time offer',
  kofiUrl: 'https://ko-fi.com/xerolinux/link/ANN25',
};
export const salePriceEUR = Math.round(ISO_PRICE_EUR * (1 - SALE.percent / 100));

// Same Firebase project as the old site, so the visit counter carries on from its totals.
export const FIREBASE = { apiKey: 'AIzaSyDT_MJQFqPiRXwqJzRJN_VdNR9qF-1ki_s', projectId: 'xerolinux-6e564' };
export const COUNT_HOSTS = ['xerolinux.xyz', 'www.xerolinux.xyz'];

// Ko-fi goal bar in the hero. Live figures come from the kofi-goal-proxy Worker (worker/);
// these are the fallback if it can't be reached at build or in the browser.
export const KOFI_GOAL = {
  proxy: 'https://kofi-goal-proxy.techxero.workers.dev/',
  link: 'https://ko-fi.com/xerolinux',
  title: 'Maintenance/Survival',
  currentEUR: 1620,
  targetEUR: 2000,
};
