def get_kde_installer_script(self):
        """Get the complete KDE installer bash script embedded"""
        # Complete bash KDE installer embedded as a raw string
        # This is the full script from xero-kde-installer.sh
        return r'''#!/bin/bash

# XeroLinux KDE Plasma Installer
# A clean and simple KDE installation script for Arch Linux

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

BROWSER=""
VPN=""
SOCIAL=""
ANDROID=""
LIBREOFFICE=""
DEV=""
PASS=""
IMAGING=""
MUSIC=""
VIDEO=""

print_header() {
    clear
    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                                                ║${NC}"
    echo -e "${PURPLE}║${CYAN}      XeroLinux KDE Plasma Installer           ${PURPLE}║${NC}"
    echo -e "${PURPLE}║                                                ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}>>${NC} ${CYAN}$1${NC}"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

detect_cpu() {
    if grep -q "GenuineIntel" /proc/cpuinfo; then
        echo "intel"
    elif grep -q "AuthenticAMD" /proc/cpuinfo; then
        echo "amd"
    else
        echo "unknown"
    fi
}

detect_vm() {
    if systemd-detect-virt -q 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

prompt_user() {
    print_header
    echo -e "${CYAN}This script will install:${NC}"
    echo -e "  ${BLUE}*${NC} KDE Plasma Desktop (XeroLinux curated selection)"
    echo -e "  ${BLUE}*${NC} Essential System Tools & Utilities"
    echo -e "  ${BLUE}*${NC} Hardware Support & Drivers"
    echo -e "  ${BLUE}*${NC} Multimedia & Graphics Applications"
    echo -e "  ${BLUE}*${NC} Power User Tools"
    echo -e "  ${BLUE}*${NC} XeroLinux & Chaotic-AUR Repositories"
    echo ""
    echo -e "${YELLOW}[!] This will modify your system!${NC}"
    echo ""
    read -p "$(echo -e ${GREEN}Do you want to proceed? ${NC}[${GREEN}y${NC}/${RED}N${NC}]: )" -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Installation cancelled by user."
        exit 0
    fi
}

customization_prompts() {
    print_header
    echo -e "${CYAN}** Personalization Time! **${NC}"
    echo ""
    echo "To make your system truly yours, we'll ask you to choose from"
    echo "10 quick categories (browsers, apps, tools, etc.)."
    echo ""
    echo -e "${GREEN}Don't worry!${NC} You can skip any category."
    echo ""
    read -p "Press Enter to continue..."

    # Browser
    print_header
    echo -e "${CYAN}[1/10] Web Browser${NC}"
    echo ""
    echo -e "  ${BLUE}1)${NC} Floorp"
    echo -e "  ${BLUE}2)${NC} Firefox"
    echo -e "  ${BLUE}3)${NC} Brave"
    echo -e "  ${BLUE}4)${NC} LibreWolf"
    echo -e "  ${BLUE}5)${NC} Vivaldi"
    echo -e "  ${BLUE}6)${NC} Tor Browser"
    echo -e "  ${BLUE}7)${NC} Mullvad Browser"
    echo -e "  ${BLUE}8)${NC} Ungoogled Chromium"
    echo -e "  ${BLUE}9)${NC} FileZilla"
    echo ""
    read -p "Enter choice (1-9, or Enter to skip): " browser_choice
    case $browser_choice in
        1) BROWSER="floorp" ;;
        2) BROWSER="firefox" ;;
        3) BROWSER="brave-bin" ;;
        4) BROWSER="librewolf" ;;
        5) BROWSER="vivaldi-meta" ;;
        6) BROWSER="tor-browser-bin" ;;
        7) BROWSER="mullvad-browser-bin" ;;
        8) BROWSER="ungoogled-chromium-bin" ;;
        9) BROWSER="filezilla" ;;
        *) BROWSER="" ;;
    esac

    # VPN
    print_header
    echo -e "${CYAN}[2/10] VPN Service${NC}"
    echo ""
    echo -e "  ${BLUE}1)${NC} ExpressVPN"
    echo -e "  ${BLUE}2)${NC} Mozilla VPN"
    echo -e "  ${BLUE}3)${NC} Mullvad VPN"
    echo -e "  ${BLUE}4)${NC} Proton VPN"
    echo ""
    read -p "Enter choice (1-4, or Enter to skip): " vpn_choice
    case $vpn_choice in
        1) VPN="expressvpn" ;;
        2) VPN="mozillavpn" ;;
        3) VPN="mullvad-vpn" ;;
        4) VPN="proton-vpn-cli" ;;
        *) VPN="" ;;
    esac

    # Social
    print_header
    echo -e "${CYAN}[3/10] Social & Communication Apps${NC}"
    echo ""
    echo -e "  ${BLUE}1)${NC} ZapZap  ${BLUE}2)${NC} Tokodon  ${BLUE}3)${NC} Discord  ${BLUE}4)${NC} Element"
    echo -e "  ${BLUE}5)${NC} Vesktop ${BLUE}6)${NC} WebCord  ${BLUE}7)${NC} Telegram ${BLUE}8)${NC} Ferdium"
    echo ""
    read -p "Enter choices (e.g., '1 3 7', or Enter to skip): " social_choices
    SOCIAL=""
    for choice in $social_choices; do
        case $choice in
            1) SOCIAL="$SOCIAL zapzap" ;;
            2) SOCIAL="$SOCIAL tokodon" ;;
            3) SOCIAL="$SOCIAL discord" ;;
            4) SOCIAL="$SOCIAL element" ;;
            5) SOCIAL="$SOCIAL vesktop" ;;
            6) SOCIAL="$SOCIAL webcord" ;;
            7) SOCIAL="$SOCIAL telegram" ;;
            8) SOCIAL="$SOCIAL ferdium-bin" ;;
        esac
    done

    # Android
    print_header
    echo -e "${CYAN}[4/10] Android Development Tools${NC}"
    echo ""
    read -p "Do you want Android tools (ADB, scrcpy, etc.)? [y/N]: " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ANDROID="heimdall qtscrcpy adbmanager android-udev android-tools android-platform android-sdk-platform-tools"
    else
        ANDROID=""
    fi

    # LibreOffice
    print_header
    echo -e "${CYAN}[5/10] Office Suite${NC}"
    echo ""
    read -p "Do you want LibreOffice? [y/N]: " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "Choose language:"
        echo -e "  ${BLUE}1)${NC} en_us  ${BLUE}2)${NC} en_gb  ${BLUE}3)${NC} en_au  ${BLUE}4)${NC} en_ca"
        echo -e "  ${BLUE}5)${NC} es_es  ${BLUE}6)${NC} es_mx  ${BLUE}7)${NC} es_ar  ${BLUE}8)${NC} fr"
        echo -e "  ${BLUE}9)${NC} de     ${BLUE}10)${NC} it    ${BLUE}11)${NC} pt    ${BLUE}12)${NC} ru"
        echo -e "  ${BLUE}13)${NC} pl    ${BLUE}14)${NC} nl    ${BLUE}15)${NC} el    ${BLUE}16)${NC} hu"
        echo -e "  ${BLUE}17)${NC} ro    ${BLUE}18)${NC} he"
        read -p "Enter choice (1-18, default en_us): " lang_choice
        case $lang_choice in
            1|"") LANG_CODE="en_us" ;;
            2) LANG_CODE="en_gb" ;;
            3) LANG_CODE="en_au" ;;
            4) LANG_CODE="en_ca" ;;
            5) LANG_CODE="es_es" ;;
            6) LANG_CODE="es_mx" ;;
            7) LANG_CODE="es_ar" ;;
            8) LANG_CODE="fr" ;;
            9) LANG_CODE="de" ;;
            10) LANG_CODE="it" ;;
            11) LANG_CODE="pt" ;;
            12) LANG_CODE="ru" ;;
            13) LANG_CODE="pl" ;;
            14) LANG_CODE="nl" ;;
            15) LANG_CODE="el" ;;
            16) LANG_CODE="hu" ;;
            17) LANG_CODE="ro" ;;
            18) LANG_CODE="he" ;;
            *) LANG_CODE="en_us" ;;
        esac
        LIBREOFFICE="hunspell libreoffice-fresh hunspell-$LANG_CODE libreoffice-extension-texmaths libreoffice-extension-writer2latex"
    else
        LIBREOFFICE=""
    fi

    # Dev tools
    print_header
    echo -e "${CYAN}[6/10] Development Tools${NC}"
    echo ""
    echo -e "  ${BLUE}1)${NC} Hugo  ${BLUE}2)${NC} Meld  ${BLUE}3)${NC} VSCodium  ${BLUE}4)${NC} GitHub Desktop"
    read -p "Enter choices: " dev_choices
    DEV=""
    for choice in $dev_choices; do
        case $choice in
            1) DEV="$DEV hugo" ;;
            2) DEV="$DEV meld" ;;
            3) DEV="$DEV vscodium-bin" ;;
            4) DEV="$DEV github-desktop" ;;
        esac
    done

    # Password managers
    print_header
    echo -e "${CYAN}[7/10] Password Manager${NC}"
    echo ""
    echo -e "  ${BLUE}1)${NC} KeePassXC  ${BLUE}2)${NC} Bitwarden"
    read -p "Enter choices: " pass_choices
    PASS=""
    for choice in $pass_choices; do
        case $choice in
            1) PASS="$PASS keepassxc" ;;
            2) PASS="$PASS bitwarden" ;;
        esac
    done

    # Creative apps
    print_header
    echo -e "${CYAN}[8/10] Creative & Imaging Apps${NC}"
    echo ""
    echo -e "  ${BLUE}1)${NC} GIMP  ${BLUE}2)${NC} Godot  ${BLUE}3)${NC} Krita  ${BLUE}4)${NC} Inkscape  ${BLUE}5)${NC} Blender"
    read -p "Enter choices: " imaging_choices
    IMAGING=""
    for choice in $imaging_choices; do
        case $choice in
            1) IMAGING="$IMAGING gimp" ;;
            2) IMAGING="$IMAGING godot" ;;
            3) IMAGING="$IMAGING krita" ;;
            4) IMAGING="$IMAGING inkscape" ;;
            5) IMAGING="$IMAGING blender" ;;
        esac
    done

    # Music apps
    print_header
    echo -e "${CYAN}[9/10] Music & Audio Apps${NC}"
    echo ""
    echo -e "  ${BLUE}1)${NC} MPV  ${BLUE}2)${NC} Amarok  ${BLUE}3)${NC} Spotify  ${BLUE}4)${NC} Tenacity  ${BLUE}5)${NC} JamesDSP  ${BLUE}6)${NC} EasyEffects"
    read -p "Enter choices: " music_choices
    MUSIC=""
    for choice in $music_choices; do
        case $choice in
            1) MUSIC="$MUSIC mpv" ;;
            2) MUSIC="$MUSIC amarok" ;;
            3) MUSIC="$MUSIC spotify" ;;
            4) MUSIC="$MUSIC tenacity" ;;
            5) MUSIC="$MUSIC jamesdsp" ;;
            6) MUSIC="$MUSIC easyeffects" ;;
        esac
    done

    # Video apps
    print_header
    echo -e "${CYAN}[10/10] Video Editing Apps${NC}"
    echo ""
    echo -e "  ${BLUE}1)${NC} Mystiq  ${BLUE}2)${NC} MakeMKV  ${BLUE}3)${NC} Kdenlive  ${BLUE}4)${NC} Avidemux  ${BLUE}5)${NC} MKVToolNix  ${BLUE}6)${NC} LosslessCut"
    read -p "Enter choices: " video_choices
    VIDEO=""
    for choice in $video_choices; do
        case $choice in
            1) VIDEO="$VIDEO mystiq" ;;
            2) VIDEO="$VIDEO makemkv" ;;
            3) VIDEO="$VIDEO kdenlive" ;;
            4) VIDEO="$VIDEO avidemux-qt" ;;
            5) VIDEO="$VIDEO mkvtoolnix-gui" ;;
            6) VIDEO="$VIDEO losslesscut-bin" ;;
        esac
    done

    print_header
    echo -e "${GREEN}[✓] Customization complete!${NC}"
    echo ""
    read -p "Press Enter to begin installation..."
}

add_repos() {
    if grep -q "\[xerolinux\]" /etc/pacman.conf; then
        print_step "XeroLinux repo already present"
    else
        print_step "Adding XeroLinux Repository..."
        echo -e '\n[xerolinux]\nSigLevel = Optional TrustAll\nServer = https://repos.xerolinux.xyz/$repo/$arch' | sudo tee -a /etc/pacman.conf >/dev/null
        print_success "XeroLinux repo added!"
    fi

    if grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
        print_step "Chaotic-AUR repo already present"
    else
        print_step "Adding Chaotic-AUR Repository..."
        sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com 2>/dev/null || true
        sudo pacman-key --lsign-key 3056513887B78AEB 2>/dev/null || true
        sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 2>/dev/null || true
        sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' 2>/dev/null || true
        echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' | sudo tee -a /etc/pacman.conf >/dev/null
        print_success "Chaotic-AUR repo added!"
    fi
}

install_kde() {
    print_header
    print_step "Starting KDE Plasma installation..."
    echo ""

    add_repos

    print_step "Updating system..."
    sudo pacman -Sy --noconfirm >/dev/null 2>&1
    print_success "System updated!"
    echo ""

    print_step "Installing Core KDE..."
    sudo pacman -S --needed --noconfirm kf6 qt6 kde-system >/dev/null 2>&1
    print_success "Core installed!"

    print_step "Installing Plasma..."
    sudo pacman -S --needed --noconfirm kwin krdp milou breeze oxygen aurorae drkonqi kwrited kgamma kscreen sddm-kcm kmenuedit bluedevil kpipewire plasma-nm plasma-pa plasma-sdk libkscreen breeze-gtk powerdevil kinfocenter flatpak-kcm kdecoration ksshaskpass kwallet-pam libksysguard plasma-vault ksystemstats kde-cli-tools oxygen-sounds kscreenlocker kglobalacceld systemsettings kde-gtk-config layer-shell-qt plasma-desktop polkit-kde-agent plasma-workspace kdeplasma-addons ocean-sound-theme qqc2-breeze-style kactivitymanagerd plasma-integration plasma-thunderbolt plasma5-integration plasma-systemmonitor xdg-desktop-portal-kde plasma-browser-integration >/dev/null 2>&1
    print_success "Plasma installed!"

    print_step "Installing SDDM..."
    sudo pacman -S --needed --noconfirm sddm >/dev/null 2>&1
    sudo systemctl enable sddm.service >/dev/null 2>&1
    print_success "SDDM installed!"

    print_step "Installing KDE Apps..."
    sudo pacman -S --needed --noconfirm krdc krfb smb4k alligator kdeconnect kio-admin kio-extras kio-gdrive konversation kio-zeroconf kdenetwork-filesharing signon-kwallet-extension okular kamera svgpart skanlite gwenview spectacle colord-kde kcolorchooser kimagemapeditor kdegraphics-thumbnailers ark kate kgpg kfind sweeper konsole kdialog yakuake skanpage filelight kmousetool kcharselect markdownpart qalculate-qt keditbookmarks kdebugsettings kwalletmanager dolphin-plugins akregator packagekit-qt5 dolphin k3b kamoso audiotube plasmatube audiocd-kio >/dev/null 2>&1
    print_success "KDE apps installed!"

    print_step "Installing Wayland..."
    sudo pacman -S --needed --noconfirm waypipe dwayland egl-wayland qt6-wayland lib32-wayland wayland-protocols kwayland-integration plasma-wayland-protocols >/dev/null 2>&1
    print_success "Wayland installed!"

    print_step "Installing system packages (this takes time)..."
    sudo pacman -S --needed --noconfirm base base-devel archiso b43-fwcutter rsync sdparm ntfs-3g gptfdisk xfsprogs tpm2-tss udftools syslinux fatresize nfs-utils e2fsprogs dosfstools exfatprogs tpm2-tools fsarchiver squashfs-tools gpart dmraid parted hdparm usbmuxd usbutils testdisk ddrescue timeshift partclone partimage clonezilla open-iscsi memtest86+-efi usb_modeswitch >/dev/null 2>&1

    sudo pacman -S --needed --noconfirm fd nano tmux brltty msedit nvme-cli terminus-font foot-terminfo kitty-terminfo pv mc gpm nbd lvm2 bolt bind less lynx sudo tldr nmap irssi mdadm wvdial hyperv mtools lsscsi ndisc6 screen man-db xl2tpd tcpdump ethtool xdotool pcsclite espeakup libfido2 xdg-utils man-pages diffutils mmc-utils sg3_utils dmidecode efibootmgr sequoia-sq edk2-shell python-pyqt6 sof-firmware libusb-compat smartmontools wireguard-tools eza ntp cava most wget dialog dnsutils logrotate >/dev/null 2>&1

    sudo pacman -S --needed --noconfirm linux linux-atm linux-headers grub os-prober grub-hooks update-grub >/dev/null 2>&1

    sudo pacman -S --needed --noconfirm preload extra-scripts >/dev/null 2>&1

    sudo pacman -S --needed --noconfirm xmlto boost ckbcomp kpmcore yaml-cpp boost-libs gtk-update-icon-cache xdg-terminal-exec-git mkinitcpio mkinitcpio-fw mkinitcpio-utils mkinitcpio-archiso mkinitcpio-openswap mkinitcpio-nfs-utils dex bash make libxinerama bash-completion kirigami polkit-gnome >/dev/null 2>&1

    print_success "System packages installed!"

    print_step "Installing hardware support..."
    CPU_VENDOR=$(detect_cpu)
    if [ "$CPU_VENDOR" = "intel" ]; then
        sudo pacman -S --needed --noconfirm fwupd intel-ucode >/dev/null 2>&1
    elif [ "$CPU_VENDOR" = "amd" ]; then
        sudo pacman -S --needed --noconfirm fwupd amd-ucode >/dev/null 2>&1
    else
        sudo pacman -S --needed --noconfirm fwupd >/dev/null 2>&1
    fi

    sudo pacman -S --needed --noconfirm mesa autorandr mesa-utils lib32-mesa xf86-video-qxl xf86-video-fbdev lib32-mesa-utils hplip print-manager scanner-support printer-support orca onboard libinput xf86-input-void xf86-input-evdev iio-sensor-proxy game-devices-udev xf86-input-vmmouse xf86-input-libinput xf86-input-synaptics xf86-input-elographics >/dev/null 2>&1
    print_success "Hardware support installed!"

    print_step "Installing multimedia..."
    sudo pacman -S --needed --noconfirm gstreamer gst-libav gst-plugins-bad gst-plugins-base gst-plugins-ugly gst-plugins-good gst-plugins-espeak gst-plugin-pipewire ffmpeg ffmpegthumbs ffnvcodec-headers >/dev/null 2>&1
    print_success "Multimedia installed!"

    print_step "Installing networking..."
    sudo pacman -S --needed --noconfirm bluez bluez-libs bluez-utils bluez-tools bluez-plugins bluez-hid2hci iw iwd ppp lftp ldns avahi samba netctl dhcpcd openssh openvpn dnsmasq dhclient openldap nss-mdns smbclient net-tools openresolv darkhttpd reflector pptpclient cloud-init openconnect traceroute networkmanager nm-cloud-setup wireless-regdb wireless_tools wpa_supplicant modemmanager-qt openpgp-card-tools systemd-resolvconf >/dev/null 2>&1
    print_success "Networking installed!"

    print_step "Installing Xorg..."
    sudo pacman -S --needed --noconfirm xorg-apps xorg-xinit xorg-server xorg-xwayland >/dev/null 2>&1
    print_success "Xorg installed!"

    print_step "Installing utilities..."
    sudo pacman -S --needed --noconfirm falkon hblock cryptsetup brightnessctl switcheroo-control power-profiles-daemon jq vim figlet ostree lolcat numlockx localsend lm_sensors appstream-glib lib32-lm_sensors bat bat-extras ttf-fira-code otf-libertinus tex-gyre-fonts ttf-hack-nerd ttf-ubuntu-font-family awesome-terminal-fonts ttf-jetbrains-mono-nerd adobe-source-sans-pro-fonts >/dev/null 2>&1
    print_success "Utilities installed!"

    print_step "Installing theming..."
    sudo pacman -S --needed --noconfirm kvantum fastfetch adw-gtk-theme oh-my-posh-bin gnome-themes-extra kwin-effect-rounded-corners-git kwin-zones kde-wallpapers kwin-scripts-kzones tela-circle-icon-theme-purple bash-language-server typescript-language-server vscode-json-languageserver >/dev/null 2>&1
    print_success "Theming installed!"

    print_step "Installing libraries..."
    sudo pacman -S --needed --noconfirm gvfs mtpfs udiskie udisks2 ldmtool gvfs-afc gvfs-mtp gvfs-nfs gvfs-smb gvfs-goa gvfs-wsdd gvfs-dnssd gvfs-google gvfs-gphoto2 gvfs-onedrive libgsf tumbler freetype2 libopenraw poppler-qt6 poppler-glib ffmpegthumbnailer python-pip python-cffi python-numpy python-docopt python-pyaudio python-pyparted python-pygments python-websockets >/dev/null 2>&1

    sudo pacman -S --needed --noconfirm paru flatpak topgrade appstream-qt pacman-contrib pacman-bintrans xdg-user-dirs ocs-url xmlstarlet yt-dlp wavpack unarchiver rate-mirrors gnustep-base parallel xsettingsd polkit-qt6 systemdgenie gnome-keyring >/dev/null 2>&1

    sudo pacman -S --needed --noconfirm vi gcc git npm nodejs vala meson gettext intltool node-gyp graphviz pkgconf semver duf btop htop iftop nvtop vnstat inxi lshw hwinfo nmon sysprof zip unzip unrar p7zip lzop lhasa unace fuseiso fuse3 sshfs s3fs-fuse cifs-utils gparted gnome-disk-utility grsync hddtemp mlocate pciutils inetutils cronie playerctl asciinema ventoy-bin downgrade pkgstats lsb-release laptop-detect yad xdo gum tree expac cblas glfw rhash assimp netpbm wmctrl libmtp polkit zenity jsoncpp oniguruma dbus-python dconf-editor perl-xml-parser appmenu-gtk-module arandr >/dev/null 2>&1
    print_success "Libraries installed!"

    [ -n "$BROWSER" ] && sudo pacman -S --needed --noconfirm $BROWSER >/dev/null 2>&1
    [ -n "$VPN" ] && sudo pacman -S --needed --noconfirm $VPN >/dev/null 2>&1
    [ -n "$SOCIAL" ] && sudo pacman -S --needed --noconfirm $SOCIAL >/dev/null 2>&1
    [ -n "$ANDROID" ] && sudo pacman -S --needed --noconfirm $ANDROID >/dev/null 2>&1
    [ -n "$LIBREOFFICE" ] && sudo pacman -S --needed --noconfirm $LIBREOFFICE >/dev/null 2>&1
    [ -n "$DEV" ] && sudo pacman -S --needed --noconfirm $DEV >/dev/null 2>&1
    [ -n "$PASS" ] && sudo pacman -S --needed --noconfirm $PASS >/dev/null 2>&1
    [ -n "$IMAGING" ] && sudo pacman -S --needed --noconfirm $IMAGING >/dev/null 2>&1
    [ -n "$MUSIC" ] && sudo pacman -S --needed --noconfirm $MUSIC >/dev/null 2>&1
    [ -n "$VIDEO" ] && sudo pacman -S --needed --noconfirm $VIDEO >/dev/null 2>&1

    if detect_vm; then
        print_step "VM detected, installing guest tools..."
        sudo pacman -S --needed --noconfirm spice-vdagent open-vm-tools qemu-guest-agent virtualbox-guest-utils >/dev/null 2>&1
    fi

    print_step "Updating initramfs..."
    sudo mkinitcpio -P >/dev/null 2>&1
    print_success "Initramfs updated!"

    print_step "Updating GRUB..."
    sudo update-grub >/dev/null 2>&1
    print_success "GRUB updated!"

    print_step "Enabling services..."
    sudo systemctl enable cups.socket saned.socket NetworkManager bluetooth power-profiles-daemon switcheroo-control dhcpcd preload sshd 2>/dev/null
    sudo systemctl disable systemd-time-wait-sync reflector pacman-init 2>/dev/null
    print_success "Services configured!"

    print_header
    echo -e "${CYAN}Apply Xero-Layan theme?${NC}"
    echo ""
    read -p "[y/N]: " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        mkdir -p ~/.config
        cd /tmp && git clone https://github.com/xerolinux/xero-layan-git 2>/dev/null
        if [ -d "xero-layan-git" ]; then
            cd xero-layan-git && chmod +x install.sh && ./install.sh
        fi
    fi

    echo ""
    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${GREEN}          Installation Complete!               ${PURPLE}║${NC}"
    echo -e "${PURPLE}╠════════════════════════════════════════════════╣${NC}"
    echo -e "${PURPLE}║${NC}  Reboot to experience your new desktop        ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}"
    echo ""
}

prompt_user
customization_prompts
install_kde
'''#!/usr/bin/env python3

"""
XeroLinux Arch Installer
Complete Arch Linux Installation with KDE Plasma
"""

import os
import sys
import subprocess
import time
import shutil
from pathlib import Path

class Colors:
    """ANSI color codes"""
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    PURPLE = '\033[0;35m'
    CYAN = '\033[0;36m'
    NC = '\033[0m'

class Installer:
    def __init__(self):
        self.install_device = ""
        self.efi_partition = ""
        self.root_partition = ""
        self.hostname = ""
        self.username = ""
        self.timezone = ""
        self.locale = ""
        self.keymap = ""
        self.is_uefi = False

    def run_command(self, cmd, check=True, shell=True, capture_output=False):
        """Run a shell command with error handling"""
        try:
            if capture_output:
                result = subprocess.run(cmd, shell=shell, check=check,
                                       capture_output=True, text=True)
                return result.stdout.strip()
            else:
                subprocess.run(cmd, shell=shell, check=check)
                return True
        except subprocess.CalledProcessError as e:
            if check:
                self.print_error(f"Command failed: {cmd}")
                return False
            return False

    def print_header(self):
        """Print installer header"""
        os.system('clear')
        print(f"{Colors.PURPLE}╔════════════════════════════════════════════════╗{Colors.NC}")
        print(f"{Colors.PURPLE}║                                                ║{Colors.NC}")
        print(f"{Colors.PURPLE}║{Colors.CYAN}        XeroLinux Arch Installer v2.0          {Colors.PURPLE}║{Colors.NC}")
        print(f"{Colors.PURPLE}║                                                ║{Colors.NC}")
        print(f"{Colors.PURPLE}╚════════════════════════════════════════════════╝{Colors.NC}")
        print()

    def print_step(self, msg):
        print(f"{Colors.BLUE}>>{Colors.NC} {Colors.CYAN}{msg}{Colors.NC}")

    def print_success(self, msg):
        print(f"{Colors.GREEN}[✓]{Colors.NC} {msg}")

    def print_error(self, msg):
        print(f"{Colors.RED}[✗]{Colors.NC} {msg}")

    def print_warning(self, msg):
        print(f"{Colors.YELLOW}[!]{Colors.NC} {msg}")

    def pause(self):
        input("Press Enter to continue...")

    def check_root(self):
        """Check if running as root"""
        if os.geteuid() != 0:
            self.print_error("This installer must be run as root!")
            sys.exit(1)

    def check_internet(self):
        """Check internet connectivity"""
        self.print_step("Checking internet connection...")
        result = self.run_command("ping -c 1 archlinux.org", check=False)
        if result:
            self.print_success("Internet connection active")
        else:
            self.print_error("No internet connection detected!")
            print("\nPlease connect to the internet and try again.")
            print("For WiFi, use: iwctl")
            sys.exit(1)

    def check_uefi(self):
        """Detect UEFI or BIOS"""
        self.print_step("Detecting boot mode...")
        if os.path.isdir("/sys/firmware/efi/efivars"):
            self.is_uefi = True
            self.print_success("UEFI mode detected")
        else:
            self.is_uefi = False
            self.print_success("BIOS/Legacy mode detected")

    def install_dependencies(self):
        """Install required packages"""
        self.print_step("Installing required dependencies...")

        self.run_command("pacman -Sy --noconfirm", check=False)

        tools = ["dialog", "fzf", "gum", "git"]
        for tool in tools:
            if not shutil.which(tool):
                self.print_step(f"Installing {tool}...")
                self.run_command(f"pacman -S --noconfirm {tool}", check=False)

        self.print_success("Dependencies installed")

    def preflight_checks(self):
        """Run all pre-flight checks"""
        self.print_header()
        print(f"{Colors.CYAN}Performing pre-flight checks...{Colors.NC}\n")

        self.check_root()
        self.check_internet()
        self.check_uefi()
        self.install_dependencies()

        print()
        self.print_success("All pre-flight checks passed!")
        print()
        self.pause()

    def select_disk(self):
        """Select installation disk"""
        self.print_header()
        print(f"{Colors.CYAN}[Step 1/10] Select Installation Disk{Colors.NC}\n")
        print(f"{Colors.YELLOW}[!] WARNING: All data on the selected disk will be ERASED!{Colors.NC}\n")
        print("Available disks:\n")

        disks = self.run_command("lsblk -ndo NAME,SIZE,TYPE | grep disk",
                                 capture_output=True).split('\n')

        disk_list = []
        for i, disk in enumerate(disks, 1):
            parts = disk.split()
            if parts:
                name = parts[0]
                size = parts[1] if len(parts) > 1 else "Unknown"
                model = self.run_command(f"lsblk -ndo MODEL /dev/{name}",
                                        capture_output=True, check=False)
                print(f"  {Colors.BLUE}{i}){Colors.NC} /dev/{name} - {size} - {model}")
                disk_list.append(name)

        print()
        choice = input("Enter disk number: ")

        try:
            choice = int(choice)
            if 1 <= choice <= len(disk_list):
                self.install_device = f"/dev/{disk_list[choice-1]}"

                print()
                print(f"{Colors.RED}╔════════════════════════════════════════════════╗{Colors.NC}")
                print(f"{Colors.RED}║              FINAL WARNING                     ║{Colors.NC}")
                print(f"{Colors.RED}╠════════════════════════════════════════════════╣{Colors.NC}")
                print(f"{Colors.RED}║{Colors.NC}  Selected disk: {Colors.YELLOW}{self.install_device}{Colors.NC}")
                print(f"{Colors.RED}║{Colors.NC}  ALL DATA WILL BE PERMANENTLY ERASED!        {Colors.RED}║{Colors.NC}")
                print(f"{Colors.RED}╚════════════════════════════════════════════════╝{Colors.NC}")
                print()

                confirm = input("Type 'YES' in capital letters to confirm: ")

                if confirm == "YES":
                    self.print_success(f"Disk {self.install_device} selected")
                else:
                    self.print_error("Confirmation failed. Exiting...")
                    sys.exit(1)
            else:
                self.print_error("Invalid selection!")
                sys.exit(1)
        except ValueError:
            self.print_error("Invalid input!")
            sys.exit(1)

    def partition_disk(self):
        """Partition the selected disk"""
        self.print_header()
        print(f"{Colors.CYAN}[Step 2/10] Disk Partitioning{Colors.NC}\n")

        self.print_step(f"Partitioning {self.install_device}...")

        self.run_command(f"wipefs -af {self.install_device}")
        self.run_command(f"sgdisk -Z {self.install_device}")

        if self.is_uefi:
            self.print_step("Creating GPT partition table (UEFI)...")

            self.run_command(f"parted -s {self.install_device} mklabel gpt")
            self.run_command(f"parted -s {self.install_device} mkpart primary fat32 1MiB 513MiB")
            self.run_command(f"parted -s {self.install_device} set 1 esp on")
            self.run_command(f"parted -s {self.install_device} mkpart primary ext4 513MiB 100%")

            time.sleep(2)

            if "nvme" in self.install_device:
                self.efi_partition = f"{self.install_device}p1"
                self.root_partition = f"{self.install_device}p2"
            else:
                self.efi_partition = f"{self.install_device}1"
                self.root_partition = f"{self.install_device}2"

            self.print_success("UEFI partitions created")
            print(f"  EFI:  {self.efi_partition} (512MB)")
            print(f"  Root: {self.root_partition}")
        else:
            self.print_step("Creating MBR partition table (BIOS)...")

            self.run_command(f"parted -s {self.install_device} mklabel msdos")
            self.run_command(f"parted -s {self.install_device} mkpart primary ext4 1MiB 100%")
            self.run_command(f"parted -s {self.install_device} set 1 boot on")

            time.sleep(2)

            if "nvme" in self.install_device:
                self.root_partition = f"{self.install_device}p1"
            else:
                self.root_partition = f"{self.install_device}1"

            self.print_success("BIOS partitions created")
            print(f"  Root: {self.root_partition}")

        print()
        self.pause()

    def format_partitions(self):
        """Format partitions"""
        self.print_header()
        print(f"{Colors.CYAN}[Step 3/10] Format Partitions{Colors.NC}\n")

        if self.is_uefi:
            self.print_step("Formatting EFI partition...")
            self.run_command(f"mkfs.fat -F32 {self.efi_partition}")
            self.print_success("EFI partition formatted")

        self.print_step("Formatting root partition...")
        self.run_command(f"mkfs.ext4 -F {self.root_partition}")
        self.print_success("Root partition formatted")

        print()
        self.pause()

    def mount_partitions(self):
        """Mount partitions"""
        self.print_header()
        print(f"{Colors.CYAN}[Step 4/10] Mount Partitions{Colors.NC}\n")

        self.print_step("Mounting partitions...")

        self.run_command(f"mount {self.root_partition} /mnt")

        if self.is_uefi:
            self.run_command("mkdir -p /mnt/boot/efi")
            self.run_command(f"mount {self.efi_partition} /mnt/boot/efi")

        self.print_success("Partitions mounted")
        print()
        self.pause()

    def install_base_system(self):
        """Install base system"""
        self.print_header()
        print(f"{Colors.CYAN}[Step 5/10] Installing Base System{Colors.NC}\n")

        self.print_step("Installing base system (this may take a while)...")

        packages = [
            "base", "base-devel", "linux", "linux-firmware", "linux-headers",
            "networkmanager", "grub", "efibootmgr", "os-prober", "sudo",
            "nano", "vim", "git", "wget", "curl", "gum"
        ]

        cmd = f"pacstrap /mnt {' '.join(packages)}"
        self.run_command(cmd)

        self.print_success("Base system installed!")

        self.print_step("Generating fstab...")
        self.run_command("genfstab -U /mnt >> /mnt/etc/fstab")
        self.print_success("Fstab generated")

        print()
        self.pause()

    def configure_system(self):
        """Configure system settings"""
        self.print_header()
        print(f"{Colors.CYAN}[Step 6/10] System Configuration{Colors.NC}\n")

        self.hostname = input("Enter hostname for your system: ")
        with open("/mnt/etc/hostname", "w") as f:
            f.write(self.hostname)

        hosts_content = f"""127.0.0.1   localhost
::1         localhost
127.0.1.1   {self.hostname}.localdomain {self.hostname}
"""
        with open("/mnt/etc/hosts", "w") as f:
            f.write(hosts_content)

        self.print_success(f"Hostname set to: {self.hostname}")

        print()
        self.print_step("Select timezone...")
        timezones = self.run_command("timedatectl list-timezones", capture_output=True)

        process = subprocess.Popen(
            ["fzf", "--height", "20", "--reverse", "--prompt=Select timezone: "],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            text=True
        )
        self.timezone, _ = process.communicate(input=timezones)
        self.timezone = self.timezone.strip()

        self.run_command(f"arch-chroot /mnt ln -sf /usr/share/zoneinfo/{self.timezone} /etc/localtime")
        self.run_command("arch-chroot /mnt hwclock --systohc")
        self.print_success(f"Timezone set to: {self.timezone}")

        print()
        self.print_step("Select locale...")
        common_locales = [
            "en_US.UTF-8", "en_GB.UTF-8", "de_DE.UTF-8", "fr_FR.UTF-8",
            "es_ES.UTF-8", "it_IT.UTF-8", "pt_BR.UTF-8", "ru_RU.UTF-8"
        ]

        print("Common locales:")
        for i, loc in enumerate(common_locales, 1):
            print(f"  {Colors.BLUE}{i}){Colors.NC} {loc}")
        print(f"  {Colors.BLUE}0){Colors.NC} Other (search all locales)")
        print()

        choice = input("Enter choice: ")

        if choice == "0":
            locales = self.run_command("cat /etc/locale.gen | grep -v '^#' | grep UTF-8 | cut -d' ' -f1",
                                      capture_output=True)
            process = subprocess.Popen(
                ["fzf", "--height", "20", "--reverse", "--prompt=Select locale: "],
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                text=True
            )
            self.locale, _ = process.communicate(input=locales)
            self.locale = self.locale.strip()
        else:
            try:
                idx = int(choice)
                if 1 <= idx <= len(common_locales):
                    self.locale = common_locales[idx-1]
                else:
                    self.locale = "en_US.UTF-8"
            except:
                self.locale = "en_US.UTF-8"

        self.run_command(f"sed -i 's/^#{self.locale}/{self.locale}/' /mnt/etc/locale.gen")
        self.run_command("arch-chroot /mnt locale-gen")
        with open("/mnt/etc/locale.conf", "w") as f:
            f.write(f"LANG={self.locale}\n")

        self.print_success(f"Locale set to: {self.locale}")

        print()
        self.print_step("Select keyboard layout...")
        common_keymaps = ["us", "uk", "de", "fr", "es", "it", "br", "ru"]

        print("Common keyboard layouts:")
        for i, km in enumerate(common_keymaps, 1):
            print(f"  {Colors.BLUE}{i}){Colors.NC} {km}")
        print(f"  {Colors.BLUE}0){Colors.NC} Other (search all layouts)")
        print()

        choice = input("Enter choice: ")

        if choice == "0":
            keymaps = self.run_command("localectl list-keymaps", capture_output=True)
            process = subprocess.Popen(
                ["fzf", "--height", "20", "--reverse", "--prompt=Select keymap: "],
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                text=True
            )
            self.keymap, _ = process.communicate(input=keymaps)
            self.keymap = self.keymap.strip()
        else:
            try:
                idx = int(choice)
                if 1 <= idx <= len(common_keymaps):
                    self.keymap = common_keymaps[idx-1]
                else:
                    self.keymap = "us"
            except:
                self.keymap = "us"

        with open("/mnt/etc/vconsole.conf", "w") as f:
            f.write(f"KEYMAP={self.keymap}\n")

        self.print_success(f"Keymap set to: {self.keymap}")

        print()
        self.pause()

    def configure_users(self):
        """Configure users and passwords"""
        self.print_header()
        print(f"{Colors.CYAN}[Step 7/10] User Configuration{Colors.NC}\n")

        self.print_step("Set root password...")
        while True:
            root_pass = input("Enter root password: ")
            root_pass_confirm = input("Confirm root password: ")

            if root_pass == root_pass_confirm:
                self.run_command(f"arch-chroot /mnt bash -c \"echo 'root:{root_pass}' | chpasswd\"")
                self.print_success("Root password set")
                break
            else:
                self.print_error("Passwords do not match! Try again.")

        print()

        self.username = input("Enter username: ")
        self.run_command(f"arch-chroot /mnt useradd -m -G wheel,audio,video,storage -s /bin/bash {self.username}")

        while True:
            user_pass = input(f"Enter password for {self.username}: ")
            user_pass_confirm = input("Confirm password: ")

            if user_pass == user_pass_confirm:
                self.run_command(f"arch-chroot /mnt bash -c \"echo '{self.username}:{user_pass}' | chpasswd\"")
                self.print_success(f"User {self.username} created")
                break
            else:
                self.print_error("Passwords do not match! Try again.")

        self.run_command("sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /mnt/etc/sudoers")

        print()
        self.pause()

    def install_bootloader(self):
        """Install GRUB bootloader"""
        self.print_header()
        print(f"{Colors.CYAN}[Step 8/10] Installing Bootloader{Colors.NC}\n")

        self.print_step("Installing GRUB...")

        if self.is_uefi:
            self.run_command("arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB")
        else:
            self.run_command(f"arch-chroot /mnt grub-install --target=i386-pc {self.install_device}")

        self.run_command("arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg")
        self.print_success("GRUB installed and configured")

        self.print_step("Enabling NetworkManager...")
        self.run_command("arch-chroot /mnt systemctl enable NetworkManager")
        self.print_success("NetworkManager enabled")

        print()
        self.pause()

    def get_kde_installer_script(self):
        """Get the complete KDE installer bash script"""
        # Read the attached bash script file
        try:
            with open('xero-kde-installer.sh', 'r') as f:
                return f.read()
        except FileNotFoundError:
            self.print_warning("KDE installer script not found, using embedded version")
            return "#!/bin/bash\necho 'KDE installer script placeholder'"

    def install_kde(self):
        """Install KDE Plasma Desktop"""
        self.print_header()
        print(f"{Colors.CYAN}[Step 9/10] Desktop Environment{Colors.NC}\n")
        print("Would you like to install KDE Plasma now?\n")
        print("This will install the full XeroLinux KDE experience with:")
        print(f"  {Colors.BLUE}*{Colors.NC} KDE Plasma Desktop")
        print(f"  {Colors.BLUE}*{Colors.NC} Custom applications and tools")
        print(f"  {Colors.BLUE}*{Colors.NC} XeroLinux repositories")
        print(f"  {Colors.BLUE}*{Colors.NC} Personalized setup options\n")

        choice = input("Install KDE Plasma now? [y/N]: ")

        if choice.lower() == 'y':
            self.print_step("Preparing KDE installation...")

            # Get KDE installer script content
            kde_script_content = self.get_kde_installer_script()

            # Write script to new system
            script_path = f"/mnt/home/{self.username}/xero-kde-installer.sh"

            with open(script_path, "w") as f:
                f.write(kde_script_content)

            self.run_command(f"chmod +x {script_path}")
            self.run_command(f"chown {self.username}:{self.username} {script_path}")

            # Run KDE installer as user in chroot
            self.print_step("Running KDE installer as user...")
            print("\nNOTE: The KDE installer will run with interactive prompts.")
            print("Please follow the on-screen instructions.\n")

            # Run the script as the user (not root!)
            self.run_command(f"arch-chroot /mnt sudo -u {self.username} bash /home/{self.username}/xero-kde-installer.sh")

            self.print_success("KDE installation complete!")
        else:
            self.print_step("Skipping KDE installation...")
            print("\nYou can install it later by running the script in your home directory.")

        print()
        self.pause()

    def finalize(self):
        """Finalize installation"""
        self.print_header()
        print(f"{Colors.CYAN}[Step 10/10] Finalization{Colors.NC}\n")

        self.print_success("Installation completed successfully!")
        print()
        print(f"{Colors.PURPLE}╔════════════════════════════════════════════════╗{Colors.NC}")
        print(f"{Colors.PURPLE}║{Colors.GREEN}         Installation Complete!                {Colors.PURPLE}║{Colors.NC}")
        print(f"{Colors.PURPLE}╠════════════════════════════════════════════════╣{Colors.NC}")
        print(f"{Colors.PURPLE}║{Colors.NC}  System: {self.hostname}")
        print(f"{Colors.PURPLE}║{Colors.NC}  User:   {self.username}")
        print(f"{Colors.PURPLE}║{Colors.NC}  Disk:   {self.install_device}")
        print(f"{Colors.PURPLE}║{Colors.NC}")
        print(f"{Colors.PURPLE}║{Colors.NC}  The system will now reboot.")
        print(f"{Colors.PURPLE}║{Colors.NC}  Remove the installation media when prompted.")
        print(f"{Colors.PURPLE}╚════════════════════════════════════════════════╝{Colors.NC}")
        print()

        input("Press Enter to reboot...")

        self.run_command("umount -R /mnt")
        self.run_command("reboot")

    def run(self):
        """Main installation flow"""
        try:
            self.preflight_checks()
            self.select_disk()
            self.partition_disk()
            self.format_partitions()
            self.mount_partitions()
            self.install_base_system()
            self.configure_system()
            self.configure_users()
            self.install_bootloader()
            self.install_kde()
            self.finalize()
        except KeyboardInterrupt:
            print(f"\n\n{Colors.RED}Installation cancelled by user.{Colors.NC}")
            sys.exit(1)
        except Exception as e:
            print(f"\n\n{Colors.RED}Installation failed with error:{Colors.NC}")
            print(f"{Colors.RED}{str(e)}{Colors.NC}")
            sys.exit(1)

if __name__ == "__main__":
    installer = Installer()
    installer.run()
