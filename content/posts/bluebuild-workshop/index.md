---
title: "BlueBuild Workshop"
date: 2024-08-01
draft: false
description: "The easiest way to build your own desktop Linux images"
tags: ["uBlue", "Distro", "Bluefin", "Fedora", "Atomic", "Builder", "Linux"]
---
### What is BlueBuild Workshop?

[**BlueBuild**](https://blue-build.org/) is a nifty toolkit for creating custom images of Linux distributions, similar to [**Bluefin**](https://projectbluefin.io). It simplifies the process by allowing you to tweak configurations in a straightforward `recipe.yml` file, perfect for those who want to share their personalized setups. You don't need to be a container wizard or a GitHub guru to get started—basic git and text editor skills will do. Just follow the documentation, ask the friendly community for help, and soon you'll be building custom Linux images like a pro.

{{< github repo="blue-build/workshop" >}}

All images will be based off of **Fedora** and have **Atomic** elements. No **Debian** or **ArchLinux** bases as of the writing of this post. Maybe in the future? Also this project is totally unrelated to **uBlue** or **Bluefin**.

### What’s a custom image?

Picture this: a custom image in the Linux world is like a gourmet pizza you can switch to without having to bake from scratch every time. So, making your own distro? Well, it’s kind of like claiming you’ve invented pizza when you’re really just adding your favorite toppings. When you’re whipping up custom images, you’re basically taking a tried-and-true Linux distro and sprinkling on your personal favorite apps and settings.

Think of it as curating a playlist with your best jams, but for your operating system. You’re still using the distro’s package manager and repositories, just with a dash of your unique flavor. It’s a lot like sharing your meticulously crafted dotfiles, but instead of just the configs, it’s the whole shebang of the OS with your personalized touch.

### BlueBuild and uBlue Differences

**Universal Blue** is an open source project started by cloud developers that builds amazing custom images based on **Atomic Fedora** along with related experiments, while BlueBuild only builds tools for custom image creation. The project now known as BlueBuild started out as just a part of Universal Blue, but was eventually split from it due to diverging from the scope and being mostly unrelated to the project’s main maintainers.

### Why use it?

To answer this question, I will say, this is not meant for everyone. But if you are a **FOSS** tinkerer and would like to create your own image(s) with your *ideal* configs and set of tools that anyone could *Rebase* to, then this is for you. This thing is so flexible.

{{< article link="/posts/aurora-atomic/" >}}

Just keep in mind that This isn't a *distro builder*, just a custom image builder. Remember that. Although you can generate ISOs from it, that's not what project was meant to be used for.

### Benefits vs Drawbacks

- **The Benefits**

Now I don't know how to put this, but you can do so much with this thing. As to benefits, I can't say much beyond what I already have. With the right amount of **Linux** knowledge you can take it to another level. You can build images that rival the likes of **Bluefin** and its derivatives to a certain degree using just images no ISOs to maintain, set it n forget it style. It's all up to you & your level of knowledge.

![bluebuild](https://i.imgur.com/4Vs4Yoq.png)

- **The Drawbacks**

This project is still young, so it will naturally come with some growing pains. As to drawbacks, it doesn't have many if any. The devs are doing a great job with it. The only thing I may not like, is the fact that it's only **Fedora** based, since am an **Arch** user myself. But that's not a drawback at all.

### My thoughts on BlueBuild

I have used this project to create my very own image called **XeroDora** based on the **uBlue Kinoite** image, and at first glance it looked easy enough to pull off. But after digging deeper, as I always do, it's not all as straightforward as I'd hoped. You will hit a few snags, which I find natural with every relatively new **FOSS** project.

One example being, dependencies. I keep running into this problem over and over and over. However it's unrelated to the project, it's just Fedora being Fedora. Still a newcomer will not be able to differentiate.

One idea would be to have some sort of error logs for the modules. Like, **BlueBuild** sees that the command failed and provides some help tips. (Thanks **@tulip** for suggestion) which would make it easier to debug.

Bottom line is, although devs are doing their best to make the project as easy as possible to use, sometimes issues happen outside project itself that require a lot of Linux know-how to troubleshoot. So as easy as it appears to be, it really isn't as I first thought.

Don't get me wrong here, I still love the project though, and so should you if you like stuff like that. That's why I will keep a close eye on it and see where it goes. I have super high hopes for it. As an Arch user, and ex-Distro maintainer, I see many images being born using this down the line...

> Please do not judge it too harshly just yet. It still has a long way to go. And devs are on the right track. If you encounter any issues, I would highly recommend you join their [**Discord**](https://discord.com/invite/MKhpfbw2) server for help.

That’s it folks ..

Cheers !
