---
title: "Six Years of XeroLinux"
date: 2026-05-29
draft: false
description: "XeroLinux just turned six. A little reflection, a lot of gratitude, and a promise that this baby of mine is not going anywhere."
tags: ["XeroLinux", "Anniversary", "Community", "Celebration"]
image: "/images/updates/anniversary/six-years.webp"
---

Six years. Six whole years of `pacman -Syu`, late night commits, broken builds at 3am, and that very specific joy of watching someone install **XeroLinux** for the first time and going "oh, that was easy."

I genuinely did not think I would be writing this post. Not because I doubted the project, but because six years is the kind of number that sneaks up on you while you are busy fixing one more bug.

So let me grab a slice and say a few things.

![A neofetch readout celebrating six years of XeroLinux](/images/updates/anniversary/neofetch-birthday.webp)

## Where this thing started

Back in 2020 this was just me, a fresh **Arch** install, and a stubborn idea: Arch is brilliant, but the front door does not have to be scary. No magic, no thousand-package bloat, just a clean **KDE Plasma** desktop and a toolkit that does the boring parts for you so you can get to the fun parts faster.

It was supposed to be a weekend project. It is funny how those go.

![The road so far, drawn as a git log](/images/updates/anniversary/roadmap.webp)

## The part that actually matters

Here is the truth: the code is the easy bit. The reason **XeroLinux** is still standing is **you**.

Every bug report, every "hey this typo in the wiki", every person who hung out in Discord helping a stranger get their GPU drivers working, every donation that kept the mirrors alive. You built this just as much as I did. I just happened to be the one pushing the commits.

![Everything the community brings, orbiting one big heart](/images/updates/anniversary/community.webp)

> *"A distro is not a download. It is a little community wearing a trench coat."*

## About this being "my baby"

People ask if I ever get tired of it, if I will quietly walk away one day like so many projects do. So let me be clear about this one. **XeroLinux is my baby.** It is not getting abandoned, and it is not going anywhere.

This project has my name and my heart bolted into it. As long as I have a keyboard and a pulse, it keeps shipping. That is not a marketing line, it is just how it is.

![Project status badges: maintained, abandoned false, commits non-stop](/images/updates/anniversary/maintained.webp)

## A fresh coat of paint

To mark the occasion, the site got a proper makeover. Top to bottom, every page, every panel, every divider, every comment field, all of it. Some of it is obvious the second you land, some of it you only catch when you start clicking around. The point was to make the whole thing feel like it belongs on a XeroLinux machine, not a generic distro blog. Here is what changed and why:

### - The new color scheme

Whole palette pulled from the [**Layan KDE theme**](https://github.com/vinceliuice/Layan-kde) by vinceliuice. Same theme the distro ships with.

### - Theme toggle in the NavBar

A slider that flips between **Xero-Layan** and **Xero-Dark**. Sticks across reloads. Find it, try it.

### - Comments, properly

Real comments under every post. Sign in, post, reply, format, drop an emoji. Trolls need not apply.

### - Updates page coverflow

The updates listing is now a **3D carousel** with the latest post front and center. Swipe through it.


---

-
And so much more... Poke around. Click things. Hover stuff. Open the comments. Toggle the theme. Half the fun is finding out how it all wires together. It's all done with care. Faster, geekier, more itself.

## A little gift

Because six years felt worth celebrating with you, not just at you, there is a gift. For a limited time, **until June 3rd 2026**, the **ISO is 25% off**. No code, no email signup, no spinning roulette of upsells, the price just drops at the checkout and that is it.

If you have been on the fence about pulling the trigger, sitting on the TUI install thinking maybe the proper ISO would be nicer, or you have been meaning to grab a second copy for the spare machine, this is the window. After June 3rd it quietly reverts and we go back to the regular pricing like nothing happened.

So here is the deal:

<figure class="sale-expired-figure">
  <div class="sale-expired-wrap">
    <img src="/images/updates/anniversary/sale.webp" alt="Anniversary sale: ISO 25 percent off until June 3rd (expired)" loading="lazy" />
    <span class="sale-expired-stamp" aria-hidden="true">
      <span class="se-line se-line-main">Expired</span>
      <span class="se-line se-line-sub">since 03 / 06 / 2026</span>
    </span>
  </div>
  <figcaption class="sale-expired-note">
    <span class="sen-arrow">&#9656;</span>
    The 25% anniversary discount closed on <strong>June 3rd, 2026</strong>. You are reading this after the window. <em>See you at the next offer.</em>
  </figcaption>
</figure>

<style>
  .sale-expired-figure { margin: 1.75rem 0 2.25rem; }
  .sale-expired-wrap {
    position: relative;
    display: inline-block;
    width: 100%;
    border-radius: 12px;
    overflow: hidden;
    isolation: isolate;
  }
  .sale-expired-wrap img {
    width: 100%;
    height: auto;
    display: block;
    /* Heavy blur on the underlying sale art so "25% off" copy is no longer legible. */
    filter: grayscale(0.7) brightness(0.55) blur(14px);
    transform: scale(1.05); /* expands the image so the blur doesn't reveal raw edges */
    transform-origin: center;
  }
  .sale-expired-wrap::after {
    content: '';
    position: absolute;
    inset: 0;
    background: linear-gradient(135deg, rgba(238,57,57,0.18), rgba(0,0,0,0.32));
    pointer-events: none;
  }
  .sale-expired-stamp {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%) rotate(-14deg);
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 0.95rem 1.8rem;
    border: 4px double #ee3939;
    color: #ee3939;
    font-family: var(--font-heading, 'Chakra Petch', sans-serif);
    font-weight: 900;
    text-transform: uppercase;
    letter-spacing: 0.2em;
    text-shadow: 0 1px 2px rgba(0, 0, 0, 0.55);
    background: transparent;
    box-shadow:
      0 0 0 4px rgba(238, 57, 57, 0.12),
      0 6px 18px rgba(0, 0, 0, 0.45);
    z-index: 2;
    user-select: none;
  }
  .sale-expired-stamp .se-line-main {
    font-size: clamp(2rem, 7vw, 3.2rem);
    line-height: 0.95;
    letter-spacing: 0.22em;
  }
  .sale-expired-stamp .se-line-sub {
    font-family: var(--font-mono, monospace);
    font-weight: 700;
    font-size: 0.72rem;
    letter-spacing: 0.28em;
    margin-top: 0.45rem;
    opacity: 0.85;
  }
  .sale-expired-note {
    margin-top: 0.85rem;
    padding: 0.55rem 0.85rem;
    font-family: var(--font-mono, monospace);
    font-size: 0.72rem;
    letter-spacing: 0.04em;
    color: var(--color-text-muted);
    border-left: 2px solid #ee3939;
    background: rgba(238, 57, 57, 0.05);
    border-radius: 0 6px 6px 0;
  }
  .sale-expired-note .sen-arrow {
    color: #ee3939;
    margin-right: 0.4rem;
    font-weight: 700;
  }
  .sale-expired-note strong { color: var(--color-text-primary); }
  .sale-expired-note em {
    color: var(--color-accent-light);
    font-style: italic;
  }
</style>

## To the next six

I have no idea exactly what year seven looks like. More polish, more in-house tools, more "how did we live without this" features, probably a few more 3am builds. What I do know is the direction: keep it geeky, keep it honest, keep it ours.

![Year seven loading bar with a little rocket](/images/updates/anniversary/year-seven.webp)

And here is the honest part. Without you, **XeroLinux** would not have lasted six months, let alone six years. You are the ones keeping it alive, plain and simple. So if you want to see it keep going, keep growing, and keep getting better, whatever you can chip in genuinely helps. No pressure, no guilt, just gratitude. Every little bit goes straight back into keeping the lights on and the commits flowing.

<div style="text-align:center; margin:2.5rem 0;">
  <a href="https://ko-fi.com/xerolinux" target="_blank" rel="noopener noreferrer" style="color:#fff; text-decoration:none;" class="inline-flex items-center gap-2 px-8 py-4 text-base font-medium rounded-xl btn-glow bg-gradient-to-r from-[var(--color-accent)] to-[var(--color-accent-dark)] hover:from-[var(--color-accent-light)] hover:to-[var(--color-accent)] transition-all duration-300 cursor-pointer">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" class="w-5 h-5"><path d="M18 8h1a4 4 0 010 8h-1"/><path d="M2 8h16v9a4 4 0 01-4 4H6a4 4 0 01-4-4V8z"/><line x1="6" y1="1" x2="6" y2="4"/><line x1="10" y1="1" x2="10" y2="4"/><line x1="14" y1="1" x2="14" y2="4"/></svg>
    Support XeroLinux Development
  </a>
</div>

So thank you. For six years, for the patience, for sticking around through the rough patches and the good ones. Here is to many more.

With love,
**DarkXero**

Now go update your system. You know you have been putting it off.
