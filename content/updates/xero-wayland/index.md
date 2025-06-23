---
title: "XeroLinux Wayland"
date: 2025-06-23
draft: false
description: "XeroLinux Moves to Wayland"
tags: ["XeroLinux", "Distro", "Wayland", "X11"]
---
## Intro

We’re excited to announce that **XeroLinux** is moving forward, from now on, all releases will be **Wayland-only**! For those curious, you can learn more about [**Wayland**](https://wayland.freedesktop.org) and the legacy [**X11**](https://en.wikipedia.org/wiki/X_Window_System) systems via these links.

This change marks a major step toward a faster, more secure, and modern desktop experience. **X11** (or X.Org) has served the Linux community well for decades, but it’s showing its age and is no longer actively maintained. By embracing **Wayland**, we’re ensuring **XeroLinux** remains at the forefront of innovation and stability.

{{< youtube iCU4W5Ab33c >}}

We’re also aware of the recent [**XLibre**](https://github.com/X11Libre/xserver) fork. While we respect the passion behind such projects, we prefer to focus our energy on building a positive, forward-thinking community, free from unnecessary drama.

## Get X11 Back

Although **XeroLinux** no longer includes **X11** support by default, especially on our **KDE** flagship, you still have the flexibility to bring it back if needed. If you require **X11** for compatibility reasons or personal preference, simply run the following command to reinstall it :

```Bash
sudo pacman -S kwin-x11 plasma-x11-session
```

This ensures you can continue using **XeroLinux** your way, even as we move forward with **Wayland** as the default.

## Wrap-Up

Rest assured, even though **X11** is no longer included by default in **XeroLinux**, our commitment to supporting all users remains unwavering. We will continue to offer assistance and guidance to anyone who needs help with **X11** setups or troubleshooting.

Our goal is to provide a smooth, enjoyable experience for everyone, whether you’re embracing the future with **Wayland** or relying on **X11** for your workflow. Together, we’re building a vibrant, inclusive community that thrives on innovation and support.

Cheers :heart:
