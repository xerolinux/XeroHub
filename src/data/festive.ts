export type FestiveId = 'new-year' | 'lunar-new-year' | 'valentines' | 'st-patricks' | 'easter' | 'independence-day' | 'halloween' | 'diwali' | 'thanksgiving' | 'christmas';

type Window = (year: number) => [Date, Date];

const day = (y: number, m: number, d: number) => new Date(y, m - 1, d);
const fixed = (m1: number, d1: number, m2: number, d2: number): Window => (y) => [day(y, m1, d1), day(y, m2, d2)];
const around = (table: Record<number, [number, number]>, before = 2, after = 2): Window => (y) => {
  const t = table[y];
  if (!t) return [day(0, 1, 1), day(0, 1, 1)];
  return [day(y, t[0], t[1] - before), day(y, t[0], t[1] + after)];
};

// Gregorian computus (Anonymous algorithm).
export function easter(y: number) {
  const a = y % 19, b = Math.floor(y / 100), c = y % 100, d = Math.floor(b / 4), e = b % 4;
  const f = Math.floor((b + 8) / 25), g = Math.floor((b - f + 1) / 3), h = (19 * a + b - d - g + 15) % 30;
  const i = Math.floor(c / 4), k = c % 4, l = (32 + 2 * e + 2 * i - h - k) % 7, m = Math.floor((a + 11 * h + 22 * l) / 451);
  const month = Math.floor((h + l - 7 * m + 114) / 31);
  return day(y, month, ((h + l - 7 * m + 114) % 31) + 1);
}

const shift = (d: Date, n: number) => day(d.getFullYear(), d.getMonth() + 1, d.getDate() + n);

const LUNAR: Record<number, [number, number]> = { 2026: [2, 17], 2027: [2, 6], 2028: [1, 26], 2029: [2, 13], 2030: [2, 3], 2031: [1, 23], 2032: [2, 11], 2033: [1, 31], 2034: [2, 19], 2035: [2, 8] };
const DIWALI: Record<number, [number, number]> = { 2026: [11, 8], 2027: [10, 29], 2028: [10, 17], 2029: [11, 5], 2030: [10, 26], 2031: [11, 14], 2032: [11, 2], 2033: [10, 22], 2034: [11, 10], 2035: [10, 30] };

export const FESTIVITIES: Record<FestiveId, { name: string; window: Window }> = {
  'new-year': { name: 'New Year', window: (y) => [day(y, 12, 31), day(y + 1, 1, 2)] },
  'lunar-new-year': { name: 'Lunar New Year', window: around(LUNAR) },
  valentines: { name: "Valentine's Day", window: fixed(2, 13, 2, 15) },
  'st-patricks': { name: "St Patrick's Day", window: fixed(3, 16, 3, 18) },
  easter: { name: 'Easter', window: (y) => [shift(easter(y), -2), shift(easter(y), 1)] },
  'independence-day': { name: 'Independence Day', window: fixed(7, 3, 7, 5) },
  halloween: { name: 'Halloween', window: fixed(10, 24, 11, 1) },
  diwali: { name: 'Diwali', window: around(DIWALI) },
  thanksgiving: {
    name: 'Thanksgiving',
    window: (y) => {
      const first = day(y, 11, 1).getDay();
      const thu = day(y, 11, 1 + ((4 - first + 7) % 7) + 21);
      return [thu, shift(thu, 3)];
    },
  },
  christmas: { name: 'Christmas', window: fixed(12, 1, 12, 30) },
};

export const FESTIVE_IDS = Object.keys(FESTIVITIES) as FestiveId[];

export function festiveFor(now: Date): FestiveId | null {
  const today = day(now.getFullYear(), now.getMonth() + 1, now.getDate()).getTime();
  let best: FestiveId | null = null;
  let bestLen = Infinity;
  for (const id of FESTIVE_IDS) {
    for (const y of [now.getFullYear() - 1, now.getFullYear()]) {
      const [a, b] = FESTIVITIES[id].window(y);
      const len = b.getTime() - a.getTime();
      if (today >= a.getTime() && today <= b.getTime() && len < bestLen) { best = id; bestLen = len; }
    }
  }
  return best;
}
