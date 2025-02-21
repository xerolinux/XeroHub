---
title: "VMware on Linux"
date: 2024-10-07
draft: false
description: "Install VMWare on Linux"
tags: ["VMWare", "Virtualization", "Tools", "Linux"]
---
### Intro

I understand that many of you newcomers to **Linux** from **Windows** sometimes prefer to use **VMWare** coz that's what you are used to. Although I would highly recommend **Virt-Manager** as it's Kernel based. But for you who prefer the former follow the guide below..

<p align="center">
    <img src="https://i.imgur.com/FDUoyg6.png" alt="shot">
</p>

### Guide

All packages compile from the **AUR**, but if you are on **XeroLinux** or have the **Chaotic-AUR** repos they will simply just install, no compilation needed.

- Grab the packages

```Bash
paru/yay -S vmware-workstation vmware-unlocker-bin vmware-keymaps
```

- Activate Networking & other services :

```Bash
sudo modprobe -a vmw_vmci vmmon
sudo systemctl enable --now vmware-networks.service
sudo systemctl enable --now vmware-usbarbitrator.service
```

Finally there's the matter of the Linux Guest OS, to set the correct resolution, it has to come with certain packages but in any case I will show you how to install them and enable. Note that the `xf86-video-vmware` package is for `X11/Xorg` only not for `Wayland` as the name implies.

To install & enable the service inside Linux guest just run :

```Bash
sudo pacman -S xf86-video-vmware open-vm-tools
sudo systemctl enable --now vmtoolsd
```

### Issues

If resolution does not get fixed and you are stuck at low, then you might need consult the follwing detailed Docs (Arch) >> [**VMWare Setup**](https://wiki.archlinux.org/title/VMware) or [**VMTools**](https://wiki.archlinux.org/title/VMware/Install_Arch_Linux_as_a_guest#Open-VM-Tools).

If you are installing another guest, like **Ubuntu**, **Debian** or anything else you will have to find relevant info on your own, I only know and use **Arch**.

Yet another tool to add to the arsenal. Best of luck.
