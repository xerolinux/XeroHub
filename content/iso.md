---
title: XeroLinux ISO
date: 2024-08-11
description: "Download The XeroLinux ISO"
featureimage: https://i.imgur.com/ejZ1ZQv.png
---
As you can see, after thinking long and hard, I have decided to revive the Distro. Only this time it's a bit different.

{{< alert icon="fire" cardColor="#e63946" iconColor="#1d3557" textColor="#f1faee" >}}
**Read Full Post** This time around it's not what you think. Make sure to go through the entire post before requesting ISO. Everything is explained here in detail, especially how to get it. Read on...
{{< /alert >}}

![XeroISO](https://i.imgur.com/ejZ1ZQv.png)

### What is it?

In short, it's just an alternative to the **XeroLinux Plasma Install** script, making it easier to install **Arch**, bypassing the need for **ArchInstall**. The ISO includes my toolkit as well as my famous **XeroLayan** rice all-in-one shot.

{{< github repo="xerolinux/xlapit-cli" >}}

You can use the included **Post-Install Toolkit**, 1st icon with my logo in the Dock, to configure it, keeping in mind that some of the features were already applied to the ISO. I have also taken the liberty of including the [**Chaotic-AUR**](https://aur.chaotic.cx) repository so it's easier for you to install **AUR** packages rather from having to compile them.

### Who ist it for?

It's for all of you out there who prefer an easier way to install **Arch** and **KDE**, and feel like supporting my work financially while getting something in return. If you don't feel like, or can't do that, you can always use **ArchInstall** in combination with my **PlasmaInstall** scripts to achieve the same result.

{{< github repo="xerolinux/xero-plasma" >}}

It will be a bit more complex, but in this case it will never cost you anything and the code will forever be made available to fork and modify to your liking.

### Included Features

As mentioned earlier in the post, some fetures available via the toolkit were already applied on the ISO. Find the list of what has already been applied below, just so you do not apply them again :

- PipeWire/Bluetooth
- Flatpak + Overrides
- Multithread Compiling
- Chaotic-AUR Enabled
- Printer Driver/Tools
- Samba Tools and configs
- Scanner Driver/Tools
- Fastfetch/OhMyPosh
- XeroLinux Layan Rice

**Theming Issue :**

There might be a small issue with **GTK4** app theming, I couldn't find a workaround, in case you use those, you will have to Launch my toolkt from the dock, head on over to **4. Customization** select option `g` to apply the fix. It only works for the included **Layan Theme**, if you use another well, you will have to ask its dev for patch, not all themes work for **GTK4/LibAdwaita** apps.

### How can I get it?

In order to get it, please click the button below to get redirected to the **Ko-Fi Store** page where you will be able to donate however much you want starting from $6 onwards, and you will receive a confirmation e-mail, with a link to a special directory containing the ISO with the necessary credentials to access it.

<div align="center">

{{< button href="https://ko-fi.com/s/cf9def9630" target="_blank" >}}
XeroLinux ISO Access
{{< /button >}}

</div>

The ISO will forever be offered **AS IS**, no further features will be added, simply because I still strongly believe in freedom of choice. Nothing will be forced on you no matter what. You are free to shape the Distro however you want making it truly yours.

All I ask for is for you not to share it with anyone. Otherwise you will be hurting the project making it harder for me to maintin. I am only one man doing all this for you, not a team. Thanks you for being supportive.

### Wrapping up

This project depends on you now. The more support I get, the longer it will live for. I cannot, due to my situation, keep maintaining something like this for free, it costs money. Hosting, Internet, and so on. I hope you understand.

You know how to flash it to a USB, if not, just use either [**Etcher**](https://etcher.balena.io) ot **Ventoy** and off to the races you go. The choice is yours.

{{< article link="/posts/ventoy-multi-boot/" >}}

ISO boots using **Grub** not **Systemd-Boot**, simply coz I prefer it lol. I had to make some hard choices. It's hard to satisfy everyone. I hope the ones I made aren't too bad for you. Hehe ;)

I sure hope you enjoy it, and let me know how it goes. For support feel free to join my personal and free [**Discord Server**](https://discord.gg/5sqxTSuKZu). I will do my best to help.
