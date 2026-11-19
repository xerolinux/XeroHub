export interface Release { date: string; iso: string[]; tui: string[] }

// Newest first. Items allow <strong> for emphasis.
export const CHANGELOG: Release[] = [
  {
    date: '2026-09-01',
    iso: ['Updated <strong>KDE/Kernel</strong> to latest (as of build).', 'General <strong>Bugfixes</strong> and <strong>Optimizations</strong>.'],
    tui: ['Refactored / Modernized <strong>progress page</strong>.', 'Fixed dead <strong>packages</strong>, optimized <strong>script</strong>.'],
  },
];
