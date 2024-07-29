---
title: "Bluefin Aurora"
date: 2024-07-01
draft: false
description: "Best Atomic KDE Distro"
tags: ["uBlue", "Distro", "Bluefin", "Fedora", "Atomic", "Aurora", "Linux"]
---
### What is uBlue Atomic?

[**uBlue**](https://universal-blue.org/) is a project which produces images based on **Fedora Atomic** distros. You can use one of the presupplied images like [**Bazzite**](bazzite.gg/) (gaming-focused image), [**Bluefin**](https://projectbluefin.io) (general use zero-manitenance image), **Aurora** or their base images with minimal customizations to vanilla kinoite/silverblue/etc.

### What is Aurora?

Before explaining it, I would like to answer the "Why Aurora ?" question, well in case you did not know it yet, I am a **KDE Plasma** shill, so why not **Aurora** ? LoL. Now on to what it is...

**Aurora** is [**Bluefin**](https://projectbluefin.io) but with another coat of paint, the **KDE Desktop**. Many people love and cherish **GNOME**, but others want the customizability or the looks of a vanilla KDE experience. For those people, **Aurora** is here to serve them that need!

{{< github repo="ublue-os/bluefin" >}}

It includes everything that makes **Bluefin** and **Bluefin-DX** so awesome, including brew on host, the bluefin-cli, the starship CLI experience, Tailscale and the container-native Ptyxis terminal. You’ll find that most of the things you’re used to in Bluefin are the same under the hood, including the just commands. Aurora is not designed to be a drastically different experience than Bluefin, which also means we (I) can keep it regularly in sync with upstream so you get the latest changes.

It is built on the **kinoite-main** Images. The images feature almost no customization, aside from some quality of life features and some branding. You can expect a vanilla KDE experience with developer batteries under the hood.

{{< youtube ZPnV2vP_v-o >}}

### The upsides / benefits

* **An Awesome Package Manager**

I will begin by saying this, it's a neat project, I love how they use their sorta package manager called `ujust` that reminds me a heck of a lot of **Topgrade** which handles everything.

{{< article link="/posts/topgrade-updater/" >}}

* **Pre-Bundled Scripts**

Not just that, but they also supply so many pre-configured scripts that make harder tasks on other distros so damn simple, it's not even funny. They even supply an image with the **nVidia** or **AMD** drivers baked it and pre-configured for you so you don't have to lift a finger.

![ujust](https://i.imgur.com/qNeqmIG.png)

* **Stability and Immunability**

Also, the fact that it's so stable with truly *almost* zero-maintenance needed by you the user is a *Huge* benefit. Especially that it uses *rpm-ostree*. And that it's immune to any mistakes you might make, is so awesome. If you break the system just reboot select an older *snapshot* and you are back up and running. However one can still break it, but you really have to try lol.

They even supply an image for us devs out there with all the tools we might need to be productive out the box. I mean wow, could there *be* any more handholding ?

### The Downsides (No Dealbreakers)

* **Too Much Cruft ?**

Which brings me to the only *Big* downside, which is in my humble opinion, that it has way too much out the box, even the simple version. I get it, it aims to be as out of one's way as possible letting us be more productive, while I agree with this, it tends to target a smaller audience. Coz not everyone wants or needs everything it provides. I mean we don't even get to choose what we want out the box, ending up having to remove the cruft we do not need. Maybe that's more of a **Fedora** limitation I do not know.

* **Laziness / No Self-Reliance**

Now this is much less of an issue, more of an obervation, but if I have learned something during my Distro Maintaining days, it's that doing too much for the user out the box, will make them both lazy and will end up too dependent on us devs/maintainers. While I can't speak for the team behind **uBlue**, it's just impossible to satisfy everyone.

* **No Freedom To Tinker**

The other downside to this whole idea of **Atomic** distros, is that, if you were a tinkerer like me, who loves to mess with the system, modify core functionalities, you simply can't. As such you will be *heavily* relying on **Flatpaks**. It's not a big deal though, since this project wasn't meant to be used that way, so am not gonna be docking it any points for that.

### Would I recommend it ?

In conclusion, I will say, this is my opinion, and that you should take it with a huge grain of salt. I am a tinkerer, a not so ordinary user so to speak. And I have only been using it a day as of the writing of this post.

But yes, of ourse I would **Highly** recommend you at least give it a try. Just make sure to select the version that works best for you. Be it **AMD**, **nVidia**, or the **Dev/DX** version.

Just make sure you know that you will not be able to tinker much with it, the way you would be able to with the likes of **Arch** or the likes.

As for me, nope it will not replace my daily driver, **ArchLinux**, nothing will, I prefer my freedom for tinkering with the system. I was just curious as to what the deal was with all the **Atomic** distros out there is all.

<div align="center">

{{< button href="https://getaurora.dev" target="_blank" >}}
Download Bluefin Aurora
{{< /button >}}

</div>

That’s it folks ..

Cheers !
