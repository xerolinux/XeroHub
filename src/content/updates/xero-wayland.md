---
title: "XeroLinux Moves to Wayland"
date: 2025-06-23
draft: false
description: "Wayland by default"
tags: ["XeroLinux", "Distro", "Wayland", "X11"]
image: "/images/updates/xero-wayland.webp"
---

## Intro

We’re excited to announce that **XeroLinux** is moving forward, from now on, all releases will be **Wayland-only**! For those curious, you can learn more about [**Wayland**](https://wayland.freedesktop.org) and the legacy [**X11**](https://en.wikipedia.org/wiki/X_Window_System) systems via these links.

This change marks a major step toward a faster, more secure, and modern desktop experience. **X11** (or X.Org) has served the Linux community well for decades, but it’s showing its age and is no longer actively maintained. By embracing **Wayland**, we’re ensuring **XeroLinux** remains at the forefront of innovation and stability.

<div style="position:relative;padding-bottom:56.25%;height:0;overflow:hidden;max-width:100%;"><iframe src="https://www.youtube.com/embed/iCU4W5Ab33c" style="position:absolute;top:0;left:0;width:100%;height:100%;border:0;" allowfullscreen></iframe></div>

We’re also aware of the recent [**XLibre**](https://github.com/X11Libre/xserver) fork. While we respect the passion behind such projects, we prefer to focus our energy on building a positive, forward-thinking community, free from unnecessary drama.

## Get X11 Back

Although **XeroLinux** no longer includes **X11** support by default, especially on our **KDE** flagship, you still have the flexibility to bring it back if needed. If you require **X11** for compatibility reasons or personal preference, simply run the following command to reinstall it :

```bash
sudo pacman -S kwin-x11 plasma-x11-session
```

This ensures you can continue using **XeroLinux** your way, even as we move forward with **Wayland** as the default.

## Wrap-Up

Rest assured, even though **X11** is no longer included by default in **XeroLinux**, our commitment to supporting all users remains unwavering. We will continue to offer assistance and guidance to anyone who needs help with **X11** setups or troubleshooting.

<p align="center">
    <img width="750" src="/images/updates/xero-wayland/FeBe8gQ.png" alt="X11">
</p>

Our goal is to provide a smooth, enjoyable experience for everyone, whether you’re embracing the future with **Wayland** or relying on **X11** for your workflow. Together, we’re building a vibrant, inclusive community that thrives on innovation and support.

Cheers :heart:
