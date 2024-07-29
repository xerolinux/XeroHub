---
title: "Enable Snaps on Arch"
date: 2024-06-27
draft: false
description: "Custom Optimized nVidia Drivers"
tags: ["Snaps", "SnapCraft", "Arch", "Guide", "Linux"]
---
### What are Snaps ?

Snaps are an innovative packaging format for distributing applications on Linux. Developed by **Canonical**, snaps are self-contained software bundles that include the app and all its dependencies. This allows snaps to work consistently across a wide range of Linux distributions, without compatibility issues. Snaps also use transactional updates, automatically rolling back if an update fails. Running in a secure sandbox, snaps have limited access to the host system, enhancing security. While some Linux users have reservations about Canonical's involvement, the snap format provides a convenient way to package and distribute applications that "just work" on any Linux desktop or server. For users and developers seeking a reliable, cross-distro packaging solution, snaps offer a compelling option to explore.

### Disclaimer :

Snap support was never intended to be used outside Ubuntu / Debian that package manager was created by Canonical for their Distribution and subsidiaries. Therefore  I will not be held responsible for any damage you incur by doing it. You will be on your own. Keep that in mind.

### Installation

With that out of the way, I would recommend you look for your apps on either Arch Repos, AUR or Flathub first since those are the package managers officially supported on XeroLinux / Arch, but if you still insist on doing it, Do it at your own risk ! here's how to do it, follow the guide step by step, if you didn't miss anything you will be well on your way to start using Snaps.

![[Image: BpMGL6X.png]](https://i.imgur.com/BpMGL6X.png)

* Step 1 : Install & enable snapd service

First things first, you will need to install `snapd` service and enable it. To do so please type the following commands in Terminal. Please report any issues to [Snapd Upstream](https://github.com/snapcore/snapd).

```Bash
paru -S --noconfirm snapd
sudo systemctl enable --now snapd.socket
sudo systemctl enable --now snapd.apparmor
```

Make sure to reboot the system after doing that for services to start correctly.

* Step 2 : Install The Snap Store

Once that's done, either start installing your snaps via `sudo snap refresh && sudo snap install packagename` commands or if you prefer to use a GUI App Store install the aforementioned Snap Store via command below.

Install the Snap Store :

```Bash
sudo snap install snap-store
```

This might take a while depending on your connection since it has to populate the massive database on first install, just be patient while it does that. Finally launch the store from the App-menu..

I hope this helps y'all...
