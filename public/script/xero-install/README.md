# ✨ Xero Arch Installer v1.7

A beautiful, streamlined Arch Linux installer designed by XeroLinux with a modern TUI.

![Screenshot](https://i.imgur.com/vl5hMAF.png)

![Xero Arch Installer](https://img.shields.io/badge/version-1.7-blue)
![License](https://img.shields.io/badge/license-GPL--3.0-green)

## Features

- 💾 **Flexible Disk Setup** - Support for BTRFS, EXT4, and XFS
- 🔒 **LUKS2 Encryption** - Optional encryption with root-only or root+boot
- 🎮 **Graphics Drivers** - Easy selection for NVIDIA, AMD, Intel, or VMs
- 🔄 **Smart Swap** - ZRAM with compression or traditional swap file
- 🚀 **Automated KDE Setup** - Runs XeroLinux KDE installer.

## Quick Start

Boot into the Arch Linux live ISO and run the following command :

```bash
bash <(curl -fsSL https://urls.xerolinux.xyz/xeroinstall)
```

## What Gets Installed

### Base System

- Linux kernel + headers
- GRUB bootloader
- Essential system utilities
- NetworkManager

### After Base Install

The installer automatically runs the XeroLinux KDE script which installs:

- KDE Plasma Desktop
- XeroLinux curated applications
- System tools and utilities
- Optional: Xero-Layan theme

## Requirements

- Arch Linux live ISO (latest recommended)
- Internet connection
- UEFI or BIOS system
- At least 20GB disk space

## Troubleshooting

### No internet connection
```bash
# For WiFi
iwctl
[iwd]# device list
[iwd]# station wlan0 scan
[iwd]# station wlan0 get-networks
[iwd]# station wlan0 connect "NetworkName"

# For Ethernet
dhcpcd
```

### Installer won't start

```bash
# Install gum manually
pacman -Sy gum

# Run installer directly
bash xero-install.sh
```

## Customization

### Adding Packages

Modify the `install_base_system()` function to add packages to the base install.

## Version History

| Version | Highlights |
|---------|------------|
| **v1.7** | Manual partitioning mode, dual-boot support, SDDM or Plasma Login Manager choice |
| **v1.6** | Parallel downloads option, pacman tweaks, misc bug fixes, faster installs |
| **v1.5** | Larger boot partition, trimmed package list, simplified connectivity check |
| **v1.4** | All package prompts merged into one screen, leaner default selection |
| **v1.3** | LUKS2 encryption, choose root-only or root+boot encryption scope |
| **v1.0** | Initial release — BTRFS, LUKS, GPU drivers, ZRAM |

## Credits

- [archinstall](https://github.com/archlinux/archinstall) - Inspiration and logic reference
- [gum](https://github.com/charmbracelet/gum) - Beautiful TUI components
- [XeroLinux](https://xerolinux.xyz) - Distribution and KDE configuration

## License

GPL-3.0 License - See [LICENSE](LICENSE) for details.

---

Made with ❤️ by the XeroLinux Team
