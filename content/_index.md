---
logo: "logos/logo.png"
description: "The XeroLinux HQ"
---

<h1 align="center">🔥 XeroLinux 🔥</h1>

<div align="center">

{{< typeit 
  tag=h4
  speed=120
>}}
Discover a Distro Fueled by our Passion for GNU/Linux.
{{< /typeit >}}

</div>

<div align="center">

{{< carousel images="shots/*" aspectRatio="16-9" interval="6000" >}}</div>

<style>
.uniform-buttons a {
  width: 150px !important;
  text-align: center !important;
  justify-content: center !important;
  font-size: 1.1rem !important;
}
@media (max-width: 600px) {
  .uniform-buttons {
    gap: 0.6rem !important;
  }
  .uniform-buttons a {
    width: 105px !important;
    font-size: 0.9rem !important;
  }
}
</style>

<div class="uniform-buttons" style="display: flex; justify-content: center; gap: 6rem; flex-wrap: nowrap; margin: 2rem 0;">

{{< button href="https://wiki.xerolinux.xyz" target="_blank" >}}
{{< icon "lightbulb" >}}&nbsp; The Wiki
{{< /button >}}

{{< button href="/download/" target="_self" >}}
{{< icon "download" >}}&nbsp; Download
{{< /button >}}

{{< button href="https://github.com/XeroLinuxDev/XeroBuild" target="_blank" >}}
{{< icon "github" >}}&nbsp; Github
{{< /button >}}

</div>

## 🚀 XeroLinux: Arch, Effortlessly Refined

**XeroLinux** represents an innovative *Arch-based* distribution designed to demystify the installation process while preserving the core principles of user-driven customization. This distribution offers a thoughtful approach to Linux that balances accessibility with the renowned flexibility of **ArchLinux**.

## ✨ A Tailored Linux Experience

The distribution also provides pre-configured environments that serve as an elegant, functional starting point for you. Unlike more heavily modified, and single purpose distributions, **XeroLinux** provides a basic framework that allows you to configure and learn about your system, encouraging you to understand and shape your system's configuration.

<div align="center">

{{< youtube hj9I8UYXToY >}}

</div>

## 🎯 Designed for Your Unique Needs

Whether you're pursuing production work, gaming, or software development, **XeroLinux** offers a versatile foundation. The included [**Toolkit**](https://github.com/synsejse/xero-toolkit/) and system improvements create a refined initial environment, while leaving ample room for you to adapt and learn.

## 💜 Supporting Innovation and Community

By choosing **XeroLinux**, you will be directly helping support the project's development. The ISO offerings represent more than just software, they're a meaningful way for you to contribute to an open-source initiative during these challenging times.

**XeroLinux** embodies the true spirit of **ArchLinux**: a platform where you have the freedom to create your ideal computing environment, guided by curiosity, learning, and personal preference. ❤️‍🔥

<style>
.kofi-wrapper {
  position: fixed;
  bottom: 20px;
  right: 20px;
  z-index: 9999;
}
.kofi-btn {
  background: #794bc4;
  color: #fff;
  border: none;
  padding: 12px 20px;
  border-radius: 30px;
  cursor: pointer;
  font-weight: 600;
  font-size: 14px;
  box-shadow: 0 4px 15px rgba(121, 75, 196, 0.4);
  transition: all 0.2s;
}
.kofi-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(121, 75, 196, 0.5);
}
.kofi-panel {
  display: none;
  position: absolute;
  bottom: 60px;
  right: 0;
  width: 320px;
  height: 500px;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 10px 40px rgba(0,0,0,0.3);
}
.kofi-panel.open {
  display: block;
}
</style>
<div class="kofi-wrapper">
  <div class="kofi-panel" id="kofiPanel">
    <iframe src="https://ko-fi.com/xerolinux/?hidefeed=true&widget=true&embed=true"
      style="border:none;width:100%;height:100%;background:#1a1a2e;"
      title="Support on Ko-fi">
    </iframe>
  </div>
  <button class="kofi-btn" onclick="document.getElementById('kofiPanel').classList.toggle('open')">
    ☕ Support Us
  </button>
</div>



