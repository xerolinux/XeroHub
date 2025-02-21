#!/usr/bin/env bash

##################################################################################################################
# Author : DarkXero
# Website : https://xerolinux.xyz
# To be used in Arch-Chroot (After installing Base packages via ArchInstall)
##################################################################################################################

# Check if the script is running as root
if [ "$EUID" -ne 0 ]; then
  dialog --title "!! Error !!" --colors --msgbox "\nThis script must be run in \Zb\Z4chroot\Zn live environment post-minimal \Zb\Z1ArchInstall\Zn. Re-run script from there.\n\nHit OK to exit." 10 60
  echo
  exit 1
fi

# Check if the script is running on Arch Linux
if ! grep -q "Arch Linux" /etc/os-release; then
  dialog --title "!! Unknown Distro !!" --colors --msgbox "\nThis script must be run on \Zb\Z1Vanilla Arch\Zn. Running it on any other Distro, even \Zb\Z6Arch-Spins\Zn might cause issues.\n\nHit OK to exit." 10 60
  exit 1
fi

# Check if dialog is installed, if not, install it
if ! command -v dialog &> /dev/null; then
  echo
  echo "dialog is not installed. Installing dialog..."
  pacman -Syy --noconfirm dialog
fi

# Function to display a dialog and handle user response
show_dialog() {
    dialog --title "Pre-Install Check" --colors --yesno "\nBy proceeding with this script you will be agreeing with my choices. It will also add the \Zb\Z1XeroLinux\Zn and \Zb\Z4Chaotic-AUR\Zn repos, incl. some quality-of-life apps.\n\n\Zb\Z4Proceed at your OWN RISK!.\Zn" 11 70
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

# Main script execution
show_dialog

# Run the command after the user clicks "OK"
bash -c "$(curl -fsSL https://xerolinux.xyz/script/xapi.sh)"
# Sleep for 3 seconds (if needed)
sleep 3

# If user agrees to proceed, run the rest of the installation steps
echo "Proceeding with the installation..."

# Function to install packages
install_packages() {
  packages=$1
  pacman -S --needed --noconfirm $packages
}

# Function to selectively install packages
selective_install() {
  packages=$1
  pacman -S --needed $packages
}

# Main menu using dialog
main_menu() {
  CHOICE=$(dialog --stdout --title ">> XeroLinux Gnome Install <<" --menu "\nChoose how to install Gnome" 11 60 4 \
    1 "Standard : ArchInstall Default Gnome Profile." \
    2 "Curated  : Xero's Curated set of Gnome packages." \
    3 "Selective: Individual package selection (Advanced).")

  case "$CHOICE" in
    1)
      install_packages "linux-headers gnome gnome-tweaks power-profiles-daemon"
      ;;
    2)
      install_packages "linux-headers evince extension-manager gdm gnome-backgrounds gnome-calculator gnome-calendar gnome-characters gnome-clocks gnome-color-manager gnome-connections gnome-terminal-transparency gnome-contacts gnome-control-center gnome-disk-utility gnome-font-viewer gnome-gesture-improvements gnome-keyring gnome-logs gnome-maps gnome-menus gnome-network-displays gnome-remote-desktop gnome-session gnome-settings-daemon gnome-shell gnome-shell-extensions gnome-system-monitor gnome-text-editor gnome-themes-extra gnome-tweaks gnome-user-share gnome-weather grilo-plugins gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-onedrive gvfs-smb gvfs-wsdd loupe nautilus rygel power-profiles-daemon simple-scan snapshot sushi tecla totem xdg-desktop-portal-gnome xdg-user-dirs-gtk nano jq xmlstarlet unrar zip unzip 7zip"
      ;;
    3)
      selective_install "linux-headers gnome gnome-tweaks power-profiles-daemon nano jq xmlstarlet unrar zip unzip p7zip"
      ;;
    *)
      if [ "$CHOICE" == "" ]; then
        clear
        exit 0
      else
        dialog --msgbox "Invalid option. Please select 1, 2, 3, or 4." 10 40
        main_menu
      fi
      ;;
  esac

  # Only enable services after package installation
  systemctl enable gdm.service && systemctl enable power-profiles-daemon.service
}

# Display main menu
main_menu

echo "Installing X.org packages..."
install_packages "xorg-apps xorg-xinit xorg-server xorg-xwayland"

echo "Installing Bluetooth packages..."
install_packages "bluez bluez-utils bluez-plugins bluez-hid2hci bluez-cups bluez-libs bluez-tools"
systemctl enable bluetooth.service

echo "Installing other useful applications..."
install_packages "downgrade brightnessctl mkinitcpio-firmware update-grub meld timeshift mpv btop rustup eza ntp most wget dnsutils logrotate gtk-update-icon-cache dex bash-completion bat bat-extras ttf-fira-code otf-libertinus tex-gyre-fonts ttf-hack-nerd ttf-ubuntu-font-family awesome-terminal-fonts ttf-jetbrains-mono-nerd adobe-source-sans-pro-fonts gtk-engines gtk-engine-murrine firefox firefox-ublock-origin ntfs-3g mtpfs udiskie udisks2 ldmtool libgsf tumbler freetype2 libopenraw ffmpegthumbnailer python-pip python-cffi python-numpy python-docopt python-pyaudio python-pyparted python-pygments python-websockets ocs-url xmlstarlet yt-dlp wavpack unarchiver gnustep-base parallel systemdgenie ark vi duf gcc yad zip xdo lzop nmon tree vala htop lshw cmake cblas expac fuse3 lhasa meson unace unrar unzip p7zip rhash sshfs vnstat nodejs cronie hwinfo arandr assimp netpbm wmctrl grsync libmtp polkit sysprof semver zenity gparted hddtemp mlocate jsoncpp fuseiso gettext node-gyp intltool graphviz pkgstats inetutils s3fs-fuse playerctl oniguruma cifs-utils lsb-release dbus-python laptop-detect perl-xml-parser gnome-disk-utility appmenu-gtk-module preload"
systemctl enable preload

# Check if GRUB is installed
if command -v grub-mkconfig &> /dev/null; then
    echo "GRUB is installed. Adding support for OS-Prober."

    # Install os-prober
    install_packages "os-prober"

    # Enable OS Prober in GRUB configuration
    sudo sed -i 's/#\s*GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' '/etc/default/grub'

    # Run os-prober and update GRUB configuration
    sudo os-prober
    sudo grub-mkconfig -o /boot/grub/grub.cfg
else
    echo "GRUB is not installed. Skipping OS-Prober support addition."
fi

echo "Detecting if you are using a VM"
result=$(systemd-detect-virt)
case $result in
  oracle)
    echo "Installing virtualbox-guest-utils..."
    install_packages "virtualbox-guest-utils"
    ;;
  kvm)
    echo "Installing qemu-guest-agent and spice-vdagent..."
    install_packages "qemu-guest-agent spice-vdagent"
    ;;
  vmware)
    echo "Installing xf86-video-vmware and open-vm-tools..."
    install_packages "xf86-video-vmware open-vm-tools xf86-input-vmmouse"
    systemctl enable vmtoolsd.service
    ;;
  *)
    echo "You are not running in a VM."
    ;;
esac

dialog --title "Installation Complete" --colors --msgbox "\nInstallation Complete. Now exit and reboot.\n\nFor further customization. Please find Toolkit in the \Zb\Z1App-Launcher\Zn under \Zb\Z4System\Zn or by typing \Zb\Z5xero-cli\Zn in terminal." 10 72

# Exit chroot and reboot
clear
echo "Type exit to exit chroot environment and reboot system..."
sleep 3
