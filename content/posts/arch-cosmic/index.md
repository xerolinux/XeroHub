---
title: "Cosmic Arch"
date: 2024-09-04
draft: false
description: "Install Cosmic DE on ArchLinux"
tags: ["Cosmic", "Arch", "ArchLinux", "ArchInstall", "Linux"]
---
<br />

{{< alert icon="fire" cardColor="#993350" iconColor="#1d3557" textColor="#f1faee" >}}
**Cosmic Script :** I have gone ahead and written a script that will help you do all this and more in one swoop. If you care to give it a whirl, keeping in mind the status of the project, you can grab it from the [**XeroLinux Wiki**](https://wiki.xerolinux.xyz/scripts/#cosmic-alpha).
{{< /alert >}}

### What is Cosmic DE?

The [**Cosmic DE**](https://blog.system76.com/post/cosmic-the-road-to-alpha/) is a new desktop environment being developed by the team behind **Pop!_OS**, a popular Linux distribution. Unlike their previous efforts, which built upon **GNOME**, the **Cosmic DE** is a ground-up development using **Rust** and a custom compositor built on **Smithay**, aiming for a lightweight, responsive, and customizable user interface.

Its most notable feature is, tiling window management with stacking, and a more integrated experience with the **Pop!_OS** ecosystem, enhancing performance and user control. It aims to offer a modern alternative to existing desktop environments, designed specifically for Linux users' needs.

### Installing Cosmic on Arch

{{< alert icon="fire" cardColor="#993350" iconColor="#1d3557" textColor="#f1faee" >}}
**Notice :** Project is still in **Alpha 1** stages, please don't use as a daily driver. It's still missing a ton of features. Install at your own risk !
{{< /alert >}}

When it comes to installing **Cosmic DE**, it has now become as easy as ever thanks to the **ArchInstall** script included on every *Arch ISO* starting v2.8.5. Yes, even though it's still in **Alpha** stages, for whatever reason, it has now made its way to the *Extra* repo on **Arch**.

Now I will not be going through how to use the **ArchInstall** script here, just watch the included video which covers it all. If you chose this Distro, then you should know how to use it by now lol.

{{< youtube dhqQjMQznSo >}}

As you can see from the video above, all you have to do it grab the latest [**Arch ISO**](https://archlinux.org/download/), boot into it and launch the **ArchInstall** then go through the motions as usual. I would change up the command a bit like so, making sure we are always running the latest version of the script :

```Bash
pacman -Syy archinstall && archinstall --advanced
```

As mentioned in the video the `--advanced` flag is required to unlock the **Cosmic DE** desktop profile. The reason it's hidden should be clear enough, in case it's not, well it's because it's in Alpha and no one sane enough who requires any kind of stability should install it.

![CosmicDE](https://i.imgur.com/Fvl9uRU.png)

Also, note the issue with the *Cosmic Greeter*, it could be that the maintainer of the packages on **Arch** forgot to include it or something else. If you are trying it way after this was written, maybe it's been fixed, if not then do as shown below to fix it.

Once all packages are installed, **Before** you exit *chroot* n reboot use this command :

```Bash
pacman -Syy cosmic-greeter
systemctl enable cosmic-greeter.service
```

Now that this is fixed, I would like to take this oportunity to mention that there's 2 more missing packages that **ArchInstall** failed to include, those are `xdg-user-dirs` which is resonsible for creating you user folders, like `Dicuments, Pictures, Videos...`, and finally the `power-profiles-daemon` tool that allows you to switch power profiles, so to fix those do this...

```Bash
pacman -Syy xdg-user-dirs power-profiles-daemon
xdg-user-dirs-update && systemctl enable power-profiles-daemon.service
```

Done ! All missing essential features fixed. Keep in mind that it's only natural for them to exist, project is still in Alpha stages, a lot of things need to be addressed. Give it time to mature before judging it, and more importantly report all the bugs related to it or any feature requests you might have upstream, to the [**Cosmic Bug Tracker**](https://github.com/pop-os)

### Customization

As we know, **Cosmic DE** will be highly customizable out of the box. It comes between **Gnome** and **KDE Plasma**. Meaning we can modify it more than the former but less than the latter. Still in my opinion that's awesome.

There are some caveats however, those being that **Qt** apps are still not fully supported eg. **Kvantum**, especially if you are used to the tried and true **Global Menu** which will not be officially supported as it's way too complex according to the devs. Also the Blur effect not there yet. Maybe in the future someone will port it over ? I dunno about **LibAdwaita** though, from what I have heard, support coming not yet there.

![CosmicThemes](https://i.imgur.com/R8Io5eQ.png)

So if you are looking for consistency, it will be a long while before we can achieve it. Still, this did not stop some theme developers from porting their themes over to it. So if you would like to try them out, just head on over to the >> [**Cosmic-Themes**](https://cosmic-themes.org) "store" and grab the one(s) you like. Importing the `.ron` files is easy just open Settings > Desktop > Desktop & Panel > Import, then select file n see it apply immediately.

### Wrapping up

As mentioned, I would highly recommend you install **Cosmic DE** on a spare non-essential device since it's still Alpha 1 software. And you will need modern enough hardware that has full support for **Wayland** since it doesn't nor will it ever have **X11** support.

However, if you are an **Arch** power user and prefer to do it the *manual way*, you can. Just head on over to the wonderful [**ArchWiki**](https://wiki.archlinux.org/title/COSMIC) and follow the instructions there. I would recommend it over **ArchInstall** as you can do more and have more flexibility.

Finally if you don't want to use it on **Arch**, you can grab their Official **Pop!_OS 24.04 LTS alpha** ISO from >> [**Cosmic Downloads**](https://system76.com/cosmic). They also have instructions for other Distros like **Fedora**, **NixOS** and more...

If you want to know what I think of this DE, and read how my experience with it went, check this post on >> [**DarkXero's Bytes**](https://bytes.xerolinux.xyz/tech/cosmic-experience/)

I hope this post has proven to be useful.

Cheers !
