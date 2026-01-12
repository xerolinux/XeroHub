#!/bin/bash

# XeroLinux KDE Plasma Installer
# A clean and simple KDE installation script for Arch Linux

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Functions
print_header() {
    clear
    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                                                ║${NC}"
    echo -e "${PURPLE}║${CYAN}     ✨ XeroLinux KDE Plasma Installer ✨     ${PURPLE}║${NC}"
    echo -e "${PURPLE}║                                                ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}➜${NC} ${CYAN}$1${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Detect CPU vendor
detect_cpu() {
    if grep -q "GenuineIntel" /proc/cpuinfo; then
        echo "intel"
    elif grep -q "AuthenticAMD" /proc/cpuinfo; then
        echo "amd"
    else
        echo "unknown"
    fi
}

# Detect if running in a VM
detect_vm() {
    if systemd-detect-virt -q; then
        return 0
    else
        return 1
    fi
}

# Detect root filesystem type
detect_filesystem() {
    local root_fs=$(findmnt -n -o FSTYPE /)
    echo "$root_fs"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "Don't run this script as root!"
        exit 1
    fi
}

# Prompt user
prompt_user() {
    print_header

    echo -e "${CYAN}This script will install:${NC}"
    echo -e "  ${BLUE}•${NC} KDE Plasma Desktop (XeroLinux curated selection)"
    echo -e "  ${BLUE}•${NC} Essential System Tools & Utilities"
    echo -e "  ${BLUE}•${NC} Hardware Support & Drivers"
    echo -e "  ${BLUE}•${NC} Multimedia & Graphics Applications"
    echo -e "  ${BLUE}•${NC} Power User Tools (monitoring, development, etc.)"
    echo ""
    echo -e "${YELLOW}⚠ This will modify your system!${NC}"
    echo ""

    read -p "$(echo -e ${GREEN}Do you want to proceed? ${NC}[${GREEN}y${NC}/${RED}N${NC}]: )" -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Installation cancelled by user. Exiting..."
        exit 0
    fi
}

# Customization prompts
customization_prompts() {
    print_header

    echo -e "${CYAN}🎨 Personalization Time!${NC}"
    echo ""
    echo -e "To make your system truly yours, we'll ask you to choose from"
    echo -e "10 quick categories (browsers, apps, tools, etc.)."
    echo ""
    echo -e "${GREEN}Don't worry!${NC} You can skip any category or select multiple options."
    echo -e "This helps keep your system lean with only what ${PURPLE}you${NC} need."
    echo ""
    read -p "Press Enter to continue..."

    # Sub-Prompt 1: Web Browser
    print_header
    echo -e "${CYAN}[1/10] Web Browser${NC}"
    echo -e "Choose your preferred web browser (or press Enter to skip):"
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

    # Sub-Prompt 2: VPN
    print_header
    echo -e "${CYAN}[2/10] VPN Service${NC}"
    echo -e "Choose your VPN client (or press Enter to skip):"
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

    # Sub-Prompt 3: Social Apps
    print_header
    echo -e "${CYAN}[3/10] Social & Communication Apps${NC}"
    echo -e "Choose your social apps (separate multiple with spaces, or press Enter to skip):"
    echo ""
    echo -e "  ${BLUE}1)${NC} ZapZap (WhatsApp)"
    echo -e "  ${BLUE}2)${NC} Tokodon (Mastodon)"
    echo -e "  ${BLUE}3)${NC} Discord"
    echo -e "  ${BLUE}4)${NC} Element (Matrix)"
    echo -e "  ${BLUE}5)${NC} Vesktop (Discord mod)"
    echo -e "  ${BLUE}6)${NC} WebCord (Discord)"
    echo -e "  ${BLUE}7)${NC} Telegram"
    echo -e "  ${BLUE}8)${NC} Ferdium (All-in-one)"
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

    # Sub-Prompt 4: Android Tools
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

    # Sub-Prompt 5: LibreOffice
    print_header
    echo -e "${CYAN}[5/10] Office Suite${NC}"
    echo ""
    read -p "Do you want LibreOffice? [y/N]: " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "Choose your language:"
        echo -e "  ${BLUE}1)${NC} English (en)"
        echo -e "  ${BLUE}2)${NC} Spanish (es)"
        echo -e "  ${BLUE}3)${NC} French (fr)"
        echo -e "  ${BLUE}4)${NC} German (de)"
        echo -e "  ${BLUE}5)${NC} Italian (it)"
        echo -e "  ${BLUE}6)${NC} Portuguese (pt)"
        echo -e "  ${BLUE}7)${NC} Russian (ru)"
        echo -e "  ${BLUE}8)${NC} Chinese (zh-CN)"
        echo -e "  ${BLUE}9)${NC} Japanese (ja)"
        echo ""
        read -p "Enter choice (1-9, default is English): " lang_choice

        case $lang_choice in
            1|"") LANG_CODE="en" ;;
            2) LANG_CODE="es" ;;
            3) LANG_CODE="fr" ;;
            4) LANG_CODE="de" ;;
            5) LANG_CODE="it" ;;
            6) LANG_CODE="pt" ;;
            7) LANG_CODE="ru" ;;
            8) LANG_CODE="zh-CN" ;;
            9) LANG_CODE="ja" ;;
            *) LANG_CODE="en" ;;
        esac

        LIBREOFFICE="hunspell libreoffice-fresh hunspell-$LANG_CODE libreoffice-extension-texmaths libreoffice-extension-writer2latex"
    else
        LIBREOFFICE=""
    fi

    # Sub-Prompt 6: Development Apps
    print_header
    echo -e "${CYAN}[6/10] Development Tools${NC}"
    echo -e "Choose your dev tools (separate multiple with spaces, or press Enter to skip):"
    echo ""
    echo -e "  ${BLUE}1)${NC} Hugo (static site generator)"
    echo -e "  ${BLUE}2)${NC} Meld (diff viewer)"
    echo -e "  ${BLUE}3)${NC} VSCodium"
    echo -e "  ${BLUE}4)${NC} GitHub Desktop"
    echo ""
    read -p "Enter choices (e.g., '1 3', or Enter to skip): " dev_choices

    DEV=""
    for choice in $dev_choices; do
        case $choice in
            1) DEV="$DEV hugo" ;;
            2) DEV="$DEV meld" ;;
            3) DEV="$DEV vscodium-bin" ;;
            4) DEV="$DEV github-desktop" ;;
        esac
    done

    # Sub-Prompt 7: Password Manager
    print_header
    echo -e "${CYAN}[7/10] Password Manager${NC}"
    echo -e "Choose your password manager (separate multiple with spaces, or press Enter to skip):"
    echo ""
    echo -e "  ${BLUE}1)${NC} KeePassXC"
    echo -e "  ${BLUE}2)${NC} Bitwarden"
    echo ""
    read -p "Enter choices (e.g., '1', or Enter to skip): " pass_choices

    PASS=""
    for choice in $pass_choices; do
        case $choice in
            1) PASS="$PASS keepassxc" ;;
            2) PASS="$PASS bitwarden" ;;
        esac
    done

    # Sub-Prompt 8: Imaging/Creative Apps
    print_header
    echo -e "${CYAN}[8/10] Creative & Imaging Apps${NC}"
    echo -e "Choose your creative tools (separate multiple with spaces, or press Enter to skip):"
    echo ""
    echo -e "  ${BLUE}1)${NC} GIMP (photo editing)"
    echo -e "  ${BLUE}2)${NC} Godot (game engine)"
    echo -e "  ${BLUE}3)${NC} Krita (digital painting)"
    echo -e "  ${BLUE}4)${NC} Inkscape (vector graphics)"
    echo -e "  ${BLUE}5)${NC} Blender (3D creation)"
    echo ""
    read -p "Enter choices (e.g., '1 3 5', or Enter to skip): " imaging_choices

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

    # Sub-Prompt 9: Music Apps
    print_header
    echo -e "${CYAN}[9/10] Music & Audio Apps${NC}"
    echo -e "Choose your music apps (separate multiple with spaces, or press Enter to skip):"
    echo ""
    echo -e "  ${BLUE}1)${NC} MPV (media player)"
    echo -e "  ${BLUE}2)${NC} Amarok (music player)"
    echo -e "  ${BLUE}3)${NC} Spotify"
    echo -e "  ${BLUE}4)${NC} Tenacity (audio editor)"
    echo -e "  ${BLUE}5)${NC} JamesDSP (audio effects)"
    echo -e "  ${BLUE}6)${NC} EasyEffects (audio effects)"
    echo ""
    read -p "Enter choices (e.g., '1 3', or Enter to skip): " music_choices

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

    # Sub-Prompt 10: Video Apps
    print_header
    echo -e "${CYAN}[10/10] Video Editing Apps${NC}"
    echo -e "Choose your video tools (separate multiple with spaces, or press Enter to skip):"
    echo ""
    echo -e "  ${BLUE}1)${NC} Mystiq (video converter)"
    echo -e "  ${BLUE}2)${NC} MakeMKV (DVD/Blu-ray ripper)"
    echo -e "  ${BLUE}3)${NC} Kdenlive (video editor)"
    echo -e "  ${BLUE}4)${NC} Avidemux (video editor)"
    echo -e "  ${BLUE}5)${NC} MKVToolNix (MKV tools)"
    echo -e "  ${BLUE}6)${NC} LosslessCut (video trimmer)"
    echo ""
    read -p "Enter choices (e.g., '3 6', or Enter to skip): " video_choices

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

    # Summary
    print_header
    echo -e "${GREEN}✓ Customization complete!${NC}"
    echo ""
    echo -e "${CYAN}Ready to install your personalized KDE Plasma system.${NC}"
    echo ""
    read -p "Press Enter to begin installation..."
}

# Main installation
install_kde() {
    print_header

    print_step "Starting KDE Plasma installation... 🚀"
    echo ""

    # Update system
    print_step "Syncing package databases..."
    sudo pacman -Sy --noconfirm || { print_error "System update failed!"; exit 1; }
    print_success "System updated!"
    echo ""

    # Install KDE Plasma - The XeroLinux Way
    print_step "Installing Core KDE Frameworks... 💎"

    # Core meta packages
    sudo pacman -S --needed --noconfirm \
        kf6 \
        qt6 \
        kde-system || { print_error "Core KDE installation failed!"; exit 1; }

    print_success "Core frameworks installed!"
    echo ""

    print_step "Installing Plasma Components... 🌊"

    # Plasma group - XeroLinux curated selection
    sudo pacman -S --needed --noconfirm \
        kwin krdp milou breeze oxygen aurorae drkonqi kwrited \
        kgamma kscreen sddm-kcm kmenuedit bluedevil kpipewire \
        plasma-nm plasma-pa plasma-sdk libkscreen breeze-gtk \
        powerdevil kinfocenter flatpak-kcm kdecoration ksshaskpass \
        kwallet-pam libksysguard plasma-vault ksystemstats kde-cli-tools \
        oxygen-sounds kscreenlocker kglobalacceld systemsettings \
        kde-gtk-config layer-shell-qt plasma-desktop polkit-kde-agent \
        plasma-workspace kdeplasma-addons ocean-sound-theme qqc2-breeze-style \
        kactivitymanagerd plasma-integration plasma-thunderbolt \
        plasma5-integration plasma-systemmonitor xdg-desktop-portal-kde \
        plasma-browser-integration || { print_error "Plasma components installation failed!"; exit 1; }

    print_success "Plasma components installed!"
    echo ""

    print_step "Installing SDDM Display Manager... 🖥️"
    sudo pacman -S --needed --noconfirm sddm || { print_error "SDDM installation failed!"; exit 1; }
    print_success "SDDM installed!"
    echo ""

    print_step "Enabling SDDM service..."
    sudo systemctl enable sddm.service || { print_error "Failed to enable SDDM!"; exit 1; }
    print_success "SDDM enabled!"
    echo ""

    print_step "Installing KDE Network Tools... 🌐"

    # KDE Network group
    sudo pacman -S --needed --noconfirm \
        krdc krfb smb4k alligator kdeconnect kio-admin kio-extras \
        kio-gdrive konversation kio-zeroconf kdenetwork-filesharing \
        signon-kwallet-extension || print_warning "Some network tools failed (non-critical)"

    print_success "Network tools installed!"
    echo ""

    print_step "Installing KDE Graphics Applications... 🎨"

    # KDE Graphics group
    sudo pacman -S --needed --noconfirm \
        okular kamera svgpart skanlite gwenview spectacle \
        colord-kde kcolorchooser kimagemapeditor \
        kdegraphics-thumbnailers || print_warning "Some graphics apps failed (non-critical)"

    print_success "Graphics applications installed!"
    echo ""

    print_step "Installing KDE Utilities... 🛠️"

    # KDE Utilities group
    sudo pacman -S --needed --noconfirm \
        ark kate kgpg kfind sweeper konsole kdialog yakuake \
        skanpage filelight kmousetool kcharselect markdownpart \
        qalculate-qt keditbookmarks kdebugsettings kwalletmanager \
        dolphin-plugins akregator packagekit-qt5 dolphin || print_warning "Some utilities failed (non-critical)"

    print_success "Utilities installed!"
    echo ""

    print_step "Installing KDE Multimedia... 🎵"

    # KDE Multimedia group
    sudo pacman -S --needed --noconfirm \
        k3b kamoso audiotube plasmatube audiocd-kio || print_warning "Some multimedia apps failed (non-critical)"

    print_success "Multimedia applications installed!"
    echo ""

    print_step "Installing Wayland Support... 🪟"

    # KDE Wayland group
    sudo pacman -S --needed --noconfirm \
        waypipe dwayland egl-wayland qt6-wayland lib32-wayland \
        wayland-protocols kwayland-integration plasma-wayland-protocols || print_warning "Some Wayland packages failed (non-critical)"

    print_success "Wayland support installed!"
    echo ""

    print_step "Installing System Base & Tools... ⚙️"

    # Detect filesystem type and set appropriate package
    ROOT_FS=$(detect_filesystem)
    FS_PROGS=""
    if [ "$ROOT_FS" = "btrfs" ]; then
        print_step "Btrfs filesystem detected..."
        FS_PROGS="btrfs-progs"
    elif [ "$ROOT_FS" = "xfs" ]; then
        print_step "XFS filesystem detected..."
        FS_PROGS="xfsprogs"
    else
        print_step "EXT4/other filesystem detected..."
        FS_PROGS=""
    fi

    # Base system packages
    sudo pacman -S --needed --noconfirm \
        base base-devel archiso b43-fwcutter rsync sdparm ntfs-3g \
        gptfdisk tpm2-tss udftools syslinux fatresize nfs-utils \
        e2fsprogs dosfstools exfatprogs tpm2-tools fsarchiver squashfs-tools \
        gpart dmraid parted hdparm usbmuxd usbutils testdisk ddrescue \
        timeshift partclone partimage clonezilla open-iscsi memtest86+-efi \
        usb_modeswitch $FS_PROGS || print_warning "Some base tools failed (non-critical)"

    print_success "System base installed!"
    echo ""

    print_step "Installing Terminal Tools... 💻"

    sudo pacman -S --needed --noconfirm \
        fd nano tmux brltty msedit nvme-cli terminus-font \
        foot-terminfo kitty-terminfo pv mc gpm nbd lvm2 bolt bind less \
        lynx sudo tldr nmap irssi mdadm wvdial hyperv mtools lsscsi \
        ndisc6 screen man-db xl2tpd tcpdump ethtool xdotool pcsclite \
        espeakup libfido2 xdg-utils man-pages diffutils mmc-utils sg3_utils \
        dmidecode efibootmgr sequoia-sq edk2-shell python-pyqt6 sof-firmware \
        libusb-compat smartmontools wireguard-tools eza ntp cava most wget \
        dialog dnsutils logrotate || print_warning "Some terminal tools failed (non-critical)"

    print_success "Terminal tools installed!"
    echo ""

    print_step "Installing Kernel & Bootloader... 🐧"

    sudo pacman -S --needed --noconfirm \
        linux linux-atm linux-headers grub os-prober grub-hooks update-grub || { print_error "Kernel/bootloader installation failed!"; exit 1; }

    print_success "Kernel & bootloader installed!"
    echo ""

    print_step "Installing XeroLinux Tools... 🎯"

    sudo pacman -S --needed --noconfirm \
        preload extra-scripts || print_warning "Some XeroLinux tools failed (non-critical)"

    print_success "XeroLinux tools installed!"
    echo ""

    print_step "Installing Build Tools & Dependencies... 🔨"

    sudo pacman -S --needed --noconfirm \
        xmlto boost ckbcomp kpmcore yaml-cpp boost-libs \
        gtk-update-icon-cache xdg-terminal-exec-git mkinitcpio mkinitcpio-fw \
        mkinitcpio-utils mkinitcpio-archiso mkinitcpio-openswap \
        mkinitcpio-nfs-utils dex bash make libxinerama bash-completion \
        kirigami polkit-gnome || print_warning "Some build tools failed (non-critical)"

    print_success "Build tools installed!"
    echo ""

    print_step "Installing Hardware Support... 🖥️"

    # CPU microcode detection
    CPU_VENDOR=$(detect_cpu)
    if [ "$CPU_VENDOR" = "intel" ]; then
        print_step "Intel CPU detected, installing Intel microcode..."
        sudo pacman -S --needed --noconfirm fwupd intel-ucode || print_warning "Intel microcode installation failed (non-critical)"
    elif [ "$CPU_VENDOR" = "amd" ]; then
        print_step "AMD CPU detected, installing AMD microcode..."
        sudo pacman -S --needed --noconfirm fwupd amd-ucode || print_warning "AMD microcode installation failed (non-critical)"
    else
        print_warning "Unknown CPU vendor, skipping microcode installation"
        sudo pacman -S --needed --noconfirm fwupd || print_warning "Firmware tools installation failed (non-critical)"
    fi

    # Video drivers
    sudo pacman -S --needed --noconfirm \
        mesa autorandr mesa-utils lib32-mesa \
        xf86-video-qxl xf86-video-fbdev lib32-mesa-utils || print_warning "Some video drivers failed (non-critical)"

    # Printer/Scanner
    sudo pacman -S --needed --noconfirm \
        hplip print-manager scanner-support printer-support || print_warning "Printer support failed (non-critical)"

    # Input devices
    sudo pacman -S --needed --noconfirm \
        orca onboard libinput xf86-input-void xf86-input-evdev \
        iio-sensor-proxy game-devices-udev xf86-input-vmmouse \
        xf86-input-libinput xf86-input-synaptics xf86-input-elographics || print_warning "Some input drivers failed (non-critical)"

    print_success "Hardware support installed!"
    echo ""

    print_step "Installing Audio & Multimedia... 🔊"

    # GStreamer
    sudo pacman -S --needed --noconfirm \
        gstreamer gst-libav gst-plugins-bad gst-plugins-base \
        gst-plugins-ugly gst-plugins-good gst-plugins-espeak \
        gst-plugin-pipewire || print_warning "GStreamer plugins failed (non-critical)"

    # Multimedia tools
    sudo pacman -S --needed --noconfirm \
        ffmpeg ffmpegthumbs ffnvcodec-headers || print_warning "FFmpeg tools failed (non-critical)"

    print_success "Audio & multimedia installed!"
    echo ""

    print_step "Installing Bluetooth & Networking... 📡"

    # Bluetooth
    sudo pacman -S --needed --noconfirm \
        bluez bluez-libs bluez-utils bluez-tools bluez-plugins bluez-hid2hci || print_warning "Bluetooth failed (non-critical)"

    # Networking
    sudo pacman -S --needed --noconfirm \
        iw iwd ppp lftp ldns avahi samba netctl dhcpcd openssh openvpn \
        dnsmasq dhclient openldap nss-mdns smbclient net-tools openresolv \
        darkhttpd reflector pptpclient cloud-init openconnect traceroute \
        networkmanager nm-cloud-setup wireless-regdb wireless_tools \
        wpa_supplicant modemmanager-qt openpgp-card-tools systemd-resolvconf || print_warning "Some networking tools failed (non-critical)"

    print_success "Bluetooth & networking installed!"
    echo ""

    print_step "Installing Xorg & Display Server... 🪟"

    sudo pacman -S --needed --noconfirm \
        xorg-apps xorg-xinit xorg-server xorg-xwayland || { print_error "Xorg installation failed!"; exit 1; }

    print_success "Xorg installed!"
    echo ""

    print_step "Installing Applications & Utilities... 📦"

    sudo pacman -S --needed --noconfirm \
        falkon hblock cryptsetup brightnessctl switcheroo-control \
        power-profiles-daemon jq vim figlet ostree lolcat numlockx \
        localsend lm_sensors appstream-glib lib32-lm_sensors bat bat-extras || print_warning "Some utilities failed (non-critical)"

    print_success "Applications installed!"
    echo ""

    print_step "Installing Fonts... 🔤"

    sudo pacman -S --needed --noconfirm \
        ttf-fira-code otf-libertinus tex-gyre-fonts ttf-hack-nerd \
        ttf-ubuntu-font-family awesome-terminal-fonts ttf-jetbrains-mono-nerd \
        adobe-source-sans-pro-fonts || print_warning "Some fonts failed (non-critical)"

    print_success "Fonts installed!"
    echo ""

    print_step "Installing Theming & Customization... 🎨"

    sudo pacman -S --needed --noconfirm \
        kvantum fastfetch adw-gtk-theme oh-my-posh-bin gnome-themes-extra \
        kwin-effect-rounded-corners-git kwin-zones kde-wallpapers \
        kwin-scripts-kzones tela-circle-icon-theme-purple || print_warning "Some themes failed (non-critical)"

    # Kate plugins
    sudo pacman -S --needed --noconfirm \
        bash-language-server typescript-language-server vscode-json-languageserver || print_warning "Kate plugins failed (non-critical)"

    print_success "Theming & customization installed!"
    echo ""

    print_step "Installing File Management & Libraries... 📁"

    # GVFS
    sudo pacman -S --needed --noconfirm \
        gvfs mtpfs udiskie udisks2 ldmtool gvfs-afc gvfs-mtp gvfs-nfs \
        gvfs-smb gvfs-goa gvfs-wsdd gvfs-dnssd gvfs-google gvfs-gphoto2 \
        gvfs-onedrive || print_warning "GVFS components failed (non-critical)"

    # Tumbler
    sudo pacman -S --needed --noconfirm \
        libgsf tumbler freetype2 libopenraw poppler-qt6 poppler-glib \
        ffmpegthumbnailer || print_warning "Tumbler components failed (non-critical)"

    # Python libraries
    sudo pacman -S --needed --noconfirm \
        python-pip python-cffi python-numpy python-docopt python-pyaudio \
        python-pyparted python-pygments python-websockets || print_warning "Python libraries failed (non-critical)"

    print_success "File management & libraries installed!"
    echo ""

    print_step "Installing Package Management Tools... 📦"

    sudo pacman -S --needed --noconfirm \
        paru flatpak topgrade appstream-qt pacman-contrib pacman-bintrans || print_warning "Some package tools failed (non-critical)"

    print_success "Package management tools installed!"
    echo ""

    print_step "Installing System Essentials... ⚡"

    sudo pacman -S --needed --noconfirm \
        xdg-user-dirs ocs-url xmlstarlet yt-dlp wavpack unarchiver \
        rate-mirrors gnustep-base parallel xsettingsd polkit-qt6 \
        systemdgenie gnome-keyring || print_warning "Some system tools failed (non-critical)"

    print_success "System essentials installed!"
    echo ""

    print_step "Installing Power User Tools & Enhancements... ⚡"

    # Development & Build Tools
    sudo pacman -S --needed --noconfirm \
        vi gcc git npm nodejs vala meson gettext intltool node-gyp \
        graphviz pkgconf semver || print_warning "Some dev tools failed (non-critical)"

    # System Monitoring & Info
    sudo pacman -S --needed --noconfirm \
        duf btop htop iftop nvtop vnstat inxi lshw hwinfo nmon \
        sysprof || print_warning "Some monitoring tools failed (non-critical)"

    # Archive & Compression
    sudo pacman -S --needed --noconfirm \
        zip unzip unrar p7zip lzop lhasa unace fuseiso || print_warning "Some archive tools failed (non-critical)"

    # File System & Storage
    sudo pacman -S --needed --noconfirm \
        fuse3 sshfs s3fs-fuse cifs-utils gparted gnome-disk-utility \
        grsync hddtemp mlocate || print_warning "Some filesystem tools failed (non-critical)"

    # Network & System Utilities
    sudo pacman -S --needed --noconfirm \
        pciutils inetutils cronie playerctl asciinema ventoy-bin \
        downgrade pkgstats lsb-release laptop-detect || print_warning "Some utilities failed (non-critical)"

    # Libraries & Dependencies
    sudo pacman -S --needed --noconfirm \
        yad xdo gum tree expac cblas glfw rhash assimp netpbm wmctrl \
        libmtp polkit zenity jsoncpp oniguruma dbus-python dconf-editor \
        perl-xml-parser appmenu-gtk-module arandr || print_warning "Some libraries failed (non-critical)"

    print_success "Power user tools installed!"
    echo ""

    # Install user-selected applications
    if [ -n "$BROWSER" ]; then
        print_step "Installing selected browser ($BROWSER)... 🌐"
        sudo pacman -S --needed --noconfirm $BROWSER || print_warning "Browser installation failed (non-critical)"
        print_success "Browser installed!"
        echo ""
    fi

    if [ -n "$VPN" ]; then
        print_step "Installing selected VPN ($VPN)... 🔒"
        sudo pacman -S --needed --noconfirm $VPN || print_warning "VPN installation failed (non-critical)"
        print_success "VPN installed!"
        echo ""
    fi

    if [ -n "$SOCIAL" ]; then
        print_step "Installing social apps... 💬"
        sudo pacman -S --needed --noconfirm $SOCIAL || print_warning "Some social apps failed (non-critical)"
        print_success "Social apps installed!"
        echo ""
    fi

    if [ -n "$ANDROID" ]; then
        print_step "Installing Android tools... 📱"
        sudo pacman -S --needed --noconfirm $ANDROID || print_warning "Some Android tools failed (non-critical)"
        print_success "Android tools installed!"
        echo ""
    fi

    if [ -n "$LIBREOFFICE" ]; then
        print_step "Installing LibreOffice... 📄"
        sudo pacman -S --needed --noconfirm $LIBREOFFICE || print_warning "LibreOffice installation failed (non-critical)"
        print_success "LibreOffice installed!"
        echo ""
    fi

    if [ -n "$DEV" ]; then
        print_step "Installing development tools... 💻"
        sudo pacman -S --needed --noconfirm $DEV || print_warning "Some dev tools failed (non-critical)"
        print_success "Development tools installed!"
        echo ""
    fi

    if [ -n "$PASS" ]; then
        print_step "Installing password manager(s)... 🔐"
        sudo pacman -S --needed --noconfirm $PASS || print_warning "Password manager installation failed (non-critical)"
        print_success "Password manager installed!"
        echo ""
    fi

    if [ -n "$IMAGING" ]; then
        print_step "Installing creative apps... 🎨"
        sudo pacman -S --needed --noconfirm $IMAGING || print_warning "Some creative apps failed (non-critical)"
        print_success "Creative apps installed!"
        echo ""
    fi

    if [ -n "$MUSIC" ]; then
        print_step "Installing music apps... 🎵"
        sudo pacman -S --needed --noconfirm $MUSIC || print_warning "Some music apps failed (non-critical)"
        print_success "Music apps installed!"
        echo ""
    fi

    if [ -n "$VIDEO" ]; then
        print_step "Installing video apps... 🎬"
        sudo pacman -S --needed --noconfirm $VIDEO || print_warning "Some video apps failed (non-critical)"
        print_success "Video apps installed!"
        echo ""
    fi

    print_step "Installing Virtual Machine Support... 🖧"

    if detect_vm; then
        VM_TYPE=$(systemd-detect-virt)
        print_step "Virtual Machine detected ($VM_TYPE), installing VM tools..."
        sudo pacman -S --needed --noconfirm \
            spice-vdagent open-vm-tools qemu-guest-agent virtualbox-guest-utils || print_warning "Some VM tools failed (non-critical)"
        print_success "VM support installed!"
    else
        print_step "Physical machine detected, skipping VM tools..."
    fi
    echo ""

    print_step "Updating initramfs... 🔄"

    sudo mkinitcpio -P || { print_error "Failed to update initramfs!"; exit 1; }
    print_success "Initramfs updated!"
    echo ""

    print_step "Updating GRUB configuration... 🔄"

    sudo update-grub || { print_error "Failed to update GRUB!"; exit 1; }
    print_success "GRUB configuration updated!"
    echo ""

    print_step "Enabling essential services... ⚙️"

    # Enable services
    sudo systemctl enable cups.socket || print_warning "Failed to enable cups.socket"
    sudo systemctl enable saned.socket || print_warning "Failed to enable saned.socket"
    sudo systemctl enable NetworkManager || print_warning "Failed to enable NetworkManager"
    sudo systemctl enable bluetooth || print_warning "Failed to enable bluetooth"
    sudo systemctl enable power-profiles-daemon || print_warning "Failed to enable power-profiles-daemon"
    sudo systemctl enable switcheroo-control || print_warning "Failed to enable switcheroo-control"
    sudo systemctl enable dhcpcd || print_warning "Failed to enable dhcpcd"
    sudo systemctl enable preload || print_warning "Failed to enable preload"
    sudo systemctl enable sshd || print_warning "Failed to enable sshd"

    print_success "Essential services enabled!"
    echo ""

    print_step "Disabling unnecessary services... 🚫"

    # Disable services
    sudo systemctl disable systemd-time-wait-sync || print_warning "Failed to disable systemd-time-wait-sync"
    sudo systemctl disable reflector || print_warning "Failed to disable reflector"
    sudo systemctl disable pacman-init || print_warning "Failed to disable pacman-init"

    print_success "Unnecessary services disabled!"
    echo ""

    # Offer Xero-Layan rice
    print_header
    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                                                ║${NC}"
    echo -e "${PURPLE}║${CYAN}        ✨ One More Thing... ✨                ${PURPLE}║${NC}"
    echo -e "${PURPLE}║                                                ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Would you like to apply the famous Xero-Layan theme?${NC}"
    echo ""
    echo -e "The Xero-Layan rice is a beautiful, cohesive design that"
    echo -e "transforms KDE Plasma into a stunning desktop experience."
    echo ""
    echo -e "It includes:"
    echo -e "  ${BLUE}•${NC} Custom Layan theme & colors"
    echo -e "  ${BLUE}•${NC} Carefully crafted panel layouts"
    echo -e "  ${BLUE}•${NC} Beautiful window decorations"
    echo -e "  ${BLUE}•${NC} Matching icons & cursors"
    echo ""
    read -p "$(echo -e ${GREEN}Apply Xero-Layan theme? ${NC}[${GREEN}y${NC}/${RED}N${NC}]: )" -n 1 -r
    echo ""
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_step "Preparing for Xero-Layan configuration... 📁"
        
        # Create ~/.config if it doesn't exist (required for rice backup)
        mkdir -p ~/.config
        print_success "Config directory ready!"
        echo ""
        
        print_step "Downloading Xero-Layan configuration... 🎨"

        cd /tmp || exit 1
        git clone https://github.com/xerolinux/xero-layan-git || { print_warning "Failed to clone Xero-Layan repo"; }

        if [ -d "xero-layan-git" ]; then
            print_success "Repository cloned!"
            echo ""
            print_step "Applying Xero-Layan theme... ✨"

            cd xero-layan-git || exit 1
            chmod +x install.sh
            ./install.sh
            rm -rf ~/.config-*

            print_success "Xero-Layan theme applied!"
            echo ""
        fi
    else
        print_step "Skipping Xero-Layan theme..."
        echo ""
    fi

    # Final message
    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${GREEN}     🎉 Installation Complete! 🎉              ${PURPLE}║${NC}"
    echo -e "${PURPLE}╠════════════════════════════════════════════════╣${NC}"
    echo -e "${PURPLE}║${NC}  Your personalized KDE Plasma is ready!       ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}  Reboot to experience your new desktop        ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}                                                ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}  Command: ${YELLOW}sudo reboot${NC}                        ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Run the script
check_root
prompt_user
customization_prompts
install_kde
