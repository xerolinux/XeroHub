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
NC='\033[0m' # No Color :(

# Functions
print_header() {
    clear
    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                                                ║${NC}"
    echo -e "${PURPLE}║${CYAN}     ✨ XeroLinux KDE Plasma Installer ✨       ${PURPLE}║${NC}"
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

# Detect if running in a VM
detect_vm() {
    if systemd-detect-virt -q; then
        return 0
    else
        return 1
    fi
}

# Detect if running in chroot environment
detect_chroot() {
    if [ "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/.)" ] 2>/dev/null; then
        return 0  # In chroot
    elif [ -f /etc/arch-chroot ]; then
        return 0  # In chroot
    elif [ "$EUID" -eq 0 ] && [ -z "$SUDO_USER" ]; then
        return 0  # Running as root without sudo (likely chroot)
    else
        return 1  # Not in chroot
    fi
}

# Set up sudo command (empty if running as root/in chroot)
setup_sudo() {
    if [ "$EUID" -eq 0 ]; then
        SUDO_CMD=""
        print_step "Running as root (chroot environment detected)"
    else
        SUDO_CMD="sudo"
    fi
}

# Check if running as root (only warn if NOT in chroot)
check_root() {
    if [[ $EUID -eq 0 ]] && ! detect_chroot; then
        print_error "Don't run this script as root!"
        exit 1
    fi
    setup_sudo
}

# Prompt user
prompt_user() {
    print_header

    echo -e "${CYAN}This script will install:${NC}"
    echo -e "  ${BLUE}•${NC} KDE Plasma Desktop (XeroLinux curated selection)"
    echo -e "  ${BLUE}•${NC} Essential KDE Applications"
    echo -e "  ${BLUE}•${NC} Your selected AUR helper & packages"
    echo -e "  ${BLUE}•${NC} XeroLinux configurations"
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

# Step A: AUR Helper Selection
select_aur_helper() {
    print_header

    echo -e "${CYAN}🔧 AUR Helper Selection${NC}"
    echo ""
    echo -e "Choose your preferred AUR helper:"
    echo ""
    echo -e "  ${BLUE}1)${NC} paru  (Rust-based, feature-rich)"
    echo -e "  ${BLUE}2)${NC} yay   (Go-based, popular choice)"
    echo ""
    read -p "Enter choice (1 or 2, default is paru): " aur_choice

    case $aur_choice in
        2) AUR_HELPER="yay" ;;
        *) AUR_HELPER="paru" ;;
    esac

    print_success "Selected AUR helper: $AUR_HELPER"
    echo ""
}

# Customization prompts
customization_prompts() {
    print_header

    echo -e "${CYAN}🎨 Personalization Time!${NC}"
    echo ""
    echo -e "To make your system truly yours, we'll ask you to choose from"
    echo -e "a few quick categories (browsers, apps, tools, etc.)."
    echo ""
    echo -e "${GREEN}Don't worry!${NC} You can skip any category or select multiple options."
    echo -e "This helps keep your system lean with only what ${PURPLE}you${NC} need."
    echo ""
    read -p "Press Enter to continue..."

    # Sub-Prompt 1: Web Browser
    print_header
    echo -e "${CYAN}[1/12] Web Browser${NC}"
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
    echo -e "${CYAN}[2/12] VPN Service${NC}"
    echo -e "Choose your VPN client (or press Enter to skip):"
    echo ""
    echo -e "  ${BLUE}1)${NC} ExpressVPN"
    echo -e "  ${BLUE}2)${NC} Mozilla VPN"
    echo -e "  ${BLUE}3)${NC} Proton VPN"
    echo ""
    read -p "Enter choice (1-3, or Enter to skip): " vpn_choice

    case $vpn_choice in
        1) VPN="expressvpn" ;;
        2) VPN="mozillavpn" ;;
        3) VPN="proton-vpn-cli" ;;
        *) VPN="" ;;
    esac

    # Sub-Prompt 3: Social Apps
    print_header
    echo -e "${CYAN}[3/12] Social & Communication Apps${NC}"
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
    echo -e "${CYAN}[4/12] Android Development Tools${NC}"
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
    echo -e "${CYAN}[5/12] Office Suite${NC}"
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
    echo -e "${CYAN}[6/12] Development Tools${NC}"
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
    echo -e "${CYAN}[7/12] Password Manager${NC}"
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
    echo -e "${CYAN}[8/12] Creative & Imaging Apps${NC}"
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
    echo -e "${CYAN}[9/12] Music & Audio Apps${NC}"
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
    echo -e "${CYAN}[10/12] Video Editing Apps${NC}"
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

    # Sub-Prompt 11: Apple Sideloading
    print_header
    echo -e "${CYAN}[11/12] Apple Sideloading App${NC}"
    echo ""
    read -p "Do you want Apple Sideloading App (plume-impactor)? [y/N]: " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        APPLE_SIDELOAD="plume-impactor"
    else
        APPLE_SIDELOAD=""
    fi

    # Sub-Prompt 12: QEMU Virtual Machine
    print_header
    echo -e "${CYAN}[12/12] QEMU Virtual Machine${NC}"
    echo ""
    read -p "Do you want QEMU Virtual Machine support? [y/N]: " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        QEMU_VM="yes"
    else
        QEMU_VM=""
    fi

    # Summary
    print_header
    echo -e "${GREEN}✓ Customization complete!${NC}"
    echo ""
    echo -e "${CYAN}Ready to install your personalized KDE Plasma system.${NC}"
    echo ""
    read -p "Press Enter to begin installation..."
}

# Step B: Install all KDE packages consolidated + enable sddm
install_kde() {
    print_header

    print_step "Starting KDE Plasma installation... 🚀"
    echo ""

    # Update system
    print_step "Syncing package databases..."
    $SUDO_CMD pacman -Sy --noconfirm || { print_error "System update failed!"; exit 1; }
    print_success "System synced!"
    echo ""

    # Install selected AUR helper
    print_step "Installing AUR helper ($AUR_HELPER)... 📦"
    $SUDO_CMD pacman -S --needed --noconfirm $AUR_HELPER || { print_error "AUR helper installation failed!"; exit 1; }
    print_success "AUR helper ($AUR_HELPER) installed!"
    echo ""

    # Step B: Install all KDE packages consolidated
    print_step "Installing KDE Plasma Desktop Environment... 💎"

    $SUDO_CMD pacman -S --needed --noconfirm \
        kf6 qt6 kde-system kwin krdp milou breeze oxygen aurorae drkonqi kwrited \
        kgamma kscreen sddm sddm-kcm kmenuedit bluedevil kpipewire plasma-nm plasma-pa \
        plasma-sdk libkscreen breeze-gtk powerdevil kinfocenter flatpak-kcm \
        kdecoration ksshaskpass kwallet-pam libksysguard plasma-vault ksystemstats \
        kde-cli-tools oxygen-sounds kscreenlocker kglobalacceld systemsettings \
        kde-gtk-config layer-shell-qt plasma-desktop polkit-kde-agent plasma-workspace \
        kdeplasma-addons ocean-sound-theme qqc2-breeze-style kactivitymanagerd \
        plasma-integration plasma-thunderbolt plasma5-integration plasma-systemmonitor \
        xdg-desktop-portal-kde plasma-browser-integration \
        krdc krfb smb4k alligator kdeconnect kio-admin kio-extras kio-gdrive \
        konversation kio-zeroconf kdenetwork-filesharing signon-kwallet-extension \
        okular kamera svgpart skanlite gwenview spectacle colord-kde kcolorchooser \
        kimagemapeditor kdegraphics-thumbnailers \
        ark kate kgpg kfind sweeper konsole kdialog yakuake skanpage filelight \
        kmousetool kcharselect markdownpart qalculate-qt keditbookmarks kdebugsettings \
        kwalletmanager dolphin-plugins akregator \
        k3b kamoso audiotube plasmatube audiocd-kio \
        waypipe dwayland egl-wayland qt6-wayland lib32-wayland wayland-protocols \
        kwayland-integration plasma-wayland-protocols || { print_error "KDE installation failed!"; exit 1; }

    print_success "KDE Plasma Desktop installed!"
    echo ""

    # Enable SDDM service immediately after KDE install
    print_step "Enabling SDDM service... 🖥️"
    $SUDO_CMD systemctl enable sddm.service || { print_error "Failed to enable SDDM!"; exit 1; }
    print_success "SDDM enabled!"
    echo ""
}

# Step C: Install custom non-KDE packages (excluding what's already in xero-install.sh)
install_custom_pkgs() {
    print_header

    print_step "Installing Additional System Packages... ⚙️"
    echo ""

    # These packages are NOT in xero-install.sh
    $SUDO_CMD pacman -S --needed --noconfirm \
        vi duf gcc npm yad zip xdo gum inxi lzop nmon tree vala btop glfw htop lshw \
        cblas expac fuse3 lhasa meson unace unrar unzip p7zip iftop nvtop rhash sshfs \
        vnstat nodejs cronie hwinfo arandr assimp netpbm wmctrl grsync libmtp polkit \
        sysprof semver zenity gparted hddtemp mlocate jsoncpp fuseiso gettext node-gyp \
        intltool graphviz pkgstats pciutils inetutils downgrade s3fs-fuse playerctl \
        asciinema oniguruma ventoy-bin cifs-utils lsb-release dbus-python dconf-editor \
        laptop-detect perl-xml-parser gnome-disk-utility appmenu-gtk-module \
        parallel xsettingsd polkit-qt6 systemdgenie gnome-keyring \
        yt-dlp wavpack unarchiver rate-mirrors gnustep-base ocs-url xmlstarlet \
        python-pip python-cffi python-numpy python-docopt python-pyaudio \
        python-pyparted python-pygments python-websockets \
        libgsf tumbler freetype2 libopenraw poppler-qt6 poppler-glib ffmpegthumbnailer \
        gvfs mtpfs udiskie udisks2 ldmtool gvfs-afc gvfs-mtp gvfs-nfs gvfs-smb \
        gvfs-goa gvfs-wsdd gvfs-dnssd gvfs-google gvfs-gphoto2 gvfs-onedrive \
        flatpak topgrade appstream-qt pacman-contrib pacman-bintrans \
        ffmpeg ffmpegthumbs ffnvcodec-headers \
        kwin-zones kde-wallpapers kwin-scripts-kzones tela-circle-icon-theme-purple \
        kvantum fastfetch adw-gtk-theme oh-my-posh-bin gnome-themes-extra \
        kwin-effect-rounded-corners-git \
        bash-language-server typescript-language-server vscode-json-languageserver \
        ttf-fira-code otf-libertinus tex-gyre-fonts ttf-hack-nerd ttf-ubuntu-font-family \
        awesome-terminal-fonts ttf-jetbrains-mono-nerd adobe-source-sans-pro-fonts \
        bat bat-extras jq vim figlet ostree lolcat numlockx localsend lm_sensors \
        appstream-glib lib32-lm_sensors \
        xmlto ckbcomp yaml-cpp kirigami boost-libs polkit-gnome gtk-update-icon-cache \
        dex bash make libxinerama bash-completion \
        hblock cryptsetup brightnessctl switcheroo-control power-profiles-daemon \
        mkinitcpio mkinitcpio-utils mkinitcpio-archiso mkinitcpio-openswap \
        mkinitcpio-nfs-utils \
        boost kpmcore xdg-terminal-exec-git \
        preload xero-toolkit extra-scripts desktop-config xero-gpu-tools \
        eza ntp cava most dialog dnsutils logrotate xdg-user-dirs \
        archiso rsync sdparm ntfs-3g tpm2-tss udftools syslinux fatresize \
        nfs-utils exfatprogs tpm2-tools fsarchiver squashfs-tools \
        gpart dmraid parted hdparm usbmuxd usbutils testdisk ddrescue timeshift \
        partclone partimage clonezilla open-iscsi memtest86+-efi usb_modeswitch \
        fd tmux brltty msedit nvme-cli terminus-font foot-terminfo kitty-terminfo \
        pv mc gpm nbd lvm2 bolt bind less lynx tldr nmap irssi mdadm wvdial hyperv \
        mtools lsscsi ndisc6 screen man-db tcpdump ethtool xdotool pcsclite \
        espeakup libfido2 xdg-utils man-pages diffutils mmc-utils sg3_utils dmidecode \
        sequoia-sq edk2-shell python-pyqt6 libusb-compat smartmontools \
        wireguard-tools || print_warning "Some packages failed (non-critical)"

    print_success "Additional system packages installed!"
    echo ""
}

# Step D: Install user-selected packages
install_user_packages() {
    print_header

    print_step "Installing User-Selected Packages... 🎯"
    echo ""

    if [ -n "$BROWSER" ]; then
        print_step "Installing selected browser ($BROWSER)... 🌐"
        $SUDO_CMD pacman -S --needed --noconfirm $BROWSER || print_warning "Browser installation failed (non-critical)"
        print_success "Browser installed!"
        echo ""
    fi

    if [ -n "$VPN" ]; then
        print_step "Installing selected VPN ($VPN)... 🔒"
        $SUDO_CMD pacman -S --needed --noconfirm $VPN || print_warning "VPN installation failed (non-critical)"
        print_success "VPN installed!"
        echo ""
    fi

    if [ -n "$SOCIAL" ]; then
        print_step "Installing social apps... 💬"
        $SUDO_CMD pacman -S --needed --noconfirm $SOCIAL || print_warning "Some social apps failed (non-critical)"
        print_success "Social apps installed!"
        echo ""
    fi

    if [ -n "$ANDROID" ]; then
        print_step "Installing Android tools... 📱"
        $SUDO_CMD pacman -S --needed --noconfirm $ANDROID || print_warning "Some Android tools failed (non-critical)"
        print_success "Android tools installed!"
        echo ""
    fi

    if [ -n "$LIBREOFFICE" ]; then
        print_step "Installing LibreOffice... 📄"
        $SUDO_CMD pacman -S --needed --noconfirm $LIBREOFFICE || print_warning "LibreOffice installation failed (non-critical)"
        print_success "LibreOffice installed!"
        echo ""
    fi

    if [ -n "$DEV" ]; then
        print_step "Installing development tools... 💻"
        $SUDO_CMD pacman -S --needed --noconfirm $DEV || print_warning "Some dev tools failed (non-critical)"
        print_success "Development tools installed!"
        echo ""
    fi

    if [ -n "$PASS" ]; then
        print_step "Installing password manager(s)... 🔐"
        $SUDO_CMD pacman -S --needed --noconfirm $PASS || print_warning "Password manager installation failed (non-critical)"
        print_success "Password manager installed!"
        echo ""
    fi

    if [ -n "$IMAGING" ]; then
        print_step "Installing creative apps... 🎨"
        $SUDO_CMD pacman -S --needed --noconfirm $IMAGING || print_warning "Some creative apps failed (non-critical)"
        print_success "Creative apps installed!"
        echo ""
    fi

    if [ -n "$MUSIC" ]; then
        print_step "Installing music apps... 🎵"
        $SUDO_CMD pacman -S --needed --noconfirm $MUSIC || print_warning "Some music apps failed (non-critical)"
        print_success "Music apps installed!"
        echo ""
    fi

    if [ -n "$VIDEO" ]; then
        print_step "Installing video apps... 🎬"
        $SUDO_CMD pacman -S --needed --noconfirm $VIDEO || print_warning "Failed to install some video apps (non-critical)"
        print_success "Video apps installed!"
        echo ""
    fi

    if [ -n "$APPLE_SIDELOAD" ]; then
        print_step "Installing Apple Sideloading App... 🍎"
        $SUDO_CMD pacman -S --needed --noconfirm $APPLE_SIDELOAD || print_warning "Apple Sideloading installation failed (non-critical)"
        print_success "Apple Sideloading App installed!"
        echo ""
    fi

    if [ -n "$QEMU_VM" ]; then
        print_step "Installing QEMU Virtual Machine support... 🖥️"
        $SUDO_CMD pacman -Rdd --noconfirm iptables gnu-netcat 2>/dev/null || true
        $SUDO_CMD pacman -S --needed --noconfirm virt-manager-meta openbsd-netcat || print_warning "QEMU installation failed (non-critical)"
        echo "options kvm-intel nested=1" | $SUDO_CMD tee /etc/modprobe.d/kvm-intel.conf > /dev/null
        $SUDO_CMD systemctl enable libvirtd.service || print_warning "Failed to enable libvirtd service"
        print_success "QEMU Virtual Machine support installed!"
        echo ""
    fi

    print_success "User-selected packages installed!"
    echo ""
}

# Install VM support if detected
install_vm_support() {
    print_step "Checking for Virtual Machine environment... 🖧"

    if detect_vm; then
        VM_TYPE=$(systemd-detect-virt)
        print_step "Virtual Machine detected ($VM_TYPE), installing VM tools..."
        $SUDO_CMD pacman -S --needed --noconfirm \
            spice-vdagent open-vm-tools qemu-guest-agent virtualbox-guest-utils || print_warning "Some VM tools failed (non-critical)"
        print_success "VM support installed!"
    else
        print_step "Physical machine detected, skipping VM tools..."
    fi
    echo ""
}

# System finalization
finalize_system() {
    print_header

    print_step "Finalizing system configuration... ⚙️"
    echo ""

    print_step "Updating initramfs... 🔄"
    $SUDO_CMD mkinitcpio -P || { print_error "Failed to update initramfs!"; exit 1; }
    print_success "Initramfs updated!"
    echo ""

    print_step "Updating GRUB configuration... 🔄"
    $SUDO_CMD update-grub || { print_error "Failed to update GRUB!"; exit 1; }
    print_success "GRUB configuration updated!"
    echo ""

    print_step "Enabling essential services... ⚙️"

    # Enable services
    $SUDO_CMD systemctl enable cups.socket || print_warning "Failed to enable cups.socket"
    $SUDO_CMD systemctl enable saned.socket || print_warning "Failed to enable saned.socket"
    $SUDO_CMD systemctl enable bluetooth || print_warning "Failed to enable bluetooth"
    $SUDO_CMD systemctl enable power-profiles-daemon || print_warning "Failed to enable power-profiles-daemon"
    $SUDO_CMD systemctl enable switcheroo-control || print_warning "Failed to enable switcheroo-control"
    $SUDO_CMD systemctl enable dhcpcd || print_warning "Failed to enable dhcpcd"
    $SUDO_CMD systemctl enable preload || print_warning "Failed to enable preload"
    $SUDO_CMD systemctl enable sshd || print_warning "Failed to enable sshd"
    $SUDO_CMD systemctl enable xero-gpu-check || print_warning "Failed to enable xero-gpu-check"

    print_success "Essential services enabled!"
    echo ""

    print_step "Disabling unnecessary services... 🚫"

    # Disable services
    $SUDO_CMD systemctl disable systemd-time-wait-sync || print_warning "Failed to disable systemd-time-wait-sync"
    $SUDO_CMD systemctl disable reflector || print_warning "Failed to disable reflector"
    $SUDO_CMD systemctl disable pacman-init || print_warning "Failed to disable pacman-init"

    print_success "Unnecessary services disabled!"
    echo ""
}

# Step E: Copy skel to actual created user's home
copy_skel_to_user() {
    print_header

    print_step "Applying XeroLinux configurations... 📁"
    echo ""

    # Determine the actual user (not root)
    if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
        ACTUAL_USER="$SUDO_USER"
    elif [[ "$EUID" -eq 0 ]]; then
        # In chroot/root context: pick first "real" user with /home (UID >= 1000, not nobody)
        ACTUAL_USER="$(getent passwd | awk -F: '$3 >= 1000 && $3 < 65534 && $1 != "nobody" && $6 ~ /^\/home\// {print $1; exit}')"
    else
        ACTUAL_USER="$USER"
    fi

    if [[ -z "${ACTUAL_USER:-}" ]]; then
        print_warning "Could not determine target user, skipping config copy"
        return 1
    fi

    ACTUAL_HOME="$(getent passwd "$ACTUAL_USER" | cut -d: -f6)"

    if [[ -z "${ACTUAL_HOME:-}" || ! -d "$ACTUAL_HOME" ]]; then
        print_warning "User home directory not found for $ACTUAL_USER ($ACTUAL_HOME), skipping user config copy"
        # We still continue with root tasks below.
    else
        print_step "Copying /etc/skel configurations to $ACTUAL_HOME for user $ACTUAL_USER..."
        echo ""

        # Copy as the user so ownership is correct
        if [[ "$EUID" -eq 0 ]]; then
            if command -v runuser >/dev/null 2>&1; then
                runuser -l "$ACTUAL_USER" -c 'cp -a /etc/skel/. "$HOME"/'
            else
                su - "$ACTUAL_USER" -c 'cp -a /etc/skel/. "$HOME"/'
            fi

            # Ensure proper ownership
            chown -R "$ACTUAL_USER:$ACTUAL_USER" "$ACTUAL_HOME"
        else
            sudo -u "$ACTUAL_USER" bash -lc 'cp -a /etc/skel/. "$HOME"/'
        fi

        print_success "XeroLinux configurations applied to $ACTUAL_HOME!"
        echo ""
    fi

    # Copy /etc/skel to /root as requested
    print_step "Copying /etc/skel configurations to /root ..."
    echo ""
    if [[ "$EUID" -eq 0 ]]; then
        cp -a /etc/skel/. /root/
    else
        sudo cp -a /etc/skel/. /root/
    fi
    print_success "Configurations copied to /root!"
    echo ""

    # Apply GRUB theme using xero-layan-git repo (run Grub.sh as root), then delete folder
    print_step "Applying GRUB theme from xero-layan-git... 🧩"
    echo ""

    WORKDIR="/tmp/xero-layan-git"
    if [[ "$EUID" -eq 0 ]]; then
        rm -rf "$WORKDIR"
        git clone https://github.com/xerolinux/xero-layan-git.git "$WORKDIR" || {
            print_warning "Failed to clone xero-layan-git repo (non-critical)"
            WORKDIR=""
        }
    else
        sudo rm -rf "$WORKDIR"
        sudo git clone https://github.com/xerolinux/xero-layan-git.git "$WORKDIR" || {
            print_warning "Failed to clone xero-layan-git repo (non-critical)"
            WORKDIR=""
        }
    fi

    if [[ -n "$WORKDIR" && -d "$WORKDIR" && -f "$WORKDIR/Grub.sh" ]]; then
        if [[ "$EUID" -eq 0 ]]; then
            cd "$WORKDIR" || return 1
            chmod +x ./Grub.sh 2>/dev/null || true
            bash ./Grub.sh || print_warning "Grub.sh failed (non-critical)"
            cd / || true
            rm -rf "$WORKDIR"
        else
            sudo bash -lc "cd '$WORKDIR' && chmod +x ./Grub.sh 2>/dev/null || true; bash ./Grub.sh" \
                || print_warning "Grub.sh failed (non-critical)"
            sudo rm -rf "$WORKDIR"
        fi
        print_success "GRUB theme applied (and repo cleaned up)."
        echo ""
    else
        print_warning "Grub.sh not found after clone; skipping GRUB theming (non-critical)"
        echo ""
        if [[ -n "$WORKDIR" && -d "$WORKDIR" ]]; then
            [[ "$EUID" -eq 0 ]] && rm -rf "$WORKDIR" || sudo rm -rf "$WORKDIR"
        fi
    fi

    # Distro identity files
    print_step "Setting distro identity files... 🏷️"
    echo ""

    fetch_file() {
        local url="$1"
        local dest="$2"

        if command -v wget >/dev/null 2>&1; then
            if [[ "$EUID" -eq 0 ]]; then
                wget -qO "$dest" "$url"
            else
                sudo wget -qO "$dest" "$url"
            fi
        elif command -v curl >/dev/null 2>&1; then
            if [[ "$EUID" -eq 0 ]]; then
                curl -fsSL "$url" -o "$dest"
            else
                sudo curl -fsSL "$url" -o "$dest"
            fi
        else
            return 1
        fi
    }

    ID_URL_BASE="https://raw.githubusercontent.com/XeroLinuxDev/XeroBuild/refs/heads/main/FOSS/airootfs/etc"

    # Ensure /etc/xdg exists
    if [[ "$EUID" -eq 0 ]]; then
        mkdir -p /etc/xdg
    else
        sudo mkdir -p /etc/xdg
    fi

    if ! fetch_file "$ID_URL_BASE/dev-rel" "/etc/dev-rel"; then
        print_warning "Failed to fetch /etc/dev-rel (non-critical)"
    else
        print_success "Updated /etc/dev-rel"
    fi

    if ! fetch_file "$ID_URL_BASE/os-release" "/etc/os-release"; then
        print_warning "Failed to fetch /etc/os-release (non-critical)"
    else
        print_success "Updated /etc/os-release"
    fi

    if ! fetch_file "$ID_URL_BASE/xdg/kcm-about-distrorc" "/etc/xdg/kcm-about-distrorc"; then
        print_warning "Failed to fetch /etc/xdg/kcm-about-distrorc (non-critical)"
    else
        print_success "Updated /etc/xdg/kcm-about-distrorc"
    fi

    echo ""
    print_success "All requested post-install config steps completed."
    echo ""
}

# Final message
show_completion() {
    print_header
    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${GREEN}     🎉 Installation Complete! 🎉              ${PURPLE}║${NC}"
    echo -e "${PURPLE}╠════════════════════════════════════════════════╣${NC}"
    echo -e "${PURPLE}║${NC}  Your personalized KDE Plasma is ready!       ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}  Reboot to experience your new desktop        ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}                                               ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}  Command: ${YELLOW}sudo reboot${NC}                        ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Run the script
check_root
prompt_user
select_aur_helper
customization_prompts
install_kde
install_custom_pkgs
install_user_packages
install_vm_support
finalize_system
copy_skel_to_user
show_completion
