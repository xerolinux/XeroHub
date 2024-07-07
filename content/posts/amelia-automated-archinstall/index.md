---
title: "Amelia Automated Archinstall"
date: 2024-07-07
draft: false
description: "Neat Project for Automating ArchInstall"
tags: ["Automation", "Bash", "Script", "Amelia", "Linux", "Arch", "ArchLinux"]
---
### Overview

Meet **Amelia** – your new best friend for installing ArchLinux! This Bash script is all about automation and ease, bringing you through the installation process with a slick **TUI** interface that’s both stylish and user-friendly.

Arch Linux is legendary for its flexibility and simplicity, but let’s face it, installing it can be a bit of a headache. That’s where **Amelia** comes in. This nifty tool mixes automation with interactivity, making the installation process a breeze without taking away any control from you, the user.

### Features

Clocking in at almost 6,000 lines of Bash brilliance, Amelia is designed for modern GPT systems. It uses the **Discoverable Partitions Specification** to automatically detect and manage partitions, saving you from the dreaded fstab editing. Seriously, who wants to manually edit fstab?

Amelia is on the cutting edge with its approach to file systems and initialization. For instance, if you’re using `ext4`, it bypasses the old `genfstab` command and lets systemd handle the necessary setup. The same goes for initramfs – systemd takes over from the old base and udev combo, streamlining everything.

But don’t worry, control freaks! Amelia keeps you in the driver’s seat with interactive, menu-driven prompts that guide you through every step.

![Amelia](https://i.imgur.com/IJqFrXI.jpeg)

### Disk Management

For handling disks, **Amelia** uses `cgdisk`, which provides a `pseudo-GUI` that’s both powerful and easy to use. It makes partition management safe and straightforward.

Amelia lets you make all the important decisions, asking for confirmation at each critical juncture. This ensures you’re always informed and in control, minimizing the risk of any unwanted surprises.

With a detailed menu system, you can personalize, configure your system, and manage disks with ease. Pick your locale, keyboard layout, and optimize your system for different desktop environments like **KDE Plasma**, **GNOME**, or **Xfce**.

Advanced users will appreciate options for kernel selection and EFI boot management. Before kicking off the installation, Amelia checks for UEFI mode, internet connectivity, and updates the system clock to keep everything in sync.

For the pros, Amelia offers features like LUKS encryption for disk partitions and customization of the pacstrap process. Depending on your level of expertise and preferences, you can choose between automatic or manual partitioning and installation modes.

### Getting Started with Amelia

Ready to dive in ? First, boot up from the **Arch** live ISO image. Once you see the shell prompt, download Amelia with this simple Curl command:

```Bash
curl -O https://gitlab.com/prism7/archery/-/raw/main/Amelia.sh
```

Make sure you’ve got a working internet connection. Then, fire up the script and follow the prompts:

```Bash
sh Amelia.sh
```

When the installation wraps up, you’ll get a confirmation screen. Reboot your computer, and voila – your shiny new Arch Linux system is ready to roll.


![[AmeliaMain]](https://i.imgur.com/21bSdkY.jpeg)


### Final Thoughts

**Amelia** is a powerhouse when it comes to installing Arch Linux. But let’s set expectations – this tool is geared towards experienced users, not beginners. Its main goal is to save time for those who already know their way around an Arch installation.

If you’re expecting a step-by-step hand-holding experience, you might be disappointed. A solid understanding of partition types and manual setup is still required, especially for disk partitioning.

I managed to set up **Arch** with a **KDE Plasma** desktop in just 20 minutes, thanks to **Amelia**. However, there were a few hiccups. We ran into issues with missing Plasma packages, with unnecessary ones being installed.

Another thing we did not like so much that we feel that might push new users away is the fact that when we selected the *regular* **Plasma** profile, it offered a selective install for every group, which we feel might overwhelm users, especially ones who have no idea what each package does.

One cool feature, however, is that **Amelia** includes ViM/NeoViM that most Devs out there might appreciate.

In summary, **Amelia** is a fantastic tool for streamlining the Arch Linux installation process. It’s a huge time-saver for seasoned users, handling much of the manual setup automatically.

For those of you still nervous about installing Arch, don’t fret – this script comes to the rescue.

For more details on Amelia, check out its **GitLab** page.

{{< gitlab projectID="53809674" >}}
