---
title: "Ventoy - Best multi-boot tool"
date: 2024-06-27
draft: false
description: "Distro-Hopper's best friend"
tags: ["ventoy", "usb-boot", "multi-boot", "distro-hopping", "linux", "opensource"]
---
### Preface

In this here post I will be talking about the famous **Ventoy** USB tool. People have asked me many times what USB tool I use to make bootable Linux drives. Well that should answer that question.

But before I dive deeper into the why I use it over others here some info to get started.

### What's Ventoy exactly?

**Ventoy** creates bootable USB devices using ISO images. That sounds an awful lot like what established programs such as Rufus do at first, but when you realize that it puts the ISO images on the drive and does not extract them, it becomes interesting.

Even better, it is possible to place multiple ISO images on the USB device after it has been prepared by **Ventoy**; this allows you to boot into different Linux systems or install different versions of Windows straight from a single USB device.

{{< youtube 6Mev24M-Bs8 >}}

Ventoy even supports Secure Boot. Other than that it also includes support for changing the filesystem of the first partition (ntfs/udf/xfs/ext2/ext3/ext4), persistence support for various Linux distributions such as Ubuntu or Linux Mint, and support for auto-installation.

![Shot1](https://i.imgur.com/x7bmLFq.png)

### Theme Support

Also, since it uses **GRUB**, naturally, you can theme it. Yes, you read that correctly, it uses Grub themes, so if there’s a theme you like and use, you can apply it to Ventoy. This tool is my go-to as I have so many ISOs and it saves me time and frustration of having to flash a 2GB ISO on one of my 128GB thumb drives wasting space in the process.

I absolutely love this thing. It’s actively being updated. Adding more features, fixing others, and baking in support for more Distros. Just make sure to update the USB stick after updating the app itself, because updating the app alone does not magically update USB. You will have to do that yourself via a small terminal command. Click button below to visit the site and read documentation.

> Note: Ventoy is available as an optional tool in XeroLinux, so no need to download from the official site, or if you are on a different Arch-based distro just grab it from AUR otherwise I think it’s available on Debian repos.

### How to get it ?

Well, there are multiple way to grab this awesome tool, but since we mostly target **ArchLinux** over here I will let you know how to get it for this specific Distro. Below is the link to their **Github** page, but don't get it from there just yet.

{{< github repo="ventoy/Ventoy" >}}

To get it on **Arch** you first need to have an **AUR** helper installed since it's only available there. You have a choice between [**YaY**](https://github.com/Jguer/yay) or [**Paru**](https://github.com/morganamilo/paru). Select whichever you want, install it then we can grab **Ventoy** via command below...

```Bash
yay or paru -S ventoy-bin
```

That's it ! Enjoy your distro-hopping. Maybe you find the one that fits your needs the best :smile:

