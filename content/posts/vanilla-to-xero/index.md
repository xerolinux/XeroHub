---
title: "Arch to XeroLinux"
date: 2025-03-23
draft: false
description: "Transform Arch to XeroLinux"
tags: ["ArchLinux", "XeroLinux", "Transform", "Guide", "Ricing", "Linux"]
---
### Intro

This keeps being asked on social. So I decided to answer it here.. How can you transform your Arch Install with **Gnome** or **KDE Plasma** to **XeroLinux** without having to reinstall or donate for the ISOs. Well, it's realtively easy, just follow this guide and you should be fine.

### Pre-requisits

We will need the toolkit which will enable everything you need to get started, like the **XeroLinux** & **Chaotic-AUR** repos and the **AUR** Helper you prefer. Without them you will not be able to proceed. 

![[Toolkit]](https://i.imgur.com/JuWceYE.png)

You will also need to be equiped with a bit of patience for some packages to compile. And please read the terminal output carefully in case of issues you will beasked for them. 

### Installation

Ok, now that you know what we will need, let's begin. To install the toolkit, repos n AUR helper type the following command in your favorite Terminal application :

```Bash
bash -c "$(curl -fsSL https://xerolinux.xyz/script/xapi.sh)"
```

![[Toolkit1]](https://i.imgur.com/5lDm8Sv.png)

As you can see from the image above you will be prompted to select your preferred **AUR Helper**, choose one and let the script install it for you. You will also notice that it will enable & activate both aforemntioned repos with multilib if you forgot it too.

![[Toolkit2]](https://i.imgur.com/tcZ8sDC.png)

Now that the toolkit has been installed and repos activated all you have to do is launch it either via `xero-cli -m` in terminal or via the shortcut found in the DE's App Menu or Dashboard in the case of **Gnome**. Once launched select option "**4 : System Customization.**".

![[Toolkit3]](https://i.imgur.com/aJBDnPS.png)

For **KDE Plasma** select option "**x. XeroLinux's Layan Rice**" as for **Gnome** select option "**z. Apply XeroLinux Gnome Settings**", and watch it do its thing. It will download necessary packages for settings to work. In case system is not rebooted after it's done, please do so otherwise you will have a mess on your hands.

![[Gnome]](https://i.imgur.com/PRun3J5.jpeg)

Image above represents what you will end up with on **Gnome**. If you dislike it and want to start from scratch, well that's easy just type the follwing command in terminal and you'll be back to to square one :

```Bash
dconf reset -f /org/gnome/
```

![[KDE]](https://i.imgur.com/VA2tycb.jpeg)

As for **KDE Plasma** above image is what you will end up with, although wallpaper might be different. Anyway that should be it. And again if you would like to start over as with **Gnome**, well, in this case there's a dedicated option in the toolkit. 

![[Service]](https://i.imgur.com/oh2PZy0.png)

As you can see from above image, just return to main menu then select option "**7 : System Troubleshooting & Tweaks**", then "**s. Reset KDE/Xero Layout back to Stock.**" finally reboot, done !

### Conclusion

I sure hope you enjoy your system with the **XeroLinux** look n feel. Although these options make your system mimic **XeroLinux** it's not representative of the Distro 1 to 1. It just gets you as close as possible to it.

If you want the full experience, you will have to donate for the ISO(s). That said, don't forget to join our Discord for any help or if you just want to chat with us.

Cheers !








