---
title: "Continue to use XeroLinux"
date: 2024-06-28
draft: false
description: "How To Keep Using XeroLinux"
tags: ["XeroLinux", "Distro", "Arch", "Linux"]
---
### Intro

With the Distro is now gone, you have two choices, either back up your data and move on to another one. I would recommend you install **Vanilla Arch** using the **ArchInstall** script via the official Arch ISO if you want to benefit from the **XeroCLI**.. Or, if you want to stick to **XeroLinux** for a bit longer while you figure things out, I would understand not easy to do everything from scratch again. You can do that, however since repos will be gone replaced with a single Xero-Repo that will only have a few packages I have created myself that make life easier.

{{< github repo="xerolinux/xlapit-cli" >}}

### How to keep XeroLinux alive

To keep the Distro alive for a while longer, you will have to remove my repos so you do not end up with error messages. Keep in mind that this will result in a message telling you that all packages that you have installed from those repos do not exist anymore every time you run the update command. Just ignore it until you move on to another Distro. With that out of the way, here's how to remove my repos.

Run this command in Terminal :

```Bash
sudo sed -i '/\[xerolinux_repo\]/,/\[xerolinux_nvidia_repo\]/d; /SigLevel = Optional TrustAll/d; /Include = \/etc\/pacman.d\/xero-mirrorlist/d' /etc/pacman.conf && sudo pacman -Rns xerolinux-mirrorlist xerowelcome
```

That's it. You can keep using XeroLinux for a while longer, as long as you want... Another thing to keep in mind though, is that none of the packages installed from my repos with xero- in the name will be getting updates anymore.. To update the rest of the packages from the AUR, just update using yay -Y --devel --save && yay -Y --gendb && yay -Syyu. Again, it's HIGHLY recommended you move on to ArchLinux with the DE/WM of your choice..

Best of luck !!!!
