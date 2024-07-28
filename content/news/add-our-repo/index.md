---
title: "Add XeroLinux Repo"
date: 2024-06-28
draft: false
description: "Add Our Repo To Your Install"
tags: ["XeroLinux", "Repo", "Arch", "ArchLinux", "Linux"]
---
Hey there...

I was recently asked if my Repo can be added to other Arch-Based Distros, short answer is yes of course you can. I will be showing you how below. Just note that my repo usually contains stuff I deem necessary, but in case you find some stuff that can be useful to you on ArchLinux feel free to add it.

Run below command :

```Bash
echo -e '\n[xerolinux]\nSigLevel = Optional TrustAll\nServer = https://repos.xerolinux.xyz/$repo/$arch' | sudo tee -a /etc/pacman.conf
```

That's basically it, now update database with `sudo pacman -Syyu` and you will notice my repo part of the update.

Cheers :heart:
