---
title: "Ollama A.I"
date: 2024-09-20
draft: false
description: "Run A.I. Locally On Your Computer With Ollama"
tags: ["AI", "Ollama", "Assistant", "Linux"]
---

### Information

[**Ollama**](https://ollama.com) is a tool that allows you to run and manage *A.I.* models locally on your own machines, providing privacy and control without relying on *cloud-based* services. While it works across multiple platforms, it integrates smoothly into any **Linux** workflow.

{{< youtube J6s0n1FhXRo >}}

### Installation

Installing is easy, it can be done in multiple ways, that I will show you here. In the video above my good friend and brother [**DistroTube**](https://www.youtube.com/@DistroTube/videos) goes through the motions on **ArcoLinux** an **Arch-Based** distro. Here, I will expanding on that just a little, while including most of the commands used.

First we will need to install the **Ollama Engine**...

- Platform-Agnostic (Recommended)

```Bash
curl -fsSL https://ollama.com/install.sh | sh
```

- ArchLinux (All Spins)

```Bash
sudo pacman -S ollama && sudo systemctl enable --now ollama
```

Now that we have the engine installed, it's time to grab the model we want to use with it, since without one it will not work properly. There are quite a few varying in size, be mindful of that.

We can select model(s) from [**This Link**](https://github.com/ollama/ollama?tab=readme-ov-file#model-library), once we have it we use the following command to install and run (using llama3.1 in this example)...

```Bash
ollama run llama3.1
```

Some models are larger than others, reaching up to 232GB !!! Also the bigger the model is the more powerful your machine should be to handle it. Please keep that in mind before diving too deep into it.

<p align="center">
    <img src="https://i.imgur.com/uIJ7AO4.png" alt="shot">
</p>

Oh and as mentioned by **DT** in the video, you can take it to the next level by customizing it, making it react using different personas, like **Mario** or any of the available ones. This is just a quirk not very useful. If you want to know how, check it out on project's **Github**

{{< github repo="ollama/ollama" >}}

### Wrap up

That's it. There's nothing to it. A.I. is where the world is headed so I thought I'd share this with y'all. It's fun to try new things, keeping up with technology. If you have any questions or issues please report them to the Devs upstream.

Cheers !
