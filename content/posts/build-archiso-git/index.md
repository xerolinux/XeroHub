---
title: "Build a Bleeding Edge Arch ISO"
date: 2025-05-19
draft: false
description: "Easy Guide to Building a Bleeding Edge Arch ISO"
tags: ["Arch", "ArchLinux", "ArchISO", "Linux"]
---
### Information

Sick & Tired of **ArchInstall** breaking ? Well fear not coz this guide will help you build an updated version using latest commits. I mean we can always grab the ISO  from the [**ArchLinux**](https://archlinux.org/download/) site as outdated as it can be. Still knowing how to build a *Bleeding Edge* one can be useful in a bind, am I right ?

<p align="center">
    <img width="500" src="https://i.imgur.com/QWqMIsr.png" alt="logo">
</p>

### Let's do this

First off we need to grab a few packages in order to be able to build the ISO. Keep in mind that in order to do this you must be on **Arch**. In case you aren't, that's where [**Distrobox**](https://distrobox.it/compatibility/) comes in really handy.

```Bash
sudo pacman -S archiso
```

Now we need clone the repo to grab latest commits. I recommend for you to keep the folder around and `git pull` every now and again to grab latest updates, that way you can always build a fresh one if and when issues do happen...

```Bash
git clone https://github.com/archlinux/archinstall
```

Now we cd into the directory and make sure script is executable via :

```Bash
cd archinstall/ && chmod +x build_iso.sh
```

Time to build the new ISO using :

```Bash
sudo ./build_iso.sh
```

Once build is done, you will find the newly created ISO under `/tmp/archlive/out/` copy it to somewhere safe before proceeding..

Finally we can delete the work directory to save space and to be able to build again later on down the line.

```Bash
sudo rm -rf /tmp/archlive/
```

### Wrapping up

Test it out and as is the norm by now, if you encounter any issues report them on **Github**.

<p align="center">
    <img width="100%" src="https://i.imgur.com/FcsiONm.png" alt="logo">
</p>

Now that we have an idea on how to build the **Arch ISO**, You can take it to another level.

Have fun, I know I will 🚀
