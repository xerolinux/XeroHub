---
title: "Grub Issues ?"
date: 2024-06-27
draft: false
description: "How to fix Grub with Arch-Chroot"
tags: ["repar", "chroot", "grub", "arch", "archlinux", "linux"]
---
![[Image: FlfFJ0o.png]](https://i.imgur.com/FlfFJ0o.png)

### Info

In case you are one of the affected people, below is how you can fix the issue. I have tested it and it works fine. And keep in mind that XeroLinux is basically ArchLinux so below fix will work on Arch as well as any Arch-Based distros with the exception of Manjaro that is NOT Arch. Read more on that >> [Here](https://wiki.manjaro.org/index.php/Manjaro:A_Different_Kind_of_Beast#:~:text=Manjaro%20is%20developed%20independently%20from,from%20its%20own%20independent%20repositories) <<

### Disclaimer :

Below guide covers EXT4/XFS/BTRFS Unencrypted Filesystems, for Encrypted Drives, you will have to either "Google it" lol, or check at the bottom of this guide where I posted a link to EndeavourOS' more advanced guide for Chrooting into your system... There are 2 options if first one works no need for the rest, and so on...

Anyway here's what to do...

### Mount your system to work in..

First of all; boot using Arch or XeroLinux Live boot USB and follow the steps below...

The device or partition with your Linux system on it will need to be mounted. To discover the kernel name of the storage device name, type:

```Bash
sudo fdisk -l
```

Mount the device or partition : (replace "sdXn" with your Actual partition name)

![[Image: SZO4qw0.png]](https://i.imgur.com/SZO4qw0.png)

For EXT4 & XFS

```Bash
sudo mount /dev/sdXn /mnt (Linux Filesystem)
sudo mount /dev/sdXn /mnt/boot/efi (EFI System)
```

For BTRFS

```Bash
sudo mount -o subvol=@ /dev/sdXn /mnt (Linux Filesystem)
sudo mount -o subvol=@ /dev/sdXn /mnt/boot/efi (EFI System)
```

### Chroot into your system :

With this information, you are able to arch-chroot, and to be able to do that you need to have root permissions, so type the following command:

```Bash
sudo arch-chroot /mnt
```

### Fix Grub boot loop issue :

Now you’ve chrooted into your installed system, and you are able to access your files, install packages, or alter scripts to rescue your system. to fix Grub run this in chroot...

```Bash
sudo grub-install --target=x86_64-efi --efi-directory=/boot/efi --force --recheck
```

![[Image: dfBQw4X.jpeg]](https://i.imgur.com/dfBQw4X.jpeg)

then update grub via below command

```Bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

Or if you have `update-grub` installed

```Bash
sudo update-grub
```

Exit arch-chroot via `exit` command then unmount your system n boot... [Advanced Chroot Guide](https://discovery.endeavouros.com/system-rescue/arch-chroot/2022/12/)

```Bash
sudo umount /mnt/boot/efi
sudo umount /mnt
```
