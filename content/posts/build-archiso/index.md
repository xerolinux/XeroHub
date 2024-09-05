---
title: "Build a Fresh Arch ISO"
date: 2024-09-05
draft: false
description: "Easy Guide to Building a Fresh Arch ISO"
tags: ["Arch", "ArchLinux", "ArchISO", "Linux"]
---
### Information

This we can build a fresh **Arch ISO** without having to wait for one every month. I mean we can always do that n grab it from [**ArchLinux**](https://archlinux.org/download/). Still knowing how to build a fresh one will always prove to be useful in a bind, am I right ?

<p align="center">
    <img width="500" src="https://i.imgur.com/QWqMIsr.png" alt="logo">
</p>

### Let's do this 🚀

First off we need to grab a few packages in order to be able to build the ISO.

```Bash
sudo pacman -S archiso
```

Create a `MyArch` folder anywhere, in my case I did it in `Documents`, then copy over `releng` folder from `/usr/share/archiso/configs` then `cd` into it like so :

```Bash
mkdir -p ~/Documents/MyArch
cp -rf /usr/share/archiso/configs/releng ~/Documents/MyArch/
cd ~/Documents/MyArch/
```

Now we need create two folders in our home directory or anywhere else, up to you, one called `work` for placing extracted files, another called `out` where final ISO will be located.

```Bash
mkdir ~/work && mkdir ~/out
```

Now that it's all done we can proceed to building a fresh new & updated **ArchISO**. Just use the command below and watch the magic happen.

```Bash
sudo mkarchiso -v -w ~/work -o ~/out releng
```

Finally we can delete the work directory to save space. just do `sudo rm -rf ~/work/`.

### Wrapping up

Now that we have an idea on how to build the **Arch ISO**, we can take it to another level. Yes, this is where most *Arch-Based* distros like **XeroLinux** begin. We can start modifying the `packages.x86_64` file inside `releng` folder adding more and more packages we might need to be included on the ISO out the box.

Just keep in mind that in order to get the `DE/WM` you want on the ISO a lot more work is involved. But now you get the idea. Have fun, I know I will 🚀

That's it !
