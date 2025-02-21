---
title: "Pacman R7.0 Update"
date: 2024-09-15
draft: false
description: "How to update to Pacman R7.0"
tags: ["Pacman", "AUR", "Arch", "Guide", "Linux"]
---
<br />

{{< alert icon="fire" cardColor="#993350" iconColor="#1d3557" textColor="#f1faee" >}}
**Notice :** Attention Arch users, Pacman 7.0 has just landed in stable Arch's repos. However, if you use local ones, you must manually intervene.
{{< /alert >}}

### What's going on ?

Recently [**Pacman**](https://wiki.archlinux.org/title/Pacman), **Arch**'s package manager recieved a major upgrade to R7.0, which brought with it a ton of changes, some of which will require [*manual intervention*](https://wiki.archlinux.org/title/Pacman).

{{< youtube DD8d8ciqkFk >}}

### The Changes

The new major version brings many new features, including introducing support for downloading packages as a *separate user* with reduced privileges.

While this enhancement improves security, users with local repositories may need to perform manual interventions to ensure seamless operation. Here’s what it’s all about.

For those utilizing *local* repositories, the new download user might not have the necessary access permissions to the repository files. This can prevent packages from downloading correctly.

To resolve this issue, you should assign the repository files and folders to the “alpm” group and ensure that the executable bit (“+x“) is set on the directories in question.

The group (and the user) are automatically set up during the upgrade to Pacman 7.0, so if you follow the terminal’s output, you will see the following messages:

```Bash
Creating group 'alpm' with GID 946.
Creating user 'alpm' (Arch Linux Package Management) with UID 946 and GID 946.
```

Here’s how you can do it:

```Bash
sudo chown :alpm -R /path/to/local/repo
```

This command changes the group ownership of your local repository files to `alpm` group, allowing the Pacman’s download user to access them appropriately.

Additionally, you will need to merge any `.pacnew` files generated during the update. These files contain new default configurations introduced with **Pacman 7.0**. Merging them ensures you’re using the latest settings and helps prevent potential conflicts.

Now, I have written a simple command that will do that quickly and efficiantly, while enabling some hidden features if you haven't enabled them yet. **This also avoids the need to re-add any additional repos you might have had in there**.

```Bash
sudo sed -i '/^# Misc options/,/ParallelDownloads = [0-9]*/c\# Misc options\nColor\nILoveCandy\nCheckSpace\n#DisableSandbox\nDownloadUser = alpm\nDisableDownloadTimeout\nParallelDownloads = 10' /etc/pacman.conf
```

We are done with `pacman.conf`. Furthermore, **Pacman 7.0** also introduces changes to improve checksum stability for Git repositories that use `.gitattributes` files.

Consequently, you might need to update the checksums in your `PKGBUILD` files that source from Git repositories. This is a one-time adjustment to accommodate the new checksum calculation method.

### AUR Helpers

{{< alert icon="fire" cardColor="#993350" iconColor="#1d3557" textColor="#f1faee" >}}
**Heads Up :** If you use yay to install packages from AUR, be aware that after upgrading to Pacman 7.0, you’ll see an error message when trying to use it.
{{< /alert >}}

```Bash
paru/yay: error while loading shared libraries: libalpm.so.14: cannot open shared object file: No such file or directory
```

Just in case you use an **AUR** helper, you will need to either recompile it since `libalpm.so` was updated to version 15. If you are using the `-git` version, otherwise if you are using the normal or `-bin` versions you will need to wait for them to get updated. Or switch to `-git` (not very recommended), up to you.

```Bash
sudo pacman -S paru-git
```

Agree and replace one with the other. Have fun ;)

### Makepkg / Rust

A few other changes were introduced with this update, especially if you compile your own packages. One of the affected files is `makepkg.conf` which contains the flags and packager info. **Do this only if you are a package maintainer**.

Here's how you can merge the changes :

```Bash
diff -u /etc/makepkg.conf /etc/makepkg.conf.pacnew > diff.patch
```

This creates a file called `diff.patch` with the differences in a unified format, which is more readable and suitable for merging.

Apply the patch (diff) to the `makepkg.conf` file using the `patch` command:

```Bash
sudo patch /etc/makepkg.conf < diff.patch
```

Last file to be affected, is `rust.conf` under `/etc/makepkg.conf.d/`. To merge changes, follow the same steps mentioned earlier for `makepkg.conf` replacing the file path and name to the ones of `rust.conf`.

### Wrapping up

**Pacman** doesn't get updated very often and when it does, there will always be some manual intervention of sorts. Also since **AUR Helpers** kinda rely on it, if you can't wait for maintainers to update *stable* version, install `-git` one, not always the best recourse as those can break at any moment. Instead, I would highly recommend, if you really want to install packages from the **AUR**, to do it without the use of a helper, like so:

```Bash
git clone https://aur.archlinux.org/packagename.git
cd packagename/ && makepkg -si
```

Also if you are using any **GUI Packages Managers** you will also need to either recompile them or wait for them to get updated. It's the nature of Rolling release Distros.

If you want to learn more about how to use **Pacman** and become a pro, I would highly recommend [**This Awesome Guide**](https://linuxiac.com/how-to-use-pacman-to-manage-software-on-arch-linux/) by [**@Linuxiac**](https://linuxiac.com).

I hope this helps y'all...
