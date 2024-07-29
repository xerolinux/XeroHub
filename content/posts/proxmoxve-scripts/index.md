---
title: "Proxmox VE Helper-Scripts"
date: 2024-07-04
draft: false
description: "Scripts for Simplifying your HomeLab"
tags: ["Proxmox", "ProxmoxVE", "Scripts", "Scripting", "HomeLab", "Automation", "Linux"]
---
This is a short one. Just letting you all know of a recent discovery of mine while I was looking into [**Proxmox VE**](https://www.proxmox.com/en/proxmox-virtual-environment/overview)

### What are they?

**Proxmox Helper Scripts**  empower users to create a Linux container or virtual machine interactively, providing choices for both simple and advanced configurations. The basic setup adheres to default settings, while the advanced setup gives users the ability to customize these defaults.

{{< youtube kcpu4z5eSEU >}}

Options are displayed to users in a dialog box format. Once the user makes their selections, the script collects and validates their input to generate the final configuration for the container or virtual machine.

{{< alert icon="fire" cardColor="#e63946" iconColor="#1d3557" textColor="#f1faee" >}}
Remember to exercise caution when obtaining scripts and automation tasks from third-party sources.
{{< /alert >}}

{{< github repo="tteck/Proxmox" >}}

### Why I like them

As you know by now, I am heavy into **Docker Containers**. Only this does not use **Docker** but rather a more isolated and lightweight environment called **LXC**, and this has provided me a very simple way to deploy them across multiple VMs. They made my life a much simpler one. I **HIGHLY** recommend them if you are trying to set up a *HomeLab* of your own. Also safer since it's all done inside VMs vs live system.

### LXC Vs. Docker

In a nutshell, **Docker** is designed for developers who want to quickly and efficiently build and deploy applications in various environments with minimal setup. On the other hand, **LXC** is more suitable for users who need a lightweight alternative to virtual machines and want more control over the operating system and hardware. For more info click >> [**Here**](https://www.docker.com/blog/lxc-vs-docker/)

### Conclusion

If you are not savvy enough in that area, they might require some learning, but don't let them overwhelm you, they are rather easy to grasp once you get the hang of things.

Have fun with them scripts. And do let me know if you have used them before, if so if they were useful or not to you. I personally love them.

Click button below to teleport to the script Database browse through them see if you find something useful that fits your needs.

<div align="center">

{{< button href="https://tteck.github.io/Proxmox/" target="_blank" >}}
Proxmox VE Helper-Scripts Database
{{< /button >}}

</div>

That’s it folks ..

Cheers !
