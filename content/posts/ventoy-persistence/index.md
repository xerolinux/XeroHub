---
title: "Ventoy Persistence"
date: 2024-06-26
draft: false
description: "Use Persistence in Ventoy"
tags: ["Ventoy", "Multi-Boot", "Tools", "Linux", "USB"]
---

### Intro

Most of you might already know about the amazing tool called **Ventoy** and how amazing it is at removing the need to have more USB drives if you want to use multiple ISOs, but you might not know about how many more amazing features it has.

Today I will be showing you how to make a specific Live ISO on your Ventoy USB Drive save all the changes that you make to it.

### The Guide

Starting off you would want to have **Ventoy** installed and copy the folder from `/opt/ventoy` to your USB Drive and renaming it to `ventoy_plugins` or anything else that you might like.

![[Image: Hg7iIzd.png]](https://i.imgur.com/Hg7iIzd.png)

Then go into the `ventoy_plugins` folder open a terminal and run `sudo sh CreatePersistenceImg.sh -s 20480 -l vtoycow` this will create a file called `persistence.dat` with the size of 20GB, refer to [this](https://www.ventoy.net/en/plugin_persistence.html) article from Ventoy for different arguments for the command. After a while you will be granted with this confirmation, just hit `y` and `enter` and in a few seconds it should be done.

![[Image: 8rKKvT4.png]](https://i.imgur.com/8rKKvT4.png)

Now create a new folder called `persistence` in the root folder and move the `persistence.dat` there. Going back to the terminal run `sudo sh VentoyPlugson.sh /dev/sdx` where `x` is your USB Drive id.

![[Image: GElDr8y.png]](https://i.imgur.com/GElDr8y.png)

Just head over to the webaddress that you get from the terminal, there you will be granted with the Ventoy Plugson WebUI. Head over to the `Persistence Plugin` and click on add new and just enter the file paths to the ISO that you want and the `persistence.dat` file and make sure that it says `OK`.

![[Image: PGduHPr.png]](https://i.imgur.com/PGduHPr.png)

Now if you boot into the Xero Linux ISO any changes that you make to it should get saved.

Cheers :heart:
