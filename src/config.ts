// ─────────────────────────────────────────────────────────────
//  XeroLinux — ONE global discount switch.
//
//  Set it here once. When live it applies EVERYWHERE automatically:
//  the homepage banner, the Download ISO card (stamp + struck price)
//  and the Crypto page (minimum donation + live converter).
//
//  Live when `enabled` is true AND today is between `start` and
//  `end` (inclusive). Past `end` everything reverts on its own.
// ─────────────────────────────────────────────────────────────

function within(start: string, end: string): boolean {
  const now = Date.now();
  const s = new Date(start + 'T00:00:00').getTime();
  const e = new Date(end + 'T23:59:59').getTime();
  return now >= s && now <= e;
}

export const discount = {
  enabled: true,            // ← master switch (false = off everywhere, dates ignored)
  start: '2026-05-31',      // ← discount begins
  end: '2026-06-03',        // ← discount ends (auto-reverts after)
  percent: 25,              // ← % off — drives every price site-wide
  basePriceEUR: 39,         // ← regular ISO price
  label: 'Discount',     // shown on the discount stamp
  note: 'Limited-time offer', // small note beside the price

  // Homepage banner copy (edit freely):
  bannerText: '25% Anniversary Discount !!!',
  bannerSub: 'Celebrating 6 years of XeroLinux - grab the ISO while it lasts',
};

/** True when the discount should show anywhere on the site. */
export const discountActive = discount.enabled && within(discount.start, discount.end);

/** Prices in whole euros. */
export const basePriceEUR = discount.basePriceEUR;
export const discountedPriceEUR = Math.round(discount.basePriceEUR * (1 - discount.percent / 100));

/** What to charge right now — discounted while active, else full price. */
export const currentPriceEUR = discountActive ? discountedPriceEUR : basePriceEUR;

// ─────────────────────────────────────────────────────────────
//  Masthead ticker (the scrolling strip under the nameplate).
//  Date-based like the discount: shows only while `enabled` is
//  true AND today is between `start` and `end` (auto-hides after).
//  Edit `items` freely; each one gets a star prefix automatically.
// ─────────────────────────────────────────────────────────────
export const ticker = {
  enabled: true,            // master switch (false = always off, dates ignored)
  start: '2026-05-31',      // ticker appears from this date
  end: '2026-12-31',        // ticker auto-hides after this date
  items: [
    'Quarterly Release',
    'Kernel Manager / SCX Tool',
    'Online vs Offline Install',
    'Your Machine / Your Decision',
    'XeroLinux in-house Tools',
    'Donate once = Lifetime Updates',
    'XeroLinux Package Manager G.U.I',
  ],
};

/** True when the ticker should show right now. */
export const tickerActive = ticker.enabled && within(ticker.start, ticker.end);

// ─────────────────────────────────────────────────────────────
//  Ko-Fi general goal (rendered as a custom Layan-themed bar).
//  Update `currentEUR` here as donations come in — the bar fills
//  automatically. `link` opens the Ko-Fi page in a new tab.
// ─────────────────────────────────────────────────────────────
export const kofiGoal = {
  enabled: true,
  title: 'Maintenance / Survival Goal',
  currentEUR: 1000,
  targetEUR: 2000,
  link: 'https://ko-fi.com/xerolinux',
};

export const kofiGoalPct = Math.max(0, Math.min(100, Math.floor((kofiGoal.currentEUR / kofiGoal.targetEUR) * 100)));
