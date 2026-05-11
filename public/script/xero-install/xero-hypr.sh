#!/bin/bash

# XeroLinux Hyprland + Noctalia Installer v1.9

SCRIPT_PATH="$(readlink -f "$0" 2>/dev/null || echo "")"

# AUR helper passed as $1 from xero-install.sh; default to paru
AUR_HELPER="${1:-paru}"
# Filesystem type passed as $2 from xero-install.sh; empty when run standalone
FILESYSTEM="${2:-}"

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
    echo -e "${PURPLE}║${CYAN}    🌿 XeroLinux Hyprland + Noctalia Installer  ${PURPLE}║${NC}"
    echo -e "${PURPLE}║                                                ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step()    { echo -e "${BLUE}➜${NC} ${CYAN}$1${NC}"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error()   { echo -e "${RED}✗${NC} $1"; sleep 1; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; sleep 1; }

# NOTE: intentionally duplicated from xero-install.sh — this script runs standalone
# inside the target chroot as an unprivileged user, so it needs its own copy.
detect_chroot() {
    if [ "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/.)" ] 2>/dev/null; then
        return 0
    elif [ -f /etc/arch-chroot ]; then
        return 0
    elif [ "${EUID:-0}" -eq 0 ] && [ -z "${SUDO_USER:-}" ]; then
        return 0
    else
        return 1
    fi
}

setup_sudo() {
    if [ "${EUID:-0}" -eq 0 ]; then
        SUDO_CMD=""
        print_step "Running as root (chroot environment)"
    else
        SUDO_CMD="sudo"
    fi
}

# Detect the real non-root user once — all config functions read these globals.
# Called right after check_root so every subsequent function can rely on them.
detect_actual_user() {
    if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
        ACTUAL_USER="$SUDO_USER"
    elif [[ -n "${USER:-}" && "${USER}" != "root" ]]; then
        ACTUAL_USER="$USER"
    elif [[ "$(id -un 2>/dev/null)" != "root" ]]; then
        ACTUAL_USER="$(id -un)"
    else
        ACTUAL_USER="$(getent passwd | awk -F: '$3 >= 1000 && $3 < 65534 && $1 != "nobody" && $6 ~ /^\/home\// {print $1; exit}')"
    fi

    if [[ -z "${ACTUAL_USER:-}" ]]; then
        print_error "Could not determine target user — cannot apply configs. Aborting."
        exit 1
    fi

    ACTUAL_HOME="$(getent passwd "$ACTUAL_USER" | cut -d: -f6 2>/dev/null)"
    [[ -z "$ACTUAL_HOME" ]] && ACTUAL_HOME="/home/${ACTUAL_USER}"

    print_success "Config target: ${ACTUAL_USER} → ${ACTUAL_HOME}"
}

# NOTE: intentionally OPPOSITE logic from xero-install.sh — rejects root outside chroot.
check_root() {
    if [[ ${EUID:-0} -eq 0 ]] && ! detect_chroot; then
        print_error "Do not run this script as root outside a chroot!"
        exit 1
    fi
    setup_sudo
}

# ── Prompt ────────────────────────────────────────────────────────────────────

prompt_user() {
    print_header

    echo -e "${RED}╔════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  MINIMAL INSTALL — Community best-effort. NO official support.                 ║${NC}"
    echo -e "${RED}║  Issues with Hyprland + Noctalia are yours to solve. Experienced users ONLY !  ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    echo -e "${CYAN}This script will install:${NC}"
    echo -e "  ${BLUE}•${NC} Hyprland compositor + lock/idle/picker"
    echo -e "  ${BLUE}•${NC} Noctalia shell (bar, launcher, notifications, wallpaper)"
    echo -e "  ${BLUE}•${NC} KDE apps: Dolphin, Konsole, Kate, Ark, Gwenview, Okular, KCalc"
    echo -e "  ${BLUE}•${NC} AUR helper: ${GREEN}${AUR_HELPER}${NC}"
    echo -e "  ${BLUE}•${NC} SDDM with HyprSDDM theme"
    [[ "$FILESYSTEM" == "btrfs" ]] && \
        echo -e "  ${BLUE}•${NC} Btrfs tools: ${GREEN}btrfs-assistant + snapper integration${NC}"
    echo -e "  ${BLUE}•${NC} Your selected optional packages"
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

# ── Package selection (same categories as xero-kde.sh) ────────────────────────

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

    BROWSER="" SOCIAL="" DEV="" PASS="" IMAGING="" MUSIC="" VIDEO="" WANTS_LIBREOFFICE=""

    for choice in $user_input; do
        case $choice in
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
            12) SOCIAL="$SOCIAL zapzap" ;;
            13) SOCIAL="$SOCIAL discord" ;;
            14) SOCIAL="$SOCIAL vesktop" ;;
            15) SOCIAL="$SOCIAL telegram-desktop" ;;
            16) SOCIAL="$SOCIAL ferdium-bin" ;;
            17) DEV="$DEV hugo" ;;
            18) DEV="$DEV meld" ;;
            19) DEV="$DEV vscodium" ;;
            20) DEV="$DEV github-desktop" ;;
            21) PASS="$PASS keepassxc" ;;
            22) PASS="$PASS bitwarden" ;;
            23) PASS="$PASS pass" ;;
            24) IMAGING="$IMAGING gimp" ;;
            25) IMAGING="$IMAGING krita" ;;
            26) IMAGING="$IMAGING inkscape" ;;
            27) MUSIC="$MUSIC mpv" ;;
            28) MUSIC="$MUSIC amarok" ;;
            29) MUSIC="$MUSIC spotify" ;;
            30) MUSIC="$MUSIC tenacity" ;;
            31) MUSIC="$MUSIC jamesdsp" ;;
            32) MUSIC="$MUSIC easyeffects" ;;
            33) VIDEO="$VIDEO makemkv" ;;
            34) VIDEO="$VIDEO kdenlive" ;;
            35) VIDEO="$VIDEO avidemux-qt" ;;
            36) VIDEO="$VIDEO mkvtoolnix-gui" ;;
            37) WANTS_LIBREOFFICE="yes" ;;
        esac
    done

    BROWSER="$(echo $BROWSER)"
    SOCIAL="$(echo $SOCIAL)"
    DEV="$(echo $DEV)"
    PASS="$(echo $PASS)"
    IMAGING="$(echo $IMAGING)"
    MUSIC="$(echo $MUSIC)"
    VIDEO="$(echo $VIDEO)"

    LIBREOFFICE=""
    if [[ -n "$WANTS_LIBREOFFICE" ]]; then
        LIBREOFFICE="hunspell libreoffice-fresh libreoffice-extension-texmaths libreoffice-extension-writer2latex"
    fi

    echo ""
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Selection Summary:${NC}"
    [[ -n "$BROWSER" ]]     && echo -e "  Browsers:    ${CYAN}$BROWSER${NC}"
    [[ -n "$SOCIAL" ]]      && echo -e "  Social:      ${CYAN}$SOCIAL${NC}"
    [[ -n "$DEV" ]]         && echo -e "  Dev Tools:   ${CYAN}$DEV${NC}"
    [[ -n "$PASS" ]]        && echo -e "  Passwords:   ${CYAN}$PASS${NC}"
    [[ -n "$IMAGING" ]]     && echo -e "  Creative:    ${CYAN}$IMAGING${NC}"
    [[ -n "$MUSIC" ]]       && echo -e "  Music/Audio: ${CYAN}$MUSIC${NC}"
    [[ -n "$VIDEO" ]]       && echo -e "  Video:       ${CYAN}$VIDEO${NC}"
    [[ -n "$LIBREOFFICE" ]] && echo -e "  LibreOffice: ${CYAN}yes${NC}"
    if [[ -z "$BROWSER$SOCIAL$DEV$PASS$IMAGING$MUSIC$VIDEO$LIBREOFFICE" ]]; then
        echo -e "  ${YELLOW}(no packages selected)${NC}"
    fi
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    read -p "Press Enter to begin installation..."
}

# ── Package install helpers (identical to xero-kde.sh) ────────────────────────

install_group() {
    local group_name="$1"; shift
    local pkgs=("$@")

    print_step "[$group_name] Installing ${#pkgs[@]} packages..."

    if $SUDO_CMD pacman -S --needed --noconfirm "${pkgs[@]}" 2>/dev/null; then
        print_success "[$group_name] Done!"
        echo ""
        return 0
    fi

    print_warning "[$group_name] Bulk install failed — retrying individually..."
    local failed=() installed=0
    for pkg in "${pkgs[@]}"; do
        if $SUDO_CMD pacman -S --needed --noconfirm "$pkg" 2>/dev/null; then
            (( installed++ )) || true
        else
            failed+=("$pkg")
        fi
    done

    [[ ${#failed[@]} -gt 0 ]] && \
        print_warning "[$group_name] Skipped (${#failed[@]}): ${failed[*]}"
    print_success "[$group_name] Done — $installed installed, ${#failed[@]} skipped."
    echo ""
    return 0
}

install_group_required() {
    local group_name="$1"; shift
    local pkgs=("$@")

    print_step "[$group_name] Installing ${#pkgs[@]} packages (required)..."

    if $SUDO_CMD pacman -S --needed --noconfirm "${pkgs[@]}" 2>/dev/null; then
        print_success "[$group_name] Done!"
        echo ""
        return 0
    fi

    print_warning "[$group_name] Bulk install failed — retrying individually..."
    local failed=() installed=0
    for pkg in "${pkgs[@]}"; do
        if $SUDO_CMD pacman -S --needed --noconfirm "$pkg" 2>/dev/null; then
            (( installed++ )) || true
        else
            failed+=("$pkg")
        fi
    done

    [[ ${#failed[@]} -gt 0 ]] && \
        print_warning "[$group_name] Skipped (${#failed[@]}): ${failed[*]}"

    if [[ $installed -eq 0 ]]; then
        print_error "[$group_name] Critical: zero packages installed — aborting!"
        exit 1
    fi

    print_success "[$group_name] Done — $installed installed, ${#failed[@]} skipped."
    echo ""
    return 0
}

install_aur_group() {
    local group_name="$1"; shift
    local pkgs=("$@")

    print_step "[$group_name] Installing ${#pkgs[@]} AUR packages..."

    if "${AUR_HELPER}" -S --needed --noconfirm "${pkgs[@]}" 2>/dev/null; then
        print_success "[$group_name] Done!"
        echo ""
        return 0
    fi

    print_warning "[$group_name] Bulk AUR install failed — retrying individually..."
    local failed=() installed=0
    for pkg in "${pkgs[@]}"; do
        if "${AUR_HELPER}" -S --needed --noconfirm "$pkg" 2>/dev/null; then
            (( installed++ )) || true
        else
            failed+=("$pkg")
        fi
    done

    [[ ${#failed[@]} -gt 0 ]] && \
        print_warning "[$group_name] Skipped (${#failed[@]}): ${failed[*]}"
    print_success "[$group_name] Done — $installed installed, ${#failed[@]} skipped."
    echo ""
    return 0
}

# ── Service helpers ───────────────────────────────────────────────────────────

enable_service_if_available() {
    local svc="$1"
    if $SUDO_CMD systemctl cat "$svc" &>/dev/null; then
        $SUDO_CMD systemctl enable "$svc" \
            && print_success "Enabled: $svc" \
            || print_warning "Failed to enable $svc"
    else
        print_warning "Unit $svc not found — skipping"
    fi
}

enable_if_installed() {
    local pkg="$1"
    local svc="${2:-$1}"
    if $SUDO_CMD pacman -Qq "$pkg" &>/dev/null; then
        enable_service_if_available "$svc"
    else
        print_warning "Package $pkg not installed — skipping $svc"
    fi
}

# ── Step A: Install all packages ──────────────────────────────────────────────

install_packages() {
    print_header
    print_step "Starting Hyprland + Noctalia installation..."
    echo ""

    print_step "Syncing and updating system..."
    $SUDO_CMD pacman -Syu --noconfirm || { print_error "System update failed!"; exit 1; }
    print_success "System updated!"
    echo ""

    # ── AUR helper ────────────────────────────────────────────────────────────
    print_step "Installing AUR helper ($AUR_HELPER)..."
    $SUDO_CMD pacman -S --needed --noconfirm "$AUR_HELPER" \
        || { print_error "AUR helper ($AUR_HELPER) installation failed!"; exit 1; }
    print_success "AUR helper ($AUR_HELPER) installed!"
    echo ""

    # ── Hyprland Core (required) ──────────────────────────────────────────────
    install_group_required "Hyprland Core" \
        hyprland hyprlock hypridle hyprpicker hyprcursor

    # ── Wayland & XDG Portals ─────────────────────────────────────────────────
    install_group "Wayland & Portals" \
        wayland qt5-wayland \
        xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-hyprland

    # ── Noctalia Dependencies ─────────────────────────────────────────────────
    install_group "Noctalia Dependencies" \
        alacritty imagemagick python \
        cliphist wl-clipboard grim slurp \
        gnome-menus noto-fonts-emoji \
        qt6ct qt5ct nwg-look \
        qt6-multimedia-ffmpeg papirus-icon-theme \
        network-manager-applet blueman

    # ── Noctalia Shell (AUR) ──────────────────────────────────────────────────
    install_aur_group "Noctalia Shell" \
        noctalia-shell matugen

    # ── KDE Apps (Dolphin pulls kio/kservice = kbuildsycoca6 for Noctalia) ────
    install_group "KDE Apps" \
        dolphin dolphin-plugins konsole kate ark \
        gwenview okular kcalc partitionmanager

    # ── Power & GPU Utilities ─────────────────────────────────────────────────
    install_group "Power & GPU Utilities" \
        switcheroo-control power-profiles-daemon brightnessctl

    # ── System Utilities A ────────────────────────────────────────────────────
    install_group "System Utilities A" \
        duf gcc npm yad zip gum inxi lzop nmon tree btop glfw htop lshw \
        cblas expac fuse3 lhasa meson unace unrar unzip p7zip iftop nvtop rhash sshfs \
        vnstat nodejs cronie hwinfo assimp netpbm wmctrl grsync libmtp polkit \
        sysprof semver zenity gparted plocate jsoncpp fuseiso gettext node-gyp \
        intltool graphviz pkgstats pciutils inetutils downgrade playerctl \
        oniguruma ventoy-bin cifs-utils lsb-release python-dbus dconf-editor \
        parallel xsettingsd polkit-qt6 systemdgenie \
        yt-dlp wavpack unarchiver rate-mirrors gnustep-base ocs-url xmlstarlet \
        libgsf tumbler freetype2 libopenraw poppler-qt6 poppler-glib ffmpegthumbnailer \
        gvfs mtpfs udiskie udisks2 libldm gvfs-afc gvfs-mtp gvfs-nfs gvfs-smb \
        gvfs-goa gvfs-wsdd gvfs-dnssd gvfs-gphoto2 gvfs-onedrive \
        flatpak topgrade appstream-qt pacman-contrib pacman-bintrans \
        ffmpeg ffmpegthumbs ffnvcodec-headers

    # ── System Utilities B ────────────────────────────────────────────────────
    install_group "System Utilities B" \
        bat bat-extras jq figlet ostree lolcat numlockx localsend lm_sensors \
        appstream-glib lib32-lm_sensors \
        xmlto ckbcomp yaml-cpp kirigami boost-libs polkit-gnome gtk-update-icon-cache \
        dex libxinerama bash-completion \
        hblock cryptsetup mkinitcpio-utils \
        mkinitcpio-openswap mkinitcpio-nfs-utils boost kpmcore xdg-terminal-exec-git \
        eza ntp cava most dialog bind logrotate xdg-user-dirs \
        rsync sdparm ntfs-3g tpm2-tss udftools syslinux fatresize \
        nfs-utils exfatprogs tpm2-tools fsarchiver squashfs-tools \
        gpart dmraid parted hdparm usbmuxd usbutils testdisk ddrescue timeshift \
        partclone partimage clonezilla memtest86+-efi usb_modeswitch \
        fd tmux brltty nvme-cli terminus-font foot-terminfo kitty-terminfo \
        pv mc gpm nbd lvm2 bolt lynx tldr nmap mdadm hyperv \
        mtools lsscsi screen tcpdump ethtool pcsclite \
        espeakup libfido2 xdg-utils smartmontools \
        sequoia-sq edk2-shell python-pyqt6 libusb-compat wireguard-tools

    # ── Python Libraries ──────────────────────────────────────────────────────
    install_group "Python Libraries" \
        python-pip python-cffi python-numpy python-docopt python-pyaudio \
        python-pyparted python-pygments python-websockets

    # ── Fonts & Themes ────────────────────────────────────────────────────────
    install_group "Fonts & Themes" \
        ttf-fira-code otf-libertinus tex-gyre-fonts ttf-hack-nerd ttf-ubuntu-font-family \
        awesome-terminal-fonts ttf-jetbrains-mono-nerd adobe-source-sans-fonts \
        tela-circle-icon-theme-purple kde-wallpapers \
        fastfetch adw-gtk-theme oh-my-posh-bin gnome-themes-extra

    # ── Language Servers ──────────────────────────────────────────────────────
    install_group "Language Servers" \
        bash-language-server typescript-language-server vscode-json-languageserver

    # ── XeroLinux Packages ────────────────────────────────────────────────────
    # desktop-config omitted — KDE-specific, not applicable to Hyprland
    install_group "XeroLinux Packages" \
        xero-toolkit extra-scripts

    # ── Btrfs GUI tools (only when installed on Btrfs) ────────────────────────
    if [[ "$FILESYSTEM" == "btrfs" ]]; then
        install_group "Btrfs Assistant" btrfs-assistant
    fi
}

# ── Step B: Install user-selected packages ────────────────────────────────────

install_user_packages() {
    print_header
    print_step "Installing User-Selected Packages..."
    echo ""

    # shellcheck disable=SC2086
    [[ -n "$BROWSER" ]]     && install_group "Browsers"          $BROWSER
    [[ -n "$SOCIAL" ]]      && install_group "Social Apps"        $SOCIAL
    [[ -n "$LIBREOFFICE" ]] && install_group "LibreOffice"        $LIBREOFFICE
    [[ -n "$DEV" ]]         && install_group "Dev Tools"          $DEV
    [[ -n "$PASS" ]]        && install_group "Password Managers"  $PASS
    [[ -n "$IMAGING" ]]     && install_group "Creative Apps"      $IMAGING
    [[ -n "$MUSIC" ]]       && install_group "Music & Audio"      $MUSIC
    [[ -n "$VIDEO" ]]       && install_group "Video Apps"         $VIDEO

    print_success "User-selected packages installed!"
    echo ""
}

# ── Step C: Hyprland session file ─────────────────────────────────────────────

ensure_hyprland_session() {
    print_step "Checking Hyprland session file..."
    local session="/usr/share/wayland-sessions/hyprland.desktop"
    if [[ -f "$session" ]]; then
        print_success "hyprland.desktop present."
        echo ""
        return
    fi
    print_warning "hyprland.desktop not found — writing manually..."
    $SUDO_CMD mkdir -p /usr/share/wayland-sessions
    $SUDO_CMD tee "$session" > /dev/null << 'EOF'
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=Hyprland
Type=Application
DesktopNames=Hyprland
EOF
    print_success "Wrote $session"
    echo ""
}

# ── Step D: Hyprland config ───────────────────────────────────────────────────

configure_hyprland() {
    print_step "Configuring Hyprland..."

    local cfg_dir="${ACTUAL_HOME}/.config/hypr"
    local cfg="${cfg_dir}/hyprland.lua"
    mkdir -p "${cfg_dir}" "${cfg_dir}/noctalia"
    chown -R "${ACTUAL_USER}:${ACTUAL_USER}" "${cfg_dir}" 2>/dev/null || true

    if [[ ! -f "$cfg" ]]; then
        local example="/usr/share/hypr/hyprland.lua"
        if [[ -f "$example" ]]; then
            cp "$example" "$cfg"
            print_success "Copied default config from $example"
        else
            touch "$cfg"
            print_success "No example config found — created empty hyprland.lua"
        fi
    else
        print_success "hyprland.lua exists — appending only."
    fi

    # Set terminal to konsole
    sed -i 's|local terminal\s*=\s*"kitty"|local terminal = "konsole"|' "$cfg" || true

    # Disable waybar if present — Noctalia replaces it
    sed -i 's|\(hl\.exec_cmd("waybar[^"]*")\)|-- \1  -- disabled: Noctalia replaces waybar|' "$cfg" || true

    if ! grep -q "qs -c noctalia-shell" "$cfg"; then
        local colors_file="${cfg_dir}/noctalia/noctalia-colors.lua"
        cat >> "$cfg" << HYPREOF

-- ────────────────────────────────────────────────────────────────────────────
-- Noctalia — colors (matugen-generated, updated on theme change)
-- ────────────────────────────────────────────────────────────────────────────
pcall(dofile, "${colors_file}")

-- ────────────────────────────────────────────────────────────────────────────
-- Noctalia — keybinds
-- ────────────────────────────────────────────────────────────────────────────
hl.bind("Print", hl.dsp.exec_cmd("qs msg -i noctalia-shell screenshot"))

-- ────────────────────────────────────────────────────────────────────────────
-- Noctalia — environment
-- ────────────────────────────────────────────────────────────────────────────
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_QPA_PLATFORM", "wayland")

-- ────────────────────────────────────────────────────────────────────────────
-- Noctalia — autostart
-- ────────────────────────────────────────────────────────────────────────────
hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE DISPLAY")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE DISPLAY")
    hl.exec_cmd("qs -c noctalia-shell")
    hl.exec_cmd("dex --autostart")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)
HYPREOF
        print_success "Appended Noctalia block to hyprland.lua"
    else
        print_success "Noctalia config already present — skipping."
    fi
    echo ""
}

# ── Step E: XDG portal config ─────────────────────────────────────────────────

configure_portals() {
    print_step "Configuring XDG portal preferences..."

    local p_dir="${ACTUAL_HOME}/.config/xdg-desktop-portal"
    mkdir -p "$p_dir"
    cat > "${p_dir}/hyprland-portals.conf" << 'PORTEOF'
[preferred]
default=hyprland;gtk;
org.freedesktop.impl.portal.Screenshot=hyprland
org.freedesktop.impl.portal.ScreenCast=hyprland
PORTEOF
    print_success "Wrote ${p_dir}/hyprland-portals.conf"
    echo ""
}

# ── Step F: Noctalia polkit agent ─────────────────────────────────────────────

install_noctalia_polkit() {
    print_step "Installing Noctalia polkit agent..."

    local plugins_dir="${ACTUAL_HOME}/.config/noctalia/plugins"
    local dest="${plugins_dir}/polkit-agent"

    if [[ -d "$dest" ]]; then
        print_success "Noctalia polkit-agent already installed — skipping."
        echo ""
        return
    fi

    mkdir -p "$plugins_dir"
    local tmp
    tmp=$(mktemp -d)

    if git clone --no-checkout --depth=1 --filter=blob:none \
        https://github.com/noctalia-dev/noctalia-plugins.git "$tmp" 2>/dev/null; then
        git -C "$tmp" sparse-checkout set polkit-agent
        git -C "$tmp" checkout
        cp -r "${tmp}/polkit-agent" "$dest"
        rm -rf "$tmp"
        print_success "polkit-agent installed to $dest"
    else
        rm -rf "$tmp"
        print_warning "Could not clone noctalia-plugins — install polkit-agent manually later."
    fi

    local plugins_json="${ACTUAL_HOME}/.config/noctalia/plugins.json"
    if [[ ! -f "$plugins_json" ]]; then
        cat > "$plugins_json" << 'PLJSON'
{
    "sources": [
        {
            "enabled": true,
            "name": "Noctalia Plugins",
            "url": "https://github.com/noctalia-dev/noctalia-plugins"
        }
    ],
    "states": {
        "polkit-agent": {
            "enabled": true,
            "sourceUrl": "https://github.com/noctalia-dev/noctalia-plugins"
        }
    },
    "version": 2
}
PLJSON
        print_success "plugins.json written with polkit-agent enabled."
    else
        print_success "plugins.json exists — skipping."
    fi
    echo ""
}

# ── Step G: MIME fix + kbuildsycoca6 oneshot ──────────────────────────────────

setup_mimetype_fix() {
    print_step "Applying MIME application menu fix..."

    local src="/etc/xdg/menus/gnome-applications.menu"
    local dst="/etc/xdg/menus/applications.menu"
    if [[ -L "$dst" ]] || [[ -f "$dst" ]]; then
        print_success "applications.menu already exists — skipping symlink."
    elif [[ -f "$src" ]]; then
        $SUDO_CMD ln -sf "$src" "$dst"
        print_success "Linked $dst → $src"
    else
        print_warning "$src not found — gnome-menus may not be installed yet."
    fi

    local svc_dir="${ACTUAL_HOME}/.config/systemd/user"
    local noc_dir="${ACTUAL_HOME}/.config/noctalia"
    local flag="${noc_dir}/.sycoca-built"
    mkdir -p "$svc_dir" "$noc_dir"
    cat > "${svc_dir}/noctalia-sycoca.service" << SVCEOF
[Unit]
Description=Rebuild KDE sycoca for Noctalia (runs once)
ConditionPathExists=!${flag}

[Service]
Type=oneshot
ExecStart=/usr/bin/kbuildsycoca6 --noincremental
ExecStartPost=/usr/bin/touch ${flag}

[Install]
WantedBy=default.target
SVCEOF

    # systemctl --user enable requires a running user session (dbus) — not available
    # in a chroot/TTY install. Create the WantedBy symlink manually instead, which
    # is exactly what systemctl --user enable does under the hood.
    local wants_dir="${svc_dir}/default.target.wants"
    mkdir -p "$wants_dir"
    ln -sf "${svc_dir}/noctalia-sycoca.service" \
        "${wants_dir}/noctalia-sycoca.service"
    print_success "Wrote + enabled noctalia-sycoca.service"
    echo ""
}

# ── Step H: SDDM + HyprSDDM ───────────────────────────────────────────────────

configure_sddm() {
    print_header
    print_step "Installing SDDM..."
    $SUDO_CMD pacman -S --needed --noconfirm sddm || { print_error "Failed to install SDDM!"; exit 1; }
    print_success "SDDM installed!"
    echo ""

    print_step "Installing HyprSDDM theme..."
    local tmp_sddm
    tmp_sddm=$(mktemp -d)
    if git clone --no-checkout --depth=1 --filter=blob:none \
            https://github.com/xerolinux/HyprXero-git.git "$tmp_sddm" 2>/dev/null; then
        git -C "$tmp_sddm" sparse-checkout set \
            Configs/System/usr/share/sddm/themes/HyprSDDM 2>/dev/null
        git -C "$tmp_sddm" checkout 2>/dev/null
        $SUDO_CMD mkdir -p /usr/share/sddm/themes
        $SUDO_CMD cp -r "$tmp_sddm/Configs/System/usr/share/sddm/themes/HyprSDDM" \
            /usr/share/sddm/themes/
        rm -rf "$tmp_sddm"
        # Patch theme.conf: XeroLinux wallpaper, purple accent, JetBrainsMono font
        local tcf=/usr/share/sddm/themes/HyprSDDM/theme.conf
        $SUDO_CMD sed -i \
            -e 's|wallpaper="backgrounds/bg.png"|wallpaper="/usr/share/wallpapers/Xero-Plasma44.jpg"|' \
            -e 's|accentColour="#568b22"|accentColour="#a06af0"|' \
            -e 's|fontFamily="Noto Sans"|fontFamily="JetBrainsMono Nerd Font"|' \
            "$tcf"
        print_success "HyprSDDM theme installed!"
    else
        print_warning "Failed to clone HyprSDDM — SDDM will use default theme"
        rm -rf "$tmp_sddm"
    fi
    echo ""

    print_step "Writing SDDM configuration..."
    $SUDO_CMD mkdir -p /etc/sddm.conf.d
    cat <<'EOF' | $SUDO_CMD tee /etc/sddm.conf > /dev/null
[General]
InputMethod=
EOF
    cat <<'EOF' | $SUDO_CMD tee /etc/sddm.conf.d/kde_settings.conf > /dev/null
[Autologin]
Relogin=false
Session=
User=

[General]
HaltCommand=/usr/bin/systemctl poweroff
RebootCommand=/usr/bin/systemctl reboot

[Theme]
Current=HyprSDDM

[Users]
MaximumUid=60000
MinimumUid=1000
EOF
    print_success "SDDM configuration written!"
    echo ""

    print_step "Enabling sddm.service..."
    $SUDO_CMD systemctl enable sddm.service || { print_error "Failed to enable sddm.service!"; exit 1; }
    print_success "sddm.service enabled!"
    echo ""
}

# ── Step I: Qt / GTK / Icon theming ───────────────────────────────────────────

configure_themes() {
    [[ -z "${ACTUAL_HOME:-}" || -z "${ACTUAL_USER:-}" ]] && return 0

    print_step "Configuring Qt + GTK icon theme and fonts..."

    # qt5ct — style=Breeze so Noctalia's Qt color template can apply its palette
    mkdir -p "$ACTUAL_HOME/.config/qt5ct"
    cat > "$ACTUAL_HOME/.config/qt5ct/qt5ct.conf" << QT5CT
[Appearance]
color_scheme_path=${ACTUAL_HOME}/.config/qt5ct/colors/noctalia.conf
custom_palette=true
icon_theme=Tela-circle-purple-dark
standard_dialogs=default
style=Breeze

[Fonts]
fixed="JetBrainsMono Nerd Font,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
general="JetBrainsMono Nerd Font,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
QT5CT

    mkdir -p "$ACTUAL_HOME/.config/qt6ct"
    cat > "$ACTUAL_HOME/.config/qt6ct/qt6ct.conf" << QT6CT
[Appearance]
color_scheme_path=${ACTUAL_HOME}/.config/qt6ct/colors/noctalia.conf
custom_palette=true
icon_theme=Tela-circle-purple-dark
standard_dialogs=default
style=Fusion

[Fonts]
fixed="JetBrainsMono Nerd Font,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,,0,0"
general="JetBrainsMono Nerd Font,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,,0,0"

[Interface]
activate_item_on_single_click=1
buttonbox_layout=0
cursor_flash_time=1000
dialog_buttons_have_icons=1
double_click_interval=400
gui_effects=@Invalid()
keyboard_scheme=2
menus_have_icons=true
show_shortcuts_in_context_menus=true
stylesheets=@Invalid()
toolbutton_style=4
underline_shortcut=1
wheel_scroll_lines=3

[Troubleshooting]
force_raster_widgets=1
ignored_applications=@Invalid()
QT6CT

    # GTK3 — icon theme + dark pref + fonts only.
    # Noctalia's GTK color template writes the actual theme colors via matugen.
    mkdir -p "$ACTUAL_HOME/.config/gtk-3.0"
    cat > "$ACTUAL_HOME/.config/gtk-3.0/settings.ini" << 'GTK3'
[Settings]
gtk-icon-theme-name=Tela-circle-purple-dark
gtk-cursor-theme-name=Breeze_Snow
gtk-font-name=JetBrainsMono Nerd Font 11
gtk-application-prefer-dark-theme=1
GTK3

    # GTK4
    mkdir -p "$ACTUAL_HOME/.config/gtk-4.0"
    cat > "$ACTUAL_HOME/.config/gtk-4.0/settings.ini" << 'GTK4'
[Settings]
gtk-icon-theme-name=Tela-circle-purple-dark
gtk-cursor-theme-name=Breeze_Snow
gtk-font-name=JetBrainsMono Nerd Font 11
gtk-application-prefer-dark-theme=1
GTK4

    # GTK2
    cat > "$ACTUAL_HOME/.gtkrc-2.0" << 'GTK2'
gtk-icon-theme-name="Tela-circle-purple-dark"
gtk-cursor-theme-name="Breeze_Snow"
gtk-font-name="JetBrainsMono Nerd Font 11"
GTK2

    # nwg-look — mirrors GTK3 settings so nwg-look shows the right values when opened
    mkdir -p "$ACTUAL_HOME/.config/nwg-look"
    cat > "$ACTUAL_HOME/.config/nwg-look/config" << 'NWGLOOK'
gtk-icon-theme-name=Tela-circle-purple-dark
gtk-cursor-theme-name=Breeze_Snow
gtk-font-name=JetBrainsMono Nerd Font 11
gtk-application-prefer-dark-theme=1
NWGLOOK

    # Noctalia settings — full config based on XeroLinux reference install.
    # /home/xero paths replaced with the actual user's home at install time.
    mkdir -p "$ACTUAL_HOME/.config/noctalia"
    cat > "$ACTUAL_HOME/.config/noctalia/settings.json" << 'NOCCONF'
{
    "appLauncher": {
        "autoPasteClipboard": false,
        "clipboardWatchImageCommand": "wl-paste --type image --watch cliphist store",
        "clipboardWatchTextCommand": "wl-paste --type text --watch cliphist store",
        "clipboardWrapText": true,
        "customLaunchPrefix": "",
        "customLaunchPrefixEnabled": false,
        "density": "default",
        "enableClipPreview": true,
        "enableClipboardChips": true,
        "enableClipboardHistory": false,
        "enableClipboardSmartIcons": true,
        "enableSessionSearch": true,
        "enableSettingsSearch": true,
        "enableWindowsSearch": true,
        "iconMode": "tabler",
        "ignoreMouseInput": false,
        "overviewLayer": false,
        "pinnedApps": [
        ],
        "position": "center",
        "screenshotAnnotationTool": "",
        "showCategories": true,
        "showIconBackground": false,
        "sortByMostUsed": true,
        "terminalCommand": "konsole -e",
        "viewMode": "list"
    },
    "audio": {
        "mprisBlacklist": [
        ],
        "preferredPlayer": "",
        "spectrumFrameRate": 30,
        "spectrumMirrored": true,
        "visualizerType": "linear",
        "volumeFeedback": false,
        "volumeFeedbackSoundFile": "",
        "volumeOverdrive": false,
        "volumeStep": 5
    },
    "bar": {
        "autoHideDelay": 500,
        "autoShowDelay": 150,
        "backgroundOpacity": 0.93,
        "barType": "simple",
        "capsuleColorKey": "none",
        "capsuleOpacity": 1,
        "contentPadding": 2,
        "density": "default",
        "displayMode": "always_visible",
        "enableExclusionZoneInset": true,
        "fontScale": 1,
        "frameRadius": 12,
        "frameThickness": 8,
        "hideOnOverview": false,
        "marginHorizontal": 4,
        "marginVertical": 4,
        "middleClickAction": "none",
        "middleClickCommand": "",
        "middleClickFollowMouse": false,
        "monitors": [
        ],
        "mouseWheelAction": "none",
        "mouseWheelWrap": true,
        "outerCorners": true,
        "position": "top",
        "reverseScroll": false,
        "rightClickAction": "controlCenter",
        "rightClickCommand": "",
        "rightClickFollowMouse": true,
        "screenOverrides": [
        ],
        "showCapsule": true,
        "showOnWorkspaceSwitch": true,
        "showOutline": false,
        "useSeparateOpacity": false,
        "widgetSpacing": 6,
        "widgets": {
            "center": [
                {
                    "characterCount": 2,
                    "colorizeIcons": false,
                    "emptyColor": "secondary",
                    "enableScrollWheel": true,
                    "focusedColor": "primary",
                    "followFocusedScreen": false,
                    "fontWeight": "bold",
                    "groupedBorderOpacity": 1,
                    "hideUnoccupied": false,
                    "iconScale": 0.8,
                    "id": "Workspace",
                    "labelMode": "index",
                    "occupiedColor": "secondary",
                    "pillSize": 0.6,
                    "showApplications": false,
                    "showApplicationsHover": false,
                    "showBadge": true,
                    "showLabelsOnlyWhenOccupied": true,
                    "unfocusedIconsOpacity": 1
                }
            ],
            "left": [
                {
                    "colorizeSystemIcon": "none",
                    "colorizeSystemText": "none",
                    "customIconPath": "",
                    "enableColorization": false,
                    "icon": "rocket",
                    "iconColor": "none",
                    "id": "Launcher",
                    "useDistroLogo": false
                },
                {
                    "clockColor": "none",
                    "customFont": "",
                    "formatHorizontal": "HH:mm ddd, MMM dd",
                    "formatVertical": "HH mm - dd MM",
                    "id": "Clock",
                    "tooltipFormat": "HH:mm ddd, MMM dd",
                    "useCustomFont": false
                },
                {
                    "compactMode": true,
                    "diskPath": "/",
                    "iconColor": "none",
                    "id": "SystemMonitor",
                    "showCpuCores": false,
                    "showCpuFreq": false,
                    "showCpuTemp": true,
                    "showCpuUsage": true,
                    "showDiskAvailable": false,
                    "showDiskUsage": false,
                    "showDiskUsageAsPercent": false,
                    "showGpuTemp": false,
                    "showLoadAverage": false,
                    "showMemoryAsPercent": false,
                    "showMemoryUsage": true,
                    "showNetworkStats": false,
                    "showSwapUsage": false,
                    "textColor": "none",
                    "useMonospaceFont": true,
                    "usePadding": false
                },
                {
                    "colorizeIcons": false,
                    "hideMode": "hidden",
                    "id": "ActiveWindow",
                    "maxWidth": 145,
                    "scrollingMode": "hover",
                    "showIcon": true,
                    "showText": true,
                    "textColor": "none",
                    "useFixedWidth": false
                },
                {
                    "compactMode": false,
                    "hideMode": "hidden",
                    "hideWhenIdle": false,
                    "id": "MediaMini",
                    "maxWidth": 145,
                    "panelShowAlbumArt": true,
                    "scrollingMode": "hover",
                    "showAlbumArt": true,
                    "showArtistFirst": true,
                    "showProgressRing": true,
                    "showVisualizer": false,
                    "textColor": "none",
                    "useFixedWidth": false,
                    "visualizerType": "linear"
                }
            ],
            "right": [
                {
                    "blacklist": [
                    ],
                    "chevronColor": "none",
                    "colorizeIcons": false,
                    "drawerEnabled": true,
                    "hidePassive": false,
                    "id": "Tray",
                    "pinned": [
                    ]
                },
                {
                    "hideWhenZero": false,
                    "hideWhenZeroUnread": false,
                    "iconColor": "none",
                    "id": "NotificationHistory",
                    "showUnreadBadge": true,
                    "unreadBadgeColor": "primary"
                },
                {
                    "deviceNativePath": "__default__",
                    "displayMode": "graphic-clean",
                    "hideIfIdle": false,
                    "hideIfNotDetected": true,
                    "id": "Battery",
                    "showNoctaliaPerformance": false,
                    "showPowerProfiles": false
                },
                {
                    "displayMode": "onhover",
                    "iconColor": "none",
                    "id": "Volume",
                    "middleClickCommand": "pwvucontrol || pavucontrol",
                    "textColor": "none"
                },
                {
                    "applyToAllMonitors": false,
                    "displayMode": "onhover",
                    "iconColor": "none",
                    "id": "Brightness",
                    "textColor": "none"
                },
                {
                    "colorizeDistroLogo": false,
                    "colorizeSystemIcon": "none",
                    "colorizeSystemText": "none",
                    "customIconPath": "",
                    "enableColorization": false,
                    "icon": "noctalia",
                    "id": "ControlCenter",
                    "useDistroLogo": false
                }
            ]
        }
    },
    "brightness": {
        "backlightDeviceMappings": [
        ],
        "brightnessStep": 5,
        "enableDdcSupport": false,
        "enforceMinimum": true
    },
    "calendar": {
        "cards": [
            {
                "enabled": true,
                "id": "calendar-header-card"
            },
            {
                "enabled": true,
                "id": "calendar-month-card"
            },
            {
                "enabled": true,
                "id": "weather-card"
            }
        ]
    },
    "colorSchemes": {
        "darkMode": true,
        "generationMethod": "tonal-spot",
        "manualSunrise": "06:30",
        "manualSunset": "18:30",
        "monitorForColors": "",
        "predefinedScheme": "Catppuccin",
        "schedulingMode": "off",
        "syncGsettings": true,
        "useWallpaperColors": false
    },
    "controlCenter": {
        "cards": [
            {
                "enabled": true,
                "id": "profile-card"
            },
            {
                "enabled": true,
                "id": "shortcuts-card"
            },
            {
                "enabled": true,
                "id": "audio-card"
            },
            {
                "enabled": false,
                "id": "brightness-card"
            },
            {
                "enabled": true,
                "id": "weather-card"
            },
            {
                "enabled": true,
                "id": "media-sysmon-card"
            }
        ],
        "diskPath": "/",
        "position": "close_to_bar_button",
        "shortcuts": {
            "left": [
                {
                    "id": "Network"
                },
                {
                    "id": "Bluetooth"
                },
                {
                    "id": "WallpaperSelector"
                },
                {
                    "id": "NoctaliaPerformance"
                }
            ],
            "right": [
                {
                    "id": "Notifications"
                },
                {
                    "id": "PowerProfile"
                },
                {
                    "id": "KeepAwake"
                },
                {
                    "id": "NightLight"
                }
            ]
        }
    },
    "desktopWidgets": {
        "enabled": false,
        "gridSnap": false,
        "gridSnapScale": false,
        "monitorWidgets": [
        ],
        "overviewEnabled": true
    },
    "dock": {
        "animationSpeed": 1,
        "backgroundOpacity": 1,
        "colorizeIcons": false,
        "deadOpacity": 0.6,
        "displayMode": "exclusive",
        "dockType": "floating",
        "enabled": true,
        "floatingRatio": 1,
        "groupApps": false,
        "groupClickAction": "cycle",
        "groupContextMenuMode": "extended",
        "groupIndicatorStyle": "dots",
        "inactiveIndicators": true,
        "indicatorColor": "primary",
        "indicatorOpacity": 0.6,
        "indicatorThickness": 3,
        "launcherIcon": "brand-adobe",
        "launcherIconColor": "primary",
        "launcherPosition": "start",
        "launcherUseDistroLogo": false,
        "monitors": [
        ],
        "onlySameOutput": true,
        "pinnedApps": [
            "org.kde.dolphin",
            "org.kde.konsole",
            "xero-toolkit"
        ],
        "pinnedStatic": false,
        "position": "bottom",
        "showDockIndicator": true,
        "showLauncherIcon": true,
        "sitOnFrame": false,
        "size": 1
    },
    "general": {
        "allowPanelsOnScreenWithoutBar": true,
        "allowPasswordWithFprintd": false,
        "animationDisabled": false,
        "animationSpeed": 1,
        "autoStartAuth": false,
        "avatarImage": "/home/xero/.face",
        "boxRadiusRatio": 1,
        "clockFormat": "hh\\nmm",
        "clockStyle": "custom",
        "compactLockScreen": false,
        "dimmerOpacity": 0.2,
        "enableBlurBehind": true,
        "enableLockScreenCountdown": true,
        "enableLockScreenMediaControls": false,
        "enableShadows": true,
        "forceBlackScreenCorners": false,
        "iRadiusRatio": 1,
        "keybinds": {
            "keyDown": [
                "Down"
            ],
            "keyEnter": [
                "Return",
                "Enter"
            ],
            "keyEscape": [
                "Esc"
            ],
            "keyLeft": [
                "Left"
            ],
            "keyRemove": [
                "Del"
            ],
            "keyRight": [
                "Right"
            ],
            "keyUp": [
                "Up"
            ]
        },
        "language": "",
        "lockOnSuspend": true,
        "lockScreenAnimations": false,
        "lockScreenBlur": 0,
        "lockScreenCountdownDuration": 10000,
        "lockScreenMonitors": [
        ],
        "lockScreenTint": 0,
        "passwordChars": false,
        "radiusRatio": 1,
        "reverseScroll": false,
        "scaleRatio": 1,
        "screenRadiusRatio": 1,
        "shadowDirection": "bottom_right",
        "shadowOffsetX": 2,
        "shadowOffsetY": 3,
        "showChangelogOnStartup": true,
        "showHibernateOnLockScreen": false,
        "showScreenCorners": false,
        "showSessionButtonsOnLockScreen": true,
        "smoothScrollEnabled": true,
        "telemetryEnabled": false
    },
    "hooks": {
        "colorGeneration": "",
        "darkModeChange": "",
        "enabled": false,
        "performanceModeDisabled": "",
        "performanceModeEnabled": "",
        "screenLock": "",
        "screenUnlock": "",
        "session": "",
        "startup": "",
        "wallpaperChange": ""
    },
    "idle": {
        "customCommands": "[]",
        "enabled": false,
        "fadeDuration": 5,
        "lockCommand": "",
        "lockTimeout": 660,
        "resumeLockCommand": "",
        "resumeScreenOffCommand": "",
        "resumeSuspendCommand": "",
        "screenOffCommand": "",
        "screenOffTimeout": 600,
        "suspendCommand": "",
        "suspendTimeout": 1800
    },
    "location": {
        "analogClockInCalendar": false,
        "autoLocate": false,
        "firstDayOfWeek": -1,
        "hideWeatherCityName": false,
        "hideWeatherTimezone": false,
        "name": "",
        "showCalendarEvents": true,
        "showCalendarWeather": true,
        "showWeekNumberInCalendar": false,
        "use12hourFormat": false,
        "useFahrenheit": false,
        "weatherEnabled": true,
        "weatherShowEffects": true,
        "weatherTaliaMascotAlways": false
    },
    "network": {
        "bluetoothAutoConnect": true,
        "bluetoothDetailsViewMode": "grid",
        "bluetoothHideUnnamedDevices": false,
        "bluetoothRssiPollIntervalMs": 60000,
        "bluetoothRssiPollingEnabled": false,
        "disableDiscoverability": false,
        "networkPanelView": "wifi",
        "wifiDetailsViewMode": "grid"
    },
    "nightLight": {
        "autoSchedule": true,
        "dayTemp": "6500",
        "enabled": false,
        "forced": false,
        "manualSunrise": "06:30",
        "manualSunset": "18:30",
        "nightTemp": "4000"
    },
    "noctaliaPerformance": {
        "disableDesktopWidgets": true,
        "disableWallpaper": false
    },
    "notifications": {
        "backgroundOpacity": 1,
        "clearDismissed": true,
        "criticalUrgencyDuration": 15,
        "density": "default",
        "enableBatteryToast": true,
        "enableKeyboardLayoutToast": true,
        "enableMarkdown": false,
        "enableMediaToast": false,
        "enabled": true,
        "location": "top_right",
        "lowUrgencyDuration": 3,
        "monitors": [
        ],
        "normalUrgencyDuration": 8,
        "overlayLayer": true,
        "respectExpireTimeout": false,
        "saveToHistory": {
            "critical": true,
            "low": true,
            "normal": true
        },
        "sounds": {
            "criticalSoundFile": "",
            "enabled": false,
            "excludedApps": "discord,firefox,chrome,chromium,edge",
            "lowSoundFile": "",
            "normalSoundFile": "",
            "separateSounds": false,
            "volume": 0.5
        }
    },
    "osd": {
        "autoHideMs": 2000,
        "backgroundOpacity": 1,
        "enabled": true,
        "enabledTypes": [
            0,
            1,
            2
        ],
        "location": "top_right",
        "monitors": [
        ],
        "overlayLayer": true
    },
    "plugins": {
        "autoUpdate": false,
        "notifyUpdates": true
    },
    "sessionMenu": {
        "countdownDuration": 10000,
        "enableCountdown": true,
        "largeButtonsLayout": "single-row",
        "largeButtonsStyle": true,
        "position": "center",
        "powerOptions": [
            {
                "action": "lock",
                "enabled": true,
                "keybind": "1"
            },
            {
                "action": "suspend",
                "enabled": true,
                "keybind": "2"
            },
            {
                "action": "hibernate",
                "enabled": true,
                "keybind": "3"
            },
            {
                "action": "reboot",
                "enabled": true,
                "keybind": "4"
            },
            {
                "action": "logout",
                "enabled": true,
                "keybind": "5"
            },
            {
                "action": "shutdown",
                "enabled": true,
                "keybind": "6"
            },
            {
                "action": "rebootToUefi",
                "enabled": true,
                "keybind": "7"
            }
        ],
        "showHeader": true,
        "showKeybinds": true
    },
    "settingsVersion": 59,
    "systemMonitor": {
        "batteryCriticalThreshold": 5,
        "batteryWarningThreshold": 20,
        "cpuCriticalThreshold": 90,
        "cpuWarningThreshold": 80,
        "criticalColor": "",
        "diskAvailCriticalThreshold": 10,
        "diskAvailWarningThreshold": 20,
        "diskCriticalThreshold": 90,
        "diskWarningThreshold": 80,
        "enableDgpuMonitoring": false,
        "externalMonitor": "resources || missioncenter || jdsystemmonitor || corestats || system-monitoring-center || gnome-system-monitor || plasma-systemmonitor || mate-system-monitor || ukui-system-monitor || deepin-system-monitor || pantheon-system-monitor",
        "gpuCriticalThreshold": 90,
        "gpuWarningThreshold": 80,
        "memCriticalThreshold": 90,
        "memWarningThreshold": 80,
        "swapCriticalThreshold": 90,
        "swapWarningThreshold": 80,
        "tempCriticalThreshold": 90,
        "tempWarningThreshold": 80,
        "useCustomColors": false,
        "warningColor": ""
    },
    "templates": {
        "activeTemplates": [
            {
                "enabled": true,
                "id": "gtk"
            },
            {
                "enabled": true,
                "id": "hyprland"
            },
            {
                "enabled": true,
                "id": "hyprtoolkit"
            },
            {
                "enabled": true,
                "id": "alacritty"
            },
            {
                "enabled": true,
                "id": "cava"
            },
            {
                "enabled": true,
                "id": "discord"
            },
            {
                "enabled": true,
                "id": "kitty"
            },
            {
                "enabled": true,
                "id": "telegram"
            },
            {
                "enabled": true,
                "id": "code"
            },
            {
                "enabled": true,
                "id": "yazi"
            },
            {
                "enabled": true,
                "id": "zenBrowser"
            },
            {
                "enabled": true,
                "id": "qt"
            },
            {
                "enabled": true,
                "id": "kcolorscheme"
            }
        ],
        "enableUserTheming": false
    },
    "ui": {
        "boxBorderEnabled": false,
        "fontDefault": "JetBrainsMono Nerd Font",
        "fontDefaultScale": 1,
        "fontFixed": "monospace",
        "fontFixedScale": 1,
        "panelBackgroundOpacity": 0.93,
        "panelsAttachedToBar": true,
        "scrollbarAlwaysVisible": true,
        "settingsPanelMode": "attached",
        "settingsPanelSideBarCardStyle": false,
        "tooltipsEnabled": true,
        "translucentWidgets": false
    },
    "wallpaper": {
        "automationEnabled": false,
        "directory": "/home/xero/Pictures/Wallpapers",
        "enableMultiMonitorDirectories": false,
        "enabled": true,
        "favorites": [
        ],
        "fillColor": "#000000",
        "fillMode": "crop",
        "hideWallpaperFilenames": false,
        "linkLightAndDarkWallpapers": true,
        "monitorDirectories": [
        ],
        "overviewBlur": 0.4,
        "overviewEnabled": false,
        "overviewTint": 0.6,
        "panelPosition": "follow_bar",
        "randomIntervalSec": 300,
        "setWallpaperOnAllMonitors": true,
        "showHiddenFiles": false,
        "skipStartupTransition": false,
        "solidColor": "#1a1a2e",
        "sortOrder": "name",
        "transitionDuration": 1500,
        "transitionEdgeSmoothness": 0.05,
        "transitionType": [
            "fade",
            "disc",
            "stripes",
            "wipe",
            "pixelate",
            "honeycomb"
        ],
        "useOriginalImages": false,
        "useSolidColor": false,
        "useWallhaven": false,
        "viewMode": "single",
        "wallhavenApiKey": "",
        "wallhavenCategories": "111",
        "wallhavenOrder": "desc",
        "wallhavenPurity": "100",
        "wallhavenQuery": "",
        "wallhavenRatios": "",
        "wallhavenResolutionHeight": "",
        "wallhavenResolutionMode": "atleast",
        "wallhavenResolutionWidth": "",
        "wallhavenSorting": "relevance",
        "wallpaperChangeMode": "random"
    }
}
NOCCONF
    sed -i "s|/home/xero|${ACTUAL_HOME}|g" "$ACTUAL_HOME/.config/noctalia/settings.json"

    print_step "Setting default wallpaper..."
    local wp_src="/usr/share/wallpapers/Xero-Plasma44.jpg"
    local noctalia_wp="/etc/xdg/quickshell/noctalia-shell/Assets/Wallpaper/noctalia.png"
    mkdir -p "$ACTUAL_HOME/Pictures/Wallpapers"
    if [[ -f "$wp_src" ]]; then
        cp "$wp_src" "$ACTUAL_HOME/Pictures/Wallpapers/Xero-Plasma44.jpg"
        $SUDO_CMD chown "$ACTUAL_USER:$ACTUAL_USER" \
            "$ACTUAL_HOME/Pictures/Wallpapers/Xero-Plasma44.jpg"
        if [[ -f "$noctalia_wp" ]]; then
            $SUDO_CMD convert "$wp_src" "$noctalia_wp" 2>/dev/null \
                && print_success "Default wallpaper set: Xero-Plasma44 (replaced noctalia.png)" \
                || print_warning "imagemagick convert failed — noctalia.png not replaced"
        else
            print_success "Default wallpaper seeded to ~/Pictures/Wallpapers"
        fi
    else
        print_warning "Xero-Plasma44.jpg not found — skipping wallpaper setup"
    fi
    echo ""

    print_step "Setting Noctalia color scheme for KDE apps..."
    for rc in katerc kwriterc dolphinrc gwenviewrc; do
        local rcfile="$ACTUAL_HOME/.config/$rc"
        # Write section fresh — more reliable than conditional sed on files that may not exist yet
        printf '\n[UiSettings]\nColorScheme=noctalia\n' >> "$rcfile"
        $SUDO_CMD chown "$ACTUAL_USER:$ACTUAL_USER" "$rcfile"
    done
    print_success "KDE app color scheme set to: noctalia"
    echo ""

    $SUDO_CMD chown -R "$ACTUAL_USER:$ACTUAL_USER" \
        "$ACTUAL_HOME/.config/qt5ct" \
        "$ACTUAL_HOME/.config/qt6ct" \
        "$ACTUAL_HOME/.config/gtk-3.0" \
        "$ACTUAL_HOME/.config/gtk-4.0" \
        "$ACTUAL_HOME/.gtkrc-2.0" \
        "$ACTUAL_HOME/.config/nwg-look" \
        "$ACTUAL_HOME/.config/noctalia" 2>/dev/null || true

    print_success "Icon theme: Tela-circle-purple-dark. Color scheme: Catppuccin (via Noctalia)."
    echo ""

    print_step "Setting system-wide Qt platform theme..."
    # QT_QPA_PLATFORMTHEME is set per-session via hl.env() in hyprland.lua.
    # Writing it to /etc/environment is too broad — it affects SDDM and system
    # services, which may not have qt6ct configured and will silently break.
    echo ""

    print_step "Copying user config to root (theme parity for root apps)..."
    $SUDO_CMD cp -r "$ACTUAL_HOME/.config/." /root/.config/
    print_success "User .config mirrored to /root/.config"
    echo ""
}

# ── Step J: Copy skel + distro identity ───────────────────────────────────────

copy_skel_to_user() {
    print_header
    print_step "Applying XeroLinux configurations... 📁"
    echo ""

    print_step "Copying /etc/skel configurations to $ACTUAL_HOME for user $ACTUAL_USER..."
    echo ""
    $SUDO_CMD cp -Rf /etc/skel/. "$ACTUAL_HOME"/
    $SUDO_CMD chown -R "$ACTUAL_USER:$ACTUAL_USER" "$ACTUAL_HOME"

    print_step "Fetching XeroLinux .bashrc..."
    curl -fsSL "https://raw.githubusercontent.com/xerolinux/XeroBuild/main/FOSS/airootfs/etc/skel/.bashrc" \
        -o "$ACTUAL_HOME/.bashrc" 2>/dev/null \
        && print_success ".bashrc applied!" \
        || print_warning "Failed to fetch .bashrc (non-critical)"

    print_step "Fetching XeroLinux desktop configs..."
    local tmp_cfg
    tmp_cfg=$(mktemp -d)
    if git clone --no-checkout --depth=1 --filter=blob:none \
        https://github.com/xerolinux/desktop-config.git "$tmp_cfg" 2>/dev/null; then
        git -C "$tmp_cfg" sparse-checkout set \
            etc/skel/.config/fastfetch \
            etc/skel/.config/ohmyposh \
            etc/skel/.config/paru \
            etc/skel/.config/bat \
            etc/skel/.config/btop \
            etc/skel/.config/topgrade.toml
        git -C "$tmp_cfg" checkout 2>/dev/null
        mkdir -p "$ACTUAL_HOME/.config"
        for d in fastfetch ohmyposh paru bat btop; do
            [[ -d "$tmp_cfg/etc/skel/.config/$d" ]] && \
                $SUDO_CMD cp -Rf "$tmp_cfg/etc/skel/.config/$d" "$ACTUAL_HOME/.config/"
        done
        [[ -f "$tmp_cfg/etc/skel/.config/topgrade.toml" ]] && \
            $SUDO_CMD cp "$tmp_cfg/etc/skel/.config/topgrade.toml" "$ACTUAL_HOME/.config/"
        rm -rf "$tmp_cfg"
        print_success "Desktop configs applied!"
    else
        rm -rf "$tmp_cfg"
        print_warning "Could not fetch desktop configs (non-critical)"
    fi

    print_step "Configuring Alacritty fonts..."
    mkdir -p "$ACTUAL_HOME/.config/alacritty"
    cat > "$ACTUAL_HOME/.config/alacritty/alacritty.toml" << 'ALACRITTY'
[font]
normal      = { family = "JetBrainsMono Nerd Font", style = "Regular" }
bold        = { family = "JetBrainsMono Nerd Font", style = "Bold" }
italic      = { family = "JetBrainsMono Nerd Font", style = "Italic" }
bold_italic = { family = "JetBrainsMono Nerd Font", style = "Bold Italic" }
size = 12.0
ALACRITTY
    print_success "Alacritty font config written."

    print_step "Configuring Konsole fonts and color scheme..."
    mkdir -p "$ACTUAL_HOME/.local/share/konsole"

    curl -fsSL \
        "https://raw.githubusercontent.com/catppuccin/konsole/main/themes/catppuccin-mocha.colorscheme" \
        -o "$ACTUAL_HOME/.local/share/konsole/catppuccin-mocha.colorscheme" 2>/dev/null \
        && print_success "Catppuccin Mocha color scheme downloaded." \
        || print_warning "Failed to fetch Catppuccin Konsole theme (non-critical)"

    cat > "$ACTUAL_HOME/.local/share/konsole/XeroLinux.profile" << 'KONSOLE'
[Appearance]
ColorScheme=catppuccin-mocha
Font=JetBrainsMono Nerd Font,12,-1,5,400,0,0,0,0,0,0,0,0,0,0,1

[General]
Name=XeroLinux
Parent=FALLBACK/
TerminalColumns=120
TerminalRows=30

[Scrolling]
HistoryMode=2
ScrollBarPosition=2

[Terminal Features]
AnimatingCursorEnabled=true
BlinkingCursorEnabled=true
KONSOLE
    mkdir -p "$ACTUAL_HOME/.config"
    cat > "$ACTUAL_HOME/.config/konsolerc" << 'KONSOLERC'
[Desktop Entry]
DefaultProfile=XeroLinux.profile

[General]
ConfigVersion=1

[KonsoleWindow]
ShowMenuBarByDefault=false

[MainWindow][Toolbar mainToolBar]
visible=false

[MainWindow][Toolbar sessionToolBar]
visible=false

[TabBar]
TabBarVisibility=ShowTabBarWhenNeeded

[UiSettings]
ColorScheme=noctalia
KONSOLERC
    print_success "Konsole config written (clean window: no toolbars, no menubar, tab bar on demand)."

    print_step "Configuring system fonts..."
    mkdir -p "$ACTUAL_HOME/.config/fontconfig"
    cat > "$ACTUAL_HOME/.config/fontconfig/fonts.conf" << 'FONTCFG'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <alias>
    <family>monospace</family>
    <prefer><family>JetBrainsMono Nerd Font</family></prefer>
  </alias>
  <alias>
    <family>sans-serif</family>
    <prefer><family>JetBrainsMono Nerd Font</family></prefer>
  </alias>
  <alias>
    <family>serif</family>
    <prefer><family>JetBrainsMono Nerd Font</family></prefer>
  </alias>
</fontconfig>
FONTCFG
    print_success "Fontconfig written."

    $SUDO_CMD chown -R "$ACTUAL_USER:$ACTUAL_USER" "$ACTUAL_HOME"

    # Runs as the actual user — no dbus/X11 needed, safe from TTY chroot.
    print_step "Creating XDG user directories..."
    if [[ "${EUID:-0}" -eq 0 ]]; then
        su -l "$ACTUAL_USER" -c "xdg-user-dirs-update" 2>/dev/null \
            && print_success "XDG user directories created!" \
            || print_warning "xdg-user-dirs-update failed (non-critical)"
    else
        xdg-user-dirs-update 2>/dev/null \
            && print_success "XDG user directories created!" \
            || print_warning "xdg-user-dirs-update failed (non-critical)"
    fi
    echo ""

    print_success "XeroLinux configurations applied to $ACTUAL_HOME!"
    echo ""

    print_step "Copying /etc/skel configurations to /root..."
    $SUDO_CMD cp -Rf /etc/skel/. /root/
    print_success "Configurations copied to /root!"
    echo ""

    print_step "Setting up XeroLinux Toolkit autostart... 🚀"
    $SUDO_CMD mkdir -p /etc/xdg/autostart
    if [[ -f /usr/share/applications/xero-toolkit.desktop ]]; then
        $SUDO_CMD cp /usr/share/applications/xero-toolkit.desktop /etc/xdg/autostart/
        print_success "XeroLinux Toolkit added to autostart!"
    else
        print_warning "xero-toolkit.desktop not found, skipping autostart setup (non-critical)"
    fi
    echo ""

    # Apply GRUB theme — direct install, bypasses Grub.sh $UID bug
    print_step "Applying GRUB theme..."
    echo ""

    local WORKDIR="/tmp/xero-layan-git"
    $SUDO_CMD rm -rf "$WORKDIR"

    if git clone --depth=1 https://github.com/xerolinux/xero-layan-git.git "$WORKDIR" 2>/dev/null; then
        local THEME_SRC="$WORKDIR/XeroLayan"
        local THEME_DEST="/boot/grub/themes/XeroLayan"

        if [[ -d "$THEME_SRC" && -f "$THEME_SRC/theme.txt" ]]; then
            $SUDO_CMD rm -rf "$THEME_DEST"
            $SUDO_CMD mkdir -p "$THEME_DEST"
            $SUDO_CMD cp -a "$THEME_SRC/." "$THEME_DEST/"

            if $SUDO_CMD grep -q "^GRUB_THEME=" /etc/default/grub 2>/dev/null; then
                $SUDO_CMD sed -i "s|^GRUB_THEME=.*|GRUB_THEME=\"${THEME_DEST}/theme.txt\"|" /etc/default/grub
            else
                echo "GRUB_THEME=\"${THEME_DEST}/theme.txt\"" | $SUDO_CMD tee -a /etc/default/grub > /dev/null
            fi

            if $SUDO_CMD update-grub 2>/dev/null; then
                print_success "GRUB theme applied!"
            elif $SUDO_CMD grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null; then
                print_success "GRUB theme applied (via grub-mkconfig)!"
            else
                print_warning "grub-mkconfig failed — theme configured but grub.cfg may be stale"
            fi
        else
            print_warning "XeroLayan theme directory or theme.txt missing — skipping"
        fi

        [[ -d "$WORKDIR/Configs/System" ]] && \
            $SUDO_CMD cp -Rf "$WORKDIR/Configs/System/." / 2>/dev/null || true
        $SUDO_CMD rm -rf "$WORKDIR"
        echo ""
    else
        print_warning "Failed to clone xero-layan-git — GRUB theme not applied (non-critical)"
        echo ""
    fi

    print_step "Setting distro identity files... 🏷️"
    echo ""

    fetch_file() {
        local url="$1" dest="$2"
        if command -v wget >/dev/null 2>&1; then
            $SUDO_CMD wget -qO "$dest" "$url"
        elif command -v curl >/dev/null 2>&1; then
            $SUDO_CMD curl -fsSL "$url" -o "$dest"
        else
            return 1
        fi
    }

    ID_URL_BASE="https://raw.githubusercontent.com/XeroLinux/XeroBuild/refs/heads/main/FOSS/airootfs/etc"
    $SUDO_CMD mkdir -p /etc/xdg

    fetch_file "$ID_URL_BASE/dev-rel"              "/etc/dev-rel"                   \
        && print_success "Updated /etc/dev-rel"    \
        || print_warning "Failed to fetch /etc/dev-rel (non-critical)"

    fetch_file "$ID_URL_BASE/os-release"           "/etc/os-release"                \
        && print_success "Updated /etc/os-release" \
        || print_warning "Failed to fetch /etc/os-release (non-critical)"

    fetch_file "$ID_URL_BASE/xdg/kcm-about-distrorc" "/etc/xdg/kcm-about-distrorc" \
        && print_success "Updated /etc/xdg/kcm-about-distrorc"                      \
        || print_warning "Failed to fetch /etc/xdg/kcm-about-distrorc (non-critical)"

    echo ""
    print_success "All post-install config steps completed."
    echo ""
}

# ── Step K: Finalize ──────────────────────────────────────────────────────────

finalize_system() {
    print_header
    print_step "Finalizing system configuration... ⚙️"
    echo ""

    print_step "Updating initramfs..."
    $SUDO_CMD mkinitcpio -P \
        && print_success "Initramfs updated!" \
        || print_warning "mkinitcpio had errors — system may still boot, check manually"
    echo ""

    print_step "Updating GRUB configuration..."
    $SUDO_CMD update-grub \
        && print_success "GRUB configuration updated!" \
        || print_warning "update-grub had errors — check bootloader config manually"
    echo ""

    print_step "Enabling core services..."
    enable_service_if_available cups.socket
    enable_service_if_available saned.socket
    enable_service_if_available bluetooth
    enable_service_if_available wpa_supplicant
    enable_service_if_available sshd
    print_success "Core services enabled!"
    echo ""

    print_step "Enabling conditional services..."
    enable_if_installed power-profiles-daemon
    enable_if_installed switcheroo-control
    [[ "$FILESYSTEM" == "btrfs" ]] && enable_service_if_available grub-btrfsd
    print_success "Conditional services processed!"
    echo ""

    print_step "Installing xero-gpu-tools..."
    $SUDO_CMD pacman -S --needed --noconfirm xero-gpu-tools \
        && enable_service_if_available xero-gpu-check \
        || print_warning "xero-gpu-tools install failed (non-critical)"
    echo ""

    print_step "Disabling live-environment services..."
    $SUDO_CMD systemctl disable iwd                      2>/dev/null || true
    $SUDO_CMD systemctl disable dhcpcd                   2>/dev/null || true
    $SUDO_CMD systemctl disable reflector                2>/dev/null || true
    $SUDO_CMD systemctl disable pacman-init              2>/dev/null || true
    $SUDO_CMD systemctl disable systemd-time-wait-sync   2>/dev/null || true
    print_success "Live-environment services disabled!"
    echo ""

    if [[ -n "${ACTUAL_USER:-}" && -n "${ACTUAL_HOME:-}" ]]; then
        print_step "Fixing ownership of user home directory..."
        $SUDO_CMD chown -R "$ACTUAL_USER:$ACTUAL_USER" "$ACTUAL_HOME" \
            && print_success "Ownership fixed for ${ACTUAL_USER}!" \
            || print_warning "chown failed — some config files may be root-owned"
        echo ""
    fi
}

# ── Completion ────────────────────────────────────────────────────────────────

show_completion() {
    print_header
    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${GREEN}     🎉 Installation Complete! 🎉              ${PURPLE}║${NC}"
    echo -e "${PURPLE}╠════════════════════════════════════════════════╣${NC}"
    echo -e "${PURPLE}║${NC}  Hyprland + Noctalia is ready!                ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}  Log out → pick ${YELLOW}Hyprland${NC} session at SDDM.    ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}                                               ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}  Command: ${YELLOW}sudo reboot${NC}                        ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}"
    echo ""
}

# ── Noctalia: Hyprland 0.55+ Lua compatibility (Gipphe fork commit ce6e713) ────

patch_noctalia_dispatcher() {
    local noc_base="/etc/xdg/quickshell/noctalia-shell"

    if [[ ! -d "$noc_base" ]]; then
        print_warning "noctalia-shell not found at $noc_base — skipping patches"
        echo ""
        return
    fi

    print_step "Applying Noctalia Hyprland 0.55+ compatibility patch (ce6e713)..."

    local tmp

    # ── Services/Compositor/HyprlandService.qml ──────────────────────────────
    tmp=$(mktemp)
    cat > "$tmp" << 'NP_HYPRSVC_EOF'
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons
import qs.Services.Keyboard

Item {
  id: root

  // Properties that match the facade interface
  property ListModel workspaces: ListModel {}
  property var windows: []
  property int focusedWindowIndex: -1

  // Signals that match the facade interface
  signal workspaceChanged
  signal activeWindowChanged
  signal windowListChanged
  signal displayScalesChanged

  // Hyprland-specific properties
  property bool initialized: false
  property var workspaceCache: ({})
  property var windowCache: ({})

  // Debounce timer for window updates
  Timer {
    id: updateTimer
    interval: 50
    repeat: false
    onTriggered: safeUpdate()
  }

  // Deferred via Qt.callLater to coalesce workspace updates: onRawEvent calls
  // refreshWorkspaces() which triggers onValuesChanged synchronously in the
  // same call stack — without deferral the ListModel gets cleared+repopulated
  // twice per event. Qt.callLater deduplicates by function identity.
  function _deferredWorkspaceUpdate() {
    safeUpdateWorkspaces();
    workspaceChanged();
  }

  // Initialization
  function initialize() {
    if (initialized)
      return;
    try {
      Hyprland.refreshWorkspaces();
      Hyprland.refreshToplevels();
      Qt.callLater(() => {
                     safeUpdateWorkspaces();
                     safeUpdateWindows();
                     queryDisplayScales();
                     queryKeyboardLayout();
                   });
      initialized = true;
      Logger.i("HyprlandService", "Service started");
    } catch (e) {
      Logger.e("HyprlandService", "Failed to initialize:", e);
    }
  }

  // Query display scales
  function queryDisplayScales() {
    hyprlandMonitorsProcess.running = true;
  }

  // Hyprland monitors process for display scale detection
  Process {
    id: hyprlandMonitorsProcess
    running: false
    command: ["hyprctl", "monitors", "-j"]

    property string accumulatedOutput: ""

    stdout: SplitParser {
      onRead: function (line) {
        // Accumulate lines instead of parsing each one
        hyprlandMonitorsProcess.accumulatedOutput += line;
      }
    }

    onExited: function (exitCode) {
      if (exitCode !== 0 || !accumulatedOutput) {
        Logger.e("HyprlandService", "Failed to query monitors, exit code:", exitCode);
        accumulatedOutput = "";
        return;
      }

      try {
        const monitorsData = JSON.parse(accumulatedOutput);
        const scales = {};

        for (const monitor of monitorsData) {
          if (monitor.name) {
            scales[monitor.name] = {
              "name": monitor.name,
              "scale": monitor.scale || 1.0,
              "width": monitor.width || 0,
              "height": monitor.height || 0,
              "refresh_rate": monitor.refreshRate || 0,
              "x": monitor.x || 0,
              "y": monitor.y || 0,
              "active_workspace": monitor.activeWorkspace ? monitor.activeWorkspace.id : -1,
              "vrr": monitor.vrr || false,
              "focused": monitor.focused || false
            };
          }
        }

        // Notify CompositorService (it will emit displayScalesChanged)
        if (CompositorService && CompositorService.onDisplayScalesUpdated) {
          CompositorService.onDisplayScalesUpdated(scales);
        }
      } catch (e) {
        Logger.e("HyprlandService", "Failed to parse monitors:", e);
      } finally {
        // Clear accumulated output for next query
        accumulatedOutput = "";
      }
    }
  }

  function queryKeyboardLayout() {
    hyprlandDevicesProcess.running = true;
  }
  // Hyprland devices process for keyboard layout detection
  Process {
    id: hyprlandDevicesProcess
    running: false
    command: ["hyprctl", "devices", "-j"]

    property string accumulatedOutput: ""

    stdout: SplitParser {
      onRead: function (line) {
        // Accumulate lines instead of parsing each one
        hyprlandDevicesProcess.accumulatedOutput += line;
      }
    }

    onExited: function (exitCode) {
      if (exitCode !== 0 || !accumulatedOutput) {
        Logger.e("HyprlandService", "Failed to query devices, exit code:", exitCode);
        accumulatedOutput = "";
        return;
      }

      try {
        const devicesData = JSON.parse(accumulatedOutput);
        for (const keyboard of devicesData.keyboards) {
          if (keyboard.main) {
            const layoutName = keyboard.active_keymap;
            KeyboardLayoutService.setCurrentLayout(layoutName);
            Logger.d("HyprlandService", "Keyboard layout switched:", layoutName);
          }
        }
      } catch (e) {
        Logger.e("HyprlandService", "Failed to parse devices:", e);
      } finally {
        // Clear accumulated output for next query
        accumulatedOutput = "";
      }
    }
  }

  // Safe update wrapper
  function safeUpdate() {
    safeUpdateWindows();
    safeUpdateWorkspaces();
    workspaceChanged();
    windowListChanged();
  }

  // Safe workspace update
  function safeUpdateWorkspaces() {
    try {
      workspaces.clear();
      workspaceCache = {};

      if (!Hyprland.workspaces || !Hyprland.workspaces.values) {
        return;
      }

      const hlWorkspaces = Hyprland.workspaces.values;
      const occupiedIds = getOccupiedWorkspaceIds();

      for (var i = 0; i < hlWorkspaces.length; i++) {
        const ws = hlWorkspaces[i];
        if (ws.name && ws.name.startsWith("special:"))
          continue;

        const wsData = {
          "id": ws.id,
          "idx": ws.id,
          "name": ws.name || "",
          "output": (ws.monitor && ws.monitor.name) ? ws.monitor.name : "",
          "isActive": ws.active === true,
          "isFocused": ws.focused === true,
          "isUrgent": ws.urgent === true,
          "isOccupied": occupiedIds[ws.id] === true
        };

        workspaceCache[ws.id] = wsData;
        workspaces.append(wsData);
      }
    } catch (e) {
      Logger.e("HyprlandService", "Error updating workspaces:", e);
    }
  }

  // Get occupied workspace IDs safely
  function getOccupiedWorkspaceIds() {
    const occupiedIds = {};

    try {
      if (!Hyprland.toplevels || !Hyprland.toplevels.values) {
        return occupiedIds;
      }

      const hlToplevels = Hyprland.toplevels.values;
      for (var i = 0; i < hlToplevels.length; i++) {
        const toplevel = hlToplevels[i];
        if (!toplevel)
          continue;
        try {
          const wsId = toplevel.workspace ? toplevel.workspace.id : null;
          if (wsId !== null && wsId !== undefined) {
            occupiedIds[wsId] = true;
          }
        } catch (e)

          // Ignore individual toplevel errors
        {}
      }
    } catch (e)

      // Return empty if we can't determine occupancy
    {}

    return occupiedIds;
  }

  // Safe window update
  function safeUpdateWindows() {
    try {
      const windowsList = [];
      windowCache = {};

      if (!Hyprland.toplevels || !Hyprland.toplevels.values) {
        windows = [];
        focusedWindowIndex = -1;
        return;
      }

      const hlToplevels = Hyprland.toplevels.values;
      let focusedWindowId = null;

      // Get active workspaces to filter focus
      const activeWorkspaceIds = {};
      if (Hyprland.workspaces && Hyprland.workspaces.values) {
        const hlWorkspaces = Hyprland.workspaces.values;
        for (var j = 0; j < hlWorkspaces.length; j++) {
          if (hlWorkspaces[j].active) {
            activeWorkspaceIds[hlWorkspaces[j].id] = true;
          }
        }
      }

      for (var i = 0; i < hlToplevels.length; i++) {
        const toplevel = hlToplevels[i];
        if (!toplevel)
          continue;
        const windowData = extractWindowData(toplevel);
        if (windowData) {
          // If the window claims to be focused, verify it's on an active workspace
          if (windowData.isFocused) {
            if (!activeWorkspaceIds[windowData.workspaceId]) {
              windowData.isFocused = false;
            }
          }

          // Normalize to a plain, backend-independent window object
          const normalized = {
            "id": windowData.id ? String(windowData.id) : "",
            "title": windowData.title ? String(windowData.title) : "",
            "appId": windowData.appId ? String(windowData.appId) : "",
            "workspaceId": (typeof windowData.workspaceId === "number" && !isNaN(windowData.workspaceId)) ? windowData.workspaceId : -1,
            "isFocused": windowData.isFocused === true,
            "output": windowData.output ? String(windowData.output) : "",
            "x": (typeof windowData.x === "number" && !isNaN(windowData.x)) ? windowData.x : 0,
            "y": (typeof windowData.y === "number" && !isNaN(windowData.y)) ? windowData.y : 0
          };

          windowsList.push(normalized);
          windowCache[normalized.id] = normalized;

          if (normalized.isFocused) {
            focusedWindowId = normalized.id;
          }
        }
      }

      windows = toSortedWindowList(windowsList);

      // Resolve focused index from sorted list (order changes after sort)
      let newFocusedIndex = -1;
      if (focusedWindowId) {
        for (let k = 0; k < windows.length; k++) {
          if (windows[k].id === focusedWindowId) {
            newFocusedIndex = k;
            break;
          }
        }
      }

      if (newFocusedIndex !== focusedWindowIndex) {
        focusedWindowIndex = newFocusedIndex;
        activeWindowChanged();
      }
    } catch (e) {
      Logger.e("HyprlandService", "Error updating windows:", e);
    }
  }

  // Extract window data safely from a toplevel
  function extractWindowData(toplevel) {
    if (!toplevel)
      return null;

    try {
      // Safely extract properties
      const windowId = safeGetProperty(toplevel, "address", "");
      if (!windowId)
        return null;

      const appId = getAppId(toplevel);
      const title = getAppTitle(toplevel);
      const wsId = toplevel.workspace ? toplevel.workspace.id : null;
      const focused = toplevel.activated === true;
      const output = toplevel.monitor?.name || "";

      // Extract position
      let x = 0;
      let y = 0;
      try {
        const ipcData = toplevel.lastIpcObject;
        if (ipcData && ipcData.at) {
          x = ipcData.at[0];
          y = ipcData.at[1];
        } else if (typeof toplevel.x !== 'undefined') {
          x = toplevel.x;
          y = toplevel.y;
        }
      } catch (e) {}

      // Normalize coordinates to safe numeric values
      const safeX = (typeof x === "number" && !isNaN(x)) ? x : 0;
      const safeY = (typeof y === "number" && !isNaN(y)) ? y : 0;

      return {
        "id": windowId,
        "title": title,
        "appId": appId,
        "workspaceId": wsId || -1,
        "isFocused": focused,
        "output": output,
        "x": safeX,
        "y": safeY
      };
    } catch (e) {
      return null;
    }
  }

  function toSortedWindowList(windowList) {
    return windowList.sort((a, b) => {
                             // Sort by workspace first (just in case they are mixed)
                             if (a.workspaceId !== b.workspaceId) {
                               return a.workspaceId - b.workspaceId;
                             }
                             // Then sort by X position (left to right)
                             if (a.x !== b.x) {
                               return a.x - b.x;
                             }
                             // Then sort by Y position (top to bottom)
                             if (a.y !== b.y) {
                               return a.y - b.y;
                             }
                             // Fallback to Window ID mapping
                             return a.id.localeCompare(b.id);
                           });
  }

  function getAppTitle(toplevel) {
    try {
      var title = toplevel.wayland.title;
      if (title)
        return title;
    } catch (e) {}

    return safeGetProperty(toplevel, "title", "");
  }

  function getAppId(toplevel) {
    if (!toplevel)
      return "";

    var appId = "";

    // Try the wayland object first!
    // From my (Lemmy) testing it works fine so we could probably get rid of all the other attempts below.
    // Leaving them in for now, just in case...
    try {
      appId = toplevel.wayland.appId;
      if (appId)
        return appId;
    } catch (e) {}

    // Try direct properties
    appId = safeGetProperty(toplevel, "class", "");
    if (appId)
      return appId;

    appId = safeGetProperty(toplevel, "initialClass", "");
    if (appId)
      return appId;

    appId = safeGetProperty(toplevel, "appId", "");
    if (appId)
      return appId;

    // Try lastIpcObject
    try {
      const ipcData = toplevel.lastIpcObject;
      if (ipcData) {
        return String(ipcData.class || ipcData.initialClass || ipcData.appId || ipcData.wm_class || "");
      }
    } catch (e) {}

    return "";
  }

  // Safe property getter
  function safeGetProperty(obj, prop, defaultValue) {
    try {
      const value = obj[prop];
      if (value !== undefined && value !== null) {
        return String(value);
      }
    } catch (e)

      // Property access failed
    {}
    return defaultValue;
  }

  function handleActiveLayoutEvent(ev) {
    try {
      let beforeParenthesis;
      const parenthesisPos = ev.lastIndexOf('(');

      if (parenthesisPos === -1) {
        beforeParenthesis = ev;
      } else {
        beforeParenthesis = ev.substring(0, parenthesisPos);
      }

      const layoutNameStart = beforeParenthesis.lastIndexOf(',') + 1;
      const layoutName = ev.substring(layoutNameStart);

      // Ignore bogus "error" layout reported by virtual keyboards (e.g. wtype)
      if (layoutName.toLowerCase() === "error") {
        Logger.d("HyprlandService", "Ignoring bogus 'error' layout from activelayout event");
        return;
      }

      KeyboardLayoutService.setCurrentLayout(layoutName);
      Logger.d("HyprlandService", "Keyboard layout switched:", layoutName);
    } catch (e) {
      Logger.e("HyprlandService", "Error handling activelayout:", e);
    }
  }

  // Connections to Hyprland
  Connections {
    target: Hyprland.workspaces
    enabled: initialized
    function onValuesChanged() {
      Qt.callLater(_deferredWorkspaceUpdate);
    }
  }

  Connections {
    target: Hyprland.toplevels
    enabled: initialized
    function onValuesChanged() {
      updateTimer.restart();
    }
  }

  Connections {
    target: Hyprland
    enabled: initialized
    function onRawEvent(event) {
      Hyprland.refreshWorkspaces();
      Hyprland.refreshToplevels();
      // Workspace and window updates are deferred — refreshWorkspaces()/
      // refreshToplevels() trigger onValuesChanged which also calls
      // Qt.callLater, so the deduplication coalesces into one update.
      Qt.callLater(_deferredWorkspaceUpdate);
      updateTimer.restart();

      const monitorsEvents = ["configreloaded", "monitoradded", "monitorremoved", "monitoraddedv2", "monitorremovedv2"];

      if (monitorsEvents.includes(event.name)) {
        Qt.callLater(queryDisplayScales);
      }

      if (event.name == "activelayout") {
        handleActiveLayoutEvent(event.data);
      }
    }
  }

  // Public functions
  function switchToWorkspace(workspace) {
    try {
      if (workspace.name) {
        Hyprland.dispatch(`hl.dsp.focus {workspace = '${workspace.name}'}`);
        return;
      }
      Hyprland.dispatch(`hl.dsp.focus {workspace = '${workspace.idx}'}`);
    } catch (e) {
      Logger.e("HyprlandService", "Failed to switch workspace:", e);
    }
  }

  function focusWindow(window) {
    try {
      if (!window || !window.id) {
        Logger.w("HyprlandService", "Invalid window object for focus");
        return;
      }

      const windowId = window.id.toString();
      Hyprland.dispatch(`hl.dsp.focus {window = 'address:0x${windowId}'}`);
      Hyprland.dispatch(`hl.dsp.window.alter_zorder {mode = 'top', window = 'address:0x${windowId}'}`); // Bring the focused window to the top (essential for Float Mode)
    } catch (e) {
      Logger.e("HyprlandService", "Failed to switch window:", e);
    }
  }

  function closeWindow(window) {
    try {
      Hyprland.dispatch(`hl.dsp.window.kill {window = 'address:0x${window.id}'}`);
    } catch (e) {
      Logger.e("HyprlandService", "Failed to close window:", e);
    }
  }

  function turnOffMonitors() {
    try {
      Hyprland.dispatch("hl.dsp.dpms { action = 'off' }");
    } catch (e) {
      Logger.e("HyprlandService", "Failed to turn off monitors:", e);
    }
  }

  function turnOnMonitors() {
    try {
      Hyprland.dispatch("hl.dsp.dpms { action = 'on' }");
    } catch (e) {
      Logger.e("HyprlandService", "Failed to turn on monitors:", e);
    }
  }

  function logout() {
    try {
      Hyprland.dispatch("hl.dsp.exit()");
    } catch (e) {
      Logger.e("HyprlandService", "Failed to logout:", e);
    }
  }

  function cycleKeyboardLayout() {
    try {
      Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", "next"]);
    } catch (e) {
      Logger.e("HyprlandService", "Failed to cycle keyboard layout:", e);
    }
  }

  function getFocusedScreen() {
    const hyprMon = Hyprland.focusedMonitor;
    if (hyprMon) {
      const monitorName = hyprMon.name;
      for (let i = 0; i < Quickshell.screens.length; i++) {
        if (Quickshell.screens[i].name === monitorName) {
          return Quickshell.screens[i];
        }
      }
    }
    return null;
  }

  function spawn(command) {
    try {
      const cmd = command[0]
      Quickshell.execDetached(["hyprctl", "dispatch", `hl.dsp.exec_cmd("${cmd.replace(/"/g, '\\"')}")`]);
    } catch (e) {
      Logger.e("HyprlandService", "Failed to spawn command:", e);
    }
  }
}
NP_HYPRSVC_EOF
    $SUDO_CMD install -m 644 "$tmp" "$noc_base/Services/Compositor/HyprlandService.qml"
    rm -f "$tmp"
    print_success "Updated: Services/Compositor/HyprlandService.qml"

    # ── Services/Theming/TemplateRegistry.qml ────────────────────────────────
    tmp=$(mktemp)
    cat > "$tmp" << 'NP_TMPLREG_EOF'
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Singleton {
  id: root

  Component.onCompleted: {
    if (Settings.data.templates.enableUserTheming)
    writeUserTemplatesToml();
  }

  readonly property string templateApplyScript: Quickshell.shellDir + '/Scripts/bash/template-apply.sh'
  readonly property string gtkRefreshScript: Quickshell.shellDir + '/Scripts/python/src/theming/gtk-refresh.py'
  readonly property string kdeApplyScript: Quickshell.shellDir + '/Scripts/python/src/theming/kde-apply-scheme.py'
  readonly property string vscodeHelperScript: Quickshell.shellDir + '/Scripts/python/src/theming/vscode-helper.py'

  // Dynamically resolved VSCode extension theme paths (all matching noctalia extensions)
  property var resolvedCodePaths: []
  property var resolvedCodiumPaths: []

  // Terminal configurations (for wallpaper-based templates)
  // Each terminal must define a postHook that sets up config includes and triggers reload
  readonly property var terminals: [
    {
      "id": "foot",
      "name": "Foot",
      "templatePath": "terminal/foot",
      "predefinedTemplatePath": "terminal/foot-predefined",
      "outputPath": "~/.config/foot/themes/noctalia",
      "postHook": `${templateApplyScript} foot`
    },
    {
      "id": "ghostty",
      "name": "Ghostty",
      "templatePath": "terminal/ghostty",
      "predefinedTemplatePath": "terminal/ghostty-predefined",
      "outputPath": "~/.config/ghostty/themes/noctalia",
      "postHook": `${templateApplyScript} ghostty`
    },
    {
      "id": "kitty",
      "name": "Kitty",
      "templatePath": "terminal/kitty.conf",
      "predefinedTemplatePath": "terminal/kitty-predefined.conf",
      "outputPath": "~/.config/kitty/themes/noctalia.conf",
      "postHook": `${templateApplyScript} kitty`
    },
    {
      "id": "alacritty",
      "name": "Alacritty",
      "templatePath": "terminal/alacritty.toml",
      "predefinedTemplatePath": "terminal/alacritty-predefined.toml",
      "outputPath": "~/.config/alacritty/themes/noctalia.toml",
      "postHook": `${templateApplyScript} alacritty`
    },
    {
      "id": "wezterm",
      "name": "Wezterm",
      "templatePath": "terminal/wezterm.toml",
      "predefinedTemplatePath": "terminal/wezterm-predefined.toml",
      "outputPath": "~/.config/wezterm/colors/Noctalia.toml",
      "postHook": `${templateApplyScript} wezterm`
    },
    {
      "id": "starship",
      "name": "Starship",
      "templatePath": "terminal/starship.toml",
      "predefinedTemplatePath": "terminal/starship-predefined.toml",
      "outputPath": "~/.cache/noctalia/starship-palette.toml",
      "postHook": `${templateApplyScript} starship`
    }
  ]

  // Application configurations - consolidated from Theming + AppThemeService
  readonly property var applications: [
    {
      "id": "gtk",
      "name": "GTK",
      "category": "system",
      "input": "gtk4.css",
      "outputs": [
        {
          "path": "~/.config/gtk-3.0/noctalia.css",
          "input": "gtk3.css"
        },
        {
          "path": "~/.config/gtk-4.0/noctalia.css",
          "input": "gtk4.css"
        }
      ],
      "postProcess": mode => `python3 ${gtkRefreshScript} ${mode}`
    },
    {
      "id": "qt",
      "name": "Qt",
      "category": "system",
      "input": "qtct.conf",
      "outputs": [
        {
          "path": "~/.config/qt5ct/colors/noctalia.conf"
        },
        {
          "path": "~/.config/qt6ct/colors/noctalia.conf"
        }
      ]
    },
    {
      "id": "kcolorscheme",
      "name": "KColorScheme",
      "category": "system",
      "input": "kcolorscheme.colors",
      "outputs": [
        {
          "path": "~/.local/share/color-schemes/noctalia.colors"
        }
      ],
      "postProcess": () => `${kdeApplyScript} noctalia`
    },
    {
      "id": "fuzzel",
      "name": "Fuzzel",
      "category": "launcher",
      "input": "fuzzel.conf",
      "outputs": [
        {
          "path": "~/.config/fuzzel/themes/noctalia"
        }
      ],
      "postProcess": () => `${templateApplyScript} fuzzel`
    },
    {
      "id": "vicinae",
      "name": "Vicinae",
      "category": "launcher",
      "input": "vicinae.toml",
      "outputs": [
        {
          "path": "~/.local/share/vicinae/themes/noctalia.toml"
        }
      ],
      "postProcess": () => `cp --update=none ${Quickshell.shellDir}/Assets/noctalia.svg ~/.local/share/vicinae/themes/noctalia.svg && ${templateApplyScript} vicinae`
    },
    {
      "id": "walker",
      "name": "Walker",
      "category": "launcher",
      "input": "walker.css",
      "outputs": [
        {
          "path": "~/.config/walker/themes/noctalia/style.css"
        }
      ],
      "postProcess": () => `${templateApplyScript} walker`,
      "strict": true // Use strict mode for palette generation (preserves custom surface/outline values)
    },
    {
      "id": "pywalfox",
      "name": "Pywalfox",
      "category": "browser",
      "input": "pywalfox.json",
      "outputs": [
        {
          "path": "~/.cache/wal/colors.json"
        }
      ],
      "postProcess": mode => `${templateApplyScript} pywalfox ${mode}`
    } // CONSOLIDATED DISCORD CLIENTS
    ,
    {
      "id": "discord",
      "name": "Discord",
      "category": "misc",
      "input": ["discord-midnight.css", "discord-material.css"],
      "clients": [
        {
          "name": "vesktop",
          "path": "~/.config/vesktop"
        },
        {
          "name": "webcord",
          "path": "~/.config/webcord"
        },
        {
          "name": "armcord",
          "path": "~/.config/armcord"
        },
        {
          "name": "equibop",
          "path": "~/.config/equibop"
        },
        {
          "name": "equicord",
          "path": "~/.config/Equicord"
        },
        {
          "name": "lightcord",
          "path": "~/.config/lightcord"
        },
        {
          "name": "dorion",
          "path": "~/.config/dorion"
        },
        {
          "name": "vencord",
          "path": "~/.config/Vencord"
        },
        {
          "name": "vencord-flatpak",
          "path": "~/.var/app/com.discordapp.Discord/config/Vencord"
        },
        {
          "name": "betterdiscord",
          "path": "~/.config/BetterDiscord"
        }
      ]
    },
    {
      "id": "code",
      "name": "VSCode",
      "category": "editor",
      "input": "code.json",
      "clients": [
        {
          "name": "code",
          "path": "~/.vscode/extensions/noctalia.noctaliatheme-0.0.5/themes/NoctaliaTheme-color-theme.json"
        },
        {
          "name": "codium",
          "path": "~/.vscode-oss/extensions/noctalia.noctaliatheme-0.0.5-universal/themes/NoctaliaTheme-color-theme.json"
        }
      ]
    },
    {
      "id": "zed",
      "name": "Zed",
      "category": "editor",
      "input": "zed.json",
      "outputs": [
        {
          "path": "~/.config/zed/themes/noctalia.json"
        }
      ],
      "dualMode": true // Template contains both dark and light theme patterns
    },
    {
      "id": "helix",
      "name": "Helix",
      "category": "editor",
      "input": "helix.toml",
      "outputs": [
        {
          "path": "~/.config/helix/themes/noctalia.toml"
        }
      ]
    },
    {
      "id": "spicetify",
      "name": "Spicetify",
      "category": "audio",
      "input": "spicetify.ini",
      "outputs": [
        {
          "path": "~/.config/spicetify/Themes/Comfy/color.ini"
        }
      ],
      "postProcess": () => `spicetify -q apply --no-restart`
    },
    {
      "id": "telegram",
      "name": "Telegram",
      "category": "misc",
      "input": "telegram.tdesktop-theme",
      "outputs": [
        {
          "path": "~/.config/telegram-desktop/themes/noctalia.tdesktop-theme"
        }
      ]
    },
    {
      "id": "zenBrowser",
      "name": "Zen Browser",
      "category": "browser",
      "input": "zen-browser/zen-userChrome.css",
      "outputs": [
        {
          "path": "~/.cache/noctalia/zen-browser/zen-userChrome.css"
        },
        {
          "path": "~/.cache/noctalia/zen-browser/zen-userContent.css",
          "input": "zen-browser/zen-userContent.css"
        }
      ],
      "postProcess": ()
                     => "sh -c 'CSS_CHROME=\"$HOME/.cache/noctalia/zen-browser/zen-userChrome.css\"; CSS_CONTENT=\"$HOME/.cache/noctalia/zen-browser/zen-userContent.css\"; LINE_CHROME=\"@import \\\"$CSS_CHROME\\\";\"; LINE_CONTENT=\"@import \\\"$CSS_CONTENT\\\";\"; find \"$HOME/.config/zen\" \"$HOME/.zen\" -mindepth 2 -maxdepth 2 -type d -name chrome -print0 2>/dev/null | while IFS= read -r -d \"\" dir; do USER_CHROME=\"$dir/userChrome.css\"; USER_CONTENT=\"$dir/userContent.css\"; mkdir -p \"$dir\"; touch \"$USER_CHROME\" \"$USER_CONTENT\"; sed -i \"/zen-browser\\/zen-userChrome\\.css/d\" \"$USER_CHROME\"; sed -i \"/zen-browser\\/zen-userContent\\.css/d\" \"$USER_CONTENT\"; if ! grep -Fq \"$LINE_CHROME\" \"$USER_CHROME\"; then printf \"%s\\n\" \"$LINE_CHROME\" >> \"$USER_CHROME\"; fi; if ! grep -Fq \"$LINE_CONTENT\" \"$USER_CONTENT\"; then printf \"%s\\n\" \"$LINE_CONTENT\" >> \"$USER_CONTENT\"; fi; done'"
    },
    {
      "id": "cava",
      "name": "Cava",
      "category": "audio",
      "input": "cava.ini",
      "outputs": [
        {
          "path": "~/.config/cava/themes/noctalia"
        }
      ],
      "postProcess": () => `${templateApplyScript} cava`
    },
    {
      "id": "yazi",
      "name": "Yazi",
      "category": "misc",
      "input": "yazi.toml",
      "outputs": [
        {
          "path": "~/.config/yazi/flavors/noctalia.yazi/flavor.toml"
        }
      ],
      "postProcess": () => `${templateApplyScript} yazi`
    },
    {
      "id": "emacs",
      "name": "Emacs",
      "category": "editor",
      "input": "emacs.el",
      "postProcess": () => `emacsclient -e "(load-theme 'noctalia t)"`
    },
    {
      "id": "labwc",
      "name": "Labwc",
      "category": "compositor",
      "input": "labwc.conf",
      "outputs": [
        {
          "path": "~/.config/labwc/themerc-override"
        }
      ],
      "postProcess": () => `${templateApplyScript} labwc`
    },
    {
      "id": "niri",
      "name": "Niri",
      "category": "compositor",
      "input": "niri.kdl",
      "outputs": [
        {
          "path": "~/.config/niri/noctalia.kdl"
        }
      ],
      "postProcess": () => `${templateApplyScript} niri`
    },
    {
      "id": "sway",
      "name": "Sway",
      "category": "compositor",
      "input": "sway",
      "outputs": [
        {
          "path": "~/.config/sway/noctalia"
        }
      ],
      "postProcess": () => `${templateApplyScript} sway`
    },
    {
      "id": "scroll",
      "name": "Scroll",
      "category": "compositor",
      "input": "scroll",
      "outputs": [
        {
          "path": "~/.config/scroll/noctalia"
        }
      ],
      "postProcess": () => `${templateApplyScript} scroll`
    },
    {
      "id": "hyprland",
      "name": "Hyprland",
      "category": "compositor",
      "input": "hyprland.lua",
      "outputs": [
        {
          "path": "~/.config/hypr/noctalia/noctalia-colors.lua"
        }
      ],
      "postProcess": () => `${templateApplyScript} hyprland`
    },
    {
      "id": "hyprtoolkit",
      "name": "Hyprtoolkit",
      "category": "system",
      "input": "hyprtoolkit.conf",
      "outputs": [
        {
          "path": "~/.config/hypr/hyprtoolkit.conf"
        }
      ]
    },
    {
      "id": "mango",
      "name": "Mango",
      "category": "compositor",
      "input": "mango.conf",
      "outputs": [
        {
          "path": "~/.config/mango/noctalia.conf"
        }
      ],
      "postProcess": () => `${templateApplyScript} mango`
    },
    {
      "id": "btop",
      "name": "btop",
      "category": "misc",
      "input": "btop.theme",
      "outputs": [
        {
          "path": "~/.config/btop/themes/noctalia.theme"
        }
      ],
      "postProcess": () => `${templateApplyScript} btop`
    },
    {
      "id": "zathura",
      "name": "Zathura",
      "category": "misc",
      "input": "zathurarc",
      "outputs": [
        {
          "path": "~/.config/zathura/noctaliarc"
        }
      ],
      "postProcess": () => `${templateApplyScript} zathura`
    },
    {
      "id": "steam",
      "name": "Steam",
      "category": "misc",
      "input": "steam.css",
      "outputs": [
        {
          "path": "~/.steam/steam/steamui/skins/Material-Theme/css/main/colors/matugen.css"
        }
      ]
    }
  ]

  // Extract Discord clients for ProgramCheckerService compatibility
  readonly property var discordClients: {
    var clients = [];
    var discordApp = applications.find(app => app.id === "discord");
    if (discordApp && discordApp.clients) {
      discordApp.clients.forEach(client => {
                                   clients.push({
                                                  "name": client.name,
                                                  "configPath": client.path,
                                                  "themePath": `${client.path}/themes/noctalia.theme.css`
                                                });
                                 });
    }
    return clients;
  }

  // Get resolved theme paths for a code client (returns array of all matching paths)
  function resolvedCodeClientPaths(clientName) {
    if (clientName === "code")
      return resolvedCodePaths;
    if (clientName === "codium")
      return resolvedCodiumPaths;
    return [];
  }

  // Extract Code clients for ProgramCheckerService compatibility
  readonly property var codeClients: {
    var clients = [];
    var codeApp = applications.find(app => app.id === "code");
    if (codeApp && codeApp.clients) {
      codeApp.clients.forEach(client => {
                                // Extract base config directory from theme path
                                var themePath = client.path;
                                var baseConfigDir = "";
                                if (client.name === "code") {
                                  // For VSCode: ~/.vscode/extensions/... -> ~/.vscode
                                  baseConfigDir = "~/.vscode";
                                } else if (client.name === "codium") {
                                  // For VSCodium: ~/.vscode-oss/extensions/... -> ~/.vscode-oss
                                  baseConfigDir = "~/.vscode-oss";
                                }
                                clients.push({
                                               "name": client.name,
                                               "configPath": baseConfigDir,
                                               "themePath": "" // resolved dynamically via resolvedCodeClientPaths()
                                             });
                              });
    }
    return clients;
  }

  // Resolve VSCode extension paths dynamically
  Process {
    id: codeResolverProcess
    command: ["python3", vscodeHelperScript, "~/.vscode/extensions"]
    running: true
    property var paths: []
    stdout: SplitParser {
      onRead: data => {
        var line = data.trim();
        if (line)
        codeResolverProcess.paths.push(line);
      }
    }
    onExited: {
      root.resolvedCodePaths = paths;
    }
  }

  Process {
    id: codiumResolverProcess
    command: ["python3", vscodeHelperScript, "~/.vscode-oss/extensions"]
    running: true
    property var paths: []
    stdout: SplitParser {
      onRead: data => {
        var line = data.trim();
        if (line)
        codiumResolverProcess.paths.push(line);
      }
    }
    onExited: {
      root.resolvedCodiumPaths = paths;
    }
  }
  // Build user templates TOML content
  function buildUserTemplatesToml() {
    var lines = [];
    lines.push("[config]");
    lines.push("");
    lines.push("[templates]");
    lines.push("");
    lines.push("# User-defined templates");
    lines.push("# Add your custom templates below");
    lines.push("# Example:");
    lines.push("# [templates.myapp]");
    lines.push("# input_path = \"~/.config/noctalia/templates/myapp.css\"");
    lines.push("# output_path = \"~/.config/myapp/theme.css\"");
    lines.push("# post_hook = \"myapp --reload-theme\"");
    lines.push("");
    lines.push("# Remove this section and add your own templates");
    lines.push("#[templates.placeholder]");
    lines.push("#input_path = \"" + Quickshell.shellDir + "/Assets/Templates/noctalia.json\"");
    lines.push("#output_path = \"" + Settings.cacheDir + "placeholder.json\"");
    lines.push("");

    return lines.join("\n") + "\n";
  }

  // Write user templates TOML file (moved from Theming)
  function writeUserTemplatesToml() {
    var userConfigPath = Settings.configDir + "user-templates.toml";

    // Check if file already exists
    fileCheckProcess.command = ["test", "-s", userConfigPath];
    fileCheckProcess.running = true;
  }

  function doWriteUserTemplatesToml() {
    var userConfigPath = Settings.configDir + "user-templates.toml";
    var configContent = buildUserTemplatesToml();
    var userConfigPathEsc = userConfigPath.replace(/'/g, "'\\''");
    var configDirEsc = Settings.configDir.replace(/'/g, "'\\''");

    // Combine mkdir and write in a single script to avoid race condition
    var script = `mkdir -p '${configDirEsc}' && cat > '${userConfigPathEsc}' << 'EOF'\n`;
    script += configContent;
    script += "EOF\n";
    fileWriteProcess.command = ["sh", "-c", script];
    fileWriteProcess.running = true;
  }

  // Extract Emacs clients for ProgramCheckerService compatibility
  readonly property var emacsClients: [
    {
      "name": "doom",
      "path": "~/.config/doom"
    },
    {
      "name": "modern",
      "path": "~/.config/emacs"
    },
    {
      "name": "traditional",
      "path": "~/.emacs.d"
    }
  ]

  // Process for checking if user templates file exists and is non-empty
  Process {
    id: fileCheckProcess
    running: false

    onExited: function (exitCode) {
      if (exitCode === 0) {
        // File exists and is non-empty, skip creation
        Logger.d("TemplateRegistry", "User templates config already exists, skipping creation");
      } else {
        // File doesn't exist or is empty, create it
        doWriteUserTemplatesToml();
      }
    }
  }

  // Process for writing user templates file with error reporting
  Process {
    id: fileWriteProcess
    running: false

    onExited: function (exitCode) {
      if (exitCode === 0) {
        Logger.d("TemplateRegistry", "User templates config written to:", Settings.configDir + "user-templates.toml");
      } else {
        Logger.e("TemplateRegistry", "Failed to write user templates config (exit code:", exitCode + ")");
      }
    }
  }
}
NP_TMPLREG_EOF
    $SUDO_CMD install -m 644 "$tmp" "$noc_base/Services/Theming/TemplateRegistry.qml"
    rm -f "$tmp"
    print_success "Updated: Services/Theming/TemplateRegistry.qml"

    # ── Scripts/bash/template-apply.sh (require→dofile fixed) ────────────────
    tmp=$(mktemp)
    cat > "$tmp" << 'NP_TMPLSH_EOF'
#!/usr/bin/env -S bash

# Ensure at least one argument is provided.
if [ "$#" -lt 1 ]; then
    # Print usage information to standard error.
    echo "Error: No application specified." >&2
    echo "Usage: $0 {kitty|ghostty|foot|alacritty|wezterm|starship|fuzzel|walker|pywalfox|cava|yazi|labwc|niri|hyprland|sway|scroll|mango|btop|zathura} [dark|light]" >&2
    exit 1
fi

APP_NAME="$1"
MODE="${2:-}" # Optional second argument for dark/light mode

# --- Apply theme based on the application name ---
case "$APP_NAME" in
kitty)
    # Many configs use: include ./current-theme.conf
    # Point it at the generated theme whenever the hook runs (including when noctalia.conf
    # was unchanged on disk and the hook was forced from the template processor).
    NOCTALIA_THEME="$HOME/.config/kitty/themes/noctalia.conf"
    CURRENT_THEME="$HOME/.config/kitty/current-theme.conf"
    if [ -f "$NOCTALIA_THEME" ]; then
        mkdir -p "$HOME/.config/kitty"
        ln -sf "themes/noctalia.conf" "$CURRENT_THEME"
    fi
    KITTY_CONF="$HOME/.config/kitty/kitty.conf"
    if [ -w "$KITTY_CONF" ]; then
        kitty +kitten themes --reload-in=all noctalia
    else
        kitty +runpy "from kitty.utils import *; reload_conf_in_all_kitties()"
    fi
    # Trigger kitty's live config reload after the template has been regenerated.
    pkill -USR1 kitty >/dev/null 2>&1 || true
    ;;

ghostty)
    # Check both potential config files
    CONFIG_FILES=("$HOME/.config/ghostty/config" "$HOME/.config/ghostty/config.ghostty")
    FOUND_CONFIG=false

    for CONFIG_FILE in "${CONFIG_FILES[@]}"; do
        if [ -f "$CONFIG_FILE" ]; then
            FOUND_CONFIG=true
            # Check if theme is already set to noctalia (flexible spacing)
            if grep -qE "^theme\s*=\s*noctalia$" "$CONFIG_FILE"; then
                : # Already correct
            elif grep -qE "^theme\s*=" "$CONFIG_FILE"; then
                # Replace existing theme line in-place
                sed -i -E 's/^theme\s*=.*/theme = noctalia/' "$CONFIG_FILE"
            else
                # Add the new theme line to the end of the file
                echo "theme = noctalia" >>"$CONFIG_FILE"
            fi
        fi
    done

    if [ "$FOUND_CONFIG" = true ]; then
        # Only signal if ghostty is running
        pgrep -f ghostty >/dev/null && pkill -SIGUSR2 ghostty || true
    else
        echo "Error: No ghostty config file found at ${CONFIG_FILES[*]}" >&2
        exit 1
    fi
    ;;

foot)
    CONFIG_FILE="$HOME/.config/foot/foot.ini"

    # Check if the config file exists, create it if it doesn't.
    if [ ! -f "$CONFIG_FILE" ]; then
        # Create the config directory if it doesn't exist
        mkdir -p "$(dirname "$CONFIG_FILE")"
        # Create the config file with the noctalia theme
        cat >"$CONFIG_FILE" <<'EOF'
[main]
include=~/.config/foot/themes/noctalia
EOF
    else
        # Check if theme is already set to noctalia
        if ! grep -q "include.*noctalia" "$CONFIG_FILE"; then
            # Remove any existing theme include line to prevent duplicates.
            sed -i '/include=.*themes/d' "$CONFIG_FILE"
            if grep -q '^\[main\]' "$CONFIG_FILE"; then
                # Insert the include line after the existing [main] section header
                sed -i '/^\[main\]/a include=~/.config/foot/themes/noctalia' "$CONFIG_FILE"
            else
                # If [main] doesn't exist, create it at the beginning with the include
                sed -i '1i [main]\ninclude=~/.config/foot/themes/noctalia\n' "$CONFIG_FILE"
            fi
        fi
    fi
    ;;

alacritty)
    CONFIG_FILE="$HOME/.config/alacritty/alacritty.toml"
    NEW_THEME_PATH='~/.config/alacritty/themes/noctalia.toml'

    # Check if the config file exists, create it if it doesn't.
    if [ ! -f "$CONFIG_FILE" ]; then
        # Create the config directory if it doesn't exist
        mkdir -p "$(dirname "$CONFIG_FILE")"
        # Create the config file with the noctalia theme import
        cat >"$CONFIG_FILE" <<'EOF'
[general]
import = [
    "~/.config/alacritty/themes/noctalia.toml"
]
EOF
    else
        # Check if noctalia theme is already imported (any path variant)
        if grep -q 'noctalia\.toml' "$CONFIG_FILE"; then
            # Update old relative path to new absolute path if needed
            if grep -q '"themes/noctalia.toml"' "$CONFIG_FILE"; then
                sed -i 's|"themes/noctalia.toml"|"'"$NEW_THEME_PATH"'"|g' "$CONFIG_FILE"
            fi
            # Already has noctalia import with correct path, nothing to do
        else
            # No noctalia import found, add it
            if grep -q '^\[general\]' "$CONFIG_FILE"; then
                # Check if import line already exists under [general]
                if grep -q '^import\s*=' "$CONFIG_FILE"; then
                    # Append to existing import array (before the closing bracket)
                    sed -i '/^import\s*=\s*\[/,/\]/{/\]/s|]|    "'"$NEW_THEME_PATH"'",\n]|}' "$CONFIG_FILE"
                else
                    # Add import line after [general] section header
                    sed -i '/^\[general\]/a import = ["'"$NEW_THEME_PATH"'"]' "$CONFIG_FILE"
                fi
            else
                # Create [general] section with import at the beginning of the file
                sed -i '1i [general]\nimport = ["'"$NEW_THEME_PATH"'"]\n' "$CONFIG_FILE"
            fi
        fi
    fi
    ;;

wezterm)
    CONFIG_FILE="$HOME/.config/wezterm/wezterm.lua"
    WEZTERM_SCHEME_LINE='config.color_scheme = "Noctalia"'

    # Check if the config file exists.
    if [ -f "$CONFIG_FILE" ]; then

        # Check if theme is already set to Noctalia (matches 'Noctalia' or "Noctalia")
        if ! grep -q "^\s*config\.color_scheme\s*=\s*['\"]Noctalia['\"]\s*" "$CONFIG_FILE"; then
            # Not set to Noctalia. Check if *any* color_scheme line exists.
            if grep -q '^\s*config\.color_scheme\s*=' "$CONFIG_FILE"; then
                # It exists, so we replace it with our desired line.
                sed -i "s|^\(\s*config\.color_scheme\s*=\s*\).*$|\1\"Noctalia\"|" "$CONFIG_FILE"
            else
                # It doesn't exist, so we add it before the 'return config' line.
                if grep -q '^\s*return\s*config' "$CONFIG_FILE"; then
                    # 'return config' exists. Insert the line before it.
                    sed -i '/^\s*return\s*config/i\'"$WEZTERM_SCHEME_LINE" "$CONFIG_FILE"
                else
                    # This is a problem. We can't find the insertion point.
                    echo "Warning: 'config.color_scheme' not set and 'return config' line not found." >&2
                    echo "         Make sure $CONFIG_FILE is correct: https://wezterm.org/config/files.html" >&2
                fi
            fi
        fi
        # touching the config file fools wezterm into reloading it
        touch "$CONFIG_FILE"
    else
        echo "Error: wezterm.lua not found at $CONFIG_FILE" >&2
        echo "Instructions to create it: https://wezterm.org/config/files.html" >&2
        exit 1
    fi
    ;;

fuzzel)
    CONFIG_FILE="$HOME/.config/fuzzel/fuzzel.ini"

    # Check if the config file exists, create it if it doesn't.
    if [ ! -f "$CONFIG_FILE" ]; then
        # Create the config directory if it doesn't exist
        mkdir -p "$(dirname "$CONFIG_FILE")"
        # Create the config file with the noctalia theme
        cat >"$CONFIG_FILE" <<'EOF'
include=~/.config/fuzzel/themes/noctalia
EOF
    else
        # Check if theme is already set to noctalia
        if grep -q "^include=~/.config/fuzzel/themes/noctalia$" "$CONFIG_FILE"; then
            : # Already correct
        elif grep -q "^include=.*themes" "$CONFIG_FILE"; then
            # Replace existing theme include line in-place
            sed -i 's|^include=.*themes.*|include=~/.config/fuzzel/themes/noctalia|' "$CONFIG_FILE"
        else
            # Add the new theme include line
            echo "include=~/.config/fuzzel/themes/noctalia" >>"$CONFIG_FILE"
        fi
    fi
    ;;

walker)
    CONFIG_FILE="$HOME/.config/walker/config.toml"

    # Check if the config file exists.
    if [ -f "$CONFIG_FILE" ]; then
        # Check if theme is already set to noctalia (flexible spacing)
        if grep -qE '^theme\s*=\s*"noctalia"' "$CONFIG_FILE"; then
            : # Already correct
        elif grep -qE '^theme\s*=' "$CONFIG_FILE"; then
            # Replace existing theme line in-place
            sed -i -E 's/^theme\s*=.*/theme = "noctalia"/' "$CONFIG_FILE"
        else
            echo 'theme = "noctalia"' >>"$CONFIG_FILE"
        fi
    else
        echo "Error: walker config file not found at $CONFIG_FILE" >&2
        exit 1
    fi
    ;;

vicinae)
    # Apply the theme
    vicinae theme set noctalia
    ;;

pywalfox)
    # Set dark/light mode first if MODE is specified
    if [ -n "$MODE" ]; then
        if [ "$MODE" = "dark" ] || [ "$MODE" = "light" ]; then
            pywalfox "$MODE"
        else
            echo "Warning: Invalid mode '$MODE'. Expected 'dark' or 'light'. Skipping mode switch." >&2
        fi
    fi
    # Update the theme
    pywalfox update
    ;;

cava)
    CONFIG_FILE="$HOME/.config/cava/config"
    THEME_MODIFIED=false

    # Check if the config file exists.
    if [ -f "$CONFIG_FILE" ]; then
        # Check if [color] section exists
        if grep -q '^\[color\]' "$CONFIG_FILE"; then
            # Check if theme is already set to noctalia under [color] (flexible spacing)
            if sed -n '/^\[color\]/,/^\[/p' "$CONFIG_FILE" | grep -qE '^theme\s*=\s*"noctalia"'; then
                : # Already correct
            elif sed -n '/^\[color\]/,/^\[/p' "$CONFIG_FILE" | grep -qE '^theme\s*='; then
                # Replace existing theme line under [color]
                sed -i -E '/^\[color\]/,/^\[/{s/^theme\s*=.*/theme = "noctalia"/}' "$CONFIG_FILE"
                THEME_MODIFIED=true
            else
                # Add theme line after [color]
                sed -i '/^\[color\]/a theme = "noctalia"' "$CONFIG_FILE"
                THEME_MODIFIED=true
            fi
        else
            # Add [color] section with theme at the end of file
            echo "" >>"$CONFIG_FILE"
            echo "[color]" >>"$CONFIG_FILE"
            echo 'theme = "noctalia"' >>"$CONFIG_FILE"
            THEME_MODIFIED=true
        fi

        # Reload cava if it's running, but only if it's not using stdin config
        if pgrep -f cava >/dev/null; then
            # Check if Cava is running with -p /dev/stdin (standalone cava)
            if ! pgrep -af cava | grep -q -- "-p.*stdin"; then
                pkill -USR1 cava
            fi
        fi
    else
        echo "Error: cava config file not found at $CONFIG_FILE" >&2
        exit 1
    fi
    ;;

yazi)
    CONFIG_FILE="$HOME/.config/yazi/theme.toml"

    # Create config directory if it doesn't exist
    mkdir -p "$(dirname "$CONFIG_FILE")"

    if [ ! -f "$CONFIG_FILE" ]; then
        cat >"$CONFIG_FILE" <<'EOF'
[flavor]
dark  = "noctalia"
light = "noctalia"
EOF
    else
        # Check if [flavor] section exists
        if grep -q '^\[flavor\]' "$CONFIG_FILE"; then
            # Update or add dark/light lines under [flavor]
            if sed -n '/^\[flavor\]/,/^\[/p' "$CONFIG_FILE" | grep -q '^dark\s*='; then
                sed -i '/^\[flavor\]/,/^\[/{s/^dark\s*=.*/dark  = "noctalia"/}' "$CONFIG_FILE"
            else
                sed -i '/^\[flavor\]/a dark  = "noctalia"' "$CONFIG_FILE"
            fi
            if sed -n '/^\[flavor\]/,/^\[/p' "$CONFIG_FILE" | grep -q '^light\s*='; then
                sed -i '/^\[flavor\]/,/^\[/{s/^light\s*=.*/light = "noctalia"/}' "$CONFIG_FILE"
            else
                sed -i '/^\[flavor\]/,/^dark/a light = "noctalia"' "$CONFIG_FILE"
            fi
        else
            # Add [flavor] section at the end
            echo "" >>"$CONFIG_FILE"
            echo "[flavor]" >>"$CONFIG_FILE"
            echo 'dark  = "noctalia"' >>"$CONFIG_FILE"
            echo 'light = "noctalia"' >>"$CONFIG_FILE"
        fi
    fi
    ;;

labwc)
    # Update the theme
    labwc -r
    ;;

niri)
    CONFIG_FILE="$HOME/.config/niri/config.kdl"
    INCLUDE_LINE='include "./noctalia.kdl"'

    # Check if the config file exists.
    if [ ! -f "$CONFIG_FILE" ]; then
        mkdir -p "$(dirname "$CONFIG_FILE")"
        echo -e "\n$INCLUDE_LINE\n" >"$CONFIG_FILE"
    else
        # Check if noctalia include already exists (flexible: quotes, ./ prefix)
        if grep -qE 'include\s+["'"'"'](\./)?noctalia\.kdl["'"'"']' "$CONFIG_FILE"; then
            : # Already included
        else
            # Add the include line to the end of the file
            echo -e "\n$INCLUDE_LINE\n" >>"$CONFIG_FILE"
        fi
    fi
    ;;

hyprland)
    echo "🎨 Applying 'noctalia' theme to Hyprland..."
    CONFIG_DIR="$HOME/.config/hypr"
    CONFIG_FILE="$CONFIG_DIR/hyprland.lua"
    THEME_FILE="$CONFIG_DIR/noctalia/noctalia-colors.lua"

    INCLUDE_LINE="dofile('$THEME_FILE')"

    # Check if the config file exists.
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Config file not found, creating $CONFIG_FILE..."
        mkdir -p "$(dirname "$CONFIG_FILE")"
        echo -e "\n$INCLUDE_LINE\n" >"$CONFIG_FILE"
        echo "Created new config file with noctalia theme."
    else
        # Check if noctalia theme source already exists (flexible matching)
        if grep -qE '(dofile|require)\s*\(.*noctalia' "$CONFIG_FILE"; then
            echo "Theme already included, skipping modification."
        else
            # Only convert symlink when we actually need to write (NixOS read-only symlinks)
            if [ -L "$CONFIG_FILE" ] && [ ! -w "$CONFIG_FILE" ]; then
                echo "Detected read-only symlink, converting to local file..."
                cp --remove-destination "$(readlink -f "$CONFIG_FILE")" "$CONFIG_FILE"
                chmod +w "$CONFIG_FILE"
            fi
            # Add the include line to the end of the file
            echo -e "\n$INCLUDE_LINE\n" >>"$CONFIG_FILE"
            echo "✅ Added noctalia theme include to config."
        fi
    fi

    # Reload hyprland
    hyprctl reload
    ;;

sway)
    echo "🎨 Applying 'noctalia' theme to Sway..."
    CONFIG_DIR="$HOME/.config/sway"
    CONFIG_FILE="$CONFIG_DIR/config"
    INCLUDE_LINE='include ~/.config/sway/noctalia'

    # Check if the config file exists.
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Config file not found, creating $CONFIG_FILE..."
        mkdir -p "$(dirname "$CONFIG_FILE")"
        echo -e "\n$INCLUDE_LINE\n" >"$CONFIG_FILE"
        echo "Created new config file with noctalia theme."
    else
        # Check if noctalia include already exists (flexible matching)
        if grep -qE 'include\s+.*noctalia' "$CONFIG_FILE"; then
            echo "Theme already included, skipping modification."
        else
            # Only convert symlink when we actually need to write (NixOS read-only symlinks)
            if [ -L "$CONFIG_FILE" ] && [ ! -w "$CONFIG_FILE" ]; then
                echo "Detected read-only symlink, converting to local file..."
                cp --remove-destination "$(readlink -f "$CONFIG_FILE")" "$CONFIG_FILE"
                chmod +w "$CONFIG_FILE"
            fi
            # Add the include line to the end of the file
            echo -e "\n$INCLUDE_LINE\n" >>"$CONFIG_FILE"
            echo "✅ Added noctalia theme include to config."
        fi
    fi

    # Reload sway
    swaymsg reload
    ;;

scroll)
    echo "Applying 'noctalia' theme to Scroll..."
    CONFIG_DIR="$HOME/.config/scroll"
    CONFIG_FILE="$CONFIG_DIR/config"
    INCLUDE_LINE='include ~/.config/scroll/noctalia'

    # Check if the config file exists.
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Config file not found, creating $CONFIG_FILE..."
        mkdir -p "$(dirname "$CONFIG_FILE")"
        echo -e "\n$INCLUDE_LINE\n" >"$CONFIG_FILE"
        echo "Created new config file with noctalia theme."
    else
        # Check if noctalia include already exists (flexible matching)
        if grep -qE 'include\s+.*noctalia' "$CONFIG_FILE"; then
            echo "Theme already included, skipping modification."
        else
            # Only convert symlink when we actually need to write
            if [ -L "$CONFIG_FILE" ] && [ ! -w "$CONFIG_FILE" ]; then
                echo "Detected read-only symlink, converting to local file..."
                cp --remove-destination "$(readlink -f "$CONFIG_FILE")" "$CONFIG_FILE"
                chmod +w "$CONFIG_FILE"
            fi
            # Add the include line to the end of the file
            echo -e "\n$INCLUDE_LINE\n" >>"$CONFIG_FILE"
            echo "Added noctalia theme include to config."
        fi
    fi

    # Reload scroll
    scrollmsg reload
    ;;

mango)
    CONFIG_DIR="$HOME/.config/mango"
    MAIN_CONFIG="$CONFIG_DIR/config.conf"
    THEME_FILE="$CONFIG_DIR/noctalia.conf"
    BACKUP_FILE="$CONFIG_DIR/theme.conf.bak"
    # This sources the noctalia theme file
    SOURCE_LINE="source = $THEME_FILE"

    # Color variables that should be moved to theme file
    COLOR_VARS="shadowscolor|rootcolor|bordercolor|focuscolor|maximizescreencolor|urgentcolor|scratchpadcolor|globalcolor|overlaycolor"

    # Create config directory if it doesn't exist
    mkdir -p "$CONFIG_DIR"

    # Check if theme is already sourced in main config
    if [ -f "$MAIN_CONFIG" ] && grep -qF "$SOURCE_LINE" "$MAIN_CONFIG"; then
        : # Theme already set
    else
        # First-time setup: backup and remove legacy color definitions

        # Scan all .conf files in config directory for legacy color variables
        for conf_file in "$CONFIG_DIR"/*.conf; do
            # Skip if no .conf files exist or if it's the theme file itself
            [ -e "$conf_file" ] || continue
            [ "$conf_file" = "$THEME_FILE" ] && continue

            # Check if this file contains any color variable definitions
            if grep -qE "^($COLOR_VARS)\s*=" "$conf_file"; then
                # Extract and append color definitions to backup file
                grep -E "^($COLOR_VARS)\s*=" "$conf_file" >>"$BACKUP_FILE"

                # Remove color definitions from original file
                if [ -L "$conf_file" ] && [ ! -w "$conf_file" ]; then
                    # Read-only symlink (e.g. NixOS): convert to local file
                    cp --remove-destination "$(readlink -f "$conf_file")" "$conf_file"
                    chmod +w "$conf_file"
                    sed -i -E "/^($COLOR_VARS)\s*=/d" "$conf_file"
                else
                    # Edit the real file, preserving any writable symlink
                    sed -i -E "/^($COLOR_VARS)\s*=/d" "$(readlink -f "$conf_file")"
                fi
            fi
        done

        # Only convert symlink when we actually need to write
        if [ -L "$MAIN_CONFIG" ] && [ ! -w "$MAIN_CONFIG" ]; then
            echo "Detected read-only symlink, converting to local file..."
            cp --remove-destination "$(readlink -f "$MAIN_CONFIG")" "$MAIN_CONFIG"
            chmod +w "$MAIN_CONFIG"
        fi

        # Add source line to main config
        if [ -f "$MAIN_CONFIG" ]; then
            echo "" >>"$MAIN_CONFIG"
            echo "# This sources the noctalia theme" >>"$MAIN_CONFIG"
            echo -e "\n$SOURCE_LINE\n" >>"$MAIN_CONFIG"
        else
            echo "# This sources the noctalia theme" >"$MAIN_CONFIG"
            echo -e "\n$SOURCE_LINE\n" >>"$MAIN_CONFIG"
        fi
    fi

    # Trigger live reload
    if command -v mmsg >/dev/null 2>&1; then
        mmsg -s -d reload_config
    else
        echo "Warning: mmsg command not found, manual restart may be needed." >&2
    fi
    ;;

btop)
    CONFIG_FILE="$HOME/.config/btop/btop.conf"

    if [ -f "$CONFIG_FILE" ]; then
        # Check if theme is already set to noctalia (flexible spacing)
        if grep -qE '^color_theme\s*=\s*"noctalia"' "$CONFIG_FILE"; then
            : # Already correct
        elif grep -qE '^color_theme\s*=' "$CONFIG_FILE"; then
            # Replace existing color_theme line in-place
            sed -i -E 's/^color_theme\s*=.*/color_theme = "noctalia"/' "$CONFIG_FILE"
        else
            echo 'color_theme = "noctalia"' >>"$CONFIG_FILE"
        fi

        if pgrep -x btop >/dev/null; then
            pkill -SIGUSR2 -x btop
        fi
    else
        echo "Warning: btop config file not found at $CONFIG_FILE" >&2
    fi
    ;;

zathura)
    ZATHURA_INSTANCES=$(dbus-send --session \
        --dest=org.freedesktop.DBus \
        --type=method_call \
        --print-reply \
        /org/freedesktop/DBus \
        org.freedesktop.DBus.ListNames |
        grep -o 'org.pwmt.zathura.PID-[0-9]*')

    for id in $ZATHURA_INSTANCES; do
        dbus-send --session \
            --dest="$id" \
            --type=method_call \
            /org/pwmt/zathura \
            org.pwmt.zathura.ExecuteCommand \
            string:"source"
    done
    ;;

starship)
    PALETTE_FILE="$HOME/.cache/noctalia/starship-palette.toml"

    # Respect STARSHIP_CONFIG env var, then fall back to standard lookup order
    if [ -n "$STARSHIP_CONFIG" ]; then
        CONFIG_FILE="$STARSHIP_CONFIG"
    elif [ -f "$HOME/.config/starship.toml" ]; then
        CONFIG_FILE="$HOME/.config/starship.toml"
    elif [ -f "$HOME/.config/starship/starship.toml" ]; then
        CONFIG_FILE="$HOME/.config/starship/starship.toml"
    else
        CONFIG_FILE="$HOME/.config/starship.toml"
    fi

    if [ ! -f "$PALETTE_FILE" ]; then
        echo "Error: Starship palette file not found at $PALETTE_FILE" >&2
        return 1
    fi

    MARKER_BEGIN='# >>> NOCTALIA STARSHIP PALETTE >>>'
    MARKER_END='# <<< NOCTALIA STARSHIP PALETTE <<<'

    # Create config file from scratch if it doesn't exist yet
    if [ ! -f "$CONFIG_FILE" ]; then
        mkdir -p "$(dirname "$CONFIG_FILE")"
        {
            printf 'palette = "noctalia"\n\n'
            printf '%s\n' "$MARKER_BEGIN"
            cat "$PALETTE_FILE"
            printf '%s\n' "$MARKER_END"
        } >"$CONFIG_FILE"
        return 0
    fi

    # Follow symlinks so we edit the real file (safe for stow / dotfile managers)
    if [ -L "$CONFIG_FILE" ]; then
        CONFIG_FILE="$(readlink -f "$CONFIG_FILE")"
    fi

    # Set or insert top-level  palette = "noctalia"
    if grep -qE '^[[:space:]]*palette[[:space:]]*=' "$CONFIG_FILE"; then
        sed -i -E 's/^([[:space:]]*)palette([[:space:]]*)=.*/\1palette\2= "noctalia"/' "$CONFIG_FILE"
    elif grep -qE '^[[:space:]]*"\$schema"' "$CONFIG_FILE"; then
        sed -i '/^[[:space:]]*"\$schema"/a palette = "noctalia"' "$CONFIG_FILE"
    else
        sed -i '1i palette = "noctalia"' "$CONFIG_FILE"
    fi

    # Remove existing palette block using awk for literal string matching
    # (avoids sed misinterpreting >, #, or other chars in the markers as regex)
    if grep -qF "$MARKER_BEGIN" "$CONFIG_FILE"; then
        awk -v begin="$MARKER_BEGIN" -v end="$MARKER_END" '
                    $0 == begin { skip = 1; next }
                    $0 == end   { skip = 0; next }
                    !skip
                ' "$CONFIG_FILE" >"${CONFIG_FILE}.noctalia.tmp" &&
            mv "${CONFIG_FILE}.noctalia.tmp" "$CONFIG_FILE"
    fi

    # Append fresh palette block, ensuring a clean newline boundary
    {
        printf '\n%s\n' "$MARKER_BEGIN"
        cat "$PALETTE_FILE"
        # Guard: ensure palette file ends with newline before closing marker
        tail -c1 "$PALETTE_FILE" | grep -q $'\n' || printf '\n'
        printf '%s\n' "$MARKER_END"
    } >>"$CONFIG_FILE"
    ;;

*)
    # Handle unknown application names.
    echo "Error: Unknown application '$APP_NAME'." >&2
    exit 1
    ;;
esac
NP_TMPLSH_EOF
    $SUDO_CMD install -m 755 "$tmp" "$noc_base/Scripts/bash/template-apply.sh"
    rm -f "$tmp"
    print_success "Updated: Scripts/bash/template-apply.sh"

    # ── Assets/Templates/hyprland.lua ────────────────────────────────────────
    tmp=$(mktemp)
    cat > "$tmp" << 'NP_HYPRLUATMPL_EOF'
local primary        = "rgba({{colors.primary.default.hex_stripped}}ff)"
local surface        = "rgba({{colors.surface.default.hex_stripped}}ff)"
local secondary      = "rgba({{colors.secondary.default.hex_stripped}}ff)"
local error_col      = "rgba({{colors.error.default.hex_stripped}}ff)"
local tertiary       = "rgba({{colors.tertiary.default.hex_stripped}}ff)"
local surface_lowest = "rgba({{colors.surface_container_lowest.default.hex_stripped}}ff)"

hl.config({
    general = {
        col = {
            active_border   = primary,
            inactive_border = surface,
        },
    },
    group = {
        col = {
            border_active        = secondary,
            border_inactive      = surface,
            border_locked_active = error_col,
            border_locked_inactive = surface,
        },
        groupbar = {
            col = {
                active        = secondary,
                inactive      = surface,
                locked_active = error_col,
                locked_inactive = surface,
            },
        },
    },
})
NP_HYPRLUATMPL_EOF
    $SUDO_CMD mkdir -p "$noc_base/Assets/Templates"
    $SUDO_CMD install -m 644 "$tmp" "$noc_base/Assets/Templates/hyprland.lua"
    rm -f "$tmp"
    print_success "Written: Assets/Templates/hyprland.lua"

    # Remove obsolete .conf template
    local tmpl_conf="$noc_base/Assets/Templates/hyprland.conf"
    [[ -f "$tmpl_conf" ]] && $SUDO_CMD rm -f "$tmpl_conf" \
        && print_success "Removed obsolete hyprland.conf template"

    print_success "Noctalia Hyprland 0.55+ patch complete!"
    echo ""
}

# ── Main ──────────────────────────────────────────────────────────────────────

check_root
detect_actual_user
prompt_user
customization_prompts
install_packages
patch_noctalia_dispatcher
install_user_packages
ensure_hyprland_session
copy_skel_to_user
configure_hyprland
configure_portals
install_noctalia_polkit
setup_mimetype_fix
configure_themes
configure_sddm
finalize_system
show_completion
[[ -n "$SCRIPT_PATH" && -f "$SCRIPT_PATH" ]] && rm -f "$SCRIPT_PATH"
