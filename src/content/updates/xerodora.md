---
title: "XeroDora: a Fedora-side Weekend Project"
date: 2026-06-24
draft: false
description: "XeroDora: a single curl-pipe-bash script that turns a fresh Fedora Everything install into a working KDE Plasma desktop. Side project, weekend cadence, critical fixes only."
tags: ["XeroLinux", "Distro", "Fedora", "KDE", "Plasma", "Side Project"]
image: "/images/updates/xerodora/banner.webp"
---

A side note from the **XeroLinux HQ**: there is a small **Fedora**-shaped thing living next to the main project. It is called **XeroDora**, and unless you spend your weekends polishing fresh installs, you may not have heard of it. This post exists so you have.

## What XeroDora actually is

XeroDora is **not a distro**. It is not a respin, not an ISO, not a fork. It is one shell script.

You start with the official [**Fedora Everything**](https://fedoraproject.org/misc/#everything) ISO, do the smallest possible install (kernel + base system + a network stack), reboot into the **TTY**, log in, and run a single line:

<div class="copy-block" data-lang="bash">
  <div class="copy-block-head">
    <span class="copy-block-label">bash</span>
    <button type="button" class="copy-block-btn" aria-label="Copy to clipboard" title="Copy">
      <svg class="icon-clip" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path></svg>
      <svg class="icon-check" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><polyline points="20 6 9 17 4 12"></polyline></svg>
    </button>
  </div>
  <pre><code>curl -fsSL https://urls.xerolinux.xyz/XeroDora | bash</code></pre>
</div>

The script does the rest. When it finishes, you reboot once and land in a configured **KDE Plasma** desktop on top of vanilla **Fedora**. No extra layer between you and upstream. No XeroLinux repos, no XeroLinux kernel, no XeroLinux packaging tricks. Pure Fedora, just dressed up so you don't have to do the dressing yourself.

![Info Sheet 01: XeroDora :: what you get](/images/updates/xerodora/features.webp)

## Why this exists at all

The honest answer: **XeroLinux is Arch**. Always has been. Some of you reach out asking whether the same comfort can be had on a Fedora base, usually because Fedora's release model fits your work pattern better, or your employer mandates RHEL-family systems, or you simply prefer `dnf` to `pacman`. XeroDora is the answer to that question, packaged as the smallest piece of software it can possibly be.

It is **not** "XeroLinux on Fedora". It is "here is the post-install routine I would run on a fresh Fedora box, written down".

## What the script does

After the curl-pipe-bash, in order:

- **Repos:** enables RPMFusion (free + nonfree), Flathub, and Terra.
- **Tuning:** sets `dnf` to 10 parallel downloads and fastest mirrors.
- **Codecs:** installs the multimedia codec set that just works.
- **Desktop:** KDE Plasma with Breeze Dark.
- **Shell:** fastfetch on terminal start.
- **Login:** Plasma Login Manager.
- **Apps:** a curated set of useful tools out of the box.
- **Optional menu:** numbered, space-separated picks for extras.
- **Optional rice:** XeroLinux rice install at the very end.

The optional app menu uses three source tags so you always know where a package comes from:

<div class="ref-callout">
  <div class="ref-callout-head">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M9.5 14.5L4 20l5.5-5.5"/><path d="M11 12l5-5 5 5-5 5z"/><path d="M14 10l-7 7"/></svg>
    <span>Menu Tags</span>
  </div>
  <dl class="ref-callout-list">
    <div class="ref-row">
      <dt class="ref-key ref-key-vanilla"><span>vanilla</span></dt>
      <dd class="ref-val">from <strong>Fedora</strong> or <strong>RPMFusion</strong></dd>
    </div>
    <div class="ref-row">
      <dt class="ref-key ref-key-repo"><span>[R]</span></dt>
      <dd class="ref-val">official vendor repo: Brave, Vivaldi, LibreWolf, VSCodium</dd>
    </div>
    <div class="ref-row">
      <dt class="ref-key ref-key-flat"><span>[F]</span></dt>
      <dd class="ref-val">Flatpak from <strong>Flathub</strong></dd>
    </div>
  </dl>
</div>

Pick numbers space-separated, or press Enter to skip and stay lean.

When the script finishes, reboot with `sudo systemctl reboot`. If you opted into the optional XeroLinux rice menu at the end of the run, you land on this:

![End result: XeroLinux Layan Rice &amp; Config](/images/updates/xerodora/result-desktop.webp)

That is the whole user-facing surface.

## Scope (please read this before opening anything)

This part is going to sound blunt because I would rather be blunt now than disappointing later.

**XeroDora is a weekend project.** It exists because the post-install dance on Fedora is the same every single time, and writing it down once was easier than typing it out for every person who asked. That is the entire story.

<div class="scope-rules">
  <div class="scope-rules-head">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 9v4"/><path d="M12 17h.01"/><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/></svg>
    <span class="scope-rules-title">Rules of engagement</span>
    <span class="scope-rules-sub">to be specific</span>
  </div>
  <ol class="scope-rules-list">
    <li class="scope-rule scope-rule-no">
      <span class="scope-rule-badge">No</span>
      <div class="scope-rule-body">
        <strong class="scope-rule-head-text">Feature requests.</strong>
        <span>If something is missing from the menu, add it yourself in your own shell after the script finishes. That is the cleaner path anyway.</span>
      </div>
    </li>
    <li class="scope-rule scope-rule-no">
      <span class="scope-rule-badge">No</span>
      <div class="scope-rule-body">
        <strong class="scope-rule-head-text">New suggestions for the script.</strong>
        <span>It does what it does. The shape is intentional.</span>
      </div>
    </li>
    <li class="scope-rule scope-rule-only">
      <span class="scope-rule-badge">Only</span>
      <div class="scope-rule-body">
        <strong class="scope-rule-head-text">Critical issues get fixed.</strong>
        <span>If the script outright breaks against a current Fedora release, that gets fixed. Cosmetic, &ldquo;I would prefer if it also did X&rdquo;, or &ldquo;can it support Y desktop too&rdquo; do not qualify.</span>
      </div>
    </li>
    <li class="scope-rule scope-rule-warn">
      <span class="scope-rule-badge">Risk</span>
      <div class="scope-rule-body">
        <strong class="scope-rule-head-text">Use at your own discretion.</strong>
        <span>It runs as root, touches package sources, installs codecs from a third-party repo. Read the script before piping it into bash if you are not already familiar with that pattern. The source is right there on the repo.</span>
      </div>
    </li>
  </ol>
</div>

The main project, the **XeroLinux ISO + T.U.I.**, is where my actual time goes. XeroDora gets the leftover hours. That is the deal.

## When XeroDora is for you

Pick **XeroDora** if you already prefer Fedora (or your environment requires it), you want KDE Plasma configured but not visually re-skinned, and you are comfortable running a shell command on a fresh install and reading what it printed. You do **not** need ongoing handholding or a roadmap.

Pick the **XeroLinux ISO** (or the free **T.U.I.** installer) if you want a fully maintained, actively developed, Arch-based system with the in-house Toolkit, Kernel Manager, SCX tool, and Package Manager GUI, plus quarterly polished releases instead of a one-shot script.

Both can coexist. Some people run XeroLinux on the main rig and XeroDora on a Fedora work laptop. That is fine.

So: there it is. **XeroDora.** A Fedora detour for those who wanted one. Use it, ignore it, or fork it. All three are valid.

<div style="text-align:center; margin:2.5rem 0;">
  <a href="https://github.com/xerolinux/XeroDora" target="_blank" rel="noopener noreferrer" style="color:#fff; text-decoration:none;" class="inline-flex items-center gap-2 px-8 py-4 text-base font-medium rounded-xl btn-glow bg-gradient-to-r from-[var(--color-accent)] to-[var(--color-accent-dark)] hover:from-[var(--color-accent-light)] hover:to-[var(--color-accent)] transition-all duration-300 cursor-pointer">
    View XeroDora on GitHub &#8594;
  </a>
</div>
