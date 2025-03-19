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
    dialog --title "Pre-Install Check" --colors --yesno "\nThis will install your choice of either \Zb\Z6KDE Plasma\Zn or \Zb\Z3Gnome\Zn (Vanilla). It will also add the \Zb\Z1XeroLinux\Zn and \Zb\Z4Chaotic-AUR\Zn repos, incl. some quality-of-life apps.\n\n\Zb\Z4Proceed at your OWN RISK!.\Zn" 11 70
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

# Main menu using dialog
main_menu() {
  CHOICE=$(dialog --stdout --title ">> XeroLinux DE Installer <<" --menu "\nChoose which DE to install :" 10 60 4 \
    1 "Plasma  : Install Plasma Desktop." \
    2 "GNOME   : Install Gnome Desktop.")

  case "$CHOICE" in
    1)
      install_packages "linux-headers nano kf6 power-profiles-daemon jq xmlstarlet unrar zip unzip p7zip qt6-3d qt6-5compat qt6-base qt6-charts qt6-connectivity qt6-declarative qt6-graphs qt6-grpc qt6-httpserver qt6-imageformats qt6-languageserver qt6-location qt6-lottie qt6-multimedia qt6-networkauth qt6-positioning qt6-quick3d qt6-quick3dphysics qt6-quickeffectmaker qt6-quicktimeline qt6-remoteobjects qt6-scxml qt6-sensors qt6-serialbus qt6-serialport qt6-shadertools qt6-speech qt6-svg qt6-tools qt6-translations qt6-virtualkeyboard qt6-wayland qt6-webchannel qt6-webengine qt6-websockets qt6-webview plasma-desktop packagekit-qt6 packagekit dolphin kcron khelpcenter kio-admin ksystemlog breeze plasma-workspace plasma-workspace-wallpapers powerdevil plasma-nm kaccounts-integration kdeplasma-addons plasma-pa plasma-integration plasma-browser-integration plasma-wayland-protocols plasma-systemmonitor kpipewire keysmith krecorder kweather plasmatube plasma-pass ocean-sound-theme qqc2-breeze-style plasma5-integration kdeconnect kdenetwork-filesharing kget kio-extras kio-gdrive kio-zeroconf colord-kde gwenview kamera kcolorchooser kdegraphics-thumbnailers kimagemapeditor kolourpaint okular spectacle svgpart ark kate kcalc kcharselect kdebugsettings kdf kdialog keditbookmarks kfind kgpg konsole markdownpart yakuake audiotube elisa ffmpegthumbs plasmatube dolphin-plugins pim-data-exporter pim-sieve-editor emoji-font ttf-joypixels gcc-libs glibc icu kauth kbookmarks kcmutils kcodecs kcompletion kconfig kconfigwidgets kcoreaddons kcrash kdbusaddons kdeclarative kglobalaccel kguiaddons ki18n kiconthemes kio kirigami kirigami-addons kitemmodels kitemviews kjobwidgets kmenuedit knewstuff knotifications knotifyconfig kpackage krunner kservice ksvg kwidgetsaddons kwindowsystem kxmlgui libcanberra libksysguard libplasma libx11 libxcb libxcursor libxi libxkbcommon libxkbfile plasma-activities plasma-activities-stats plasma5support polkit polkit-kde-agent qt6-5compat qt6-base qt6-declarative qt6-wayland sdl2 solid sonnet systemsettings wayland xcb-util-keysyms xdg-user-dirs scim extra-cmake-modules intltool wayland-protocols xf86-input-libinput sddm-kcm bluedevil breeze-gtk drkonqi kde-gtk-config kdeplasma-addons kinfocenter kscreen ksshaskpass oxygen oxygen-sounds xdg-desktop-portal-kde breeze-grub flatpak-kcm networkmanager-qt quota-tools qt5-x11extras gpsd pacman-contrib cmake "
      sleep 2
      systemctl enable sddm.service && systemctl enable power-profiles-daemon.service
      ;;
    2)
      install_packages "linux-headers evince extension-manager gdm gnome-backgrounds gnome-calculator gnome-calendar gnome-characters gnome-clocks gnome-color-manager gnome-connections gnome-terminal-transparency gnome-contacts gnome-control-center gnome-disk-utility gnome-font-viewer gnome-gesture-improvements gnome-keyring gnome-logs gnome-maps gnome-menus gnome-network-displays gnome-remote-desktop gnome-session gnome-settings-daemon gnome-shell gnome-shell-extensions gnome-system-monitor gnome-text-editor gnome-themes-extra gnome-tweaks gnome-user-share gnome-weather grilo-plugins gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-onedrive gvfs-smb gvfs-wsdd loupe nautilus rygel power-profiles-daemon simple-scan snapshot sushi tecla totem xdg-desktop-portal-gnome xdg-user-dirs-gtk nano jq xmlstarlet unrar zip unzip 7zip"
      sleep 2
      systemctl enable gdm.service && systemctl enable power-profiles-daemon.service
      ;;
    *)
      if [ "$CHOICE" == "" ]; then
        clear
        exit 0
      else
        dialog --msgbox "Invalid option. Please select 1 or 2." 10 40
        main_menu
      fi
      ;;
  esac
}

# Display main menu
main_menu

echo "Installing missing X.org packages..."
install_packages "xorg-apps xorg-xinit xorg-server xorg-xwayland"

echo "Installing Bluetooth packages..."
install_packages "bluez bluez-utils bluez-plugins bluez-hid2hci bluez-cups bluez-libs bluez-tools"
systemctl enable bluetooth.service

echo "Installing other useful applications..."
install_packages "downgrade brightnessctl mkinitcpio-firmware update-grub meld timeshift mpv gnome-disk-utility btop git rustup eza ntp most wget dnsutils logrotate gtk-update-icon-cache dex bash-completion bat bat-extras ttf-fira-code otf-libertinus tex-gyre-fonts ttf-hack-nerd ttf-ubuntu-font-family awesome-terminal-fonts ttf-jetbrains-mono-nerd adobe-source-sans-pro-fonts gtk-engines gtk-engine-murrine gnome-themes-extra firefox firefox-ublock-origin ntfs-3g gvfs mtpfs udiskie udisks2 ldmtool gvfs-afc gvfs-mtp gvfs-nfs gvfs-smb gvfs-gphoto2 libgsf tumbler freetype2 libopenraw ffmpegthumbnailer python-pip python-cffi python-numpy python-docopt python-pyaudio python-pyparted python-pygments python-websockets ocs-url xmlstarlet yt-dlp wavpack unarchiver gnustep-base parallel systemdgenie gnome-keyring ark vi duf gcc yad zip xdo lzop nmon tree vala htop lshw cblas expac fuse3 lhasa meson unace rhash sshfs vnstat nodejs cronie hwinfo arandr assimp netpbm wmctrl grsync libmtp sysprof semver zenity gparted hddtemp mlocate jsoncpp fuseiso gettext node-gyp graphviz pkgstats inetutils s3fs-fuse playerctl oniguruma cifs-utils lsb-release dbus-python laptop-detect perl-xml-parser preload"
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
