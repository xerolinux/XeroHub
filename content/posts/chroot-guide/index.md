---
title: "Chroot Guide"
date: 2024-06-27
draft: false
description: "Troubleshoot using Chroot"
tags: ["Chroot", "Troubleshooting", "Arch", "Guide", "linux"]
---
### Info

![[Image: jll2heu.png]](https://i.imgur.com/jll2heu.png)

Changing Root (Chroot) is the process of changing of the apparent disk root directory (and the current running process and its children) to another root directory. When you change root to another directory you cannot access files and commands outside that directory. This directory is called a “chroot jail”. Changing root is commonly done for system maintenance for such tasks as reinstalling GRUB or resetting a forgotten password. Changing root is often done from a LiveCD or LiveUSB into a mounted partition that contains an installed system.

### Requirements

* You’ll need to boot to another working Linux environment (for example, to a LiveCD or USB flash disk).
* Root privileges are required in order to chroot.
* Be sure that the architectures of the Linux environment you have booted into matches the architecture of the root directory you wish to enter (i.e. i686, x86\_64). You can find the architecture of your current environment by: `uname -m`
* If you need any kernel modules loaded in the chroot environment, load them before chrooting. It may also be useful to initialize your swap (`swapon /dev/<device-or-partition-name>`) and to connect to your network before chrooting.

### Mounting the device

The device or partition with the Linux system on it will need to be mounted. To discover the kernel name of the storage device name, type:

```Bash
fdisk -l
```

Create a directory where you would like to mount the device or partition, then mount it:

```Bash
sudo mkdir /mnt/xero
sudo mount /dev/device_or_partition_name /mnt/xero
```

For LUKS encrypted devices, mount won’t work, use `udisksctl` instead, first unlock the device (all commands as regular user):

```Bash
sudo udisksctl unlock -b /dev/device_or_partition_name
```

Get the device mapper name:

```Bash
ls - la /dev/mapper
```

then mount the returned mapper:

```Bash
udiskctl mount -b /dev/mapper/mapper_name
```

### Changing Root

Mount the temporary filesystems:

```Bash
cd /mnt/xero
sudo mount -t proc proc proc/
sudo mount -t sysfs sys sys/
sudo mount -o bind /dev dev/
```
Mount other parts of your filesystem (e.g. /boot, /var, /usr…) that reside on separate partitions but which you need access to. For example:

```Bash
sudo mount /dev/device_or_partition_name boot/
```

It’s possible to mount filesystems after you’ve chrooted, but it’s more convenient to do so beforehand. The reasoning for this is you’ll have to unmount the temporary filesystems after you exit a chroot so this lets you unmount all the filesystems in a single command. This also allows a safer shutdown. Because the external Linux environment knows all mounted partitions it can safely unmount them during shutdown.

If you’ve setup your network and want to use it in the chroot environment, copy over your DNS servers so that you will be connected to the network:

```Bash
cp -L /etc/resolv.conf etc/resolv.conf
```

Now chroot to your installed device or partition and define your shell:

```Bash
sudo chroot . /bin/bash
```

If you see the error, `chroot: cannot run command '/bin/bash': Exec format` error it is likely the two architectures do not match.

If you’ll be doing anything with GRUB inside the chroot environment, you’ll need to be sure your /etc/mtab is up-to-date:

```Bash
sudo rm /etc/mtab && grep -v rootfs /proc/mounts > /etc/mtab
```

If you use bash, your root $HOME/.bashrc will be sourced on login provided your ~/.bash\_profile specifies it (source ~/.bashrc). To source your chrooted, global bash configuration do:

```Bash
source /etc/profile
```

If your bash configuration doesn’t use a unique prompt, consider creating one to be able to differentiate your chroot environment:

```Bash
export PS1="(chroot) $PS1"
```

### Perform System Maintenance

At this point you can perform whatever system maintenance you require inside the chroot environment, some common examples being:

* Upgrade or downgrade packages
* Rebuild your initcpio image
* Reset a forgotten password
* Fix your /etc/fstab
* Reinstall GRUB

With this information, you are able to arch-chroot, and to be able to do that you need to have root permissions, so type the following command:

Then type the following:

```Bash
sudo arch-chroot /mnt/xero
```

Now you’ve chrooted into your installed system, and you are able to access your files, install packages, or alter scripts to rescue your system.

To make sure `arch-chroot` is working check after your users home folder ls `/home` that should give your username from the installed system.

### Exiting chroot

When you’re finished with system maintenance, exit the chroot shell:

```Bash
exit
```

Then unmount the temporary filesystems and any mounted devices:

```Bash
umount {proc,sys,dev,boot...}
```

Finally attempt to unmount your hard drive:

```Bash
cd ..umount xero/
```

If you get an error saying that '/mnt' (or any other partition) is busy, this can mean one of two things:

* A program was left running inside of the chroot.
* Or more frequently: a sub-mount still exists. For example, `/mnt/xero/usr` within `/mnt/xero`.

In the latter case, unmount the sub-mount mount point first. To get a reminder of all the current mount points, run mount with no parameters. If you still are unable to unmount a partition, use the force option:

```Bash
umount -f /mnt
```

After this you will be able to safely reboot.
