---
title: "Flatpak Tips & Tricks"
date: 2024-06-27
draft: false
description: "Use Flatpaks To Their Fullest"
tags: ["Flatpak", "Tips", "Linux"]
---
### Intro

Slowly and steadily, Flatpak has a growing acceptance in the desktop Linux world.

It is well integrated into Fedora and many other distributions like Linux Mint, elementary, Solus, etc. prefer it over Ubuntu’s Snap.

If you love using Flatpak applications, let me share a few tips, tools, and tweaks to make your Flatpak experience better and smoother.

{{< youtube jDVCITRWGgs >}}

### Use Flathub to explore new Flatpak applications

This one goes without saying.

If you are looking for new applications in Flatpak packaging, browse the [Flathub](https://flathub.org) website.

This is the official website from the Flatpak project and it lists and distributes a huge number of Flatpak applications.

You can look for recommended apps in the “Editor’s choice” section, recently updated apps, new apps and popular apps.

![[Image: iAHc4uB.png]](https://i.imgur.com/iAHc4uB.png)


You can have the application screenshots, description, developer information, and installation instructions on the individual application webpages.

### Use Flatline extension to install Flatpak from the browser

The [Flathub](https://flathub.org) website provides command line instructions to install the application.

There is also an Install button but it doesn’t install the application for you. It downloads a `.flatpakref` file and then you’ll have to use the command line to install from the flatpakref file.

![[Image: wovEk8x.png]](https://i.imgur.com/wovEk8x.png)

If you have to use the command line ultimately, it doesn’t make sense to download the flatpakref file.

You can make things better by using Flatline. It’s a Browser extension and it makes that Install button useful by converting it into appstream link.

This way, when you click on the Install button for any application on the [Flathub](https://flathub.org) website, it will ask you to open the link in an XDG application like the Software Center.

* Grab it for Firefox -> [Firefox Add-on](https://addons.mozilla.org/en-US/firefox/addon/flatline-flatpak/)
* Grab it for Chromium Browsers -> [Chrome Extension](https://chrome.google.com/webstore/detail/flatline/cpbniogoilfagmcoipghkgnpmdglfmjm/related)

![[Image: Nsvf6WO.png]](https://i.imgur.com/Nsvf6WO.png)

This also means that you should have Fltapak support integrated into the software center.

### Manage Flatpak permissions graphically With Flatseal

Flatseal is a graphical utility to review and modify your Flatpak applications’ permissions. This makes things a lot easier than going through the commands.

![[Image: nf6PVxe.png]](https://i.imgur.com/nf6PVxe.png)

It lists all the installed Flatpak applications and shows what kind of permissions the selected application has.

You may enable or disable the permissions. Please bear in mind that disabling some permissions might impact the normal functioning of the application. You should know what you are doing.

### Apply GTK system themes to Flatpak applications

You might have already noticed that most Flatpak apps don’t change their appearance as per the current system theme.

Why? Because Flatpak apps run inside a ‘container’ and don’t have access to the host filesystem, network, or physical devices.

You can choose to install themes as Flatpak to solve this issue. However, your favorite theme might not be available in Flatpak format.

Alternatively, you can make some manual effort and force the Flatpak applications to use a given theme.  Check [This Thread](https://forum.xerolinux.xyz/thread-152.html) to know more...

### Update Flatpak apps and clean them

This is more for Flatpak unfriendly distributions like Ubuntu. If your distro doesn’t come baked in with Flatpak and you don’t have it integrated with the Software center, your installed Flatpak apps won’t be updated with system updates.

You can update all your installed Flatpak apps simultaneously with:

```Bash
flatpak update
```

![[Image: M6j3R4s.png]](https://i.imgur.com/M6j3R4s.png)

### Conclusion

Flatpak should be the one and only method to deliver apps. Please note I said "Apps". There are things that can never be delivered as Flatpaks, like DEs and WMs, among many system related, like Tweaks, Themes, Kernels etc.. So as much as we want a single method for EVERYTHING, sadly that is impossible.. Still Flatpak should overtake the likes of Snaps and AppImages in my opinion...
