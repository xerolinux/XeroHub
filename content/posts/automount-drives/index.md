---
title: "Automount Drives in Linux"
date: 2024-06-28
draft: false
description: "Automount All Drives in Linux"
tags: ["Drives", "Mout", "Automount", "Guide", "GDisk", "Linux"]
---
### Intro

This keeps being asked on social. So I decided to post it here.. It's all over the net but I guess either no one knows how to search or too lazy, in any case here it is...

### Gnome Disks

[Gnome Disks](https://wiki.gnome.org/Apps/Disks) has many features, like S.M.A.R.T. monitoring, partition management, benchmarking, and more, including one that might not be obvious, but is very useful: it can set drives to mount automatically at startup.

Use it to automount your new hard disk that uses Ext4, your Windows NTFS / exFAT partition, etc.

![[Image: jsnRZUU.png]](https://i.imgur.com/jsnRZUU.png)

Disks, or Gnome Disk Utility, is installed by default in many Linux distributions, including Ubuntu, Fedora, both Linux Mint Cinnamon and MATE, Xubuntu, and so on. If it's not installed, use your Linux distribution's package manager to install it - search / install gnome-disk-utility.

For each partition you set to mount automatically on startup, Gnome Disks adds an entry in your /etc/fstab file, useful for those who are not very familiar with editing /etc/fstab. That means each partition mounted on startup through Disks is available system-wide, and not just for your user.

### How to automount Disks on startup

Start by launching "Disks" from your applications menu. Choose the hard disk from the left Disks sidebar, select the partition you want to auto mount on startup, then click the button with the gears icon under it, and click `Edit Mount Options`:

![[Image: 27YPYEC.png]](https://i.imgur.com/27YPYEC.png)

In the mount options, toggle the `User Session Defaults` option (this may be called `Automatic Mount Options` on older versions) to enable the options below it, and make sure `Mount at system startup` is enabled. You can enter a name under `Display Name`. The defaults should be enough for most users, so you don't have to change anything here. After you're done, click `OK` :

![[Image: HzloKaO.png]](https://i.imgur.com/HzloKaO.png)

To test the changes, you can reboot your system or type the following command to mount all filesystems mentioned in `fstab` (since Disks sets partitions to automount on startup by adding them to `/etc/fstab`) :

```Bash
sudo mount --all
```

Hope this answers that question....


