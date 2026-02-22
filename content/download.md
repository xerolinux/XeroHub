---
title: Download
date: 2025-09-30
description: "Download XeroLinux"
---

# 🐧 Looking for your next Distro ?

Welcome to the official download page for **XeroLinux**, a fast, lightweight, and finely tuned Linux experience. The ISO is currently available through a small donation. This isn't a paywall or a demand, just a gentle ask, if you find value in this project, your support helps keep it alive and actively developed. It also helps me navigate the ongoing economic crisis in Lebanon. Whether you donate or not.

However, if you are unable to donate, I understand. You can get it for free using my simple custom install script.

Thank you for being here.

<div align="center">

{{< changelog >}}

</div>

---

## 📦 Choose Edition

<style>
.edition-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 3rem;
  margin: 2rem 0;
  align-items: start;
}
@media (max-width: 900px) {
  .edition-grid {
    grid-template-columns: 1fr;
  }
  .edition-box > div:has(.rounded-md), .edition-box .rounded-md {
    height: auto !important;
    min-height: unset !important;
    max-height: unset !important;
  }
}
.edition-box {
  display: flex;
  flex-direction: column;
}
.edition-box h3 {
  text-align: center;
  margin-bottom: 1rem;
  min-height: 32px;
}
.edition-box > div:has(.rounded-md), .edition-box .rounded-md {
  height: auto !important;
  min-height: unset !important;
  max-height: unset !important;
  overflow: hidden;
}
.edition-buttons {
  text-align: center;
  padding-top: 1.5rem;
  min-height: 60px;
}
.edition-buttons .btn-row {
  display: flex;
  justify-content: center;
  gap: 1rem;
}
.edition-buttons a {
  text-align: center !important;
  justify-content: center !important;
  white-space: nowrap !important;
  height: 44px !important;
  display: inline-flex !important;
  align-items: center !important;
}
.edition-box:first-child .edition-buttons a {
  width: 100% !important;
}
.edition-box:last-child .edition-buttons .btn-row {
  width: 100%;
}
.edition-box:last-child .edition-buttons a {
  flex: 1;
  width: calc(50% - 0.5rem) !important;
}
/* Discontinued Demo box */
.edition-box.discontinued {
  filter: saturate(0);
  opacity: 0.6;
}
.crossed-out-wrapper {
  position: relative;
}
.crossed-out-wrapper .skull-overlay {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  font-size: 9rem;
  opacity: 0.3;
  z-index: 5;
  pointer-events: none;
  line-height: 1;
}
.crossed-out-wrapper::before,
.crossed-out-wrapper::after {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 10;
  pointer-events: none;
}
.crossed-out-wrapper::before {
  background: linear-gradient(
    to bottom right,
    transparent calc(50% - 2px),
    #ff4444 calc(50% - 2px),
    #ff4444 calc(50% + 2px),
    transparent calc(50% + 2px)
  );
}
.crossed-out-wrapper::after {
  background: linear-gradient(
    to bottom left,
    transparent calc(50% - 2px),
    #ff4444 calc(50% - 2px),
    #ff4444 calc(50% + 2px),
    transparent calc(50% + 2px)
  );
}
.btn-disabled {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 44px;
  border-radius: 0.375rem;
  background: #555;
  color: #999;
  cursor: not-allowed;
  font-weight: 500;
  pointer-events: none;
}
</style>

<div class="edition-grid">

<div class="edition-box discontinued">

<h3 style="text-align: center;">🧪 Demo Edition (Discontinued)</h3>

<div class="crossed-out-wrapper">
<span class="skull-overlay">☠️</span>

{{< alert icon="triangle-exclamation" cardColor="#ff990030" iconColor="#ff9900" textColor="#ffcc80" >}}
- ⚠️ For VM testing only.
- ⚠️ Persistence disabled.
- ❌ Toolkit not included.
- ⚠️ No installer only Live.
- ⚠️ 100 MiB Cowspace limit.
- ❌ No GPU Drivers Just VM/FOSS.
{{< /alert >}}

</div>

<div class="edition-buttons">
<span class="btn-disabled">No Longer Available</span>
</div>

</div>

<div class="edition-box">

<h3 style="text-align: center;">💿 Unlocked Edition</h3>

{{< alert icon="check" cardColor="#00cc6630" iconColor="#00cc66" textColor="#80ffb3" >}}
- ✅ Full Calamares installer.
- ✅ 2 ISOs (Intel/AMD & nVidia)
- ✅ Post-Install Toolkit included.
- ✅ BTRFS/Encryption features enabled.
- ✅ Full community support on Discord.
- ✅ Full package manager support enabled.
{{< /alert >}}

<div class="edition-buttons">
<div class="btn-row">

{{< button href="https://ko-fi.com/s/cf9def9630" target="_blank" >}}
Ko-Fi Shop
{{< /button >}}

{{< button href="https://iso.xerolinux.xyz/crypto.html" target="_blank" >}}
Crypto Portal
{{< /button >}}

</div>
</div>

</div>

</div>

{{< alert icon="circle-info" cardColor="#6666ff30" iconColor="#9999ff" textColor="#ccccff" >}}
**🆓 Free Alternative :** Prefer to be a nerd ? So beit, use the custom [**XeroInstall Script**](https://wiki.xerolinux.xyz/xero-install/) to install it the *ArchInstall* way.
{{< /alert >}}

---
