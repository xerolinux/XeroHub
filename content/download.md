---
title: Download
date: 2025-09-30
description: "Download XeroLinux"
---

# 🐧 Looking for your next Distro ?

{{< alert icon="circle-info" cardColor="#ff990020" iconColor="#ff9900" textColor="#ffcc80" >}}
**Note :** Demo ISO has been retired in favor of the free **T.U.I** installer. **XeroLinux** deserves to be experienced in full !
{{< /alert >}}

Welcome to the official **XeroLinux** download page. If you're just getting started, the **ISO** is your best bet, it comes with the **Calamares** GUI installer, which makes setup a breeze, while still giving you full control over manual drive partitioning. It's available through a small donation. This isn't a paywall or a demand, but a humble ask. If you find value in this project, your support goes a long way in keeping this project alive and actively developed. It also helps me weather the ongoing economic crisis here in **Lebanon**. Every bit counts, and I truly appreciate it.

However, if you are unable to donate, I understand. The **T.U.I installer** gives you the same full **XeroLinux** experience through a much simplified and user-friendly terminal-based setup, completely free. Both paths lead to the same destination.

<div align="center">

{{< changelog >}}

</div>

---

## 📦 Choose your path

<style>
.path-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 2rem;
  margin: 1.5rem 0;
  align-items: stretch;
}
@media (max-width: 768px) {
  .path-grid {
    grid-template-columns: 1fr;
  }
}
.path-card {
  background: rgba(255, 255, 255, 0.03);
  border-radius: 12px;
  padding: 2rem;
  display: flex;
  flex-direction: column;
}
.path-card.iso {
  border: 1px solid rgba(0, 204, 102, 0.2);
}
.path-card.tui {
  border: 1px solid rgba(102, 102, 255, 0.2);
}
.path-card h3 {
  text-align: center;
  font-size: 1.25rem;
  margin: 0 0 0.5rem 0;
}
.path-label {
  display: block;
  text-align: center;
  font-size: 0.75rem;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  margin-bottom: 1.25rem;
}
.path-card.iso .path-label { color: #00cc66; }
.path-card.tui .path-label { color: #9999ff; }
.path-card h4 {
  font-size: 1rem;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  margin-bottom: 1rem;
  padding-bottom: 0.75rem;
}
.path-card.iso h4 {
  color: #00cc66;
  border-bottom: 1px solid rgba(0, 204, 102, 0.15);
}
.path-card.tui h4 {
  color: #9999ff;
  border-bottom: 1px solid rgba(102, 102, 255, 0.15);
}
.path-features {
  list-style: none;
  padding: 0;
  margin: 0;
  flex: 1;
}
.path-features li {
  padding: 0.45rem 0 0.45rem 1.75rem;
  position: relative;
  color: rgba(255, 255, 255, 0.85);
}
.path-card.iso .path-features li::before {
  content: '✓';
  position: absolute;
  left: 0;
  color: #00cc66;
  font-weight: 700;
}
.path-card.tui .path-features li::before {
  content: '✓';
  position: absolute;
  left: 0;
  color: #9999ff;
  font-weight: 700;
}
.path-warning {
  background: rgba(255, 80, 60, 0.12);
  border: 1px solid rgba(255, 80, 60, 0.3);
  border-radius: 8px;
  padding: 0.5rem 1rem;
  font-size: 0.85rem;
  color: #ff9080;
  text-align: center;
  font-weight: 600;
  margin-bottom: 1.25rem;
}
.path-badge {
  background: rgba(0, 204, 102, 0.12);
  border: 1px solid rgba(0, 204, 102, 0.3);
  border-radius: 8px;
  padding: 0.5rem 1rem;
  font-size: 0.85rem;
  color: #80ffb3;
  text-align: center;
  font-weight: 600;
  margin-bottom: 1.25rem;
}
.path-buttons {
  display: flex;
  justify-content: center;
  gap: 1rem;
  padding-top: 1.5rem;
  margin-top: 1.5rem;
}
.path-card.iso .path-buttons {
  border-top: 1px solid rgba(0, 204, 102, 0.1);
}
.path-card.tui .path-buttons {
  border-top: 1px solid rgba(102, 102, 255, 0.1);
}
.path-buttons a {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  height: 44px;
  white-space: nowrap;
  flex: 1;
  width: 100%;
}
</style>

<div class="path-grid">

<div class="path-card iso">
<h3>📀 XeroLinux ISO</h3>
<span class="path-label">Donation-based</span>
<h4>Highlights</h4>
<ul class="path-features">
  <li>Live Environment based</li>
  <li>Post-install toolkit included</li>
  <li>Dedicated <strong>Intel/AMD</strong> & <strong>nVidia</strong> ISOs</li>
  <li>Guided <strong>Calamares</strong> graphical installer</li>
  <li><strong>Sched-ext</strong> Tool for managing Schedulers</li>
  <li>Hybrid graphics optimized out of the box</li>
</ul>
<div class="path-badge">✅ Full control over disk partitioning</div>
<div class="path-buttons">

{{< button href="https://ko-fi.com/s/cf9def9630" target="_blank" >}}
Ko-Fi Shop
{{< /button >}}

{{< button href="https://iso.xerolinux.xyz/crypto.html" target="_blank" >}}
Crypto Portal
{{< /button >}}

</div>
</div>

<div class="path-card tui">
<h3>📜 XeroLinux T.U.I</h3>
<span class="path-label">Completely free</span>
<h4>Highlights</h4>
<ul class="path-features">
  <li>Same destination as the ISO</li>
  <li>Answer, confirm & you're done</li>
  <li>No-nonsense <strong>Bash</strong>-powered installer</li>
  <li>More encryption options than the ISO</li>
  <li>Simple question-based terminal setup</li>
  <li>Full <strong>XeroLinux</strong> experience at zero cost</li>
</ul>
<div class="path-warning">⚠️ Wipes entire drive — no manual partitioning</div>
<div class="path-buttons">

{{< button href="https://wiki.xerolinux.xyz/xero-install/" target="_blank" >}}
Check the T.U.I Wiki for How-To
{{< /button >}}

</div>
</div>

</div>

---
