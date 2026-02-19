#!/bin/bash

# XeroLinux KDE Plasma Installer

SCRIPT_PATH="$(readlink -f "$0" 2>/dev/null || echo "")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

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
    sleep 1
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    sleep 1
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
    clear

    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}                PACKAGE SELECTION -- Choose Your Apps${NC}"
    echo -e "${CYAN}     Enter numbers separated by spaces, or press Enter to skip all${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}-- WEB BROWSERS -----------------------------------------------------------${NC}"
    echo ""
    echo -e "  ${CYAN} 1)${NC} Floorp              ${CYAN} 2)${NC} Firefox             ${CYAN} 3)${NC} Brave"
    echo -e "  ${CYAN} 4)${NC} LibreWolf           ${CYAN} 5)${NC} Vivaldi             ${CYAN} 6)${NC} Tor Browser"
    echo -e "  ${CYAN} 7)${NC} Mullvad Browser     ${CYAN} 8)${NC} Ungoogled Chromium  ${CYAN} 9)${NC} FileZilla"
    echo -e "  ${CYAN}10)${NC} Helium Browser      ${CYAN}11)${NC} Zen Browser"
    echo ""
    echo -e "${GREEN}-- SOCIAL & COMMUNICATION -------------------------------------------------${NC}"
    echo ""
    echo -e "  ${GREEN}12)${NC} ZapZap (WhatsApp)   ${GREEN}13)${NC} Discord             ${GREEN}14)${NC} Vesktop"
    echo -e "  ${GREEN}15)${NC} Telegram            ${GREEN}16)${NC} Ferdium (All-in-one)"
    echo ""
    echo -e "${PURPLE}-- DEVELOPMENT TOOLS ------------------------------------------------------${NC}"
    echo ""
    echo -e "  ${PURPLE}17)${NC} Hugo                ${PURPLE}18)${NC} Meld (diff viewer)  ${PURPLE}19)${NC} VSCodium"
    echo -e "  ${PURPLE}20)${NC} GitHub Desktop"
    echo ""
    echo -e "${YELLOW}-- PASSWORD MANAGERS -------------------------------------------------------${NC}"
    echo ""
    echo -e "  ${YELLOW}21)${NC} KeePassXC           ${YELLOW}22)${NC} Bitwarden           ${YELLOW}23)${NC} pass"
    echo ""
    echo -e "${BLUE}-- CREATIVE & IMAGING -----------------------------------------------------${NC}"
    echo ""
    echo -e "  ${BLUE}24)${NC} GIMP                ${BLUE}25)${NC} Krita               ${BLUE}26)${NC} Inkscape"
    echo ""
    echo -e "${RED}-- MUSIC & AUDIO ----------------------------------------------------------${NC}"
    echo ""
    echo -e "  ${RED}27)${NC} MPV                 ${RED}28)${NC} Amarok              ${RED}29)${NC} Spotify"
    echo -e "  ${RED}30)${NC} Tenacity            ${RED}31)${NC} JamesDSP            ${RED}32)${NC} EasyEffects"
    echo ""
    echo -e "${GREEN}-- VIDEO EDITING ----------------------------------------------------------${NC}"
    echo ""
    echo -e "  ${GREEN}33)${NC} MakeMKV             ${GREEN}34)${NC} Kdenlive            ${GREEN}35)${NC} Avidemux"
    echo -e "  ${GREEN}36)${NC} MKVToolNix"
    echo ""
    echo -e "${CYAN}-- OFFICE -----------------------------------------------------------------${NC}"
    echo ""
    echo -e "  ${CYAN}37)${NC} LibreOffice"
    echo ""

    read -p ">> Your choices: " user_input

    BROWSER=""
    SOCIAL=""
    DEV=""
    PASS=""
    IMAGING=""
    MUSIC=""
    VIDEO=""
    WANTS_LIBREOFFICE=""

    for choice in $user_input; do
        case $choice in
            # Web Browsers
            1)  BROWSER="$BROWSER floorp" ;;
            2)  BROWSER="$BROWSER firefox" ;;
            3)  BROWSER="$BROWSER brave-bin" ;;
            4)  BROWSER="$BROWSER librewolf" ;;
            5)  BROWSER="$BROWSER vivaldi-meta" ;;
            6)  BROWSER="$BROWSER tor-browser-bin" ;;
            7)  BROWSER="$BROWSER mullvad-browser-bin" ;;
            8)  BROWSER="$BROWSER ungoogled-chromium-bin" ;;
            9)  BROWSER="$BROWSER filezilla" ;;
            10) BROWSER="$BROWSER helium-browser-bin" ;;
            11) BROWSER="$BROWSER zen-browser-bin" ;;
            # Social & Communication
            12) SOCIAL="$SOCIAL zapzap" ;;
            13) SOCIAL="$SOCIAL discord" ;;
            14) SOCIAL="$SOCIAL vesktop" ;;
            15) SOCIAL="$SOCIAL telegram-desktop" ;;
            16) SOCIAL="$SOCIAL ferdium-bin" ;;
            # Development Tools
            17) DEV="$DEV hugo" ;;
            18) DEV="$DEV meld" ;;
            19) DEV="$DEV vscodium" ;;
            20) DEV="$DEV github-desktop" ;;
            # Password Managers
            21) PASS="$PASS keepassxc" ;;
            22) PASS="$PASS bitwarden" ;;
            23) PASS="$PASS pass" ;;
            # Creative & Imaging
            24) IMAGING="$IMAGING gimp" ;;
            25) IMAGING="$IMAGING krita" ;;
            26) IMAGING="$IMAGING inkscape" ;;
            # Music & Audio
            27) MUSIC="$MUSIC mpv" ;;
            28) MUSIC="$MUSIC amarok" ;;
            29) MUSIC="$MUSIC spotify" ;;
            30) MUSIC="$MUSIC tenacity" ;;
            31) MUSIC="$MUSIC jamesdsp" ;;
            32) MUSIC="$MUSIC easyeffects" ;;
            # Video Editing
            33) VIDEO="$VIDEO makemkv" ;;
            34) VIDEO="$VIDEO kdenlive" ;;
            35) VIDEO="$VIDEO avidemux-qt" ;;
            36) VIDEO="$VIDEO mkvtoolnix-gui" ;;
            # Office
            37) WANTS_LIBREOFFICE="yes" ;;
        esac
    done

    # Trim leading whitespace from all variables
    BROWSER="$(echo $BROWSER)"
    SOCIAL="$(echo $SOCIAL)"
    DEV="$(echo $DEV)"
    PASS="$(echo $PASS)"
    IMAGING="$(echo $IMAGING)"
    MUSIC="$(echo $MUSIC)"
    VIDEO="$(echo $VIDEO)"

    # LibreOffice language selection
    LIBREOFFICE=""
    if [[ -n "$WANTS_LIBREOFFICE" ]]; then
        echo ""
        echo -e "${CYAN}LibreOffice selected -- Choose your language (UI + spellcheck):${NC}"
        echo ""

        LO_LANG_MENU=(
            "Use system locale|SYSTEM|"
            "English (US)|en_US|hunspell-en_us"
            "English (GB)|en_GB|hunspell-en_gb"
            "English (AU)|en_AU|hunspell-en_au"
            "English (CA)|en_CA|hunspell-en_ca"
            "German|de_DE|hunspell-de"
            "Greek|el_GR|hunspell-el"
            "French|fr_FR|hunspell-fr"
            "Hebrew|he_IL|hunspell-he"
            "Hungarian|hu_HU|hunspell-hu"
            "Italian|it_IT|hunspell-it"
            "Dutch|nl_NL|hunspell-nl"
            "Polish|pl_PL|hunspell-pl"
            "Romanian|ro_RO|hunspell-ro"
            "Russian|ru_RU|hunspell-ru"
            "Spanish (generic)|es|hunspell-es_any"
            "Spanish (Argentina)|es_AR|hunspell-es_ar"
            "Spanish (Bolivia)|es_BO|hunspell-es_bo"
            "Spanish (Chile)|es_CL|hunspell-es_cl"
            "Spanish (Colombia)|es_CO|hunspell-es_co"
            "Spanish (Costa Rica)|es_CR|hunspell-es_cr"
            "Spanish (Cuba)|es_CU|hunspell-es_cu"
            "Spanish (Dominican Republic)|es_DO|hunspell-es_do"
            "Spanish (Ecuador)|es_EC|hunspell-es_ec"
            "Spanish (Spain)|es_ES|hunspell-es_es"
            "Spanish (Guatemala)|es_GT|hunspell-es_gt"
            "Spanish (Honduras)|es_HN|hunspell-es_hn"
            "Spanish (Mexico)|es_MX|hunspell-es_mx"
            "Spanish (Nicaragua)|es_NI|hunspell-es_ni"
            "Spanish (Panama)|es_PA|hunspell-es_pa"
            "Spanish (Peru)|es_PE|hunspell-es_pe"
            "Spanish (Puerto Rico)|es_PR|hunspell-es_pr"
            "Spanish (Paraguay)|es_PY|hunspell-es_py"
            "Spanish (El Salvador)|es_SV|hunspell-es_sv"
            "Spanish (Uruguay)|es_UY|hunspell-es_uy"
            "Spanish (Venezuela)|es_VE|hunspell-es_ve"
            "Custom (enter locale code)|CUSTOM|"
        )

        for i in "${!LO_LANG_MENU[@]}"; do
            idx=$((i + 1))
            IFS='|' read -r label loc _ <<< "${LO_LANG_MENU[$i]}"
            if [[ "$loc" == "SYSTEM" ]]; then
                sys_loc="$(locale 2>/dev/null | awk -F= '/^LANG=/{print $2}' | tr -d '"')"
                sys_loc="${sys_loc:-en_US}"
                echo -e "  ${BLUE}${idx})${NC} ${label} (${sys_loc})"
            elif [[ "$loc" == "CUSTOM" ]]; then
                echo -e "  ${BLUE}${idx})${NC} ${label}"
            else
                echo -e "  ${BLUE}${idx})${NC} ${label} (${loc})"
            fi
        done

        echo ""
        read -p "Enter choice (default: English US): " lang_choice

        if [[ -z "$lang_choice" ]]; then
            lang_choice=2
        fi

        if ! [[ "$lang_choice" =~ ^[0-9]+$ ]] || (( lang_choice < 1 || lang_choice > ${#LO_LANG_MENU[@]} )); then
            lang_choice=2
        fi

        IFS='|' read -r _ LOCALE_SELECTED HUNSPELL_SELECTED <<< "${LO_LANG_MENU[$((lang_choice - 1))]}"

        if [[ "$LOCALE_SELECTED" == "SYSTEM" ]]; then
            LOCALE_SELECTED="$(locale 2>/dev/null | awk -F= '/^LANG=/{print $2}' | tr -d '"')"
            LOCALE_SELECTED="${LOCALE_SELECTED:-en_US}"
        elif [[ "$LOCALE_SELECTED" == "CUSTOM" ]]; then
            read -p "Enter locale code (examples: en_US, en_GB, fr_FR, es_MX, ru_RU, zh_CN): " LOCALE_SELECTED
            LOCALE_SELECTED="${LOCALE_SELECTED:-en_US}"
            HUNSPELL_SELECTED=""
        fi

        normalize_locale() {
            local loc="$1"
            loc="${loc%%.*}"     # strip .UTF-8
            loc="${loc%%@*}"     # strip @variant
            echo "$loc"
        }

        hunspell_from_locale() {
            local loc
            loc="$(normalize_locale "$1")"
            local lang="${loc%%_*}"
            local region=""
            if [[ "$loc" == *"_"* ]]; then
                region="${loc#*_}"
            fi
            lang="${lang,,}"
            region="${region,,}"

            case "$lang" in
                en)
                    if [[ -n "$region" ]]; then
                        echo "hunspell-en_${region}"
                    else
                        echo "hunspell-en_us"
                    fi
                    ;;
                es)
                    if [[ -n "$region" ]]; then
                        echo "hunspell-es_${region}"
                    else
                        echo "hunspell-es_any"
                    fi
                    ;;
                zh|ja|ko)
                    echo ""
                    ;;
                pt)
                    if [[ "$region" == "br" ]]; then
                        echo "hunspell-pt_br"
                    else
                        echo "hunspell-pt_pt"
                    fi
                    ;;
                *)
                    if [[ -n "$region" ]]; then
                        echo "hunspell-${lang}_${region}"
                    else
                        echo "hunspell-$lang"
                    fi
                    ;;
            esac
        }

        lo_langpack_from_locale() {
            local loc
            loc="$(normalize_locale "$1")"
            loc="${loc,,}"
            loc="${loc/_/-}"

            local lang="${loc%%-*}"
            local region=""
            if [[ "$loc" == *"-"* ]]; then
                region="${loc#*-}"
            fi

            local candidates=()
            if [[ -n "$region" ]]; then
                candidates+=("${lang}-${region}")
            fi
            candidates+=("${lang}")

            for c in "${candidates[@]}"; do
                if pacman -Si "libreoffice-fresh-$c" &>/dev/null; then
                    echo "libreoffice-fresh-$c"
                    return 0
                fi
            done

            echo ""
            return 0
        }

        add_pkg_if_exists() {
            local pkg="$1"
            if [[ -z "$pkg" ]]; then
                return 0
            fi
            if pacman -Si "$pkg" &>/dev/null; then
                LO_PKGS="$LO_PKGS $pkg"
            else
                print_warning "Package not found in repos, skipping: $pkg"
            fi
        }

        LO_PKGS="hunspell libreoffice-fresh libreoffice-extension-texmaths libreoffice-extension-writer2latex"

        if [[ -z "$HUNSPELL_SELECTED" ]]; then
            HUNSPELL_SELECTED="$(hunspell_from_locale "$LOCALE_SELECTED")"
        fi

        add_pkg_if_exists "$HUNSPELL_SELECTED"

        LO_LANGPACK="$(lo_langpack_from_locale "$LOCALE_SELECTED")"
        add_pkg_if_exists "$LO_LANGPACK"

        LIBREOFFICE="$(echo "$LO_PKGS" | xargs)"
    fi

    echo ""
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Selection Summary:${NC}"
    [[ -n "$BROWSER" ]]        && echo -e "  Browsers:       ${CYAN}$BROWSER${NC}"
    [[ -n "$SOCIAL" ]]         && echo -e "  Social:         ${CYAN}$SOCIAL${NC}"
    [[ -n "$DEV" ]]            && echo -e "  Dev Tools:      ${CYAN}$DEV${NC}"
    [[ -n "$PASS" ]]           && echo -e "  Passwords:      ${CYAN}$PASS${NC}"
    [[ -n "$IMAGING" ]]        && echo -e "  Creative:       ${CYAN}$IMAGING${NC}"
    [[ -n "$MUSIC" ]]          && echo -e "  Music/Audio:    ${CYAN}$MUSIC${NC}"
    [[ -n "$VIDEO" ]]          && echo -e "  Video:          ${CYAN}$VIDEO${NC}"
    [[ -n "$LIBREOFFICE" ]]    && echo -e "  LibreOffice:    ${CYAN}yes${NC}"

    if [[ -z "$BROWSER$SOCIAL$DEV$PASS$IMAGING$MUSIC$VIDEO$LIBREOFFICE" ]]; then
        echo -e "  ${YELLOW}(no packages selected)${NC}"
    fi

    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    read -p "Press Enter to begin installation..."
}

# Step B: Install all packages + enable plasma login manager
install_packages() {
    print_header

    print_step "Starting KDE Plasma installation..."
    echo ""

    print_step "Syncing and updating system..."
    $SUDO_CMD pacman -Syu --noconfirm || { print_error "System update failed!"; exit 1; }
    print_success "System updated!"
    echo ""

    print_step "Installing AUR helper ($AUR_HELPER)..."
    $SUDO_CMD pacman -S --needed --noconfirm $AUR_HELPER || { print_error "AUR helper installation failed!"; exit 1; }
    print_success "AUR helper ($AUR_HELPER) installed!"
    echo ""

    print_step "Installing KDE Plasma and system packages..."

    $SUDO_CMD pacman -S --needed --noconfirm \
        kf6 qt6 kde-system \
        kwin krdp milou breeze oxygen drkonqi kwrited \
        kgamma kscreen plasma-login-manager kmenuedit bluedevil kpipewire plasma-nm plasma-pa \
        plasma-sdk libkscreen breeze-gtk powerdevil kinfocenter flatpak-kcm \
        kdecoration ksshaskpass kwallet-pam libksysguard plasma-vault ksystemstats \
        kde-cli-tools oxygen-sounds kscreenlocker kglobalacceld systemsettings \
        kde-gtk-config layer-shell-qt plasma-desktop polkit-kde-agent plasma-workspace \
        kdeplasma-addons ocean-sound-theme qqc2-breeze-style kactivitymanagerd \
        plasma-integration plasma-thunderbolt plasma-systemmonitor \
        xdg-desktop-portal-kde plasma-browser-integration \
        krdc krfb smb4k alligator kdeconnect kio-admin kio-extras kio-gdrive \
        konversation kio-zeroconf kdenetwork-filesharing signon-kwallet-extension \
        okular kamera svgpart skanlite gwenview spectacle colord-kde kcolorchooser \
        kimagemapeditor kdegraphics-thumbnailers \
        ark kate kgpg kfind sweeper konsole kdialog yakuake skanpage filelight \
        kmousetool kcharselect markdownpart qalculate-qt keditbookmarks kdebugsettings \
        kwalletmanager dolphin-plugins \
        k3b kamoso audiotube plasmatube audiocd-kio \
        waypipe egl-wayland qt6-wayland lib32-wayland wayland-protocols \
        kwayland-integration plasma-wayland-protocols \
        plasma-keyboard ocrad \
        vi duf gcc npm yad zip xdo gum inxi lzop nmon tree vala btop glfw htop lshw \
        cblas expac fuse3 lhasa meson unace unrar unzip p7zip iftop nvtop rhash sshfs \
        vnstat nodejs cronie hwinfo arandr assimp netpbm wmctrl grsync libmtp polkit \
        sysprof semver zenity gparted plocate jsoncpp fuseiso gettext node-gyp \
        intltool graphviz pkgstats pciutils inetutils downgrade s3fs-fuse playerctl \
        asciinema oniguruma ventoy-bin cifs-utils lsb-release python-dbus dconf-editor \
        laptop-detect perl-xml-parser gnome-disk-utility appmenu-gtk-module \
        parallel xsettingsd polkit-qt6 systemdgenie \
        yt-dlp wavpack unarchiver rate-mirrors gnustep-base ocs-url xmlstarlet \
        python-pip python-cffi python-numpy python-docopt python-pyaudio \
        python-pyparted python-pygments python-websockets \
        libgsf tumbler freetype2 libopenraw poppler-qt6 poppler-glib ffmpegthumbnailer \
        gvfs mtpfs udiskie udisks2 libldm gvfs-afc gvfs-mtp gvfs-nfs gvfs-smb \
        gvfs-goa gvfs-wsdd gvfs-dnssd gvfs-google gvfs-gphoto2 gvfs-onedrive \
        flatpak topgrade appstream-qt pacman-contrib pacman-bintrans \
        ffmpeg ffmpegthumbs ffnvcodec-headers \
        kwin-zones kde-wallpapers kwin-scripts-kzones tela-circle-icon-theme-purple \
        kvantum fastfetch adw-gtk-theme oh-my-posh-bin gnome-themes-extra \
        kwin-effect-rounded-corners-git \
        bash-language-server typescript-language-server vscode-json-languageserver \
        ttf-fira-code otf-libertinus tex-gyre-fonts ttf-hack-nerd ttf-ubuntu-font-family \
        awesome-terminal-fonts ttf-jetbrains-mono-nerd adobe-source-sans-fonts \
        bat bat-extras jq vim figlet ostree lolcat numlockx localsend lm_sensors \
        appstream-glib lib32-lm_sensors \
        xmlto ckbcomp yaml-cpp kirigami boost-libs polkit-gnome gtk-update-icon-cache \
        dex libxinerama bash-completion \
        hblock cryptsetup brightnessctl switcheroo-control power-profiles-daemon \
        mkinitcpio-utils mkinitcpio-archiso mkinitcpio-openswap \
        mkinitcpio-nfs-utils \
        boost kpmcore xdg-terminal-exec-git \
        preload xero-toolkit extra-scripts desktop-config xero-gpu-tools \
        eza ntp cava most dialog dnsutils logrotate xdg-user-dirs \
        archiso rsync sdparm ntfs-3g tpm2-tss udftools syslinux fatresize \
        nfs-utils exfatprogs tpm2-tools fsarchiver squashfs-tools \
        gpart dmraid parted hdparm usbmuxd usbutils testdisk ddrescue timeshift \
        partclone partimage clonezilla open-iscsi memtest86+-efi usb_modeswitch \
        fd tmux brltty msedit nvme-cli terminus-font foot-terminfo kitty-terminfo \
        pv mc gpm nbd lvm2 bolt bind lynx tldr nmap irssi mdadm wvdial hyperv \
        mtools lsscsi ndisc6 screen tcpdump ethtool xdotool pcsclite \
        espeakup libfido2 xdg-utils smartmontools \
        sequoia-sq edk2-shell python-pyqt6 libusb-compat \
        wireguard-tools || print_warning "Some packages failed (non-critical)"

    print_success "All packages installed!"
    echo ""

    print_step "Enabling Plasma Login Manager..."
    $SUDO_CMD systemctl enable plasmalogin.service || { print_error "Failed to enable Plasma Login Manager!"; exit 1; }
    print_success "Plasma Login Manager enabled!"
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

    if [ -n "$SOCIAL" ]; then
        print_step "Installing social apps... 💬"
        $SUDO_CMD pacman -S --needed --noconfirm $SOCIAL || print_warning "Some social apps failed (non-critical)"
        print_success "Social apps installed!"
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

    print_success "User-selected packages installed!"
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
    $SUDO_CMD systemctl disable iwd 2>/dev/null || true
    $SUDO_CMD systemctl disable dhcpcd 2>/dev/null || true
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

    # Determine the actual user (not root) — try every reliable method
    if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
        ACTUAL_USER="$SUDO_USER"
    elif [[ -n "${USER:-}" && "${USER}" != "root" ]]; then
        ACTUAL_USER="$USER"
    elif [[ "$(id -un 2>/dev/null)" != "root" ]]; then
        ACTUAL_USER="$(id -un)"
    else
        # Running as root (chroot) — find the first human user
        ACTUAL_USER="$(getent passwd | awk -F: '$3 >= 1000 && $3 < 65534 && $1 != "nobody" && $6 ~ /^\/home\// {print $1; exit}')"
    fi

    if [[ -z "${ACTUAL_USER:-}" ]]; then
        print_warning "Could not determine target user, skipping config copy"
        return 1
    fi

    ACTUAL_HOME="$(getent passwd "$ACTUAL_USER" | cut -d: -f6)"

    if [[ -z "${ACTUAL_HOME:-}" || ! -d "$ACTUAL_HOME" ]]; then
        print_warning "User home directory not found for $ACTUAL_USER ($ACTUAL_HOME), skipping user config copy"
        return 1
    fi

    # Copy /etc/skel to user's home (as root so nothing is skipped)
    print_step "Copying /etc/skel configurations to $ACTUAL_HOME for user $ACTUAL_USER..."
    echo ""

    if ! $SUDO_CMD cp -Rf /etc/skel/. "$ACTUAL_HOME"/; then
        print_error "Failed to copy /etc/skel to $ACTUAL_HOME!"
        return 1
    fi

    $SUDO_CMD chown -R "$ACTUAL_USER:$ACTUAL_USER" "$ACTUAL_HOME"

    # Add Oh-My-Posh config to user's .bashrc if not already present
    OMP_LINE='eval "$(oh-my-posh init bash --config $HOME/.config/ohmyposh/xero.omp.json)"'
    if ! grep -qF "oh-my-posh init bash" "$ACTUAL_HOME/.bashrc" 2>/dev/null; then
        echo "" >> "$ACTUAL_HOME/.bashrc"
        echo "# Oh-My-Posh Config" >> "$ACTUAL_HOME/.bashrc"
        echo "$OMP_LINE" >> "$ACTUAL_HOME/.bashrc"
    fi

    # Add clear && fastfetch to user's .bashrc if not already present
    if ! grep -qF "clear && fastfetch" "$ACTUAL_HOME/.bashrc" 2>/dev/null; then
        echo "" >> "$ACTUAL_HOME/.bashrc"
        echo "# Fastfetch on terminal start" >> "$ACTUAL_HOME/.bashrc"
        echo "clear && fastfetch" >> "$ACTUAL_HOME/.bashrc"
    fi

    $SUDO_CMD chown -R "$ACTUAL_USER:$ACTUAL_USER" "$ACTUAL_HOME"

    print_success "XeroLinux configurations applied to $ACTUAL_HOME!"
    echo ""

    # Copy /etc/skel to /root
    print_step "Copying /etc/skel configurations to /root..."
    echo ""
    $SUDO_CMD cp -Rf /etc/skel/. /root/
    print_success "Configurations copied to /root!"
    echo ""

    # Copy xero-toolkit.desktop to autostart
    print_step "Setting up XeroLinux Toolkit autostart... 🚀"
    echo ""
    $SUDO_CMD mkdir -p /etc/xdg/autostart
    if [[ -f /usr/share/applications/xero-toolkit.desktop ]]; then
        $SUDO_CMD cp /usr/share/applications/xero-toolkit.desktop /etc/xdg/autostart/
        print_success "XeroLinux Toolkit added to autostart!"
    else
        print_warning "xero-toolkit.desktop not found, skipping autostart setup (non-critical)"
    fi
    echo ""

    # Apply GRUB theme using xero-layan-git repo
    print_step "Applying GRUB theme from xero-layan-git... 🧩"
    echo ""

    WORKDIR="/tmp/xero-layan-git"
    rm -rf "$WORKDIR"
    git clone https://github.com/xerolinux/xero-layan-git.git "$WORKDIR" || {
        print_warning "Failed to clone xero-layan-git repo (non-critical)"
        WORKDIR=""
    }

    if [[ -n "$WORKDIR" && -d "$WORKDIR" && -f "$WORKDIR/Grub.sh" ]]; then
        $SUDO_CMD cp -Rf "$WORKDIR/Configs/System/." /
        chmod +x "$WORKDIR/Grub.sh" 2>/dev/null || true
        $SUDO_CMD bash -c "cd '$WORKDIR' && bash ./Grub.sh" || print_warning "Grub.sh failed (non-critical)"
        rm -rf "$WORKDIR"
        print_success "GRUB theme applied (and repo cleaned up)."
        echo ""
    else
        print_warning "Grub.sh not found after clone; skipping GRUB theming (non-critical)"
        echo ""
        [[ -n "$WORKDIR" && -d "$WORKDIR" ]] && rm -rf "$WORKDIR"
    fi

    # Distro identity files
    print_step "Setting distro identity files... 🏷️"
    echo ""

    fetch_file() {
        local url="$1"
        local dest="$2"

        if command -v wget >/dev/null 2>&1; then
            $SUDO_CMD wget -qO "$dest" "$url"
        elif command -v curl >/dev/null 2>&1; then
            $SUDO_CMD curl -fsSL "$url" -o "$dest"
        else
            return 1
        fi
    }

    ID_URL_BASE="https://raw.githubusercontent.com/XeroLinuxDev/XeroBuild/refs/heads/main/FOSS/airootfs/etc"

    $SUDO_CMD mkdir -p /etc/xdg

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

check_root
prompt_user
select_aur_helper
customization_prompts
install_packages
install_user_packages
finalize_system
copy_skel_to_user
show_completion

# Clean up: remove this script
if [[ -n "$SCRIPT_PATH" && -f "$SCRIPT_PATH" ]]; then
    rm -f "$SCRIPT_PATH"
fi
