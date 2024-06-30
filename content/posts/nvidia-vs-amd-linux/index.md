---
title: "nVidia vs AMD on Linux"
date: 2024-06-30
draft: false
description: "The Age Old Debate or nVidia vs AMD on Linux"
tags: ["nVidia", "AMD", "Debate", "Linux"]
---

### Disclaimer

I've gathered some relevant information for you below, which I hope you'll find useful. Please use it at your discretion. If you perceive any favoritism, it's not intentional on my part. The goal here is to provide what best fits your needs. It won't make a difference to me what you choose; what's important is that it works for you.

The information might be incomplete due to the short notice, but it's the best I could compile. I could have made this post much longer, but I want to ensure you actually read and find value in it. So, enjoy what I've put together!

### Introduction

Choosing the right GPU for your Linux system involves weighing several factors, especially considering the evolving landscape of drivers, performance benchmarks, and software compatibility. The debate between AMD Radeon and Nvidia RTX GPUs is one of the oldest in the tech community, akin to the timeless Android vs iOS debate. Here’s a general breakdown based on recent experiences with AMD Radeon and insights into Nvidia GPUs

{{< youtube oDCRXhR5n2g >}}

### AMD Radeon : FOSS and Easy

Examining AMD GPUs on Linux reveals both their strengths and challenges. Here’s a breakdown of the pros and cons.

- **Open-Source Drivers:** AMD’s commitment to open-source drivers is a significant advantage for Linux users. Installation is straightforward, and compatibility with modern Linux distributions like Ubuntu and ArchLinux is generally robust. Gaming performance out of the box is commendable, with most titles running smoothly using these drivers.

A quote from AMD's **Forrest Norod** :

> We are absolutely committed to open [ecosystems], even open to working with customers or others that are directly competing with us in the end. That is to everybody's benefit, ourselves included.

- **Price Performance Ratio:** One of the standout features of AMD GPUs is their competitive pricing relative to Nvidia. The RX 6700 XT, for example offers excellent value for money, often providing more VRAM at a lower cost compared to Nvidia’s equivalents.

- **Gaming Experience:** For gaming enthusiasts, AMD GPUs shine brightly. Titles run seamlessly on Linux with open-source drivers, leveraging Vulkan and OpenGL without major issues. They handle high-resolution gaming admirably, although it may fall significantly behind Nvidia in raw ray tracing performance.

- **Setup and Compatibility:** Setting up AMD GPUs is straightforward with open-source drivers.

### Challenges with AMD GPUs

- [**DaVinci Resolve**](https://www.blackmagicdesign.com/products/davinciresolve) and **OpenCL:** AMD’s support for **DaVinci Resolve** can be hit or miss. While recent updates have improved compatibility, Nvidia GPUs still hold an edge in performance and reliability for professional video editing tasks due to robust CUDA support.

- **Machine Learning:** Nvidia’s dominance in machine learning tasks remains unchallenged on Linux, primarily due to superior CUDA support. Although AMD’s ROCm platform is evolving, compatibility and performance may not yet match Nvidia’s offerings for AI and deep learning applications.

- **Machine Learning & Encoding:** Challenges arise when needing specific features like hardware video encoding (VAAPI) or compatibility with proprietary software such as DaVinci Resolve. Installing bleeding-edge Mesa libraries and kernels may be necessary for optimal performance, which can complicate the setup for less experienced users.

- **OpenCL and ROCm Support:** While AMD supports OpenCL, the ecosystem is still catching up to Nvidia’s CUDA dominance in fields like machine learning and professional video editing. Updates like ROCm 6.0.x show promise but may not yet fully match Nvidia’s capabilities in these specialized areas.

### Nvidia RTX Series : Proprietary but Robust

Nvidia’s RTX GPUs offer a diverse range of advantages over AMD, but they also come with their own set of challenges. Now we are not gonna be mentioning older GTX and lower GPUs since those present even more limitations.

- **CUDA and Proprietary Drivers:** Nvidia’s proprietary drivers are highly esteemed for stability and performance on Linux, particularly in scientific computing, AI, and professional video editing where CUDA acceleration is indispensable. They generally integrate well with distributions like **Ubuntu** but may encounter occasional compatibility and stability issues, especially with newer kernel versions or specific configurations.

- **Enhanced Stability with Version 555.x:** Recent updates introduce [**Explicit Sync Explained**](https://zamundaaa.github.io/wayland/2024/04/05/explicit-sync.html) support for **Wayland** users, [**merged**](https://gitlab.freedesktop.org/wayland/wayland-protocols/-/merge_requests/90) a short while ago, enhancing stability and performance optimizations without additional configuration, although full support depends on the desktop environment like **KDE Plasma** or **GNOME**, not currently available for **Hyprland**.

- **Ray Tracing and DLSS:** Nvidia RTX GPUs excel in real-time ray tracing and AI-enhanced features such as DLSS, delivering superior visual fidelity and performance in supported games and applications. This makes them a preferred choice for users seeking cutting-edge graphics capabilities on Linux.

- **Encoder Superiority:** Nvidia’s NVENC (encoder) is widely regarded as superior to AMD’s **VCE**-based encoding solutions. This advantage is crucial for professionals relying on robust hardware video encoding capabilities, where Nvidia’s NVENC outperforms AMD’s offerings.

### Challenges with nVidia GPUs

Although Nvidia has these significant advantages over AMD, it also faces its own set of challenges:

- **Setup Complexity:** Setting up Nvidia drivers on Linux can be intricate, especially with newer kernel versions. Compatibility issues may arise, necessitating manual configuration and occasional troubleshooting for optimal performance. Despite recent updates enhancing Wayland support, Nvidia’s settings control panel remains non-functional on **Wayland**, contrasting with ongoing improvements in **AMDGPU** Linux graphics drivers.

### Conclusion: Making the Right Choice

Choosing between AMD Radeon and Nvidia RTX GPUs on Linux boils down to your specific needs and priorities:

- **Gaming and Budget:** If gaming performance and budget-friendly options are your main concerns, AMD Radeon GPUs offer compelling choices with good open-source driver support and competitive pricing.

- **Professional Applications:** For professionals needing CUDA support for applications like DaVinci Resolve or extensive machine learning tasks, Nvidia RTX GPUs provide superior performance and reliability, albeit with a more complex setup process.

- **Future Prospects:** AMD’s continuous improvement with open-source drivers and updates like ROCm 6.0.x suggest promising developments for broader compatibility and performance gains. Nvidia’s established dominance in CUDA and advanced features ensures robust support for demanding professional workflows.

In conclusion, whether you lean towards AMD Radeon for its open-source ethos and gaming prowess or Nvidia RTX for CUDA-driven performance and advanced graphics capabilities, understanding these nuances is crucial for making an informed decision on your next GPU purchase for Linux.

### Data Links

Since I do not have the hardware myself to test and provide the data some of you out there might want to look at, below are some relevant links.

- [**AMD vs nVidia Gaming Benchmarks**](https://www.phoronix.com/review/august-2023-linux-gpus/2)
- [**Nvidia vs AMD: GPUs in Machine Learning**](https://www.quora.com/Which-is-a-better-GPU-for-machine-learning-AMD-or-NVIDIA)
- [**Nvidia nVenc vs AMD VCE**](https://www.tomshardware.com/news/amd-intel-nvidia-video-encoding-performance-quality-tested)
