---
title: "How To Downgrade Packages"
date: 2024-06-27
draft: false
description: "Downgrade Packages On ArchLinux"
tags: ["Downgrade", "Guide", "ArchLinux", "Guide", "Linux"]
---
### What is Downgrade ?

Downgrade is a Bash script that makes it easier to downgrade packages in Arch Linux to an older version. It checks both the local pacman cache and the Arch Linux Archive (ALA) for available older versions of a package and allows you to select which version to install

### Why do we need it ?

As you might know, Arch Linux is a rolling release and DIY (do-it-yourself) distribution. So you have to be a bit careful while updating it often, especially installing or updating packages from the third party repositories like AUR. You might be end up with broken system if you don't know what you are doing. It is your responsibility to make Arch Linux more stable. However, we all do mistakes. It is difficult to be careful all time. Sometimes, you want to update to most bleeding edge, and you might be stuck with broken packages. Don't panic! In such cases, you can simply rollback to the old stable packages. This short tutorial describes how to downgrade a package in Arch Linux and its variants like EndeavourOS, Manjaro Linux.

### Install Downgrade utility

The downgrade package is available in AUR, so you can install it using any AUR helper programs such as Paru or Yay.

Using Paru:

```Bash
paru -S downgrade
```

Using Yay:

```Bash
yay -S downgrade
```

### Downgrade a package

The typical usage of "downgrade" command is:

```Bash
sudo downgrade [PACKAGE, ...] [-- [PACMAN OPTIONS]]
```

Let us say you want to downgrade opera web browser to any available old version.

To do so, run:

```Bash
sudo downgrade opera
```

This command will list all available versions of opera package (both new and old) from your local cache and remote mirror.

Sample output:

```Bash
Available packages:

1) opera-37.0.2178.43-1-x86_64.pkg.tar.xz (local)
2) opera-37.0.2178.43-1-x86_64.pkg.tar.xz (remote)
3) opera-37.0.2178.32-1-x86_64.pkg.tar.xz (remote)
4) opera-36.0.2130.65-2-x86_64.pkg.tar.xz (remote)
5) opera-36.0.2130.65-1-x86_64.pkg.tar.xz (remote)
6) opera-36.0.2130.46-2-x86_64.pkg.tar.xz (remote)
7) opera-36.0.2130.46-1-x86_64.pkg.tar.xz (remote)
8) opera-36.0.2130.32-2-x86_64.pkg.tar.xz (remote)
9) opera-36.0.2130.32-1-x86_64.pkg.tar.xz (remote)

select a package by number:
```

Just type the package number of your choice, and hit enter to install it.

That's it. The current installed package will be downgraded to the old version.
