---
title: "Fix Unbootable System"
date: 2024-06-28
draft: false
description: "Fix a Broken Update"
tags: ["Boot", "Kernel", "Grub", "Guide", "Linux"]
---
### Preface

Are you having an issue after updating your system with the message `vmlinuz-linux not found`? Watch the video below by Erik Dubois, should help you get out of that predicament ...

{{< youtube NfMbs9zzkDw >}}

### Disclaimer :

Below guide covers EXT4/XFS/Unencrypted Filesystems, for Encrypted Drives, you will have to "Google it" lol,

Anyway here's what to do...

### Mount your system to work in..

First of all boot using your XeroLinux Live boot USB and follow the steps below...

The device or partition with your Linux system on it will need to be mounted. To discover the kernel name of the storage device name, type:

```Bash
sudo fdisk -l
```

Mount the device or partition : (replace "sdXn" with your actual partition name)

![[Image: SZO4qw0.png]](https://i.imgur.com/SZO4qw0.png)

For EXT4 & XFS

```Bash
mount /dev/sdXn /mnt (Linux Filesystem)
mount /dev/sdXn /mnt/boot/efi (EFI System)
```

### Chroot into your system :

With this information, you are able to arch-chroot, and to be able to do that you need to have root permissions, so type the following command:

```Bash
arch-chroot /mnt
```

### Reinstall missing Kernel :

Now it's time to get the Kernel back in order to get the system to boot once again.. Do this now...

```Bash
pacman -S linux linux-headers
```

Finally update the system if needed...

```Bash
pacman -Syyu
```

Exit arch-chroot via `exit` command then unmount your system

```Bash
umount /mnt/boot/efi
umount /mnt
```

Now reboot all should be good...

Hope this helps
