---
title: "Theming Flatpaks"
date: 2024-06-27
draft: false
description: "Theme Flatpaks The Right Way"
tags: ["Flatpak", "Theming", "Ricing", "Guide", "linux"]
---
### Intro

One of the reasons why some users avoid installing Flatpak apps is that most Flatpak apps don’t change their appearance as per the current system theme. This makes the applications look out of the place in your otherwise beautiful set up.

The official way to apply GTK themes to Flatpak apps is by [installing the desired theme as a flatpak](https://docs.flatpak.org/en/latest/desktop-integration.html#theming). However, there are only a few GTK themes that can be installed as Flatpak.

This means that if you found a beautiful GTK theme, your Flatpak applications will still be using their default appearance. But wait! There is a workaround.

{{< youtube IYXlgzrZRIE >}}

## Tutorial

In this tutorial, I am going to introduce you a way to make Flatpak apps aware of external GTK themes.

To enable this functionality, users need to install the GTK themes similar to the one used in KDE (as for other distros) but also run these commands:

**- Step 1:** Give Flatpak apps access to GTK themes location

GTK themes are located in `/usr/share/themes` for all users, and in `~/.themes` for a specific user. Notice that you can’t give access to `/usr/share/themes` because according to [Flatpak Documentation](https://docs.flatpak.org/en/latest/sandbox-permissions.html#filesystem-access) they are blacklisted.

So, since all included GTK Themes in XeroLinux  are located under `/usr/share/themes` which Flatpaks cannot access we need to copy them to `~/.themes` .

Once that is done, to give all flatpak packages permission to access `~/.themes` run the following command:

```Bash
sudo flatpak override --filesystem=$HOME/.themes
```

**- Step 2:** Enable System-Wide Flatpak Override

Now we need to apply a system-wide override telling Flatpaks to use whatever GTK theme system is using, it will be applied by default on next release of XeroLinux if it hasn't been already..

Commands :

```Bash
sudo flatpak override --filesystem=xdg-config/gtk-3.0:ro
sudo flatpak override --filesystem=xdg-config/gtk-4.0:ro
```

Also sometimes that alone might not work, so you will need to set specific theme via...

```Bash
sudo flatpak override org.gnome.Calculator --env=GTK_THEME=name-of-gtk-theme
```

Once that's done you will end up with a file in the system that includes those values. Seemingly enough there is some info about that exact issue on the [Flathub iisue reporter](https://github.com/flatpak/flatpak/issues/4633)..

As you can see in the screenshot below, there is two themes available, Ant-Bloody and Orchis-dark. Copy and paste the exact theme name in the above command:

![[Image: uT6brUj.png]](https://i.imgur.com/uT6brUj.png)

This only applies to GTK3/4 based packages, for QT in most cases nothing needs to be done ![Wink](https://forum.xerolinux.xyz/images/smilies/wink.png "Wink")

Here's the Original Thread on [Manjaro Forums](https://forum.manjaro.org/t/add-out-of-the-box-flatpak-gtk-application-themes-for-kde-plasma-users/117103)... Oh and [This Thread](https://itsfoss.com/flatpak-app-apply-theme/) Too....

