---
title: "WayDroid Setup Guide"
date: 2024-07-01
draft: false
description: "Set Up WayDroid on Linux"
tags: ["WayDroid", "Wayland", "Setup", "Guide", "Linux"]
---
### WayDroid in a nutshell

[**WayDroid**](https://waydro.id/) is a container-based tool that allows for launching a complete **Android** system within the Linux desktop. It does this with Linux namespaces, effectively utilizing the Linux kernel. In simple terms, namespaces are a feature that helps isolate and separate parts of a computer so that it is possible to run each part independently as if it is the only one on the computer.

If you're trying to run Android apps on Linux, WayDroid is the way to do it, and former "Android on Linux" tools like Anbox recommend it. WayDroid is compatible with a wide variety of Linux distributions and CPU architectures. Additionally, it harnesses Android's Mesa technology to enable efficient GPU pass-through from the container to the host system, which enhances the performance of graphical applications, ensuring a smooth user experience.

{{< github repo="waydroid/waydroid" >}}

### Setting Up WayDroid in No Time

**Supported Hardware**

- I) Supported CPUs :

Waydroid supports most of the common architectures (ARM, ARM64, x86 & x86_64 CPUs).

- II) Supported GPUs :

Waydroid uses Android’s mesa integration for passthrough, and that enables support to most ARM/ARM64 SOCs on the mobile side, and Intel/AMD GPUs for the PC side.

[If you have Nvidia dedicated GPU and an integrated AMD/Intel GPU, you can choose to pass Waydroid graphics only through your integrated one.

1. Waydroid only works in a Wayland session manager, so make sure you are in that session.

2. Second you will need the necessary binder modules

```Bash
paru -S binder_linux-dkms
```

3. Installing Waydroid:

```Bash
paru -S waydroid
```

Now Reboot !

4. Setting up Waydroid:

```Bash
sudo waydroid init -s GAPPS -f
```

(You might have to reboot again.)

5. Enable and start the waydroid-container service:

```Bash
sudo systemctl enable --now waydroid-container
```

Then launch Waydroid from the applications menu. For network in your Waydroid container, please check this out >> [**Network in WayDroid**](https://wiki.archlinux.org/title/Waydroid#Network)

6. To Sideload an application:

```Bash
waydroid app install $path_to_apk
```

### Register your WayDroid with Google

Run `sudo waydroid-extras`, and select **Android 11**, then the **Get Google Device ID** option, **make sure Waydroid is running and Gapps has been installed!** Copy the returned numeric ID open >> [**Device Registration Page**](https://google.com/android/uncertified/), enter the ID and register it, you may need to wait up to 10-20 minutes for device to get registered, then clear Google Play Service’s cache and try logging in!

To update WayDroid all you have to do is run the following command, keep in mind that image is well over 800MB in size...

```Bash
sudo waydroid upgrade
```

### Troubleshooting WayDroid

To fix unusable rotated apps, since some rotated for phones rather than tablets. As for other troubleshooting tips visit this link on the >> [**ArchWiki**](https://wiki.archlinux.org/title/Waydroid#Troubleshooting).

```Bash
sudo waydroid shell wm set-fix-to-user-rotation enabled
```

Hope this answers that question....
