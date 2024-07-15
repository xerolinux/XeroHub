---
title: "Batocera On Deck - Part 1"
date: 2024-07-15
draft: false
description: "Batocera on the Steam Deck"
tags: ["Batocera", "Emulation", "Retro Gaming", "Steam Deck", "Deck", "SteamDeck", "Linux"]
---

Hey there, retro gamer! Ready to turn your Steam Deck into a time machine for classic games? That's where this guide comes in!

### Batocera

[**Batocera**](https://batocera.org) is an open-source and completely free retro-gaming distribution that can be copied to a USB stick or an SD card with the aim of turning any computer/nano computer into a gaming console during a game or permanently. Batocera.linux does not require any modification on your computer. Note that you must own the games you play in order to comply with the law.

{{< github repo="batocera-linux/batocera.linux" >}}

### Background

Let me start by answering this question, before you ask it. "What do you mean by Part 1?". Simple, this guide will be your normal run of the mill about installing [**Batocera**](https://batocera.org) on an SD-Card dual booting it with **SteamOS**.

"What will you cover in Part 2?". Well, that's the moment where you will be rolling your eyes, while you call me a weirdo. Part 2 will cover how to wipe **SteamOS** replacing it with **Batocera** on the Deck's internal SSD.

![BatDeck](https://i.imgur.com/ysod9Zp.png)

### The reason why

I for one never cared about playing Triple-A games on that thing. Maybe indie games yes, reason being, I never saw any advantage of going from high FPS to extremely low just to justify my purchase. In my eyes the Deck has always been a monster **Emulation Machine**, no more no less. That's where am gonna leave it. Say what you will, it's my Deck, so I can do with it as I please. Freedom...

Now on with the guide eh ?

### Why Batocera ?

Because who doesn’t love a good nostalgia trip? Batocera lets you play retro games on your Steam Deck without messing with your Steam library. It runs off a microSD card, so you can keep your games separate and swap systems effortlessly.

### What You Need:

Below is a list of things you will need before we proceed. I would recommend 2 cards, one you will be using and another as a backup, just in case something goes wrong.

- **MicroSD Card:** A fast U3 A2 card for smooth gameplay.
- **Batocera Image:** The image we will be using.
- **Balena Etcher:** Tool for flashing the image onto the microSD card
- **Steam Deck:** Your ultimate gaming device.

{{< youtube 0GNr6kEI7zM >}}

### Step-by-Step Guide

**1. Download Batocera:**

First things first, head over to the [**Batocera Site**](https://batocera.org) and grab the latest image for the Steam Deck. Make sure you select the correct image for your Steam Deck’s architecture – this is crucial to avoid any hiccups later on.

**2. Install Balena Etcher:**

Next up, we need Balena Etcher. This handy tool will flash the Batocera image onto your microSD card. Download it from [**Balena's Site**](https://www.balena.io/etcher), install it on your Steam Deck, and fire it up. It’s super user-friendly, so no need to sweat this part.

**3. Flash Batocera to the microSD Card:**

![Flash](https://i.imgur.com/xZ67kOl.png)

Insert your microSD card into the Steam Deck or use an external card reader if you have one. Open Balena Etcher, select the Batocera image file you just downloaded, and choose your microSD card as the target. Hit the “Flash!” button and watch the magic happen. This process might take a few minutes, so maybe grab a coffee or do a quick victory dance.

**4. Booting into Batocera:**

Once the flashing is done, insert the microSD card into your Steam Deck. Now, power on the Deck while holding the volume down button to enter the boot menu. Select the microSD card from the boot options, and voila! You’re booting into Batocera. Welcome to the retro world!

![Boot](https://i.imgur.com/NusAyt7.png)

**5. First Time Setup:**

When you boot into Batocera for the first time, there are a few housekeeping items to handle:

![Setup](https://i.imgur.com/OTIJjaa.png)

- **Connect to WiFi:** Press the Start button, navigate to Network Settings, and enable WiFi. Select your network and enter the password. You’re online and ready to go!
- **Configure Controllers:** Most controllers are supported right out of the box. Connect via USB or Bluetooth, then head to Controller Settings to map buttons if needed. Easy peasy.
- **System Language:** If you prefer a language other than English, go to System Settings and change the language. Now you can navigate in your language of choice.

**6. Adding Your Games:**

This is where the fun begins. You need to add your game ROMs:

- Connect your Steam Deck to a PC or use the built-in file manager.
- Transfer your game ROMs to the “share/roms” directory on the microSD card. You can organize them by creating subfolders for each console. Batocera will automatically detect and list your games. It’s like magic!

**7. Customizing Batocera:**

Now, let’s make Batocera your own:

- **Themes:** Go to the UI Settings to change themes and give Batocera a fresh look. There are plenty to choose from, so find one that screams “you.”
Shaders: Enhance your gaming experience with graphical shaders. Find them in the Video Settings. They can make your games look even better than you remember.
- **Emulator Settings:** Tweak individual emulator settings for optimal performance. This can make a huge difference in how smoothly your games run.

### A Proper Boot Menu

After the initial setup, you might find it annoying to hold down the volume key during boot up. We can make this experience much smoother with a boot menu called Clover.

![Clover](https://i.imgur.com/STiHnl1.png)

**Installing Clover:**

1. Ensure the Batocera microSD card is in place.
2. Boot into SteamOS and access the Steam desktop.
3. Connect to WiFi if you’re not already connected.
4. Open the Konsole terminal and type the following commands:

```Bash
cd ~/
git clone https://github.com/ryanrudolfoba/SteamDeck-Clover-dualboot
cd ~/SteamDeck-Clover-dualboot
chmod +x install-Clover.sh
./install-Clover.sh
```

5. If prompted to set a sudo password, do so and rerun the script with `./install-Clover.sh`.
6. The script will ask for your sudo password and let you choose the default OS (SteamOS is recommended).
7. The script will run automatically, setting up Clover. Once done, you’ll see a boot menu every time you start your Steam Deck, allowing you to select your desired environment.

### Troubleshooting Tips

Running into issues? Here are some quick fixes:

- **Batocera Not Booting:** Double-check that the image was flashed correctly and the microSD card is properly inserted. Sometimes it’s the simple things.
- **Controller Issues:** Make sure your controllers are fully charged and properly paired. If needed, re-map the buttons in Controller Settings.
- **Network Problems:** Restart your router or double-check your WiFi settings. Sometimes technology just needs a little nudge.
- **Slow Performance:** Consider using a faster microSD card or tweaking emulator settings for better performance.

### Bonus Tips:

- **Backup microSD:** Keep a second card with a fresh Batocera image just in case. You never know when you might need it.
- **Explore Settings:** Batocera is packed with customization options. Take some time to explore and tweak settings to your liking.
- **BIOS Files:** Some games may require BIOS files. Ensure these are placed in the correct directories for each console.

Enjoy your retro gaming adventure on the Steam Deck! With this guide, you're all set to dive into the golden age of gaming. Happy gaming!

### Wrapping It Up

Before Batocera, my Steam Deck felt like a reliable but joyless workhorse. Installing Batocera changed everything. It transformed my Deck into a retro gaming paradise, making it feel more like the fun, nostalgic handhelds I love. With the retro magic of Batocera and a proper boot menu, my appreciation for the Deck skyrocketed.

In short, Batocera brings the joy of retro gaming front and center, making everything feel delightfully vintage and new all at once.

If you are looking for a much more detailed guide, might I recommend checking either [**Wagner's Tech Talk**](https://wagnerstechtalk.com/sd-batocera/) or [**Retro Handhelds**](https://retrohandhelds.gg/batocera-on-steam-deck-setup-guide/) where I sourced most my material from.

See you in *Part 2*, in a couple of weeks when my **Steam Deck** is back with me, and have tested my methods before bringing you the guide, just so I am as accurate as possible....
