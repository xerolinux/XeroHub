---
title: "Build a Fresh Arch ISO"
date: 2024-09-05
draft: false
description: "Easy Guide to Building a Fresh Arch ISO"
tags: ["Arch", "ArchLinux", "ArchISO", "Linux"]
---
### Information

Sick & Tired of waiting a whole month before you can grab a fresh copy of the **Arch** ISO ? Well fear not coz this guide will help you build a fresh one. I mean we can always grab the ISO  from the [**ArchLinux**](https://archlinux.org/download/) site as outdated as it can be. Still knowing how to build a fresh one can be useful in a bind, am I right ?

<p align="center">
    <img width="500" src="https://i.imgur.com/QWqMIsr.png" alt="logo">
</p>

### Let's do this

First off we need to grab a few packages in order to be able to build the ISO. Keep in mind that in order to do this you must be on **Arch**. In case you aren't, that's where [**Distrobox**](https://distrobox.it/compatibility/) comes in really handy.

```Bash
sudo pacman -S archiso
```

Now we need create two folders in our home directory or anywhere else, up to you, one called `ArchWork` for placing extracted files, another called `ArchOut` where final ISO will be located.

```Bash
mkdir ~/ArchWork && mkdir ~/ArchOut
```

Now that it's all done we can proceed to building a fresh new & updated **ArchISO**. Just use the command below and watch the magic happen.

```Bash
sudo mkarchiso -v -w ~/ArchWork -o ~/ArchOut /usr/share/archiso/configs/releng
```

Finally we can delete the work directory to save space. just do `sudo rm -rf ~/work/`.

### Wrapping up

In case you are using the **XeroLinux** toolkit or Distro, make sure to update, coz as is my nature, I added the option to all that with a single click, for convenience. Test it out and as is the norm by now, if you encounter any issues report them on **Github**.

<p align="center">
    <img width="100%" src="https://i.imgur.com/FcsiONm.png" alt="logo">
</p>

Now that we have an idea on how to build the **Arch ISO**, You can take it to another level. Yes, this is how most *Arch-Based* distros like **XeroLinux** began. Just keep in mind that getting the `DE/WM` you want on the ISO requires a lot more work.

Have fun, I know I will 🚀
