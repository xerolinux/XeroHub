#!/bin/bash
#
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║                    ✨ XeroHyprNoc Installer v1.0 ✨                           ║
# ║                                                                               ║
# ║        Arch-based Linux → Hyprland + Noctalia Shell post-install             ║
# ║                                                                               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
#
# Run as your regular user with sudo access.
# Author: XeroLinux Team
# License: GPL-3.0

set -Eeuo pipefail

VERSION="1.0"
SCRIPT_USER="${USER}"
SCRIPT_HOME="${HOME}"
# Accept AUR helper as $1 when called from xero-hyprnoc-install.sh (chroot context)
AUR_CMD=""
AUR_HELPER="${1:-}"
SUDO_CMD=""

# ── Colors ────────────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# ── Print helpers ─────────────────────────────────────────────────────────────

print_header() {
    clear
    echo -e "${PURPLE}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                                                    ║${NC}"
    echo -e "${PURPLE}║${CYAN}      ✨ XeroHyprNoc Installer v${VERSION} ✨           ${PURPLE}║${NC}"
    echo -e "${PURPLE}║                                                    ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step()    { echo -e "${BLUE}➜${NC} ${CYAN}$1${NC}"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error()   { echo -e "${RED}✗${NC} $1"; sleep 1; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; sleep 1; }

on_err() {
    local exit_code=$? line_no=${1:-?} cmd=${2:-?}
    echo -e "${RED}ERROR (exit=${exit_code}) at line ${line_no}${NC}"
    echo -e "${RED}${cmd}${NC}"
    exit "${exit_code}"
}
trap 'on_err "$LINENO" "$BASH_COMMAND"' ERR

# ── Root check ────────────────────────────────────────────────────────────────

detect_chroot() {
    [ "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/.)" ] 2>/dev/null \
        || [ -f /etc/arch-chroot ] \
        || ([[ "${EUID:-0}" -eq 0 ]] && [[ -z "${SUDO_USER:-}" ]])
}

check_root() {
    if [[ "${EUID:-0}" -eq 0 ]] && ! detect_chroot; then
        echo -e "${RED}✗ Do not run as root outside a chroot!${NC}"
        exit 1
    fi
    if [[ "${EUID:-0}" -eq 0 ]]; then
        SUDO_CMD=""
        print_step "Running as root (chroot environment)"
    else
        SUDO_CMD="sudo"
    fi
}

# ── Prompt ────────────────────────────────────────────────────────────────────

prompt_user() {
    print_header
    echo -e "${CYAN}This script will install:${NC}"
    echo -e "  ${BLUE}•${NC} Hyprland — dynamic tiling Wayland compositor"
    echo -e "  ${BLUE}•${NC} Noctalia Shell — bar, notifications, wallpaper, lock, launcher, polkit"
    echo -e "  ${BLUE}•${NC} Hyprlock + Hypridle — screen locker and idle daemon"
    echo -e "  ${BLUE}•${NC} Full Wayland + XDG portal stack"
    echo -e "  ${BLUE}•${NC} PipeWire audio stack"
    echo -e "  ${BLUE}•${NC} SDDM display manager with XeroDark theme"
    echo -e "  ${BLUE}•${NC} matugen + adw-gtk3 for Material You theming"
    echo -e "  ${BLUE}•${NC} Your selected optional packages"
    echo ""
    echo -e "${YELLOW}⚠  This will modify your system!${NC}"
    echo ""
    read -p "$(echo -e "${GREEN}Proceed?${NC} [${GREEN}y${NC}/${RED}N${NC}]: ")" -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Installation cancelled."
        exit 0
    fi
}

# ── Preflight ─────────────────────────────────────────────────────────────────

preflight() {
    print_header
    print_step "Running preflight checks..."
    echo ""

    if ! ping -c1 -W3 8.8.8.8 &>/dev/null; then
        print_error "No internet connection detected."
        exit 1
    fi
    print_success "Internet: OK"

    local free_gb
    free_gb=$(df -BG / | awk 'NR==2{gsub("G",""); print $4}')
    if (( free_gb < 10 )); then
        print_error "Less than 10 GB free on / (${free_gb} GB available)."
        exit 1
    fi
    print_success "Disk: ${free_gb} GB free on /"

    local os_id os_like
    os_id=$(grep -oP '(?<=^ID=)[^\s"]+' /etc/os-release 2>/dev/null || true)
    os_like=$(grep -oP '(?<=^ID_LIKE=)[^\n"]+' /etc/os-release 2>/dev/null || true)
    if [[ "${os_id}" != "arch" && "${os_like}" != *arch* ]]; then
        print_error "Requires an Arch-based distro (Arch, CachyOS, Garuda, Manjaro, EndeavourOS, etc.)."
        exit 1
    fi
    if ! command -v pacman &>/dev/null; then
        print_error "pacman not found."
        exit 1
    fi
    print_success "Distro: ${os_id} (Arch-based)"
    print_success "User: ${SCRIPT_USER}, Home: ${SCRIPT_HOME}"
    echo ""
}

# ── AUR helper ────────────────────────────────────────────────────────────────

ensure_aur_helper() {
    print_step "Checking for AUR helper..."

    # When called from the main installer, $AUR_HELPER is pre-set (paru or yay).
    # Install it via pacman if it's in Chaotic-AUR/xerolinux repo, otherwise build from AUR.
    if [[ -n "${AUR_HELPER}" ]]; then
        if command -v "${AUR_HELPER}" &>/dev/null; then
            AUR_CMD="${AUR_HELPER}"
            print_success "Found: ${AUR_HELPER}"
            echo ""
            return
        fi
        print_step "Installing ${AUR_HELPER} (from repo or AUR)..."
        if $SUDO_CMD pacman -S --needed --noconfirm "${AUR_HELPER}" 2>/dev/null; then
            AUR_CMD="${AUR_HELPER}"
            print_success "${AUR_HELPER} installed."
            echo ""
            return
        fi
        # Fall through to build from AUR below
    fi

    if command -v yay &>/dev/null; then
        AUR_CMD="yay"; print_success "Found: yay"; echo ""; return
    fi
    if command -v paru &>/dev/null; then
        AUR_CMD="paru"; print_success "Found: paru"; echo ""; return
    fi

    local target="${AUR_HELPER:-yay}"
    print_step "Building ${target} from AUR..."
    $SUDO_CMD pacman -S --needed --noconfirm base-devel git
    local tmp
    tmp=$(mktemp -d)
    git clone "https://aur.archlinux.org/${target}.git" "${tmp}/${target}"
    (cd "${tmp}/${target}" && makepkg -si --noconfirm)
    rm -rf "${tmp}"
    AUR_CMD="${target}"
    print_success "${target} installed."
    echo ""
}

# ── Chaotic-AUR (optional) ────────────────────────────────────────────────────

setup_chaotic_aur() {
    # Auto-skip if already configured (e.g. called from xero-hyprnoc-install.sh)
    if grep -q "\[chaotic-aur\]" /etc/pacman.conf 2>/dev/null; then
        print_success "Chaotic-AUR already configured — skipping."
        echo ""
        return
    fi

    print_header
    echo -e "${CYAN}Chaotic-AUR provides pre-built AUR binaries.${NC}"
    echo -e "${CYAN}Faster installs for noctalia-shell, matugen, and optional apps.${NC}"
    echo ""
    read -p "$(echo -e "${GREEN}Add Chaotic-AUR?${NC} [${GREEN}y${NC}/${RED}N${NC}]: ")" -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Skipping Chaotic-AUR."
        echo ""
        return
    fi

    print_step "Adding Chaotic-AUR keyring..."
    $SUDO_CMD pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    $SUDO_CMD pacman-key --lsign-key 3056513887B78AEB
    $SUDO_CMD pacman -U --noconfirm \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

    printf '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n' \
        | $SUDO_CMD tee -a /etc/pacman.conf > /dev/null

    $SUDO_CMD pacman -Syy --noconfirm
    print_success "Chaotic-AUR added and synced."
    echo ""
}

# ── Package install helpers ───────────────────────────────────────────────────

# Bulk install via pacman; retry individually on failure. Never aborts.
install_group() {
    local group="$1"; shift
    local pkgs=("$@")
    print_step "[${group}] Installing ${#pkgs[@]} packages..."
    if $SUDO_CMD pacman -S --needed --noconfirm "${pkgs[@]}" 2>/dev/null; then
        print_success "[${group}] Done!"
        echo ""
        return 0
    fi
    print_warning "[${group}] Bulk install failed — retrying individually..."
    local failed=() installed=0
    for pkg in "${pkgs[@]}"; do
        if $SUDO_CMD pacman -S --needed --noconfirm "${pkg}" 2>/dev/null; then
            (( installed++ )) || true
        else
            failed+=("${pkg}")
        fi
    done
    [[ ${#failed[@]} -gt 0 ]] && print_warning "[${group}] Skipped (${#failed[@]}): ${failed[*]}"
    print_success "[${group}] Done — ${installed} installed, ${#failed[@]} skipped."
    echo ""
    return 0
}

# Bulk install via AUR helper; retry individually on failure. Never aborts.
install_aur_group() {
    local group="$1"; shift
    local pkgs=("$@")
    [[ -z "${AUR_CMD}" ]] && { print_error "AUR helper not set."; exit 1; }
    print_step "[${group}] Installing ${#pkgs[@]} AUR packages..."
    if "${AUR_CMD}" -S --needed --noconfirm "${pkgs[@]}" 2>/dev/null; then
        print_success "[${group}] Done!"
        echo ""
        return 0
    fi
    print_warning "[${group}] Bulk failed — retrying individually..."
    local failed=() installed=0
    for pkg in "${pkgs[@]}"; do
        if "${AUR_CMD}" -S --needed --noconfirm "${pkg}" 2>/dev/null; then
            (( installed++ )) || true
        else
            failed+=("${pkg}")
        fi
    done
    [[ ${#failed[@]} -gt 0 ]] && print_warning "[${group}] Skipped (${#failed[@]}): ${failed[*]}"
    print_success "[${group}] Done — ${installed} installed, ${#failed[@]} skipped."
    echo ""
    return 0
}

# ── Core package installation ─────────────────────────────────────────────────

install_packages() {
    print_header
    print_step "Syncing and updating system..."
    $SUDO_CMD pacman -Syu --noconfirm || { print_error "System update failed!"; exit 1; }
    print_success "System updated!"
    echo ""

    # ── Hyprland compositor ───────────────────────────────────────────────────
    install_group "Hyprland" \
        hyprland hyprlock hypridle hyprpicker hyprcursor

    # ── Wayland stack ─────────────────────────────────────────────────────────
    install_group "Wayland Stack" \
        wayland wayland-protocols xwayland \
        qt5-wayland qt6-wayland \
        xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-hyprland \
        xdg-utils

    # ── Audio (PipeWire) ──────────────────────────────────────────────────────
    install_group "Audio" \
        pipewire pipewire-alsa pipewire-audio pipewire-pulse wireplumber

    # ── Noctalia runtime dependencies ─────────────────────────────────────────
    install_group "Noctalia Dependencies" \
        alacritty brightnessctl imagemagick python git cava \
        cliphist wl-clipboard grim slurp \
        gnome-keyring gnome-menus polkit-gnome \
        qt6ct qt5ct nwg-look xsettingsd \
        qt6-multimedia-ffmpeg papirus-icon-theme \
        network-manager-applet blueman

    # ── System utilities ──────────────────────────────────────────────────────
    install_group "System Utilities" \
        btop fastfetch bat eza fzf ripgrep \
        zip unzip p7zip unrar ark \
        gvfs gvfs-mtp gvfs-smb gvfs-afc udisks2 udiskie \
        ttf-jetbrains-mono-nerd ttf-hack-nerd noto-fonts \
        dconf-editor polkit-qt6 xdg-user-dirs

    # ── AUR: Noctalia shell + theming ─────────────────────────────────────────
    install_aur_group "Noctalia Shell" \
        noctalia-shell matugen

    install_aur_group "GTK Theme" \
        adw-gtk3 || print_warning "adw-gtk3 failed — GTK theming won't apply. Continuing."

    # ── Desktop/MIME databases ────────────────────────────────────────────────
    print_step "Updating desktop and MIME databases..."
    $SUDO_CMD update-desktop-database /usr/share/applications 2>/dev/null || true
    $SUDO_CMD update-mime-database /usr/share/mime 2>/dev/null || true
    $SUDO_CMD xdg-user-dirs-update 2>/dev/null || true
    print_success "Databases updated."
    echo ""
}

# ── Optional app selection ────────────────────────────────────────────────────

BROWSER="" SOCIAL="" DEV="" PASS="" IMAGING="" MUSIC="" OFFICE=""

customization_prompts() {
    clear
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}                OPTIONAL PACKAGES — Choose Your Apps${NC}"
    echo -e "${CYAN}     Enter numbers separated by spaces, or press Enter to skip all${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo ""

    echo -e "${CYAN}── WEB BROWSERS ──────────────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "  ${CYAN} 1)${NC} Firefox            ${CYAN} 2)${NC} Floorp             ${CYAN} 3)${NC} Brave"
    echo -e "  ${CYAN} 4)${NC} LibreWolf          ${CYAN} 5)${NC} Zen Browser        ${CYAN} 6)${NC} Vivaldi"
    echo -e "  ${CYAN} 7)${NC} Mullvad Browser    ${CYAN} 8)${NC} Ungoogled Chromium"
    echo ""

    echo -e "${GREEN}── SOCIAL & COMMUNICATION ──────────────────────────────────────────────${NC}"
    echo ""
    echo -e "  ${GREEN} 9)${NC} Discord           ${GREEN}10)${NC} Vesktop            ${GREEN}11)${NC} Telegram"
    echo -e "  ${GREEN}12)${NC} ZapZap            ${GREEN}13)${NC} Ferdium"
    echo ""

    echo -e "${PURPLE}── DEVELOPMENT TOOLS ───────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "  ${PURPLE}14)${NC} VSCodium          ${PURPLE}15)${NC} GitHub Desktop     ${PURPLE}16)${NC} Meld"
    echo -e "  ${PURPLE}17)${NC} Hugo"
    echo ""

    echo -e "${YELLOW}── PASSWORD MANAGERS ───────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "  ${YELLOW}18)${NC} KeePassXC         ${YELLOW}19)${NC} Bitwarden"
    echo ""

    echo -e "${BLUE}── CREATIVE & IMAGING ──────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "  ${BLUE}20)${NC} GIMP              ${BLUE}21)${NC} Krita              ${BLUE}22)${NC} Inkscape"
    echo ""

    echo -e "${RED}── MEDIA & AUDIO ───────────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "  ${RED}23)${NC} MPV               ${RED}24)${NC} Spotify            ${RED}25)${NC} EasyEffects"
    echo -e "  ${RED}26)${NC} Tenacity          ${RED}27)${NC} Kdenlive"
    echo ""

    echo -e "${CYAN}── OFFICE ──────────────────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "  ${CYAN}28)${NC} LibreOffice"
    echo ""

    read -p ">> Your choices: " user_input

    for choice in $user_input; do
        case $choice in
             1) BROWSER="$BROWSER firefox" ;;
             2) BROWSER="$BROWSER floorp" ;;
             3) BROWSER="$BROWSER brave-bin" ;;
             4) BROWSER="$BROWSER librewolf" ;;
             5) BROWSER="$BROWSER zen-browser-bin" ;;
             6) BROWSER="$BROWSER vivaldi-meta" ;;
             7) BROWSER="$BROWSER mullvad-browser-bin" ;;
             8) BROWSER="$BROWSER ungoogled-chromium-bin" ;;
             9) SOCIAL="$SOCIAL discord" ;;
            10) SOCIAL="$SOCIAL vesktop" ;;
            11) SOCIAL="$SOCIAL telegram-desktop" ;;
            12) SOCIAL="$SOCIAL zapzap" ;;
            13) SOCIAL="$SOCIAL ferdium-bin" ;;
            14) DEV="$DEV vscodium" ;;
            15) DEV="$DEV github-desktop" ;;
            16) DEV="$DEV meld" ;;
            17) DEV="$DEV hugo" ;;
            18) PASS="$PASS keepassxc" ;;
            19) PASS="$PASS bitwarden" ;;
            20) IMAGING="$IMAGING gimp" ;;
            21) IMAGING="$IMAGING krita" ;;
            22) IMAGING="$IMAGING inkscape" ;;
            23) MUSIC="$MUSIC mpv" ;;
            24) MUSIC="$MUSIC spotify" ;;
            25) MUSIC="$MUSIC easyeffects" ;;
            26) MUSIC="$MUSIC tenacity" ;;
            27) MUSIC="$MUSIC kdenlive" ;;
            28) OFFICE="$OFFICE libreoffice-fresh" ;;
        esac
    done

    BROWSER="$(echo $BROWSER | xargs)" SOCIAL="$(echo $SOCIAL | xargs)"
    DEV="$(echo $DEV | xargs)"         PASS="$(echo $PASS | xargs)"
    IMAGING="$(echo $IMAGING | xargs)" MUSIC="$(echo $MUSIC | xargs)"
    OFFICE="$(echo $OFFICE | xargs)"

    echo ""
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Selection Summary:${NC}"
    [[ -n "$BROWSER" ]] && echo -e "  Browsers:   ${CYAN}${BROWSER}${NC}"
    [[ -n "$SOCIAL" ]]  && echo -e "  Social:     ${CYAN}${SOCIAL}${NC}"
    [[ -n "$DEV" ]]     && echo -e "  Dev Tools:  ${CYAN}${DEV}${NC}"
    [[ -n "$PASS" ]]    && echo -e "  Passwords:  ${CYAN}${PASS}${NC}"
    [[ -n "$IMAGING" ]] && echo -e "  Creative:   ${CYAN}${IMAGING}${NC}"
    [[ -n "$MUSIC" ]]   && echo -e "  Media:      ${CYAN}${MUSIC}${NC}"
    [[ -n "$OFFICE" ]]  && echo -e "  Office:     ${CYAN}${OFFICE}${NC}"
    if [[ -z "$BROWSER$SOCIAL$DEV$PASS$IMAGING$MUSIC$OFFICE" ]]; then
        echo -e "  ${YELLOW}(none selected)${NC}"
    fi
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    read -p "Press Enter to begin installation..."
}

install_user_packages() {
    print_header
    print_step "Installing user-selected packages..."
    echo ""
    # Use AUR helper for all — handles both official and AUR packages
    [[ -n "$BROWSER" ]] && install_aur_group "Browsers"          $BROWSER
    [[ -n "$SOCIAL" ]]  && install_aur_group "Social Apps"       $SOCIAL
    [[ -n "$DEV" ]]     && install_aur_group "Dev Tools"         $DEV
    [[ -n "$PASS" ]]    && install_group     "Password Managers" $PASS
    [[ -n "$IMAGING" ]] && install_group     "Creative Apps"     $IMAGING
    [[ -n "$MUSIC" ]]   && install_aur_group "Media & Audio"     $MUSIC
    [[ -n "$OFFICE" ]]  && install_group     "Office"            $OFFICE
    print_success "User-selected packages installed!"
    echo ""
}

# ── Hyprland session file ─────────────────────────────────────────────────────

ensure_hyprland_session() {
    print_step "Checking Hyprland session file..."
    local session="/usr/share/wayland-sessions/hyprland.desktop"
    if [[ -f "${session}" ]]; then
        print_success "hyprland.desktop present."
        echo ""
        return
    fi
    print_warning "hyprland.desktop not found — writing manually..."
    $SUDO_CMD mkdir -p /usr/share/wayland-sessions
    $SUDO_CMD tee "${session}" > /dev/null << 'EOF'
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=Hyprland
Type=Application
DesktopNames=Hyprland
EOF
    print_success "Wrote ${session}"
    echo ""
}

# ── Hyprland config ───────────────────────────────────────────────────────────

configure_hyprland() {
    print_step "Configuring Hyprland..."
    local cfg_dir="${SCRIPT_HOME}/.config/hypr"
    local cfg="${cfg_dir}/hyprland.conf"
    mkdir -p "${cfg_dir}"

    if [[ ! -f "${cfg}" ]]; then
        local example="/usr/share/hyprland/hyprland.conf"
        if [[ -f "${example}" ]]; then
            cp "${example}" "${cfg}"
            print_success "Copied default config from ${example}"
        else
            touch "${cfg}"
            print_warning "No example config found — created empty hyprland.conf."
        fi
    else
        print_success "hyprland.conf exists — appending only."
    fi

    # Disable waybar if present — Noctalia replaces it
    sed -i 's|^\(exec-once\s*=\s*waybar\)|# \1  # disabled: Noctalia replaces waybar|' "${cfg}" || true

    if grep -q "# xerohyprnoc" "${cfg}"; then
        print_success "XeroHyprNoc block already present — skipping."
        echo ""
        return
    fi

    cat >> "${cfg}" << 'EOF'

# ─────────────────────────────────────────────────────────────────────────────
# XeroHyprNoc — appended by xero-hyprnoc.sh v1.0
# ─────────────────────────────────────────────────────────────────────────────

# Export current env to D-Bus and systemd user session.
# Required so portals, tray apps, and systemd-managed services inherit the
# correct Wayland/display environment that Hyprland sets up at launch.
exec-once = dbus-update-activation-environment --systemd --all

# GTK settings daemon — reads ~/.config/xsettingsd/xsettingsd.conf and serves
# theme, font, and icon settings to GTK2/GTK3 apps via the XSETTINGS protocol.
# Without this, nwg-look theme changes won't persist across reboots.
exec-once = xsettingsd

# Noctalia shell: bar, notifications, wallpaper, lock screen, launcher, polkit agent.
# Replaces waybar, mako/dunst, swaybg, wlsunset, and swaylock.
exec-once = qs -c noctalia-shell

# Clipboard history — pairs with cliphist for clipboard manager
exec-once = wl-paste --watch cliphist store

# ── Environment variables ─────────────────────────────────────────────────────
env = QT_QPA_PLATFORMTHEME,qt6ct
env = XCURSOR_SIZE,24
env = XCURSOR_THEME,Hyprland

# ── Monitor configuration ─────────────────────────────────────────────────────
# After first login run: hyprctl monitors
# Note your output name and preferred mode, then uncomment and edit below.
#
# monitor = DP-1, 1920x1080@60, 0x0, 1
# monitor = , preferred, auto, 1    # catch-all for any unspecified monitor

# # xerohyprnoc
EOF

    print_success "Hyprland config written."
    echo ""
}

# ── XDG portal config ─────────────────────────────────────────────────────────

configure_portals() {
    print_step "Writing XDG portal config..."
    local conf_dir="${SCRIPT_HOME}/.config/xdg-desktop-portal"
    local conf="${conf_dir}/hyprland-portals.conf"
    mkdir -p "${conf_dir}"

    if [[ -f "${conf}" ]]; then
        print_success "hyprland-portals.conf exists — skipping."
        echo ""
        return
    fi

    cat > "${conf}" << 'EOF'
[preferred]
default=hyprland;gtk;
org.freedesktop.impl.portal.Secret=gnome-keyring;
org.freedesktop.impl.portal.FileChooser=gtk;
org.freedesktop.impl.portal.Notification=gtk;
org.freedesktop.impl.portal.Access=gtk;
EOF

    print_success "Portal config written to ${conf}"
    echo ""
}

# ── System environment ────────────────────────────────────────────────────────

configure_system_env() {
    print_step "Writing system environment vars..."
    local env_file="/etc/environment"

    if ! grep -q "XDG_DATA_DIRS" "${env_file}" 2>/dev/null; then
        echo 'XDG_DATA_DIRS=/usr/local/share:/usr/share' | $SUDO_CMD tee -a "${env_file}" > /dev/null
        print_success "Added XDG_DATA_DIRS"
    else
        print_success "XDG_DATA_DIRS already set — skipping."
    fi

    if [[ ! -f /etc/xdg/menus/applications.menu && -f /etc/xdg/menus/gnome-applications.menu ]]; then
        $SUDO_CMD ln -s /etc/xdg/menus/gnome-applications.menu /etc/xdg/menus/applications.menu
        print_success "Linked gnome-applications.menu → applications.menu"
    fi

    echo ""
}

# ── Noctalia polkit agent ─────────────────────────────────────────────────────

install_noctalia_polkit() {
    print_step "Installing Noctalia polkit agent..."
    local plugins_dir="${SCRIPT_HOME}/.config/noctalia/plugins"
    local dest="${plugins_dir}/polkit-agent"

    if [[ -d "${dest}" ]]; then
        print_success "Noctalia polkit-agent already installed — skipping."
        echo ""
        return
    fi

    mkdir -p "${plugins_dir}"
    local tmp
    tmp=$(mktemp -d)

    if git clone --no-checkout --depth=1 --filter=blob:none \
        https://github.com/noctalia-dev/noctalia-plugins.git "${tmp}" 2>/dev/null; then
        git -C "${tmp}" sparse-checkout set polkit-agent
        git -C "${tmp}" checkout
        cp -r "${tmp}/polkit-agent" "${dest}"
        rm -rf "${tmp}"
        print_success "polkit-agent installed to ${dest}"
    else
        rm -rf "${tmp}"
        print_warning "Could not clone noctalia-plugins — install polkit-agent manually later."
    fi

    local plugins_json="${SCRIPT_HOME}/.config/noctalia/plugins.json"
    if [[ ! -f "${plugins_json}" ]]; then
        cat > "${plugins_json}" << 'EOF'
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
EOF
        print_success "plugins.json written with polkit-agent enabled."
    else
        print_success "plugins.json exists — skipping."
    fi
    echo ""
}

# ── SDDM display manager ──────────────────────────────────────────────────────

setup_sddm() {
    print_header
    print_step "Installing SDDM..."
    $SUDO_CMD pacman -S --needed --noconfirm sddm \
        || { print_error "SDDM install failed!"; exit 1; }
    print_success "SDDM installed."
    echo ""

    print_step "Installing XeroDark SDDM theme..."
    if [[ ! -d /usr/share/sddm/themes/XeroDark ]]; then
        $SUDO_CMD git clone --depth=1 https://github.com/xerolinux/XeroDark.git \
            /usr/share/sddm/themes/XeroDark \
            && print_success "XeroDark theme installed." \
            || print_warning "Failed to clone XeroDark — SDDM will use default theme."
    else
        print_success "XeroDark theme already present."
    fi
    echo ""

    print_step "Writing SDDM configuration..."
    $SUDO_CMD mkdir -p /etc/sddm.conf.d
    $SUDO_CMD tee /etc/sddm.conf > /dev/null << 'EOF'
[General]
InputMethod=
EOF
    $SUDO_CMD tee /etc/sddm.conf.d/xero_settings.conf > /dev/null << 'EOF'
[Autologin]
Relogin=false
Session=hyprland
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
    print_success "SDDM configured."
    echo ""

    print_step "Enabling sddm.service..."
    $SUDO_CMD systemctl enable sddm.service \
        && print_success "sddm.service enabled." \
        || { print_error "Failed to enable sddm.service!"; exit 1; }
    echo ""
}

# ── Completion ────────────────────────────────────────────────────────────────

show_completion() {
    print_header
    echo -e "${PURPLE}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${GREEN}     ✨ XeroHyprNoc — Install Complete! ✨         ${PURPLE}║${NC}"
    echo -e "${PURPLE}╠════════════════════════════════════════════════════╣${NC}"
    echo -e "${PURPLE}║${NC}  Hyprland + Noctalia Shell is ready.             ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}                                                  ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}  TO START:                                       ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}  Reboot → log in via SDDM → select Hyprland     ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}  from the session menu.                          ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}                                                  ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}  DISPLAY SETUP (after first login):              ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}  1. Run: ${YELLOW}hyprctl monitors${NC}                      ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}  2. Edit: ${YELLOW}~/.config/hypr/hyprland.conf${NC}         ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}  3. Uncomment and fill the monitor = line        ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}                                                  ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}  NOTE: If Noctalia doesn't appear on first boot, ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}  log out and back in once to fully initialize.   ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}                                                  ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════════╝${NC}"
    echo ""
    read -p "$(echo -e "${GREEN}Reboot now?${NC} [${GREEN}y${NC}/${RED}N${NC}]: ")" -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        $SUDO_CMD reboot
    else
        echo -e "  Reboot when ready: ${YELLOW}sudo reboot${NC}"
        echo ""
    fi
}

# ── Main ──────────────────────────────────────────────────────────────────────

main() {
    check_root
    prompt_user
    customization_prompts
    preflight
    ensure_aur_helper
    setup_chaotic_aur
    install_packages
    install_user_packages
    ensure_hyprland_session
    configure_hyprland
    configure_portals
    configure_system_env
    install_noctalia_polkit
    setup_sddm
    show_completion
}

main
