# Xero T.U.I

![Xero T.U.I installing XeroLinux in a terminal](https://xerolinux.xyz/media/xero-tui.webp)

A terminal installer that turns the Arch Linux live ISO into the full XeroLinux KDE Plasma desktop, the same destination as the official ISO, with more options: auto or manual partitioning, Btrfs, ext4 or XFS, LUKS2 encryption of root or root and boot, graphics drivers for Intel, AMD, NVIDIA and VMs, ZRAM or a swap file, an extra kernel, and optional apps picked up front. It uses SDDM rather than Plasma Login Manager for compatibility. Meant for experienced Arch users.

Boot the [Arch ISO](https://archlinux.org/download/), get online, then run:

```bash
bash <(curl -fsSL https://urls.xerolinux.xyz/xeroinstall)
```
