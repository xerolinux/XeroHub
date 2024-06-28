---
title: "Nix Package Manager"
date: 2024-06-28
draft: false
description: "Use the Nix Package Manager Anywhere"
tags: ["Terminal", "Packages", "NixOS", "Nix", "Linux"]
---
### Intro

Yet again my good friend and Linux enthusiast [**ChriTitus**](https://twitter.com/christitustech/) has brought another cool Package Manager this time called **#Nix**.

{{< youtube Ty8C2B910EI >}}

Seems to be cool and easy to Install and use. Here's the written guide ported directly from his [**ChrisTitusTech**](https://christitus.com/nix-package-manager/) site..

### Installation

Install Nix using this curl command :

```Bash
curl -L https://nixos.org/nix/install | sh
```

Source

{{< github repo="NixOS/nix" >}}

Note: Recommend multi-user install if it prompts for it.

### Finding Packages

We recommend using their [**WebStore**](https://search.nixos.org/packages) to find packages to install, but make sure to click the “unstable” button as NixOS stable is a Linux Distribution few use.

![[Image: hLVPjV1]](https://i.imgur.com/hLVPjV1.png)

Or from terminal you can list all packages with `nix-env -qaP` then just `grep` what you are looking for.

Example: `nix-env -qaP | grep hugo`

### Help and Manual

You can get more details with `man nix` or `man nix-env`

### Troubleshooting

Programs not showing up in start menu

NIX stores all the .desktop files for the programs it installs @ `/home/$USER/.nix-profile/share/applications/` and a simple symlink will fix them not showing up in your start menu.

```Bash
ln -s /home/$USER/.nix-profile/share/applications/* /home/$USER/.local/share/applications/
```

Enjoy :heart:


