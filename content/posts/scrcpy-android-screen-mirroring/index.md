---
title: "Scrcpy Android screen mirroring tool"
date: 2024-07-05
draft: "false"
description: A screen mirroring tool that lets you see and control your android phone from your PC
tags: ["scrcpy", "Tools", "Android", "Linux", "FOSS", "Mirroring"]
---
{{< alert "mastodon" >}}
This article was graciously contributed by [**Cylis**](https://fosstodon.org/@Cylis@mas.to).
{{< /alert >}}

### What is it?

Scrcpy is free, open-source **Android screen-mirroring** application that lets you use your Android with Scrcpy for Windows, macOS, or even Linux. But it's not the only one. Many software and applications let you control your phone or view your phone's content on other devices. However, every tool has its own flaws and shortcomings.

There is no need to root your devices since it's an open-source application. Whether you want to run Scrcpy on multiple devices, use applications on your phone, or even share files across two phones, Scrcpy is a perfect solution.

{{< youtube TDnQa_-fK4s >}}

It uses **ADB** to do things like:

🖥️ Mirror the screen wired and wirelessly<br>
📂 Copy files to your mobile with drag & drop<br>
⌨️ Control playback using your keyboard or even play games<br>
🎵 Audio forwarding<br>
📷 Mirroring as a WebCam only on Linux

### How Does Scrcpy Work?

It's a question of many.

How does **Scrcpy** work, or how to use Scrcpy on Android?

It's important to understand the working of the software. When you connect devices via Scrcpy, it will execute a server on the connected devices. As a result, the client and server will communicate over a specific protocol to run the video on the connected device screen. The client(your computer/laptop) instantly decodes the video frames and shows them as your Android's HD mirror. Whether you're using Android with a mouse or keyboard, the client and server communicate to give you an uninterrupted session.

### How To Set Up Scrcpy On Android

Software that requires rooting your Android device before installation is always tiring. With the open-source software of Scrcpy, you don't have to root your device. Although a complicated start-up process once you know it, it's very easy to install and run Scrcpy.

**Requirements :**

- Android 5.0+
- For Audio Forwarding Android 11.0+
- Enable USB debugging in Developer settings.

**Installing it :**

Install it using **Pacman** :

```Bash
sudo pacman -S scrcpy
```

### Display & Control Android On PC With Scrcpy

You can display your Android on a PC and use Scrcpy on Android with two methods: USB and Wireless. Let's discuss each.

**With USB**

Whether you're using Scrcpy for Windows 10, Linux, or macOS, here is what you need to do:

With [**USB Debugging**](https://www.microfocus.com/documentation/silk-test/200/en/silk4j-help-en/GUID-BE1EA2BA-EFF2-4B2D-8F09-4BEE0947DFB2.html) enabled, follow these steps:

* Connect your phone to your PC via USB cable.
* Confirm USB Debugging via pop-up on Device.
* Run `scrcpy` in the Terminal.

**Wireless**

To use Scrcpy on Android wirelessly :

* Connect Phone to PC and confirm USB debugging by running the `adb services` command.
* Run the `adb tcpip 5555` command to enable WiFi Debug mode then unplug the USB.
* Run the `adb connect <device IP address>` command. (The IP address can be found in settings > About Phone > IP Address)
* Run `scrcpy` in the Terminal.

### Explore Scrcpy Features Using Commands

Screen mirroring is not the only feature of Scrcpy, but there is a lot more you can do with it. We will share Scrcpy commands for running other features of Scrcpy on your PC as well.

* Recording

If you want to record the screen of Android via Scrcpy, run the following command:

```Bash
scrcpy --record myrecording.mp4
```

* Change Resolution

You can also change Scrcpy resolution when mirroring the Android screen by running the following command:

```Bash
scrcpy --max-size 720
```

There are more, but am not gonna put them all here. Just head on over to the project **Git Repo** below to see them all, report issues and even share some ideas you might have with them...

{{< github repo="Genymobile/scrcpy" >}}

### Bonus : GUI Version of SCRCPY

If you prefer a GUI based version of SCRCPY, there is one. However it's not as maintained as the official version. It uses `QT` so it works best on those types of DEs, like **KDE Plasma**, **LXQT** and so on. To install it from the AUR

```Bash
paru -S qtscrcpy
```

For more info and issues visit the project **Git Repo**

{{< github repo="barry-ran/QtScrcpy" >}}

That's it, enjoy and let us know how it works for you...
