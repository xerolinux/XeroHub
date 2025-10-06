---
title: "XeroLinux Fingerprint GUI"
date: 2025-10-06
draft: false
description: "Register your prints with ease on Arch"
tags: ["Fingerprint", "Arch", "ArchLinux", "XeroLinux", "Linux"]
---

{{< alert icon="fire" cardColor="#993350" iconColor="#1d3557" textColor="#f1faee" >}}
**Status :** Before you get all excited, this tool was created for **XeroLinux** no other distro. Trying on others will result in failure. However it will be opened up in the future so you can install n use it on the likes of **Debian** and **Fedora** based distros. Source code => [**Here**](https://github.com/XeroLinuxDev/xfprintd-gui)
{{< /alert >}}

### What is it

Our fingerprint tool is a handy utility created by us in **Rust**, that allows you to use your fingerprint reader to authenticate yourself quickly and securely. With this tool, you can enroll your fingerprint through a simple and intuitive GUI, which creates a digital fingerprint profile stored safely on your system. 

Once set up, it integrates with Linux's authentication framework (such as PAM), letting you log in, or authorize commands like sudo just by placing your finger on the scanner, no need to type your password every time. Setup usually involves installing a package like "fprintd," enrolling your fingerprint via command line, and enabling fingerprint authentication for your login and sudo prompts. This improves both the convenience and security of your Linux experience by using biometrics in place of or alongside passwords.

We have also taken the time to ensure you do not do anything stupid like locking yourself out of your system. There are checks in place.

### Reasons

The reason we decided to create this tool is simple, I have a **Thinkpad** laptop with a fingerprint sensor that I didn't want to go to waste, looked for an existing tool that would help with it, but alas I couldn't find one, not on the Arch repos or the **A.U.R**. There was one, but it's from almost a decade ago, making it incompatible with any of the modern scanners. 

Should I accept it and move on like so many have done in the past ? Nope, I took this as a challenge. So I sat down, and began work on the GUI. And before you ask, yes I used **ChatGPT Claude A.I** to do it. Remember I am not a developer but an ideas person. Anyway with the GUI in place I went looking for an actual developer who can help bring this idea to life. I have since found one and the rest is history...

### Usage

{{< alert icon="fire" cardColor="#993350" iconColor="#1d3557" textColor="#f1faee" >}}
**Support :** This tool uses `fprintd` on the backend. It's just a GUI wrapper for it. So sensor support might limited. There's no definitive list of what devices it does or doesn't support. So all you can do is try and see, then report your findings to the `fprintd` devs.
{{< /alert >}}

This tool has an intuitive UI, making it easy to understand and use. It has all the checks in place in order to keep it from locking you out of your system. Here's how to use it.

![main](https://i.imgur.com/WUGMuLk.png)

As you can see from the image above, this is the main screen, click on the **Enroll Fingerprint** button to begin. Note the toggles, they will not be functional until at least one print is registered. Once you have clicked the button, you will be taken to the prints registration page as seen below.

![mng](https://i.imgur.com/LoCci1h.png)

There, you select which print you want to register. You got all 5 fingers for each hand. Select the one you want to register an you will be taken to the registration page where you can either delete existing print or add new one. To register click the add button and swipe finger as many times as needed until you see the success message like so...

![nroll](https://i.imgur.com/EiR3YeU.png)

Once registered, you can go back to register more or back to main screen, where you can enable biometric authentication on either, **Login**(i), **Terminal/Sudo** or **Polkit/Prompt**. No more having to type your password over and over and over again. It's amazing and we had fun working on it.

> **(i)** : When it comes to *Login*, the **SDDM Display Manager/Greeter** currently doesn’t *natively* support fingerprint login, as a result it won't display a “scan your finger” message. Click the "BULB" icon to know more. It's a "Hack" until support is added to **SDDM**, (if ever lol).

### Credits

This tool wouldn't have been possible if it weren't for my good friend and now **XeroLinux** team member [**Synse**](https://github.com/BananikXenos). He worked tirelessly to bring life to my idea. Please give him a follow on **Github** to show support.

We will be working on new tools as time passes. Keep an eye out !

Cheers !
