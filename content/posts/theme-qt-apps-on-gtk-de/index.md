---
title: "Make KDE apps use System theme in XFCE/Gnome"
date: 2024-06-27
draft: false
description: "Theme QT Apps on GTK DEs"
tags: ["ricing", "gtk", "kde", "plasma", "themes", "qt", "linux"]
---
### Intro

As I was working on **XFCE** & **Gnome**, I noticed that since they both use **GTK3/4**, some **Qt** apps made for **KDE** like **KdenLive** did not follow the system theme. I found a guide that I will be sharing with you all...

Apps built with Q (aka KDE apps) do not look great on the XFCE4 & GNOME desktop because they don’t respect the default theme. The way to fix this is to use **Kvantum**. With it, you can set **KDE** app themes to use a similar theme to what you use.

![Shot1](https://i.imgur.com/UK5MPRI.png)

### Before we begin...

In this guide, we’ll be using the **Adapta GTK** theme for **XFCE**. We’re focusing on Adapta because it has a **Kvantum** theme that is widely available and helps blend **KDE** apps in with **XFCE4** quite well.

Before starting this guide, we highly recommend installing the **Adapta GTK** theme onto your Linux PC and enabling it as the default theme in **XFCE**.

### Installing Kvantum on Linux

To get **Kvantum** working on your Linux PC, you will need to install it alongside the management tool. To get started, open up a terminal window and install the Kvantum manager, as well as everything else necessary to use it.

**Arch Linux**

**Kvantum** is available to Arch Linux users and has been for a very long time. There is an **[AUR package](https://aur.archlinux.org/packages/kvantum-qt5-git/)**. There’s also a package in the official Arch Linux software sources, which we recommend.

To get the latest Kvantum on your Arch Linux PC, enter the following terminal command.

```Bash
sudo pacman -S kvantum
```

**Downloading Kvantum themes**

In this guide, we’re focusing on the **Kvantum Adapta** theme. However, if you want to use a different GTK theme and need a matching Kvantum theme to go with it, the best place to go is the KDE Store.

The KDE Store has tons of stuff to download, including Kvantum theme engine themes. To download a Kvantum theme, head over to the **[Kvantum page](https://store.kde.org/browse/cat/123/order/latest/)** on the KDE store. From there, look through the latest themes to download.

Once you’ve downloaded a theme, launch Kvantum Manager, select “Install/Update Theme,” and install it. Then, select “Change/Delete Theme” to start using it on your system.

### Using Kvantum to make KDE apps look better

To make your KDE apps look better on the XFCE4 desktop, start by launching “Kvantum Manager” from the app menu. If you cannot find it in the app menu, open up the XFCE4 quick launcher with Alt + F2, and enter “kvantummanager” in the launch box.

Once the Kvantum Manager app is open on the XFCE4 desktop, follow the step-by-step instructions outlined below.

**- Step 1:** Locate the “Change/Delete Theme” option in the Kvantum Manager. If you cannot find it, it is directly below the “Install/Update Theme.”

After selecting the “Change/Delete Theme” button, you will see a menu that says “Select a theme,” followed by a blank text box. Change it to “Kvdapta.”

![Shot2](https://i.imgur.com/JVEudZ1.png)

**- Step 2:** Open up a terminal window and install the Qt5ct app.

```Bash
sudo pacman -S qt5ct
```

**- Step 3:** Open up a terminal window and use the **echo** command to edit the profile file to add the environmental variable.

```Bash
echo "export QT_QPA_PLATFORMTHEME=qt5ct" >> ~/.profile
```

**- Step 4:** Log out of your XFCE 4 session and log back in.

**- Step 5:** Open up Qt5ct via the app menu. Or, launch it via the terminal with the **qt5ct** command.

![Shot3](https://i.imgur.com/v261wDF.png)

**Step 6:** Locate the “Appearance” tab. Then, find the “Style” menu. In the menu, select “kvantum.” Then, select “Apply” to apply changes.

![Shot4](https://i.imgur.com/EKMmXrF.png)

Upon applying your changes, KDE applications on XFCE 4 should be using the Kvantum theme set up earlier. This method works the same way on both **XFCE & GNOME**.

Guide by: **[AddictiveTips.com](https://www.addictivetips.com/ubuntu-linux-tips/make-kde-apps-look-better/)**
