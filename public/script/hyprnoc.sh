#!/bin/bash
#
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║                       Extra HyprNoc — Hyprland + Noctalia                     ║
# ║                                                                               ║
# ║        Drop-in addon for an existing XeroLinux / KDE Plasma install.          ║
# ║        Skips base system, SDDM config, KDE apps already on XeroBuild.         ║
# ║                                                                               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -uo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# AUR helper assumed present on XeroLinux (paru ships by default).
AUR_HELPER="${1:-paru}"
AUR_CMD=""

# Run as regular user with sudo.
SCRIPT_USER="${SUDO_USER:-${USER}}"
SCRIPT_HOME="$(getent passwd "${SCRIPT_USER}" | cut -d: -f6)"
SUDO_CMD="sudo"

print_header() {
    clear
    echo -e "${PURPLE}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${CYAN}     ✨ Extra HyprNoc — Hyprland + Noctalia ✨    ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${YELLOW}       For existing XeroLinux / KDE installs      ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step()    { echo -e "${BLUE}➜${NC} ${CYAN}$1${NC}"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; sleep 1; }
print_error()   { echo -e "${RED}✗${NC} $1"; sleep 1; }

# ── Sanity ────────────────────────────────────────────────────────────────────

check_root() {
    if [[ ${EUID:-0} -eq 0 ]]; then
        print_error "Do not run as root. Run as your normal user (sudo will be invoked when needed)."
        exit 1
    fi
}

prompt_user() {
    print_header
    echo -e "${CYAN}This script installs:${NC}"
    echo -e "  ${BLUE}•${NC} Hyprland compositor (hyprland, hyprlock, hypridle, hyprpicker, hyprcursor)"
    echo -e "  ${BLUE}•${NC} Wayland bits not already on XeroLinux (wayland, qt5-wayland)"
    echo -e "  ${BLUE}•${NC} XDG portals (xdg-desktop-portal-hyprland + gtk)"
    echo -e "  ${BLUE}•${NC} Noctalia shell + dependencies (alacritty, qt5/6ct, nwg-look, etc.)"
    echo -e "  ${BLUE}•${NC} Noctalia polkit-agent plugin"
    echo -e "  ${BLUE}•${NC} Hyprland session file + Hyprland config + portal config"
    echo ""
    echo -e "${YELLOW}It does NOT touch SDDM, KDE apps, or anything already on XeroBuild.${NC}"
    echo ""
    read -p "$(echo -e ${GREEN}Proceed? ${NC}[${GREEN}y${NC}/${RED}N${NC}]: )" -n 1 -r
    echo ""
    [[ $REPLY =~ ^[Yy]$ ]] || { print_warning "Cancelled."; exit 0; }
}

preflight() {
    print_header
    print_step "Preflight checks..."
    if ! ping -c1 -W3 8.8.8.8 &>/dev/null; then
        print_error "No internet."
        exit 1
    fi
    print_success "Internet: OK"

    if ! command -v pacman &>/dev/null; then
        print_error "pacman not found — must be Arch-based."
        exit 1
    fi

    local os_id
    os_id=$(grep -oP '(?<=^ID=)[^\s"]+' /etc/os-release 2>/dev/null || true)
    print_success "Distro: ${os_id:-unknown}"
    print_success "User:   ${SCRIPT_USER}, Home: ${SCRIPT_HOME}"
    echo ""
}

ensure_aur_helper() {
    print_step "Checking AUR helper..."
    if command -v "${AUR_HELPER}" &>/dev/null; then
        AUR_CMD="${AUR_HELPER}"
        print_success "Found: ${AUR_HELPER}"
        echo ""
        return
    fi
    if command -v paru &>/dev/null; then
        AUR_CMD="paru"; print_success "Found: paru"; echo ""; return
    fi
    if command -v yay &>/dev/null; then
        AUR_CMD="yay"; print_success "Found: yay"; echo ""; return
    fi
    print_error "No AUR helper found (paru/yay). XeroLinux usually ships paru — install one and re-run."
    exit 1
}

# ── Package install helpers ───────────────────────────────────────────────────

install_group() {
    local group="$1"; shift
    local pkgs=("$@")
    print_step "[${group}] Installing ${#pkgs[@]} packages..."
    if $SUDO_CMD pacman -S --needed --noconfirm "${pkgs[@]}"; then
        print_success "[${group}] Done!"
        echo ""
        return 0
    fi
    print_warning "[${group}] Bulk install failed — retrying individually..."
    local failed=() installed=0
    for pkg in "${pkgs[@]}"; do
        if $SUDO_CMD pacman -S --needed --noconfirm "${pkg}"; then
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

install_aur_group() {
    local group="$1"; shift
    local pkgs=("$@")
    print_step "[${group}] Installing ${#pkgs[@]} AUR packages..."
    if "${AUR_CMD}" -S --needed --noconfirm "${pkgs[@]}"; then
        print_success "[${group}] Done!"
        echo ""
        return 0
    fi
    print_warning "[${group}] Bulk failed — retrying individually..."
    local failed=() installed=0
    for pkg in "${pkgs[@]}"; do
        if "${AUR_CMD}" -S --needed --noconfirm "${pkg}"; then
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

# ── Core install ──────────────────────────────────────────────────────────────

install_packages() {
    print_header

    install_group "Hyprland" \
        hyprland hyprlock hypridle hyprpicker hyprcursor

    install_group "Wayland Extras" \
        wayland qt5-wayland

    install_group "XDG Portals" \
        xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-hyprland

    install_group "Noctalia Dependencies" \
        alacritty imagemagick python \
        cliphist wl-clipboard grim slurp \
        gnome-menus \
        qt6ct qt5ct nwg-look \
        qt6-multimedia-ffmpeg papirus-icon-theme \
        network-manager-applet blueman

    install_aur_group "Noctalia Shell" \
        noctalia-shell matugen

    print_step "Updating desktop and MIME databases..."
    $SUDO_CMD update-desktop-database /usr/share/applications 2>/dev/null || true
    $SUDO_CMD update-mime-database /usr/share/mime 2>/dev/null || true
    $SUDO_CMD xdg-user-dirs-update 2>/dev/null || true
    print_success "Databases updated."
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

    local example="/usr/share/hypr/hyprland.conf"
    if [[ ! -f "${example}" ]]; then
        print_error "Default config not found at ${example} — ensure hyprland is installed."
        exit 1
    fi

    if [[ ! -f "${cfg}" ]]; then
        cp "${example}" "${cfg}"
        print_success "Copied default config from ${example}"
    else
        print_success "hyprland.conf exists — appending only."
    fi

    # Disable waybar if present — Noctalia replaces it
    sed -i 's|^\(exec-once\s*=\s*waybar\)|# \1  # disabled: Noctalia replaces waybar|' "${cfg}" || true

    if ! grep -q "qs -c noctalia-shell" "${cfg}"; then
        cat >> "${cfg}" << 'HYPREOF'

# ────────────────────────────────────────────────────────────────────────────
# Noctalia — environment
# ────────────────────────────────────────────────────────────────────────────
env = QT_QPA_PLATFORMTHEME,qt6ct

# ────────────────────────────────────────────────────────────────────────────
# Noctalia shell — bar, notifications, wallpaper, lock screen, launcher, polkit
# ────────────────────────────────────────────────────────────────────────────
exec-once = qs -c noctalia-shell
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

# ── XDG portal config ─────────────────────────────────────────────────────────

configure_portals() {
    print_step "Configuring XDG portal preferences..."
    local p_dir="${SCRIPT_HOME}/.config/xdg-desktop-portal"
    mkdir -p "${p_dir}"
    cat > "${p_dir}/hyprland-portals.conf" << 'PORTEOF'
[preferred]
default=hyprland;gtk;
org.freedesktop.impl.portal.Screenshot=hyprland
org.freedesktop.impl.portal.ScreenCast=hyprland
PORTEOF
    print_success "Wrote ${p_dir}/hyprland-portals.conf"
    echo ""
}

# ── Noctalia polkit agent plugin ──────────────────────────────────────────────

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
        https://github.com/noctalia-dev/noctalia-plugins.git "${tmp}"; then
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
        cat > "${plugins_json}" << 'PLJSON'
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

# ── MIME application menu fix ─────────────────────────────────────────────────

setup_mimetype_fix() {
    print_step "Applying MIME application menu fix..."

    # Symlink — sudo available here, do it now
    local src="/etc/xdg/menus/gnome-applications.menu"
    local dst="/etc/xdg/menus/applications.menu"
    if [[ -L "${dst}" ]] || [[ -f "${dst}" ]]; then
        print_success "applications.menu already exists — skipping symlink."
    elif [[ -f "${src}" ]]; then
        $SUDO_CMD ln -sf "${src}" "${dst}"
        print_success "Linked ${dst} → ${src}"
    else
        print_warning "${src} not found — gnome-menus may not be installed yet."
    fi

    # kbuildsycoca6 must run inside a user session — one-shot systemd user service
    local svc_dir="${SCRIPT_HOME}/.config/systemd/user"
    local noc_dir="${SCRIPT_HOME}/.config/noctalia"
    local flag="${noc_dir}/.sycoca-built"
    mkdir -p "${svc_dir}" "${noc_dir}"
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

    systemctl --user enable noctalia-sycoca.service 2>/dev/null || true
    print_success "Wrote + enabled noctalia-sycoca.service — kbuildsycoca6 fires at first Hyprland login."
    echo ""
}

# ── Completion ────────────────────────────────────────────────────────────────

show_completion() {
    print_header
    echo -e "${PURPLE}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${GREEN}     ✨  Extra HyprNoc — Install Complete!  ✨    ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  Hyprland + Noctalia is now installed."
    echo ""
    echo -e "  ${CYAN}TO USE:${NC}"
    echo -e "  Log out → at SDDM, pick ${YELLOW}Hyprland${NC} session → log in."
    echo ""
    echo -e "  ${CYAN}DISPLAYS:${NC}"
    echo -e "  Run ${YELLOW}hyprctl monitors${NC} after first login"
    echo -e "  and edit ${YELLOW}~/.config/hypr/hyprland.conf${NC}"
    echo ""
    echo -e "  KDE Plasma session is untouched."
    echo ""
}

# ── Main ──────────────────────────────────────────────────────────────────────

main() {
    check_root
    prompt_user
    preflight
    ensure_aur_helper
    install_packages
    setup_mimetype_fix
    ensure_hyprland_session
    configure_hyprland
    configure_portals
    install_noctalia_polkit
    show_completion
}

main
