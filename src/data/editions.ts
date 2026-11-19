// Latest ISO per edition. Counts are a build-time snapshot; the live numbers come from the download API.
export interface EditionInfo {
  id: 'std' | 'nvidia';
  name: string;
  file: string;
  sizeGB: string;
  sha256: string;
  release: number;
  total: number;
}

export const EDITIONS: EditionInfo[] = [
  { id: 'std', name: 'Intel / AMD', file: 'xerolinux-2026.09-x86_64.iso', sizeGB: '5.7 GB', sha256: 'a78a468bf960bf656751d42ce1e7d0a2880b567c5c638a89301a4917effdf8d6', release: 171, total: 1044 },
  { id: 'nvidia', name: 'nVidia', file: 'xerolinux-nvidia-2026.09-x86_64.iso', sizeGB: '7.1 GB', sha256: 'df0397bd601a0f8f8835ff6671fb8c843c663e238cd9cb4a791027a86a640797', release: 156, total: 952 },
];
