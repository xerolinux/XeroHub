---
title: "Pin nVidia Drivers"
date: 2024-08-07
draft: false
description: "Prepare for the nVidia R560 Drivers"
tags: ["nVidia", "R560", "Drivers", "GPU", "Pin", "Linux"]
---
**This post is only for affected users**

Please read the entire post before you start worrying. I have included a short addendum towards the end, make sure to read it. If you are not affected, then you can ignore this.

### What is happening?

**nVidia** just released the **R560** version of its drivers; which drops support for all GPUs that use the **Pascal** architecture or *SOC*. That includes all **900 & 10** series cards, with exception of the **1650ti** and **1660ti**.

New drivers will default to using the [**Open GPU Kernel Modules**](https://developer.nvidia.com/blog/nvidia-transitions-fully-towards-open-source-gpu-kernel-modules/) which only support cards using the **Turing** architecture and above moving forward.

![OpenKMS](https://i.imgur.com/kFNHP1d.png)

They have been preparing us for a while now, so we cannot complain too much in my honest opinion. So we knew this day would come eventually. If you are like me and own one of them older GPUs and want to preserve your sanity, this post is for you.

That's why, we have to get ready and *Pin* our drivers to current working release before new ones drop so we do not suffer the infamous **Black Screen Of Death** resulting from unsupported drivers.

### Pin/Hold nVidia Drivers

Before we begin, I need to say that I will be showing you how to "Pin" drivers on **ArchLinux** & **Flatpak**, if you run something else like **Fedora**, **Nix** or **Gentoo**, you will have to find a guide to do just that on their support forums. Sorry but I do not use any of those so I have no clue.

Anyway, with that being said, here's how you can "Pin" them...

- **Pacman.conf :**

Usually to block packages from being updated on **Arch**, we have to add them to *Pacman*'s `IgnorePKG`. To do so please run the following command in terminal :

```Bash
sudo nano /etc/pacman.conf
```

Scroll down a bit until you see the `# IgnorePKG =` line, remove the `#` from the beginning of the line to activate it, then after the `=` add the following packages

```
nvidia-dkms nvidia-settings nvidia-utils opencl-nvidia libxnvctrl lib32-opencl-nvidia lib32-nvidia-utils
```

![Pacman](https://i.imgur.com/PzpOTPx.png)

Save and quit. Now with that being done, your **nVidia** drivers will never get updated ever again. You will see a message every time you run an update that those packages will be ignored.

- **Flatpak :**

Now comes the turn of **Flatpaks**. To avoid them from being updated, especially if you use something like **OBS-Studio**, we will need to use a tool called **Warehouse** making it easy. If you don't know what it is look at the article below.

{{< article link="/posts/warehouse-flatpak/" >}}

Now, launch it, click on the filter icon and enable the `Show Runtimes` option in order to see the drivers currently installed on your system.

![Warehouse](https://i.imgur.com/s7aEmPu.png)

Once that's done, close filter window, scroll down the list until you see the **nVidia** drivers, click on the 3 vertical dots and select the **Disable Updates** option. That's it ! Now they will never be updated.

### Downgrade Drivers

This, in my opinion is the most likely scenario to happen to most users who are new to **Linux** as a whole. It's the one where drivers get updated without previously having "Pinned" them. If that happens to you, and you end up with a black screen, fear not there is a solution. It's called *Downgrading*. We will be using a tool called, you guessed it, **Downgrade**. More info in article below.

{{< article link="/posts/downgrade-tool/" >}}

Since you are stuck on a black screen, with no way to get to the desktop, all you can do in this case is switch to the **TTY** via `CTRL+ALT+F3`. Once there we need to downgrade drivers to whatever previous working ones were.

- **Install Downgrade :**

If you do not already have it, well you will need to install it, you can either use `yay` or `paru` whichever AUR helper you got, if you don't have one check article below :

{{< article link="/posts/install-yay-paru/" >}}

Once you have your **AUR Helper** of choice, time to install **Downgrade** :


```Bash
paru -S --noconfirm --needed downgrade
```

Now we can downgrade the drivers. To do that just run the following in Terminal :

```Bash
sudo downgrade nvidia-dkms nvidia-settings nvidia-utils opencl-nvidia libxnvctrl lib32-opencl-nvidia lib32-nvidia-utils
```

Make sure to select whatever previous working ones were from the list for each of the packages being downgraded. Could be from your local cache if you did not clear it or will be downloaded. Once that's done, you will be prompted if you want to add the affected packages to *pacman*'s ignore list, please make sure you answer with `y` to all, otherwise drivers will get upgraded next time there's an update.

### Wrapping up

That covers all the *Official* scenarios on **Arch**. If you are on something else I would highly recommend you consult relevant documentation. I know it sucks, but drivers can't be supported forever. There will always be a time where aging hardware will be dropped. It is what it is.

Note how I said *Official*, because there are many *Unofficial* ways to keep using older drivers. One of them being the **TKG nVidia-All** script. To know more check article below.

{{< article link="/posts/tkg-nvidia-all/" >}}

Another way would be to find a repo like **Chaotic-AUR** enable it and install older drivers from there should they have them if you do not want to compile them yourself.

{{< article link="/posts/chaotic-aur/" >}}

But those methods are for the more *Linux-Savvy* users out there, not for everyone. Anyway I hope this guide has helped you avoid any headaches.

**Addendum :**

From what I can see on **ArchLinux** repos `nvidia-dkms` will be the ones that will contain the **Proprietary** blobs where `nvidia-open-dkms` will have the **Open Kernel Modules** moving forward, with us ending up with 2 Driver editions.

If that's the case, you are safe to keep using the former for `Pascal` and older cards with latter only being required if you are on `Turing` or above. I must admit this can be a bit confusing for some newcomers to **Linux**. Such is the life of a Linux user I guess.

Cheers !
