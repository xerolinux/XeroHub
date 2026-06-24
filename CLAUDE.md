# XeroLinux HQ — Claude Code Context

Built with **Astro v7** + **Tailwind CSS**. Terminal/retro aesthetic. Hosted at `xerolinux.xyz`.

---

## Stack

- Framework: Astro 7
- Styling: Tailwind CSS (Layan theme tokens)
- Backend/DB: Firebase
- Fonts/icons: monospace-forward, terminal aesthetic

---

## Design Principles

- Terminal/retro aesthetic is intentional and must be preserved across all changes
- Color palette: dark background, `#5657f5` accent (theme-color), muted greens/grays for terminal elements
- No bright or "modern SaaS" styling — keep it consistent with the existing tone
- The `system-record.log` block, marquee ticker, and neofetch footer are signature elements — do not remove or restructure them without explicit instruction

### Live Visual Elements (not visible in static HTML)
Several design elements only render in the browser and must not be removed or broken:
- **Hero background:** Animated matrix rain canvas in Layan/RGB colors — intentional, do not remove
- **Hero header blur:** Frosted glass / blur effect activates on scroll, blurring content behind the sticky nav — intentional
- **Sale/discount badge:** Visibility is config-driven — hidden when no sale is active, shown automatically when a sale is enabled in the settings file. Do not hardcode its visibility or display state
- **CTA button hierarchy:** Already implemented — Download is the large primary filled button, Wiki is smaller secondary, GitHub is minimal/tertiary. Do not flatten them back to equal weight

---

## Site Architecture Notes

### Sale/Discount System
There is a settings file that controls the active sale banner sitewide (anniversary, Easter, Christmas, etc). The discount display on `/download/` and the homepage banner are driven by this config — do not hardcode sale text or prices anywhere. Always reference the settings file for sale state. Do not remove or simplify this system.

### Updates Page — Dual Layout (Mobile vs Desktop)
The `/updates/` page intentionally renders two list representations of the same posts:
- **Mobile:** Hero post card + simple numbered list for the rest
- **Desktop:** Coverflow/card carousel layout

This is not duplication. Do not consolidate or remove either layout. They are responsive counterparts controlled via CSS/Tailwind breakpoints.

---

## Known Issues to Address

These were identified via full site audit and should be fixed when touching relevant sections.

### Homepage `/`

**1. Nav clock/date element needs repositioning**
- The `Vol. MMXXVI · --:-- 12H` clock currently sits in the main nav row competing with the logo for visual weight
- Fix: Move it to a dedicated slim status bar sitting **above** the nav, not inside it — full width, small font, 60–70% opacity, subtle bottom border separating it from the nav below. Content example: `Vol. MMXXVI  ·  Wednesday, June 24  ·  14:32 24H  ·  ● online`
- On mobile: collapse or hide this bar entirely
- This reinforces the terminal/WM aesthetic (like a tiling WM status bar) while keeping the main nav row clean

**2. RSS link appears twice in the nav**
- Once as an icon in the logo row, once as a text link in the secondary Merch row
- Fix: Keep one instance only — the icon in the main nav row; remove the text duplicate

**3. Nav has three stacking rows with no visual separation**
- Main row (logo/clock/RSS/toggle) + marquee ticker + secondary row (Merch/RSS) bleed into each other
- Fix: Add subtle borders or background differentiation between the three nav bands so they read as distinct zones

**4. Screenshots gallery has no interactivity**
- Three flat thumbnails with no lightbox, no hover state, no click-to-enlarge
- Fix: Add a lightbox/modal on click, or a swiper carousel with keyboard navigation — users need to actually see the screenshots at full size

**5. `xero@arch:~/screenshots` terminal header is visually disconnected from the gallery**
- Floats above the images with no enclosing border
- Fix: Wrap the entire gallery in a terminal window frame — fake titlebar, the prompt as header, screenshots inside the "window body"

**6. Screenshot captions have no styling**
- `▸Calamares installer: ...` is left-aligned plain text with no visual treatment
- Fix: Style as a caption bar below each image, or an overlay on hover, consistent with the terminal aesthetic

**7. "Why XeroLinux?" three columns have no visual differentiation**
- Three headings and paragraphs in a row, no icons, no borders, no accent markers
- Fix: Add a left accent border in `#5657f5`, or a terminal-style `[01]` prefix on each heading

**8. Section counter badges (`01`, `02`, `03`) are positioned inconsistently**
- Appear at different visual positions relative to their sections across the page
- Fix: Lock to one position — top-left of each section container — and make them a consistent styled element

**9. YouTube thumbnail in "Arch, Refined" section is a raw unstyled image**
- Pulls `hqdefault.jpg` (low-res) from `i.ytimg.com` with no play button, no border, no hover state
- Fix: Add a styled play button overlay and link to YouTube, or use `maxresdefault.jpg` for better resolution

**10. Spec Sheet section is visually flat**
- Four items (KDE Plasma, Arch Linux, Wayland, XeroHub) are just stacked text labels
- Fix: Add actual logos/icons for each (KDE, Arch, Wayland), wrap each in a card with a subtle border, or use a terminal `key: value` definition list format

**11. No scroll-entrance animations**
- Sections appear statically as the user scrolls
- Fix: Add subtle `opacity-0 → opacity-100` fade-ins or `translateY` slide-ins via Intersection Observer — Astro makes this straightforward

**12. No consistent vertical rhythm between sections**
- Some sections feel cramped, others have too much air
- Fix: Establish a fixed `py` spacing scale for major section breaks and apply it consistently sitewide (e.g. `py-20` or `py-24`)

---

### Download Page `/download/`

**13. Astro version mismatch**
- This page still reports `Astro v6.4.2` in its meta while the rest of the site is on v7.0.2
- Fix: Rebuild/migrate this page under the v7 build pipeline

**14. ISO and TUI cards have inconsistent visual weight**
- ISO card has a sale badge, price display, strikethrough, and multiple buttons; TUI card has none of that — they look like they belong to different pages
- Fix: Give both cards the same border, padding, and button style logic regardless of content differences

**15. XeroDora section has no visual separation from the main cards above**
- A user scrolling past ISO/TUI hits XeroDora with no signal it's a secondary/supplementary product
- Fix: Add a stronger section divider and a visual treatment that communicates "side project, not a third main download option"

**16. `~ ~ ~ E.O.F ~ ~ ~` divider is used twice on the same page**
- Used as both a section separator and a page-end marker, which makes it meaningless as either
- Fix: Reserve it for page-end only; use a different visual treatment for mid-page section breaks

---

### Updates Index `/updates/`

**17. Tag filter bar has no visual styling**
- Filter buttons (`▸All10 ▸ISO 2 ▸Community 3...`) appear as plain text with no interactive styling
- Fix: Style as pill/badge elements with clear active/inactive states so users understand they are clickable filters

**18. "XeroLinux Goes Quarterly" renders as orphaned text**
- Appears as a heading with no linked card, no visual treatment — looks like a broken element
- Fix: Either wire it to its post card or remove the orphaned heading

---

### Post Pages (General)

**19. Post body text has no max-width constraint**
- On wide monitors line lengths stretch far past comfortable reading width (~65–75 chars)
- Fix: Cap the content column with `max-w-prose` or `max-w-3xl`, centered in the layout

**20. Post hero image has no spacing from the metadata line above it**
- Byline (author, date, tags, read time) flows directly into the full-width image with no breathing room
- Fix: Add bottom padding to the metadata block before the image

**21. `// Filed:` category tags don't look clickable**
- These are category tags but have no pill/badge styling, no underline, no hover state — look like static text
- Fix: Style as pill badges or terminal-style `[tag]` buttons with hover states

**22. Comments toolbar has no enclosing container**
- Formatting buttons (B, I, S, K) and emoji picker float in a row with no background or border
- Fix: Add a toolbar bar with a subtle background and bottom border that visually ties the controls to the textarea below

**23. CAPTCHA renders as inline plain text**
- `prove human: ? + ? =` has no visual distinction from surrounding content
- Fix: Style as a clearly labeled form field with a visible input box so users don't overlook it

---

### Post: ISO Price Change `/updates/iso-price-update/`

**24. No actual prices mentioned**
- The post explains why the price went up but never states old or new price
- Fix: Add one line with the actual figures so the post is self-contained

**25. Unattributed blockquote**
- The italicized quote reads as DarkXero speaking but is formatted as an external quote
- Fix: Either remove blockquote formatting or attribute it explicitly (e.g. `— DarkXero`)

**26. Meta-description is too vague**
- Could be more specific for search — include the actual price change context
- Fix: e.g. "The XeroLinux ISO moves from €29 to €39 — a one-time payment, lifetime updates. Full breakdown of why."

---

### Post: XeroLinux Team `/updates/xerolinux-team/`

**27. Tone is inconsistent with the rest of the site**
- "Ideas volcano", "debug katanas", "meme shields at spam armies" — hype-heavy language that clashes with the calm terminal aesthetic everywhere else
- Fix: Rewrite to match the site tone — confident and direct, not hyperbolic

**28. No structured role listing**
- Each person gets a paragraph but no clear role title
- Fix: Add a simple Name / Role / GitHub structure, either as a table or definition-style list

**29. Meta-description is a draft note**
- Current value: "Growing the team" — this is what shows in Google results
- Fix: Write a real description, e.g. "Meet the people behind XeroLinux — the maintainers, developers, and community team keeping the project alive."

---

### Post: XeroLinux Reviews `/updates/xero-reviews/`

**30. Page was not migrated to the new site design**
- Uses old nav, old logo path (`/logos/logo.png`), old footer, old theme-color (`#794BC4` vs `#5657f5`), and links to pages that no longer exist (`/gear/`, `/videos/`)
- Fix: Rebuild this page under the current site template

**31. Tone is overly apologetic**
- "I'm not entirely sure why..." and "There's no pressure" reads as uncertain
- Fix: Be direct — "If you review Linux distros, reach out and I'll send you a free ISO."

**32. Email is JS-only via Cloudflare obfuscation**
- Users without JS can't see the contact email
- Fix: Add a fallback contact method (Discord link, Fosstodon handle) that works without JS

---

### Crypto Portal `/crypto/`

**33. Completely off-brand and unstyled**
- No site nav, no standard header/footer, no terminal aesthetic — looks like a standalone external page
- Fix: Wrap in the standard site layout with header and footer

**34. Mobile warning is a bad first impression**
- "Better Viewed on a Larger Screen" is the first thing mobile users see
- Fix: Make the page responsive, or silently redirect mobile users to Ko-Fi

**35. Emoji-heavy UI clashes with site aesthetic**
- Uses 💸 ❤️ 💰 🧾 📩 💎 ⚡ everywhere; the rest of the site uses `★ // ▸` and code-style markers
- Fix: Replace emoji with terminal-style markers consistent with the rest of the site

**36. Captcha field broken**
- The math CAPTCHA renders as "What is ?" — the question values are not loading
- Fix: Debug the JS responsible for populating the captcha question

**37. Apologetic opening copy**
- "We know we're a bit late to the game" — unnecessary
- Fix: Remove it. Just present the feature.

---

### Sitewide

**38. Footer neofetch block and main footer content have no visual separation**
- The neofetch block blends into the footer logo/links area with no divider
- Fix: Add a horizontal rule or subtle background shift between the two zones

---

## Content Rules

- Do not duplicate copy across sections — each section must add new information
- Feature claims must match what's listed in `/download/` and the wiki
- "Donate once = Lifetime Updates" is a key value prop — must be prominent and clearly explained wherever the ISO contribution model is mentioned
- Sale/discount text must always come from the settings file — never hardcoded

---

## Do Not Touch

- The marquee ticker content and order (managed separately)
- The neofetch block in the footer
- The `system-record.log` spec block structure
- Firebase integration
- OG/meta tags unless explicitly asked
- **The Ko-Fi progress bar widget** — complex auto-updating setup synced live with Ko-Fi donation data. Intentional, functional, and links directly to the donation page. Do not move, restyle, rewire, or remove any part of it.
- **The sale settings file** — controls all discount banners sitewide. Do not bypass or hardcode sale states anywhere.
- **The Updates page dual layout** — mobile list and desktop coverflow are intentional responsive counterparts, not duplication.
- **Hero matrix rain animation** — animated canvas background in Layan/RGB colors. Intentional design element, do not remove or replace.
- **Hero scroll blur effect** — frosted glass blur activates on scroll behind the sticky nav. Intentional, do not remove.
- **CTA button hierarchy** — Download (primary/filled), Wiki (secondary/outline), GitHub (tertiary/minimal) is already implemented. Do not flatten to equal weight.
