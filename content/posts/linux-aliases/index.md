---
title: "Linux Aliases"
date: 2024-08-27
draft: false
description: "How To Create Your Own Terminal Aliases"
tags: ["Terminal", "Alias", "Linux"]
---
### Intro

Are you sick and tired of having to type the lengthy update commands in terminal like I am ? Don't you wish there were shorter and easier ones ? Well, you are in luck. This post will cover how you can create your own easy to remember *Aliases*.

### What are aliases?

Basically, they are custom user created commands, by you, that execute various actions. However, I would highly recommend you check if you have any tools installed that have similar ones, and avoid replicating or replacing them.

{{< youtube 4v4Mcncvsac >}}

### How to create Aliases

First, before you start, you will have to know what shell you are using, as different ones use different config files. In case of **Bash** you will have to edit the `.bashrc` file found in your home directory's root. And in the case of **ZSH**, it will be the `.zshrc` file found at that same location and so on.

With that out of the way, the method is the same for both. Just open relevant file in your IDE of choice and let's begin.

![Terminal](https://i.imgur.com/Ks6e0Mn.png)

Here's how aliases are structured :

```Bash
alias shortcmd="actualcmd"
```

Update Example (Arch) :

```Bash
alias up="sudo pacman -Syu"
```

Update Example (Debian) :

```Bash
alias update="sudo apt update && sudo apt upgrade"
```

You can also use aliases to execute scripts and edit files among many many many other things. They are amazing. I use a ton of them in **XeroLinux**. To check them out visit this link >> [**XeroLinux Aliases**](https://github.com/xerolinux/xero-fixes/blob/main/conf/.bashrc).

Quick examples :

- Edit Pacman.conf

```Bash
alias npcm="sudo nano /etc/pacman.conf"
```

- Execute script :

```Bash
alias cmd="/path/to/script/sript.sh"
```

You get the idea. Now save your file, restart your terminal and test them out. The sky's the limit as how many you can create.

### Wrapping up

Using aliases makes one's Linux journey a much more pleasant one. So do not hesitate to use them. I, like everyone else get frustrated with having to memorize the ones provided by the distro am using. Especially why I test so many. That's the first thing I do when installing a distro. Never again will I go through this ordeal. Anyway I hope this post has proven useful.

That’s it folks ..

Cheers !
