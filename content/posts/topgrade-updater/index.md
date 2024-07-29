---
title: "Topgrade AiO Updater"
date: 2024-06-26
draft: false
description: "All-in-One updater tool"
tags: ["Update", "All-In-One", "TUI", "Terminal", "Tools", "Linux"]
---

### Intro

Upgrading Linux has gotten much easier than it used to be. In the old days, you might upgrade certain pieces of software, but mostly you would wait until you bought the next version of your distro of choice. Then you’d install it and marvel at the upgraded software.

Package management systems have made this easy, but they can’t update every part of your system. What about Ruby Gems or packages you installed via a third-party package manager like Linuxbrew? How will you keep your configuration files synced?

![[Image: Aqqr28I.png]](https://i.imgur.com/Aqqr28I.png)

### What Is Topgrade ?

You can get a clue of just what Topgrade is meant to do by looking at its GitHub page. Its slogan, written at the top of the page, is “upgrade everything.” That’s exactly what it is meant to do.

While we’re focusing on Linux here, Topgrade also works on macOS and Windows. Topgrade is written in Rust, so it should be rather speedy. It’s also licensed under the GNU GPL 3.0, so it’s free as in libre, not just free of charge.

{{< youtube 7i4fBakD7Yw >}}

### What Does Topgrade Update ?

On Linux it will upgrade your system via its package manager, but that’s just the beginning. It will also upgrade Ruby Gems, Atom packages, Linuxbrew and nix packages, and more. It also upgrades apps installed via Snap or Flatpak. This is far from everything, but it should give you an idea.

![[Image: 5EGo5tK.png]](https://i.imgur.com/5EGo5tK.png)

Topgrade can also upgrade a large portion of your configuration files. It will upgrade your Vim or Neovim configuration if you use NeoBundle, Vundle, Plug, or Dein. If you use a Git repository for your dotfiles, it will also pull any recent changes to them.

You can also add custom commands for Topgrade to run while upgrading. This is handy if you use some custom scripts you’d like to keep automatically updated.

### Installing Topgrade

If you run Vanilla Arch, Topgrade is available via the [AUR package](https://aur.archlinux.org/packages/topgrade-bin/). Fortunately, this is fairly easy. On XeroLinux, you can install it with the following commands:

```Bash
paru -S topgrade-bin
```

### Using Topgrade

Now that Topgrade is installed, keeping your system up to date is easy. To run Topgrade’s basic update steps, just run the command:

```Bash
topgrade
```

![[Image: lwqfe3q.png]](https://i.imgur.com/lwqfe3q.png)

If you want to add some custom commands or tweak how Topgrade works, you’ll need to edit its configuration file. On Linux, this is located at `~/.config/topgrade.toml` For example, if you have a list of Git repositories you’d like to refresh, add the following to the file:

```
git-repos = [
    "~/my-repos/repo_name",
]
```

For more information on tweaking the configuration file, see the Customization section on the Topgrade **GitHub** page below.

{{< github repo="topgrade-rs/topgrade" >}}

### Conclusion

**Topgrade** gives you a ton of power when it comes to keeping your system up to date. That said, it may be overkill if you just want to keep your system up to date and secure. If you don’t install much third-party software, you may not need Topgrade.

Cheers :heart:
