// Latest ISO per edition. Counts are a build-time snapshot; the live numbers come from the download API.
export interface EditionInfo {
  id: 'std' | 'nvidia';
  name: string;
  file: string;
  sizeGB: string;
  sha256: string;
  sha1: string;
  md5: string;
  date: string;
  blurb: string;
  // Name split for two-tone colouring, plus the disc's two RGB colours.
  l1: string; sep: string; l2: string; c1: string; c2: string; a: string; b: string;
  release: number;
  total: number;
}

export const EDITIONS: EditionInfo[] = [
  { id: 'std', name: 'Intel / AMD', file: 'xerolinux-2026.09-x86_64.iso', sizeGB: '5.7 GB', sha256: 'a78a468bf960bf656751d42ce1e7d0a2880b567c5c638a89301a4917effdf8d6', sha1: '6294044b253bfdad32708e8114ace024d87aabff', md5: '9ea937dbe275d7b932fc43be3f2d5b15', date: 'Sep 2, 2026', blurb: 'For systems with an Intel or AMD GPU/iGPU', l1: 'Intel', sep: ' / ', l2: 'AMD', c1: '#84b0f8', c2: '#f69292', a: '66,133,244', b: '238,57,57', release: 171, total: 1044 },
  { id: 'nvidia', name: 'nVidia', file: 'xerolinux-nvidia-2026.09-x86_64.iso', sizeGB: '7.1 GB', sha256: 'df0397bd601a0f8f8835ff6671fb8c843c663e238cd9cb4a791027a86a640797', sha1: '87d2219d089ee0a607003abe2b520145cf6239d6', md5: '2e4eeee16c8fb81c37d62c4badf75ee2', date: 'Sep 2, 2026', blurb: 'For systems with an nVidia GPU', l1: 'nVidia', sep: '', l2: '', c1: '#2bd05a', c2: '#2bd05a', a: '43,208,90', b: '86,87,245', release: 156, total: 952 },
];

export const ISO_FEATURES = ['Live Environment based', 'Post-install toolkit included', 'Dedicated Intel/AMD & nVidia ISOs', 'Guided Calamares graphical installer', 'Kernel Manager for CachyOS & tuned kernels', 'Hybrid graphics optimized out of the box'];

export const VERSION = EDITIONS[0].file.match(/\d{4}\.\d{2}/)?.[0] ?? '';

export const discStyle = (a: string, b: string) =>
  `background: radial-gradient(circle, var(--bg) 0 14%, rgba(255,255,255,0.55) 14.5% 16.5%, rgba(10,12,28,0.35) 17% 30%, transparent 30.5%), conic-gradient(from 0deg, rgb(${a}), rgba(${a},0.55) 12%, #fff 18%, rgba(${a},0.7) 25%, rgb(${b}) 42%, rgba(${b},0.6) 55%, #fff 62%, rgba(${b},0.75) 70%, rgb(${a}) 88%, rgb(${a})); box-shadow: 0 0 18px rgba(${a},0.4), inset 0 0 0 1px rgba(255,255,255,0.35);`;
