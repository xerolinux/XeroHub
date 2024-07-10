---
title: "XeroLinux Plasma Install"
date: 2024-07-08
draft: false
description: "Get XeroLinux Back With Our Tool"
tags: ["XeroLinux", "Distro", "Script", "Toolkit", "Plasma", "Guide", "Arch", "Linux"]
---
{{< youtube v0UPif52i5A >}}

### Introduction

I want to begin by thanking everyone who has shown the Distro all the the love. Without whom it wouldn't have lasted as long as it did. As well as the rest of the projects present and future.

**Clarification :**

> Intention of the **PlasmaInstall** script was not to replace **ArchInstall** but to fix its **Plasma** profile while extending it further nothing more. If you want **Gnome**, **XFCE** or any other DE/WM for that matter, existing profiles are fine. The only other one that is messed up is the **Hyprland** one but alas since I don't use it I have no idea how to fix it. However, the Toolkit can be used on any DE or WM it's agnostic.

Now, this guide complements the above video, they are to be used together, I will try not to ramble on too much. Some of you have asked the question, "is the Distro really gone ?" I would like to say, no, not really. Let me explain a bit before going ahead with written guide. Since it was nothing but **ArchLinux** + Customized/riced **KDE Plasma** nothing more, one could achieve the same result by using my **Plasma Install** script.

Yeah we can easily get **XeroLinux** back in all its glory, it's just no longer an ISO with **Calamares**. It's still easy to install thanks in part to the *infamous* **ArchInstall** script then my own. So all is not lost.

In this super detailed guide I will be showing off how it can be done.

![XeroLayan](https://i.imgur.com/VA2tycb.jpeg)

### What we need

Let's start off by knowing what we need to get started. First off, we will need the latest version of the >> [**ArchLinux ISO**](https://archlinux.org/download/), a USB stick to burn ISO onto, we can either use >> [**Balena Etcher**](https://etcher.balena.io/#download-etcher) or the highly recommended >> **Ventoy** linked below.

{{< article link="/posts/ventoy-multi-boot/" >}}

Those are the essentials. As to my **Plasma Install** script will get to that a bit later down the line. Once we got everything, we shall begin...

### Part 1 - Installing ArchLinux

Ok, so now that we have burned the ISO to the USB using either tools, boot the system we want to install it on using it. Am not gonna go through showing you how, you should know that by now lol.

![ArchISO](https://i.imgur.com/RO64NWD.png)

**Note :**

> This guide expects you to be connected to the internet via ethernet. If you aren't and need to connect over WiFi, you can follow guide on the [**ArchWiki**](https://wiki.archlinux.org/title/Installation_guide#Connect_to_the_internet)

- **Remote Install via SSH**

Now, unlike other guides out there, I will be showing how we can use **SSH** to do the installation remotely, which will make things much easier. All we need is a secondary PC running **Linux**. If none is available, this part can be skipped.

Ok, first things first, we need to set a password to the *root* user. We do it by typing the following command in the TTY, like this :

```Bash
passwd
```

Now we type our temporary password & confirm it. Once that's done, we need to get the machine's **IP Address**, we do that by running this command :

```Bash
ip a
```

Once we have it, all we need to do to connect to the machine is the following command :

```Bash
ssh root@ipaddress
```

We confirm by typing `yes`. That's it, now we are connected to the machine remotely, so we can now easily copy paste comands for a much simpler install...

- **ArchInstall Script**

Once connected, first thing we will have to do is, make sure we have latest version of **ArchInstall**. We do that by running the following command :

```Bash
pacman -Syy archinstall && archinstall --advanced
```

Now some of you might be asking me, "why the `--advanced` flag ?", to which I answer, simply because devs still hide the *parallel downloads* behind it for whatever reason. It's fine at least now you know.

![ArchInstall](https://i.imgur.com/OVzwVYt.png)

Ok, now that we have the installer running, am not going to go through each and every option one by one, just the important ones. Those are explained in the video. Am also not gonna bother with *manual partitioning* since the guide is intended for single OS easy install.

That's why we will be using the **Best Guess** option, carefully selecting the correct drive we want install **ArchLinux** onto.

{{< alert icon="fire" cardColor="#e63946" iconColor="#1d3557" textColor="#f1faee" >}}
I will not be held responsible for any data loss resulting from selection of the wrong drive. **BE VERY CAREFUL HERE**.
{{< /alert >}}

Anyway, let's make sure we skip the parts I mentioned in the video, since everything will now be done **Post-Install** via my Toolkit. Don't forget to set parallel downloads to as many as you like for faster downloads. Also as mentioned, we do not need to enable any extra repos like *multilib* since my script will do that for us later on.

Now once everything is configured and set, hit install, sit back, grab a cup of Tea/Coffee and watch it do its thing. Might take a while it all depends on Internet connection...

### Part 2 - Installing Plasma

Once that's all done, we will be prompted if we want to `chroot` into our new install, we answer with yes of course since we still have no DE yet.

{{< alert icon="fire" cardColor="#e63946" iconColor="#1d3557" textColor="#f1faee" >}}
**User Caution**. We do not recommend to blindly execute scripts without inspecting them first.
{{< /alert >}}

To download and inspect script, use the following command, open it in your IDE of choice and inspect it. Only run it when you trust the code.

```Bash
wget https://tinyurl.com/PlasmaInstall
```

Once you trust it, you can move on. Now, depending on the method that was used, `ssh` or not, we either copy paste the command below or type it manually :

```Bash
bash -c "$(curl -fsSL https://tinyurl.com/PlasmaInstall)"
```

This will execute the script. Just go through the prompts. I would **Highly** recommend option **3) Xero's Curated Set Of Plasma Packages** to avoind any future headaches. I went through all groups with a fine tooth comb as the saying goes making sure we get the best experience. But that's not to say we cannot select any of the other options, it's all up to you in the end.

![Script](https://i.imgur.com/TOZNp4j.png)

At the end, script will prompt us if we want to enable the **XeroLinux Repo** and install the Toolkit, to which we answer with yes, since we will be using it to set everything up later on.

You will notice that, the *multilib* repo was enabled as well. I made sure of that since most newcomers forget to do it. It's an essential repo required for the likes of **Steam**, and various drivers.

Finally, for now at least, once script is done, we will be prompted to exit and reboot the system. We do that by typing `exit` then `reboot`, and that's it for this part anyway...

### Part 3 - Setting up the system

If all went smoothly, we should now be greeted with `SDDM`, **KDE**'s login page. I would recommend **Plasma X11** over **Wayland**, at least for now. Yes, my script still includes **X11** for compatibility. I will not get rid of it any time soon, at least not until I feel that more apps are ready for **Wayland**.

Once logged in, there are a few things we need to take care of first. Open Terminal, as shown in video, and update the system

```Bash
sudo pacman -Syyu
```

Then we launch the **XeroLinux Post Installation Toolkit** from the AppMenu, under **System**. That's what we will be using from here on in.

![XLAPiT](https://i.imgur.com/JuWceYE.png)

It's up to you to discover all the options, that's why I did not mention them all in video, nor will I here. The whole point of this guide is how to get **XeroLinux** back not to set up the system from A to Z.

- **1 : System Setup**

There's nothing to do here except select **Install 3rd-Party GUI Package Manager(s)** or **Add & Enable the ChaoticAUR Repository**, since my **Plasma Script** took care of the rest for us. Neat eh ?

**Note :**

> I would highly recommend you enable the **Chaotic AUR** repo, if you install a lot of packages from the **AUR**, to avoid having to compile them.

- **2 : System Drivers**

This is the part where you select drivers you need for our hardware. Am not going to help you here. All you need to know was mentioned in the video. Just know that selecting the wrong ones will break the system, so that's where you need to understand what works for you.

- **4 : System Customization**

Now we jump to Customization section. Just select option **x. XeroLinux's Layan Plasma 6 Rice**, enter your `sudo` password, and watch it do its thing.. Once it's done, we will be prompted to reboot. Use the AppMenu to do that..

**Note :**

> If you have selected to enable the **Chaotic AUR** repos, install will go fast. If not it will take a bit, while it compiles some packages from the **AUR**.

### Final words

That's it boys n girls. We just got **XeroLinux** back ! The rest is up to you. Go through the toolkit see if you find anything useful. If you encounter any issues or have any questions, feel free to contact me on either **Fosstodon** or **Discord**, or even in the video comments section.

I will do my best to answer. Keep in mind that I might not have all the answers, simply because I only have the hardware I have, might be different than yours, so can't know what works on something I do not own. Though I am and always will open to suggestions...

{{< github repo="xerolinux/xero-plasma" >}}

Use the repo above to report any issues with **PlasmaInstall**, and I will get to them as soon as I can. You can also request features to be added there too..

If you want features to be added to the Toolkit, or have any issues to report, feel free to do so on the repo below. I will do my best to get to them...

{{< github repo="xerolinux/xlapit-cli" >}}

Best of luck !!!!
