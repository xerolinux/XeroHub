---
title: "M4LW Hyprland Dots"
date: 2024-07-05
draft: false
description: "The Most Advanced Hyprland Dots Ever!"
tags: ["Hyprland", "Dots", "Ricing", "Theming", "GTK", "Wayland", "Linux"]
---
### What is Hyprland?

In a nutshell, **Hyprland** is a dynamic tiling **Wayland** compositor based on *wlroots* that doesn't sacrifice on its looks. It provides the latest Wayland features, is highly customizable, has all the eyecandy, the most powerful plugins, easy IPC, much more QoL stuff than other wlr-based compositors and more...

### The ML4W Dot Files

Before getting to it, I would like to say that, while I, myself do not and will not ever be using WMs since my workflow is tailored around DEs, that doesn't mean I do not appreciate the hard work others put into making them more approachable, and pretty to both look at and use.

That being said, I have been following Hyprland's growth as time went on, especially all the rices being created for it. I have seen so many awesome ones, but the one that caught my eye, which we will be talking about, is the one by a guy named [**@Stephan Raabe**](https://gitlab.com/stephan-raabe).

{{< youtube sVFnd5LAYAc >}}

As you can see from the video above, he has gone above and beyond the natural limits, making **Hyprland** all that more fun and easy to use by creating *GUI Config Tools* written in **GTK** not only for his dots but you can effortlessly configure almost every aspect of **Hyprland** making it truly your own. It's truly amazing !!!!

Here's a quote from the dev :

> **PLEASE NOTE:** Every Linux distribution and setup can be different. Therefore, I cannot guarantee that the installation will work everywhere. Installation on your own risk.

### How to Install them

Before we start, just know that the **ML4W** Dotfiles should work on all Arch Linux based distributions, though they have been only tested with the following ones. Support for other Distros like **Fedora** and so on are slowly being added according to Dev.

- Arch Linux (recommended)
- EndeavourOS
- Manjaro Linux
- Garuda Linux
- Arco Linux
- XeroLinux w/Hyprland

> For **Manjaro** users: Hyprland and required packages are under ongoing development. That's why it could be possible that some packages are not immediately available on Manjaro. But usually, the packages will be published later. Maybe you can install required packages manually.

> For **ArcoLinux** users: Please reinstall/force the installation of all packages during the installation/update process of the install script. The script will also offer to remove ttf-ms-fonts if installed to avoid issues with icons on waybar.

![ML4W](https://i.imgur.com/amMcyTO.jpeg)

The installation script will create a backups from configurations of your .config folder that will be overwritten from the installation procedure and previous ML4W Dotfiles installation.

If possible, please create a snapshot of your current system if snapper or Timeshift is installed and available.

With main points out of the way, he made installation so simple, as simple as running a script and following prompts. The script will download all files from GitLab and start the installation.

Just copy/enter the following command into your terminal.

```Bash
bash <(curl -s https://gitlab.com/stephan-raabe/dotfiles/-/raw/main/setup.sh)
```

Or from the **AUR** using either `yay` or `paru` up to you.

```Bash
yay/paru -S --noconfirm --needed ml4w-hyprland && ml4w-hyprland-setup
```

Finally, find link to the **Git Repo** below, or if you want head directly to the project website, click here >> [**MyLinuxForWork**](https://www.ml4w.com)

{{< github repo="mylinuxforwork/dotfiles" >}}

That’s it folks ..

Cheers !
