---
title: "Homebrew on Linux"
date: 2024-06-26
draft: false
description: "Use Homebrew on Linux"
tags: ["Bash", "Scripts", "Tools", "Linux"]
---
### Intro

[@ChrisTitus](https://christitus.com/) brought to my attention [HomeBrew](https://brew.sh/) or Brew for short, the so called "Forgotten Package Manager" usually used on macOS... It's Distro agnostic so it can be installed and enabled on any of your choice.. On his guide he used it on [Fedora](https://getfedora.org/), I will include the Arch version here..

{{< youtube QsYEvnV-P34 >}}

**Main issues it addresses:**

* Older packages from stable Linux distributions
* Putting the installed packages in easy spots to reference them and modify them when needed.
* Using sudo can be dangerous and brew installs it to a home directory instead of systemwide without needing sudo.

{{< github repo="Homebrew/brew" >}}

### Installing Homebrew

1- AUR Package :

```Bash
yay -S brew-git
```

2- Install Script :

```Bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

3- Make brew available in terminal :

Add the following line to `~/.bashrc` or `~/.zshrc`

```Bash
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
```

### Using Homebrew :

With HomeBrew setup here are the commands :


`brew install programname` - Install programname using brew

`brew search programname` - Search for programname in brew

`brew uninstall programname` - Uninstall program

`brew update` - Updates brew

`brew upgrade program` - Updates just that one program

`brew list` - List programs in brew


Got Lost? `man brew` to look at all documentation in terminal or don’t know what a program does? `brew info programname`. Also note this package manager cannot replace main one on your distro as it can be limited as far as packages go, but it's very useful as Chris mentioned in video above

That’s it folks ..

Cheers :heart:
