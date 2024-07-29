---
title: "Install Yay or Paru"
date: 2024-06-27
draft: false
description: "Best Ways To Install Yay or Paru"
tags: ["Yay", "Paru", "AUR", "Guide", "Linux", "Arch", "ArchLinux"]
---
### What Are Those?

Yay & Paru are **AUR** Helpers. What's that ? Well, an **AUR** helper is a tool that automates the process of installing and managing packages from the Arch User Repository (AUR) on Arch Linux. The main purpose of AUR helpers is to simplify the installation and updating of AUR packages, which are not available in the official Arch Linux repositories

![[Image: l2MiVr0.jpeg]](https://i.imgur.com/l2MiVr0.jpeg)

### What is the difference between the two ?

The primary differences between the AUR helpers Yay and Paru lie in their underlying programming languages and some of their default settings and features. **Yay** is written in **Go**, while **Paru** is implemented in the more efficient **Rust** language, resulting in better performance. Additionally, Paru has some saner default settings, such as requiring users to review the PKGBUILD before installing a package, which is an important security consideration when working with the Arch User Repository. Yay, on the other hand, offers a unique "--combinedupgrade" flag that provides a color-coded output to distinguish between repository and AUR package upgrades, a feature not present in Paru. In terms of active development, Paru is currently more actively maintained than Yay, though both continue to receive updates and improvements. The choice between the two ultimately comes down to personal preference and specific needs when managing packages from the AUR..

### Yay Installation :

```Bash
cd ~ && git clone https://aur.archlinux.org/yay-bin.git
cd ~/yay-bin/ && makepkg -rsi --noconfirm
cd ~ && rm -Rf ~/yay-bin/
```
### Yay Configuration :

```Bash
yay -Y --devel --save && yay -Y --gendb
sed -i 's/"sudoloop": false/"sudoloop": true/' ~/.config/yay/config.json;
```

Anyway here's how to proceed for Paru...

### Paru Installation :

```Bash
cd ~ && git clone https://aur.archlinux.org/paru-bin.git
cd ~/paru-bin/ && makepkg -rsi --noconfirm
cd ~ && rm -Rf ~/paru-bin/
```
### Paru Configuration :

```Bash
sudo sed -i -e 's/^#BottomUp/BottomUp/' -e 's/^#SudoLoop/SudoLoop/' -e 's/^#CombinedUpgrade/CombinedUpgrade/' -e 's/^#UpgradeMenu/UpgradeMenu/' -e 's/^#NewsOnUpgrade/NewsOnUpgrade/' /etc/paru.conf
echo "SkipReview" | sudo tee -a /etc/paru.conf > /dev/null
paru --gendb;
```

###  Closing

Once that is done, you can use it to start installing packages from the [AUR](https://aur.archlinux.org). Keep in mind that you do not need to install both; just select the one you prefer, either one works.. I would recommend YaY myself though.. [ArchWiki Page](https://wiki.archlinux.org/title/AUR_helpers)
