---
title: "Wallpaper Engine for Plasma"
date: 2024-06-27
draft: false
description: "Animate your Wallpapers on Plasma"
tags: ["ricing", "animated", "wallpapers", "kde", "plasma", "themes", "linux"]
---

### Intro

I have always wanted to use cool animated wallpapers on Linux. Found many free ways, but nothing rivaled the awesome features of [Wallpaper Engine](https://www.wallpaperengine.io/en) found on steam for the low price of $5.. Only problem was that it only ran on Windows, nothing else. But someone awesome took it upon him/herself to port it over to Linux.

Below is a video on how to get it running on KDE Plasma via that plugin... Just note that, as it's mentioned in the video, not all animated wallpapers will work, test it and see. Oh and any Audio Spectrum ones that are supposed to react to music will absolutely not work as it has no way to hook to players. Besides that it should work.

{{< youtube irDqraC0K6g >}}

### Installation

I recommend that you grab it from the **AUR** if you don't want to have any headaches, but I will also include a link to their **Github** as well if you prefer building it from source, choice is yours as usual.

```Bash
paru -S plasma6-wallpapers-wallpaper-engine-git
```

Build from Source :

{{< github repo="catsout/wallpaper-engine-kde-plugin" >}}

### Wayland ?

Well I do not and cannot use **Wayland** due to my aging GPU. But if you do use it, then there's another tool based on **Wallpaper Engine** for it. Try it out..

```Bash
paru -S waywe
```
