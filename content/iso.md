---
title: XeroLinux ISO
date: 2024-08-11
description: "Download The XeroLinux ISO"
featureimage: https://i.imgur.com/ejZ1ZQv.png
---
As you can see, after thinking long and hard, I have decided to revive the Distro. Only this time it's a bit different.

{{< alert icon="fire" cardColor="#993350" iconColor="#1d3557" textColor="#f1faee" >}}
**Notice :** ISO is currently **EFI** only, will not boot on **Legacy Bios** systems. Support will be re-added soon. Project source code can be found here 👉 [**XeroLinuxDev**](https://github.com/XeroLinuxDev)
{{< /alert >}}

![XeroISO](https://i.imgur.com/ejZ1ZQv.png)

### What is it?

In short, it's just an alternative to the **XeroLinux Plasma Install** script, making it easier to install **Arch**, bypassing the need for **ArchInstall**. The ISO includes my toolkit as well as my famous **XeroLayan** rice all-in-one shot.

{{< github repo="xerolinux/xlapit-cli" >}}

You can use the included **Post-Install Toolkit**, 1st icon with my logo in the Dock, to configure it, keeping in mind that some of the features were already applied to the ISO. I have also taken the liberty of including the [**Chaotic-AUR**](https://aur.chaotic.cx) repository so it's easier for you to install **AUR** packages rather from having to compile them.

### Who ist it for?

It's for all of you out there, who prefer an easier way to install **Arch** and are fans of the **KDE** Desktop Environment, and feel like supporting my work financially while getting something in return. If you prefer not to, or can't, you can always use **ArchInstall** in combination with my **PlasmaInstall** scripts to achieve a similar result.

{{< article link="/news/xerolinux-plasma/" >}}

It will be a bit more complex, but will never cost you anything and the code will forever be made available to fork and modify to your liking.

### Included Features

As mentioned earlier in the post, some features available via the toolkit were already applied on the ISO, since it was initially created for *Vanilla Arch*. Find the list of what has already been applied below :

✅ PipeWire/Bluetooth<br>
✅ Flatpak + Overrides<br>
✅ Multithread Compiling<br>
✅ Chaotic-AUR Enabled<br>
✅ Printer Driver/Tools<br>
✅ Samba Tools and configs<br>
✅ Scanner Driver/Tools<br>
✅ Fastfetch/OhMyPosh<br>
✅ XeroLinux Layan Rice

### Issues + Fixes

- ⚠️ **Theming Issue** ⚠️

There might be a small issue with **GTK4/LibAdwaita** app theming, I couldn't find a workaround. In case you use those, you will have to Launch the toolkit from the dock, head on over to **4. Customization** select option `u` to apply the fix & update both GTK as well as KDE themes to latest versions from source.

![Fix](https://i.imgur.com/cBVO4ki.png)

The included fix only works for the default 🎨**Layan Theme**🎨, if you use another, well, you will have to ask its dev for patch, not all themes work for **GTK4/LibAdwaita** apps since Devs are mostly anti-theming.

- ⚠️ **Tailscale Issue** ⚠️

If you use [**Tailscale**](https://tailscale.com), you will need to install it via the toolkit as well. Issue is that since this is a custom distro, official installer will not be able to recognize it unless devs add it.

![TSFix](https://i.imgur.com/ZFbFfsL.png)

While I have requested this, in the meantime, you will need to launch toolkit, choose option **2. System Drivers** then >> **5. Tailscale w/XeroLinux fix** (name might change) as seen in the image above and install it from there. That's it, **Tailscale** will successfully install. Just make sure you reboot the system once it's done for the service to run.

### How can I get it?

In order to get it, please click the button below to get redirected to the **Ko-Fi Store** page where you will be able to donate however much you want starting from $6 onwards, and you will receive a confirmation e-mail, with a link to a special directory containing the ISO on [**Mega.nz**](https://mega.nz) with the Decryption key required to access it.

<div align="center">

🔐 👉 {{< button href="https://ko-fi.com/s/cf9def9630" target="_blank" >}}
XeroLinux ISO Access
{{< /button >}} 👈 🔐

</div>

All I ask for, is for you not to share it with anyone. Otherwise you will be hurting the project making it harder for me to maintain. I am only one man doing all this for you, not a team. Thank you for being supportive.

### Collaboration

While the ISO will always be offered **AS IS**, with no further major features planned, we may introduce some quality-of-life improvements along the way. The goal is to give you total freedom, allowing you to shape the Distro into something uniquely yours.

If you have any ideas on how to enhance the Distro or extend the toolkit's functionality, I'm all ears. After all, a static Distro can become stale over time. However, I’m committed to ensuring it remains versatile and not limited to a single purpose.

Let's collaborate and take this project to new heights while keeping it simple and user-friendly. Your input can make a big difference!

### Wrapping up

This project depends on you. The more support I get, the longer it will live for. I cannot, due to my situation, keep maintaining something like this for free, it costs money. Hosting, Internet, and so on. I hope you understand.

You know how to flash it to a USB, if not, just use either [**Etcher**](https://etcher.balena.io) ot **Ventoy** and off to the races you go. The choice is yours.

{{< article link="/posts/ventoy-multi-boot/" >}}

ISO boots using **Grub** not **Systemd-Boot**, simply coz I prefer it lol. I had to make a few choices. It's hard to satisfy everyone. I hope the ones I made aren't too bad. Hehe ;)

I sure hope you enjoy it, and let me know how it goes. For support feel free to join my personal and free [**Discord Server**](https://discord.gg/5sqxTSuKZu). I will do my best to help.
