#!/bin/bash

# XeroLinux Hyprland + Noctalia Installer v1.8

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

    echo -e "${CYAN}This script will install:${NC}"
    echo -e "  ${BLUE}•${NC} Hyprland compositor + lock/idle/picker"
    echo -e "  ${BLUE}•${NC} Noctalia shell (bar, launcher, notifications, wallpaper)"
    echo -e "  ${BLUE}•${NC} KDE apps: Dolphin, Konsole, Kate, Ark, Gwenview, Okular, KCalc"
    echo -e "  ${BLUE}•${NC} AUR helper: ${GREEN}${AUR_HELPER}${NC}"
    echo -e "  ${BLUE}•${NC} SDDM with XeroDark theme"
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

# ── Package selection (same categories as xero-kde.sh) ───────────────────────

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

# ── Package install helpers (identical to xero-kde.sh) ───────────────────────

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

# ── Step A: Install all packages ─────────────────────────────────────────────

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
        gnome-menus \
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
        duf gcc npm yad zip xdo gum inxi lzop nmon tree btop glfw htop lshw \
        cblas expac fuse3 lhasa meson unace unrar unzip p7zip iftop nvtop rhash sshfs \
        vnstat nodejs cronie hwinfo arandr assimp netpbm wmctrl grsync libmtp polkit \
        sysprof semver zenity gparted plocate jsoncpp fuseiso gettext node-gyp \
        intltool graphviz pkgstats pciutils inetutils downgrade s3fs-fuse playerctl \
        asciinema oniguruma ventoy-bin cifs-utils lsb-release python-dbus dconf-editor \
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
        hblock cryptsetup mkinitcpio-utils mkinitcpio-archiso \
        mkinitcpio-openswap mkinitcpio-nfs-utils boost kpmcore xdg-terminal-exec-git \
        eza ntp cava most dialog bind logrotate xdg-user-dirs \
        archiso rsync sdparm ntfs-3g tpm2-tss udftools syslinux fatresize \
        nfs-utils exfatprogs tpm2-tools fsarchiver squashfs-tools \
        gpart dmraid parted hdparm usbmuxd usbutils testdisk ddrescue timeshift \
        partclone partimage clonezilla open-iscsi memtest86+-efi usb_modeswitch \
        fd tmux brltty msedit nvme-cli terminus-font foot-terminfo kitty-terminfo \
        pv mc gpm nbd lvm2 bolt lynx tldr nmap irssi mdadm wvdial hyperv \
        mtools lsscsi ndisc6 screen tcpdump ethtool xdotool pcsclite \
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
        tela-circle-icon-theme-purple \
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

# ── Step B: Install user-selected packages ───────────────────────────────────

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

# ── Step C: Hyprland session file ────────────────────────────────────────────

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

    local user_home
    if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
        user_home="$(getent passwd "${SUDO_USER}" | cut -d: -f6)"
    else
        user_home="$HOME"
    fi

    local cfg_dir="${user_home}/.config/hypr"
    local cfg="${cfg_dir}/hyprland.conf"
    mkdir -p "${cfg_dir}"

    local example="/usr/share/hypr/hyprland.conf"
    if [[ ! -f "$example" ]]; then
        print_error "Default config not found at $example — ensure hyprland is installed."
        return 1
    fi

    if [[ ! -f "$cfg" ]]; then
        cp "$example" "$cfg"
        print_success "Copied default config from $example"
    else
        print_success "hyprland.conf exists — appending only."
    fi

    # Set terminal to konsole — replaces default kitty
    sed -i 's|^\$terminal\s*=.*|$terminal = konsole|' "$cfg" || true

    # Disable waybar if present — Noctalia replaces it
    sed -i 's|^\(exec-once\s*=\s*waybar\)|# \1  # disabled: Noctalia replaces waybar|' "$cfg" || true

    if ! grep -q "qs -c noctalia-shell" "$cfg"; then
        cat >> "$cfg" << 'HYPREOF'

# ────────────────────────────────────────────────────────────────────────────
# Noctalia — environment
# ────────────────────────────────────────────────────────────────────────────
env = QT_QPA_PLATFORMTHEME,qt6ct

# ────────────────────────────────────────────────────────────────────────────
# Noctalia shell — bar, notifications, wallpaper, lock screen, launcher, polkit
# ────────────────────────────────────────────────────────────────────────────
exec-once = qs -c noctalia-shell
exec-once = dex --autostart
exec-once = nm-applet --indicator
exec-once = blueman-applet
exec-once = wl-paste --type text  --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store
HYPREOF
        print_success "Appended Noctalia env + exec-once block to hyprland.conf"
    else
        print_success "Noctalia config already present — skipping."
    fi
    echo ""
}

# ── Step E: XDG portal config ─────────────────────────────────────────────────

configure_portals() {
    print_step "Configuring XDG portal preferences..."

    local user_home
    if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
        user_home="$(getent passwd "${SUDO_USER}" | cut -d: -f6)"
    else
        user_home="$HOME"
    fi

    local p_dir="${user_home}/.config/xdg-desktop-portal"
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

    local user_home
    if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
        user_home="$(getent passwd "${SUDO_USER}" | cut -d: -f6)"
    else
        user_home="$HOME"
    fi

    local plugins_dir="${user_home}/.config/noctalia/plugins"
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

    local plugins_json="${user_home}/.config/noctalia/plugins.json"
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

    local user_home
    if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
        user_home="$(getent passwd "${SUDO_USER}" | cut -d: -f6)"
    else
        user_home="$HOME"
    fi

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

    local svc_dir="${user_home}/.config/systemd/user"
    local noc_dir="${user_home}/.config/noctalia"
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

# ── Step H: SDDM + XeroDark ───────────────────────────────────────────────────

configure_sddm() {
    print_header
    print_step "Installing SDDM..."
    $SUDO_CMD pacman -S --needed --noconfirm sddm || { print_error "Failed to install SDDM!"; exit 1; }
    print_success "SDDM installed!"
    echo ""

    # XeroDark is a KDE-based SDDM theme — requires these QML modules even without
    # a full Plasma install. breeze provides org.kde.breeze.components,
    # plasma-workspace provides org.kde.plasma.private.keyboardIndicator.
    print_step "Installing SDDM theme dependencies (KDE QML modules)..."
    $SUDO_CMD pacman -S --needed --noconfirm breeze plasma-workspace \
        || print_warning "Some SDDM theme deps failed — theme may show errors"
    echo ""

    print_step "Installing XeroDark SDDM theme..."
    $SUDO_CMD git clone https://github.com/xerolinux/XeroDark.git /usr/share/sddm/themes/XeroDark \
        || print_warning "Failed to clone XeroDark theme"
    print_success "XeroDark theme installed!"
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
Current=XeroDark

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

# ── Step I: Qt / GTK / Icon theming ──────────────────────────────────────────

configure_themes() {
    [[ -z "${ACTUAL_HOME:-}" || -z "${ACTUAL_USER:-}" ]] && return 0

    print_step "Configuring Qt + GTK icon theme and fonts..."

    # qt5ct — style=Breeze so Noctalia's Qt color template can apply its palette
    mkdir -p "$ACTUAL_HOME/.config/qt5ct"
    cat > "$ACTUAL_HOME/.config/qt5ct/qt5ct.conf" << 'QT5CT'
[Appearance]
color_scheme_path=
custom_palette=false
icon_theme=Tela-circle-purple-dark
standard_dialogs=default
style=Breeze

[Fonts]
fixed="JetBrainsMono Nerd Font,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
general="JetBrainsMono Nerd Font,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
QT5CT

    # qt6ct
    mkdir -p "$ACTUAL_HOME/.config/qt6ct"
    cat > "$ACTUAL_HOME/.config/qt6ct/qt6ct.conf" << 'QT6CT'
[Appearance]
color_scheme_path=
custom_palette=false
icon_theme=Tela-circle-purple-dark
standard_dialogs=default
style=Breeze

[Fonts]
fixed="JetBrainsMono Nerd Font,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
general="JetBrainsMono Nerd Font,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
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
    if [[ ! -f "$ACTUAL_HOME/.config/noctalia/settings.json" ]]; then
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
        "pinnedApps": [],
        "position": "center",
        "screenshotAnnotationTool": "",
        "showCategories": true,
        "showIconBackground": false,
        "sortByMostUsed": true,
        "terminalCommand": "konsole -e",
        "viewMode": "list"
    },
    "audio": {
        "mprisBlacklist": [],
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
        "monitors": [],
        "mouseWheelAction": "none",
        "mouseWheelWrap": true,
        "outerCorners": true,
        "position": "top",
        "reverseScroll": false,
        "rightClickAction": "controlCenter",
        "rightClickCommand": "",
        "rightClickFollowMouse": true,
        "screenOverrides": [],
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
                    "blacklist": [],
                    "chevronColor": "none",
                    "colorizeIcons": false,
                    "drawerEnabled": true,
                    "hidePassive": false,
                    "id": "Tray",
                    "pinned": []
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
        "backlightDeviceMappings": [],
        "brightnessStep": 5,
        "enableDdcSupport": false,
        "enforceMinimum": true
    },
    "calendar": {
        "cards": [
            { "enabled": true, "id": "calendar-header-card" },
            { "enabled": true, "id": "calendar-month-card" },
            { "enabled": true, "id": "weather-card" }
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
            { "enabled": true,  "id": "profile-card" },
            { "enabled": true,  "id": "shortcuts-card" },
            { "enabled": true,  "id": "audio-card" },
            { "enabled": false, "id": "brightness-card" },
            { "enabled": true,  "id": "weather-card" },
            { "enabled": true,  "id": "media-sysmon-card" }
        ],
        "diskPath": "/",
        "position": "close_to_bar_button",
        "shortcuts": {
            "left": [
                { "id": "Network" },
                { "id": "Bluetooth" },
                { "id": "WallpaperSelector" },
                { "id": "NoctaliaPerformance" }
            ],
            "right": [
                { "id": "Notifications" },
                { "id": "PowerProfile" },
                { "id": "KeepAwake" },
                { "id": "NightLight" }
            ]
        }
    },
    "desktopWidgets": {
        "enabled": false,
        "gridSnap": false,
        "gridSnapScale": false,
        "monitorWidgets": [],
        "overviewEnabled": true
    },
    "dock": {
        "animationSpeed": 1,
        "backgroundOpacity": 1,
        "colorizeIcons": false,
        "deadOpacity": 0.6,
        "displayMode": "auto_hide",
        "dockType": "floating",
        "enabled": true,
        "floatingRatio": 1,
        "groupApps": false,
        "groupClickAction": "cycle",
        "groupContextMenuMode": "extended",
        "groupIndicatorStyle": "dots",
        "inactiveIndicators": false,
        "indicatorColor": "primary",
        "indicatorOpacity": 0.6,
        "indicatorThickness": 3,
        "launcherIcon": "",
        "launcherIconColor": "none",
        "launcherPosition": "end",
        "launcherUseDistroLogo": false,
        "monitors": [],
        "onlySameOutput": true,
        "pinnedApps": [],
        "pinnedStatic": false,
        "position": "bottom",
        "showDockIndicator": false,
        "showLauncherIcon": false,
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
            "keyDown":   ["Down"],
            "keyEnter":  ["Return", "Enter"],
            "keyEscape": ["Esc"],
            "keyLeft":   ["Left"],
            "keyRemove": ["Del"],
            "keyRight":  ["Right"],
            "keyUp":     ["Up"]
        },
        "language": "",
        "lockOnSuspend": true,
        "lockScreenAnimations": false,
        "lockScreenBlur": 0,
        "lockScreenCountdownDuration": 10000,
        "lockScreenMonitors": [],
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
        "disableWallpaper": true
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
        "monitors": [],
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
        "enabledTypes": [0, 1, 2],
        "location": "top_right",
        "monitors": [],
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
            { "action": "lock",         "enabled": true, "keybind": "1" },
            { "action": "suspend",      "enabled": true, "keybind": "2" },
            { "action": "hibernate",    "enabled": true, "keybind": "3" },
            { "action": "reboot",       "enabled": true, "keybind": "4" },
            { "action": "logout",       "enabled": true, "keybind": "5" },
            { "action": "shutdown",     "enabled": true, "keybind": "6" },
            { "action": "rebootToUefi", "enabled": true, "keybind": "7" }
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
            { "enabled": true, "id": "gtk" },
            { "enabled": true, "id": "hyprland" },
            { "enabled": true, "id": "hyprtoolkit" },
            { "enabled": true, "id": "alacritty" },
            { "enabled": true, "id": "cava" },
            { "enabled": true, "id": "discord" },
            { "enabled": true, "id": "kitty" },
            { "enabled": true, "id": "telegram" },
            { "enabled": true, "id": "code" },
            { "enabled": true, "id": "yazi" },
            { "enabled": true, "id": "zenBrowser" },
            { "enabled": true, "id": "qt" },
            { "enabled": true, "id": "kcolorscheme" }
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
        "favorites": [],
        "fillColor": "#000000",
        "fillMode": "crop",
        "hideWallpaperFilenames": false,
        "linkLightAndDarkWallpapers": true,
        "monitorDirectories": [],
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
        "transitionType": ["fade", "disc", "stripes", "wipe", "pixelate", "honeycomb"],
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
        # Replace /home/xero paths with the actual user's home directory
        sed -i "s|/home/xero|${ACTUAL_HOME}|g" "$ACTUAL_HOME/.config/noctalia/settings.json"
    fi

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
}

# ── Step J: Copy skel + distro identity ───────────────────────────────────────

copy_skel_to_user() {
    print_header
    print_step "Applying XeroLinux configurations... 📁"
    echo ""

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
        print_warning "Could not determine target user, skipping config copy"
        return 1
    fi

    ACTUAL_HOME="$(getent passwd "$ACTUAL_USER" | cut -d: -f6)"
    if [[ -z "${ACTUAL_HOME:-}" || ! -d "$ACTUAL_HOME" ]]; then
        print_warning "User home directory not found for $ACTUAL_USER, skipping"
        return 1
    fi

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
KONSOLE
    mkdir -p "$ACTUAL_HOME/.config"
    cat > "$ACTUAL_HOME/.config/konsolerc" << 'KONSOLERC'
[Desktop Entry]
DefaultProfile=XeroLinux.profile

[KonsoleWindow]
ShowMenuBarByDefault=false

[MainWindow]
ToolBarsMovable=Disabled

[MainWindow][Toolbar mainToolBar]
visible=false

[MainWindow][Toolbar sessionToolBar]
visible=false

[TabBar]
TabBarVisibility=ShowTabBarWhenNeeded
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

    # Create standard XDG user directories (Downloads, Documents, Pictures, etc.)
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
        local THEME_DEST="/usr/share/grub/themes/XeroLayan"

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

    # Distro identity files
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

# ── Step J: Finalize ──────────────────────────────────────────────────────────

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

# ── Main ──────────────────────────────────────────────────────────────────────

check_root
prompt_user
customization_prompts
install_packages
install_user_packages
ensure_hyprland_session
configure_hyprland
configure_portals
install_noctalia_polkit
setup_mimetype_fix
copy_skel_to_user
configure_themes
configure_sddm
finalize_system
show_completion
