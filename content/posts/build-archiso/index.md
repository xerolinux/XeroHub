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

Now that we have an idea on how to build the **Arch ISO**, we can take it to another level. Yes, this is where most *Arch-Based* distros like **XeroLinux** begin. We can start modifying the `packages.x86_64` file inside `releng` folder adding more and more packages we might need to be included on the ISO out the box.

Just keep in mind that in order to get the `DE/WM` you want on the ISO a lot more work is involved. But now you get the idea. Have fun, I know I will 🚀

That's it !
