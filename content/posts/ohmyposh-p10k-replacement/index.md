---
title: "Oh My Posh Prompt"
date: 2024-07-08
draft: false
description: "A beautiful prompt for your $hell"
tags: ["Prompt", "Shell", "ZSH", "Bash", "OhMyZsh", "OhMyPosh", "Linux"]
---

{{< youtube 9U8LCjuQzdc >}}

### Some information

[**Oh My Posh**](https://ohmyposh.dev/) is a custom prompt engine for any shell that has the ability to adjust the prompt string with a function or variable. It’s beautiful, elegant and intuitive; if you use git from the command line it will be great for you.

It has several predefined themes that allow you to customize your prompt in a matter of seconds, it is also possible to create your own theme, it is compatible with BASH, PowerShell, CMD, Fish, Zsh and nushell is developed in golang and can be installed on **GNU/Linux**, **MacOS**, **Windows** and **Termux** (Android).

![Prompt](https://i.imgur.com/jjSKX0P.png)

### Installing Oh My Posh

In this guide we will be doing it on **ArchLinux** as is the norm. However it is possible to install on any other Distro, The package is available on the **AUR** so we will be installing it from there. Remember that if you have enabled the **ChaoticAUR** Repo you can use *pacman* instead. We have written an article on you can do that linked below.

{{< article link="/posts/chaotic-aur/" >}}

With that out of the way. now we can go ahead and install it with :

```Bash
paru -S oh-my-posh-bin
```

Now that it is installed, we need to activate it. In the video above, it was shown on `.zshrc` but the same can be done for `.bashrc`. Worry not though, I will be showing both. But before we do that, unlike video, we are not going to create a custom config, you are free to do so, will link you to the project **Git** at the end of this post where you can follow a more in-depth tutorial. We will be keeping it simple here.

So let's grab the one we like from >> [**OMP Theme Repo**](https://ohmyposh.dev/docs/themes)

![Aliens](https://i.imgur.com/OL0pbr3.png)

![NightOwl](https://i.imgur.com/EZmvwxa.png)

To grab it we will have to create the folder where we will be storing our selected config. We can do it either via our favorite file manager or Terminal. Since we are on **Arch** we gonna be **Terminal Ninjas** lol...

```Bash
mkdir -p "$HOME/.config/ohmyposh"
```

Now we need to selec the *Theme/Config* and put it there. For this example we will be using **Dracula**. Replace it with the one you have chosen from the link above.

```Bash
curl -o "$HOME/.config/ohmyposh/dracula.omp.json" https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/dracula.omp.json
```

Ok, so now that we have our config, we need to *Activate* it.

For **Bash** we will have to edit our `.bashrc` by adding the following line to it :

```Bash
eval "$(oh-my-posh init bash --config $HOME/.config/ohmyposh/dracula.omp.json)"
```

As for **ZSH** we will have to edit our `.zshrc` by adding the following line to it :

```Bash
eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/dracula.omp.json)"
```

That's it ! Now if you had a shell/terminal window open, relaunch it n see **Oh My Posh** in action !!!!

![Preview](https://i.imgur.com/GJiIrxm.png)

Oh, I forgot to mention that it also has its own set of commands * flags you can use. For example did you know that even if you have installed it from the **AUR/ChaoticAUR**, where sometimes they lag behind, you can update it using an internal command ? Here's how, might need to run with `sudo` :

```Bash
oh-my-posh upgrade
```

Here's a list of all Flags/Commands :

![Commands](https://i.imgur.com/DX1x5gP.png)

**Note**

> In case you were using the now on Life Support **Powerlevel10k**, as shown in the video, remove any mention of it from either `.bashrc` or `.zshrc`.

### Closing words & thoughts

It's a shame to see a project like **Powerlevel10k** slowly die. But where one goes others are born from their ashes. Now **THAT**'s the beauty of Open Source.

![Toolkit](https://i.imgur.com/tWgYv7k.png)

As you can see from the image above, for those of you out there using the **XeroLinux Post Install Toolkit**, we added the option that will do everything mentioned in this guide automatically for you.

Keep in mind that this only applies to **Bash**, for anyone who prefers **Fish** that will always be *Vanilla* as for those of you, who, like myself love **ZSH**, well it is included with option **4. ZSH All-in-one w/OMP**...

{{< github repo="xerolinux/xlapit-cli" >}}

There's nothing to say now, except that this project is awesome, I love it and hope it lives long an prosper. Now as mentioned earlier if you want to create your very own config, just head on over to the project's **Git** below or check out the >> [**OMP Docs**](https://ohmyposh.dev/docs/)

{{< github repo="JanDeDobbeleer/oh-my-posh" >}}

That’s it folks ..

Cheers !
