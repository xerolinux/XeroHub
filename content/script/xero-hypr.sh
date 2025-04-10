#!/usr/bin/env bash

set -euo pipefail

##################################################################################################################
# Author : DarkXero
# Website : https://xerolinux.xyz
# To be used in Arch-Chroot (After installing Base packages via ArchInstall)
##################################################################################################################

# Check if dialog, gum, and wget are installed, and install them together if missing
if ! command -v dialog &> /dev/null || ! command -v gum &> /dev/null || ! command -v wget &> /dev/null; then
    echo "dialog, gum, or wget are not installed. Installing all at once..."
    sudo pacman -Syy --noconfirm dialog gum wget
fi

# Verify Arch Linux environment
if ! grep -iq "^ID=arch" /etc/os-release; then
    dialog --title "Unsupported OS" --colors --msgbox "\nThis script requires \Zb\Z1Vanilla Arch Linux\Zn.\nExiting..." 0 0
    exit 1
fi

# Function to display a dialog and handle user response
show_dialog() {
    dialog --title "Hyprland Compatibility Check" --colors --yesno "$1 Doing so will add the \Zb\Z1XeroLinux\Zn and \Zb\Z6Chaotic-AUR\Zn repos. Make sure to select 'yay' as the AUR helper when asked for everything to work properly.\n\n\Zb\Z6Proceed at your OWN RISK!.\Zn" 0 0
    response=$?
    if [ $response -eq 0 ]; then
        echo
        clear && echo "Proceeding with the installation..."
        sleep 3
        return 0
    else
        echo
        clear && echo "Canceling the installation..."
        echo
        sleep 3
        exit 1
    fi
}

# Function to determine GPU compatibility for Wayland
check_gpu_compatibility() {
    if command -v lspci &> /dev/null; then
        GPU_INFO=$(lspci | grep -E "VGA|3D")

        if echo "$GPU_INFO" | grep -qi "NVIDIA"; then
            # Check for NVIDIA GPU compatibility (900 series and up)
            if echo "$GPU_INFO" | grep -Eqi "GTX (9[0-9]{2}|[1-9][0-9]{3})|RTX|Titan|A[0-9]{2,3}"; then
                show_dialog "\n\nYour \Zb\Z6nVidia\Zn GPU should support \Zb\Z1Hyprland WM\Zn, do you want to proceed?"
            else
                show_dialog "\n\nOlder \Zb\Z6nVidia\Zn GPU detected. Only 900 series and later support \Zb\Z1Hyprland WM\Zn."
            fi
        elif echo "$GPU_INFO" | grep -qi "Intel"; then
            # Check for Intel GPU compatibility (HD Graphics 4000 series and newer)
            if echo "$GPU_INFO" | grep -Eqi "HD Graphics ([4-9][0-9]{2,3}|[1-9][0-9]{4,})|Iris|Xe"; then
                show_dialog "\n\nYour \Zb\Z6Intel\Zn GPU should support \Zb\Z1Hyprland WM\Zn, do you want to proceed?"
            else
                show_dialog "\n\nOlder \Zb\Z6Intel\Zn GPU detected. Only HD Graphics 4000 series and newer support \Zb\Z1Hyprland WM\Zn."
            fi
        elif echo "$GPU_INFO" | grep -qi "AMD"; then
            # Check for AMD GPU compatibility (RX 480 and newer)
            if echo "$GPU_INFO" | grep -Eqi "RX (4[8-9][0-9]|[5-9][0-9]{2,3})|VEGA|RDNA|RADEON PRO"; then
                show_dialog "\n\nYour \Zb\Z6AMD\Zn GPU should support \Zb\Z1Hyprland WM\Zn, do you want to proceed?"
            else
                show_dialog "\n\nOlder \Zb\Z6AMD\Zn GPU detected. Only RX 480 and newer support \Zb\Z1Hyprland WM\Zn."
            fi
        else
            show_dialog "\n\nUnknown or unsupported GPU detected. \Zb\Z1Hyprland WM\Zn compatibility is uncertain, do you want to proceed anyway?"
        fi
    else
        show_dialog "Cannot detect GPU. 'lspci' command not found."
    fi
}

# Function to install packages
install_packages() {
    packages=$1
    sudo pacman -S --needed --noconfirm $packages || { echo "Error installing packages: $packages"; exit 1; }
}

# Main script execution
check_gpu_compatibility

# Download and run the xapi script securely
curl -fsSL https://xerolinux.xyz/script/xapi.sh -o /tmp/xapi.sh && bash /tmp/xapi.sh

# Install Hyprland and dependencies together using a single pacman command.
clear && install_packages "hyprland hypridle hyprland-protocols hyprlock hyprpaper hyprpicker hyprpolkitagent hyprsunset linux-headers pacman-contrib xdg-desktop-portal-hyprland xdg-user-dirs power-profiles-daemon"

# Enable services after package installation.
xdg-user-dirs-update && sudo systemctl enable power-profiles-daemon.service

echo "Installing Bluetooth packages..."
install_packages "bluez bluez-utils bluez-plugins bluez-hid2hci bluez-cups bluez-libs bluez-tools"
sudo systemctl enable bluetooth.service

echo "Installing other useful applications..."
install_packages "downgrade update-grub meld timeshift mpv gnome-disk-utility btop nano git rustup eza ntp most wget dnsutils logrotate gtk-update-icon-cache dex bash-completion bat bat-extras ttf-fira-code otf-libertinus tex-gyre-fonts ttf-hack-nerd ttf-ubuntu-font-family awesome-terminal-fonts ttf-jetbrains-mono-nerd adobe-source-sans-pro-fonts gtk-engines gtk-engine-murrine gnome-themes-extra ntfs-3g gvfs mtpfs udiskie udisks2 ldmtool gvfs-afc gvfs-mtp gvfs-nfs gvfs-smb gvfs-gphoto2 libgsf tumbler freetype2 libopenraw ffmpegthumbnailer python-pip python-cffi python-numpy python-docopt python-pyaudio python-pyparted python-pygments python-websockets ocs-url xmlstarlet yt-dlp wavpack unarchiver gnustep-base parallel systemdgenie gnome-keyring ark vi duf gcc yad zip xdo lzop nmon tree vala htop lshw cmake cblas expac fuse3 lhasa meson unace unrar unzip p7zip rhash sshfs vnstat nodejs cronie hwinfo arandr assimp netpbm wmctrl grsync libmtp polkit sysprof semver zenity gparted hddtemp mlocate jsoncpp fuseiso gettext node-gyp intltool graphviz pkgstats inetutils s3fs-fuse playerctl oniguruma cifs-utils lsb-release dbus-python laptop-detect perl-xml-parser appmenu-gtk-module"

# Check if GRUB is installed
if command -v grub-mkconfig &> /dev/null; then
    echo "GRUB is installed. Adding support for OS-Prober."

    # Install os-prober
    install_packages "os-prober"

    # Enable OS Prober in GRUB configuration
    if [ -f "/etc/default/grub" ]; then
        sudo sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' '/etc/default/grub'
    fi

    # Run os-prober and update GRUB configuration
    sudo os-prober && sudo grub-mkconfig -o /boot/grub/grub.cfg || { echo "Error updating GRUB configuration."; exit 1; }
else
    echo "GRUB is not installed. Skipping OS-Prober setup."
fi

# Prompt user for ML4W dot files setup
dialog --title "ML4W Dot Files" --colors --yesno "\nDo you want to apply \Zb\Z1ML4W\Zn dot files? Selecting 'Yes' will execute the Setup script from source. Selecting 'No' will result in a bone stock install.\n\nHit Yes or No to continue." 0 0

# Capture the exit status of dialog (0 for Yes, 1 for No)
response=$?

if [ "$response" -eq 0 ]; then
    echo "Applying ML4W dot files..."
    curl -s https://raw.githubusercontent.com/mylinuxforwork/dotfiles/main/setup-arch.sh -o /tmp/setup-arch.sh
    bash /tmp/setup-arch.sh
    install_packages "nwg-displays"
else
    echo "Skipping ML4W dot files setup."
fi

# Detect if running in a VM and install guest tools
echo
echo "Detecting if you are using a VM"
result=$(systemd-detect-virt)
case $result in
  oracle)
    echo "Installing Virtualbox Guest tools..."
    echo
    sudo pacman -S --noconfirm --needed virtualbox-guest-utils && reboot
    ;;
  kvm)
    echo "Installing QEmu Guest tools..."
    echo
    sudo pacman -S --noconfirm --needed qemu-guest-agent spice-vdagent && reboot
    ;;
  vmware)
    echo "Installing VMWare Guest Tools..."
    echo
    sudo pacman -S --noconfirm --needed xf86-video-vmware open-vm-tools xf86-input-vmmouse
    sudo systemctl enable --now vmtoolsd.service && reboot
    ;;
  *)
    echo "You are not running in a VM."
    ;;
esac
sleep 2

dialog --title "Installation Complete" --msgbox "\nInstallation Complete. Now exit and reboot.\n\nFor further customization, please find our Toolkit in AppMenu under System or by typing xero-cli in terminal." 0 0

# Exit chroot and reboot
clear
echo "Type exit to leave chroot environment and reboot system..."
sleep 3
