# ✨ Xero Arch Installer v1.0

A beautiful, streamlined Arch Linux installer designed by XeroLinux with a modern TUI.

![Screenshot](https://i.imgur.com/vl5hMAF.png)

![Xero Arch Installer](https://img.shields.io/badge/version-1.0-blue)
![License](https://img.shields.io/badge/license-GPL--3.0-green)

## Features

- 🎨 **Beautiful TUI** - Modern interface using `gum` for clean menus
- 💾 **Flexible Disk Setup** - Support for BTRFS (with subvolumes), EXT4, XFS
- 🔒 **LUKS Encryption** - Optional full disk encryption
- 🎮 **Graphics Drivers** - Easy selection for NVIDIA, AMD, Intel, or VMs
- 🔄 **Smart Swap** - ZRAM with compression or traditional swap file
- 🚀 **Automated KDE Setup** - Runs XeroLinux KDE installer.

## Quick Start

Boot into the Arch Linux live ISO and run the following command :

```bash
bash <(curl -fsSL https://xerolinux.xyz/script/xero-install/install.sh)
```

Or step by step:

```bash
# Connect to internet (for WiFi)
iwctl

# Run installer
curl -fsSL https://xerolinux.xyz/script/xero-install/install.sh | bash
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

## Configuration Options

### 1. Installer Language

Select the interface language for the installer.

### 2. Locales

- **System Locale**: Language and encoding (e.g., `en_US.UTF-8`)
- **Keyboard Layout**: Console keyboard layout (e.g., `us`, `de`, `fr`)

### 3. Disk Configuration

- **Target Disk**: Select installation disk (⚠️ will be erased!)
- **Filesystem**: BTRFS (recommended), EXT4, or XFS
- **Encryption**: Optional LUKS2 full disk encryption

### 4. Swap

- **ZRAM**: Compressed RAM swap (recommended)
- **File**: Traditional swap file
- **None**: No swap

### 5. Hostname

System hostname (e.g., `xero-desktop`)

### 6. Graphics Driver

**Single GPU Setups :**

- **mesa-all**: All open-source drivers (safe default)
- **nvidia-open**: NVIDIA open kernel module (Turing+ GPUs)
- **nvidia-legacy**: NVIDIA proprietary (900/1000)
- **nvidia-nouveau**: NVIDIA open-source nouveau
- **amd**: AMD/ATI open-source
- **intel**: Intel open-source
- **vm**: Virtual machine drivers

**Hybrid Setups :**

- **intel-amd**
- **intel-nvidia-turing**
- **intel-nvidia-legacy**
- **amd-nvidia-turing**
- **amd-nvidia-legacy**

### 7. Authentication

User will be part of `wheel` group. So can use `sudo` out the box.

- **Username**: Your user account
- **User Password**: Password for your account
- **Root Password**: System root password

### 8. Timezone
Select your region and city for timezone configuration.

## BTRFS Subvolume Layout

When using BTRFS, the installer creates:

| Subvolume | Mountpoint | Purpose |
|-----------|------------|---------|
| @ | / | Root filesystem |
| @home | /home | User data |
| @var | /var | Variable data |
| @tmp | /tmp | Temporary files |
| @snapshots | /.snapshots | Timeshift snapshots |

## Encryption

When enabled, the installer:
1. Creates a LUKS2 encrypted container
2. Configures mkinitcpio with `encrypt` hook
3. Sets up GRUB with proper kernel parameters
4. Prompts for password at boot

## File Structure

```
xero-install/
├── install.sh          # Curl launcher script
├── xero-install.sh     # Main installer
└── README.md           # This file
```

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

### NVIDIA issues after install

```bash
# Regenerate initramfs
sudo mkinitcpio -P

# Rebuild GRUB config
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

## Customization

### Adding Packages

Modify the `install_base_system()` function to add packages to the base install.

## Version History

- **v1.0** - Initial release
  - Gum-based TUI
  - BTRFS with subvolumes
  - LUKS encryption support
  - Graphics driver selection
  - ZRAM swap support

## Credits

- [archinstall](https://github.com/archlinux/archinstall) - Inspiration and logic reference
- [gum](https://github.com/charmbracelet/gum) - Beautiful TUI components
- [XeroLinux](https://xerolinux.xyz) - Distribution and KDE configuration

## License

GPL-3.0 License - See [LICENSE](LICENSE) for details.

---

Made with ❤️ by the XeroLinux Team
