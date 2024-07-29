---
title: "The Chaotic-AUR"
date: 2024-07-03
draft: false
description: "Install AUR Packages Without Building Them"
tags: ["AUR", "Chaotic-AUR", "Repos", "Repository", "ArchLinux", "Arch", "Linux"]
---
### A bit of information

[**Chaotic-AUR**](https://aur.chaotic.cx) is an unofficial package repository that contains pre-built packages from the **Arch User Repository** (AUR) . It is an automated building service that compiles AUR packages so users don't have to build them themselves.

**Chaotic-AUR** is a convenient way to access AUR packages without having to build them yourself, but users should still exercise caution and verify the packages, as it is an unofficial repository

{{< youtube 0XR0chZU3vY >}}

### Activate Chaotic-AUR Repos

If you want to start using the **Chaotic-AUR** or just need to copy the setup commands, this is the right place for you.

Before we begin, I would like to remind everyone that if you are using the **XeroLinux Toolkit** it has an option that automates everything for you. Check it out on **Github** below.

{{< github repo="xerolinux/xlapit-cli" >}}

If you prefer to do it manually, then we start by retrieving the primary key to enable the installation of our keyring and mirror list:

```Bash
pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
pacman-key --lsign-key 3056513887B78AEB
pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
```

Then, we append (adding at the end) the following to `/etc/pacman.conf`:

```Bash
echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' | sudo tee -a /etc/pacman.conf
```

### The benefits

Only one benefit comes from using the **Chaotic-AUR**. And that's the fact that packages are most often if not always screened by the maintainers before being added, saving us the headache of being the guinea pigs.

Did I mention that you can request packages to be added there ? Oh yes, that's a side-benefit to all this. If you want to do that head on over to their **Github Repo** linked below and use the issues tab to either report an issue with a package, request a new package to be added or a **PKGBUILD** to be updated.

{{< github repo="chaotic-aur/packages" >}}

That’s it folks ..

Cheers !
