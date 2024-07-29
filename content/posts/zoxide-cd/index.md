---
title: "Zoxide the smarter cd command"
date: 2024-06-27
draft: false
description: "Terminal command for G33ks & Pros"
tags: ["terminal", "TUI", "Arch", "tools", "cd", "linux"]
---
### Intro

While browsing **YouTube** I stumbled upon a video showing off a neat little tool called **Zoxide**. It's touted to be a smarter `cd` command, inspired by `z` and `autojump`. It remembers which directories you use most frequently, so you can "jump" to them in just a few keystrokes. **Zoxide** works on all major shells.

{{< youtube aghxkpyRVDY >}}

### How to get it ?

There are 2 ways to get it, either via your Arch Linux's package manager or a CURL command. However the devs recommend the latter. I will post both below.

**- Arch's Pacman**
```Bash
sudo pacman -S --noconfirm zoxide
```

**- Recommended CURL command**
```Bash
curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
```

However you choose to get it is up to you. Anyway here's a link to their **Github** page below.

{{< github repo="ajeetdsouza/zoxide" >}}

Enjoy :heart:


