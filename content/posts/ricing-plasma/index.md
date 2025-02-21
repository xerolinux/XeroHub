---
title: "Ricing KDE Plasma"
date: 2024-07-29
draft: false
description: "An introduntory guide to ricing KDE Plasma"
tags: ["Plasma", "Ricing", "KDE", "KDE Plasma", "Guide", "Linux"]
---
### Intro

Before we begin, here's brief intro as to why I care about ricing.

In case you didn't know it, I began my **Linux** journey with **KDE Plasma** because of the freedom of customization. I love ricing my setups. I hated that **macOS** & **Windows** did not allow this.

And if you want to see what I have managed to do, well, hop on over to my **Layan** rice's **Githup** repository, you will get blown away.

{{< github repo="xerolinux/xero-layan-git" >}}

### A bit of understanding

Ricing can be a bit invloved. At least if you are like me, and care about consistency. It's not about just slapping a desktop theme and calling it a day. That's just lazy. Please don't do that.

![Rice](https://i.imgur.com/irOECxY.jpeg)

**KDE Plasma** is a ricing a beast, no doubt about that. That's one of its biggest selling points. So it's normal when I say, it can be very, very intricate. You can rice everything in it.

We need to also know what library the system uses. **KDE** uses a library called **Qt**, pronounced like *cute*. But you might encounter apps that use the **GTK2/3/4** library, typically ones created for **Gnome** or **XFCE**.

> Keep in mind though, to successfully theme **GTK4** or, as it's called now **LibAdwaita**, we need to make sure the necessary *Hacks* are included in the theme we have chosen, simply because, as we all know, **Gnome** devs despise the whole idea of theming for whatever reason.

So it will be up to you, the user, to find all theme elements required for a complete and consistent look. Whay do I say this you may ask? Well, quite simply because, and it saddens me to say this, very few themes come complete, allowing such consistency. But it can be done.

With that out of the way, let's get to it shall we ?

### KDE Plasma pieces

As I said earlier in the post, **KDE Plasma** is made of many elements that can be themed or riced. So here, I will be explaining what they are and the tools we need to theme them.

{{< alert icon="fire" cardColor="#e63946" iconColor="#1d3557" textColor="#f1faee" >}}
**Friendly Advice :** Never install themes from any repos or the **AUR**. Always grab them from source, after you have inspected the code. For your own sanity. And make sure they are compatible with **Plasma 6**.
{{< /alert >}}

Please read the above warning, ignoring it will result in nothing but headaches. Trust me, I made that mistake and wasted more time than I can count trying to solve the resulting issues.

- **Kvantum Manager**

First, we will need and app that I highly recommend to have on hand, called **Kvantum**. I consider it an essantial tool for every ricer out there.

![Kvantum](https://i.imgur.com/DNfv0aG.png)

{{< github repo="tsujan/Kvantum" >}}

This will take care of the awesome window blur and transparency effects for all **Qt** based apps. It will not work on anything else, keep that in mind.

- **SDDM Login Manager**

Another element **KDE Plasma** uses, is [**SDDM**](https://wiki.archlinux.org/title/SDDM) for its **Display Manager/Login**.

![SDDM](https://i.imgur.com/hLBbJvF.jpeg)

It too can be themed.

- **Grub Bootloader**

Now, I can already hear you say that this is unrelated to **KDE Plasma**, to which I will say, yes I agree. Also, not everyone will be using [**Grub**](https://wiki.archlinux.org/title/GRUB). Also true.

![Grub](https://i.imgur.com/tyoOZV1.png)

But for the sake of completeness, I do like to theme it as well.

- **Konsole Terminal Emulator**

[**Konsole**](https://konsole.kde.org/) is the *Terminal Emulator* that **Plasma** ships. I know most of you switch to **Alacritty** or even **Kitty**. But I prefer to stick with what ships with the DE I use.

![Konsole](https://i.imgur.com/pXDM5ZM.png)

That too can be themed.

### The more complete the better

Now that we have an understanding of the various elements that make for a more complete experience, here's what themes we choose need to have before using them.

Not all of them contain all the elements. Sadly there are some out there that are incomplete making it harder to get a cohesive look. So I would avoid those if I were you.

Once we have found a noce theme, we need to make sure it applies to the following parts of **Plasma** :

- **Colors** : Resposible for accent and window colors.
- **Application Style** : Theme specific Kvantum style.
- **Plasma Style** : Light/Dark window style.
- **Window Decorations** : The top window minimize/close/maximize bar.
- **Cursors** : Cursor theme (Optional)
- **Icons** : A fitting icon theme. (Optional)
- **SDDM** : Login theme.

![Settings](https://i.imgur.com/ggNKZYO.png)

That's it really. In case you do not find a theme that contains all these elements, it's not a huge issue, you can always hunt for one that fits the **Global Theme**. It's hard to find one I know, but who knows you might get lucky lol.

### Applying our themes

Once you have downloaded your chosen theme and theme elements from their sources (Github/Gitlab), follow their respective guides to install them, then head on over to the **KDE Settings** to apply them.

For **Kvantum**, just launch it, select the theme from the drop down and hit apply. Then select it as the **Application Style**.

As for **Konsole**, launch it, make sure you have moved its theme file into `~/.local/share/konsole/` folder, right click inside its window, select *create new profile* from the context menu, give it a name, one that you recognize, on the left click on *appearance*, select your theme, if you want to enable transparency with blur, click on edit, this is where you do that. Confirm, done.

Now I will not talk about **Grub** here since all themes for it will come with their own instructions and/or install scripts.

### Panel & Widgets

Oh boy, the reason I will not be talking about those is is simple, it's your rice you do with those as you please. **KDE Plasma** comes with some awesome widgets, use those to get started, if you want more, well, you will find them on the [**KDE Store**](https://store.kde.org).

{{< alert icon="fire" cardColor="#e63946" iconColor="#1d3557" textColor="#f1faee" >}}
**Warning :** Please make sure they are compatible with **Plasma 6**.
{{< /alert >}}

![XeroLayan](https://i.imgur.com/VA2tycb.jpeg)

As for the panel, position it wherever your heart desires. Top, bottom, left or right. It's all up to you. You can even use it as a Dock. Above is the end result of my very own rice I call the **XeroLayan** rice.

### Bonus for the G33ks

As a bonus, for all the G33ks out there, I would like to include a nice find. Some of us would love to make our rices reproduce-able without having to apply every element over and over, others just want to have a backup.

That's where this **Github Repo** comes in handy. It shows us what files are affected by the various theme elements. So have at it and enjoy !

{{< github repo="shalva97/kde-configuration-files" >}}

Don't forget about **Konsave** the GUI tool that does exactly that, just in a much simpler way. Article attached below.

{{< article link="/posts/konsave-tool/" >}}

That's all se wrote folks. I hope this has helped you understand more of what ricing **KDE Plasma** is all about.

Cheers !
