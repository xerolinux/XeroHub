---
title: "TKG nVidia-AiO Installer"
date: 2024-06-27
draft: false
description: "Custom Optimized nVidia Drivers"
tags: ["nvidia", "drivers", "gpu", "legacy", "linux", "opensource", "bash", "script"]
---
### Introduction

In this post I will be telling you about a very useful tool/script that might help all of you out there having issues with the infamous **nVidia** GPU on Linux...

Now, a few users were reporting issues with **nVidia** lately, so I went on the hunt for a few fixes. After some research I stumbled upon an AiO Installer Script by the famous **TKG**...

### What is it?

What that script does is actually very simple, it gives the you, the user, an option to install various versions of the **nVidia** drivers. Meaning that if you are using one that requires an older version you can install it, or if you need a specific one that is more compatible you can do that too..

You can also select to install the **DKMS** version in the case where you are using a custom kernel other than **LTS** or **Zen**...

{{< youtube QW2XGMAu6VE >}}

Here's a quote from the man himself:

> **LIBGLVND** compatible, with 32 bit libs and DKMS enabled out of the box (you will still be asked if you want to use the regular package). Installs for all currently installed kernels. Comes with custom patches to enhance kernel compatibility, dynamically applied when you're requesting a driver that's not compatible OOTB with your currently installed kernel(s). Unwanted packages can be disabled with switches in the **PKGBUILD**. Defaults to complete installation.

### DKMS or regular?

**DKMS** is recommended as it allows for automatic module rebuilding on kernel updates. As long as you're on the same major version (5.8.x for example), you won't need to regenerate the packages on updates, which is a huge QoL feature. Regular modules can also be problematic on Manjaro due to differences in kernel hooking mechanisms compared to Arch. So if in doubt, go **DKMS**.

### Frogging GitHUB

Well, now that you know more click the button below to get teleported to his GitHub where you will find more info and instructions on how to build and install the drivers.

{{< github repo="Frogging-Family/nvidia-all" >}}

### Useful or a dud?

I hope this discovery helps you fix them issues. I never said this will be **THE** fix, but it could be I have no idea.

That's why I would love it if you reported back your experience with it below. Did it work or not? What issues did you encounter? You need help?

