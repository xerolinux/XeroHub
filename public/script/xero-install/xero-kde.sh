#!/bin/bash

# XeroLinux KDE Plasma Installer v2.0.0
#
# Fetched by xero-install.sh's prepare_desktop_installer and run via
# `arch-chroot ... su -l "$user" -c "bash '$script_path' ..."` — always a
# real file on disk, unlike xero-install.sh which may be piped into bash.

SCRIPT_PATH="$(readlink -f "$0" 2>/dev/null || echo "")"

PART_LABEL="Part 2 - XeroKDE Install"

# AUR helper passed as $1 from xero-install.sh; default to paru
AUR_HELPER="${1:-paru}"
# Filesystem type passed as $2 from xero-install.sh; empty when run standalone
FILESYSTEM="${2:-}"

# Extra-package selections from xero-install.sh's main menu travel here via
# a small state file rather than positional args (some are long
# space-separated package lists). Defaults below cover a missing/standalone run.
STATE_FILE="$HOME/.xero-desktop-state"
BROWSER=""
SOCIAL=""
DEV=""
PASS=""
IMAGING=""
MUSIC=""
VIDEO=""
WANTS_LIBREOFFICE="no"
LO_LOCALE=""
LO_HUNSPELL=""
if [[ -f "$STATE_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$STATE_FILE"
fi

# ── Colours ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'
# 256-color accents matching xero-install.sh's gum palette exactly (gum
# `--foreground N` and raw `\033[38;5;Nm` both index the same xterm-256
# table), so the splash/banner reads as the same brand across both scripts.
PINK_ACCENT='\033[38;5;198m'
CYAN_ACCENT='\033[38;5;45m'

# Plain tput/printf, not gum — gum isn't installed into the target system
# until later in this script's own package groups.
term_cols() {
    local cols
    cols=$(tput cols 2>/dev/null) || cols=80
    [[ "$cols" =~ ^[0-9]+$ ]] || cols=80
    echo "$cols"
}

term_lines() {
    local lines
    lines=$(tput lines 2>/dev/null) || lines=24
    [[ "$lines" =~ ^[0-9]+$ ]] || lines=24
    echo "$lines"
}

vpad_for() {
    local content_height="$1"
    local rows; rows=$(term_lines)
    local pad=$(( (rows - content_height) / 2 ))
    [[ $pad -lt 0 ]] && pad=0
    echo "$pad"
}

print_vpad() {
    local n="$1" i
    for (( i = 0; i < n; i++ )); do echo ""; done
}

center_pad() {
    local text="$1" width="${2:-$(term_cols)}"
    local len=${#text}
    local pad=$(( (width - len) / 2 ))
    [[ $pad -lt 0 ]] && pad=0
    printf '%*s%s' "$pad" '' "$text"
}

# Same safety net as xero-install.sh: always restore the cursor and kill
# run_step_visual's background redraw loop (a forked process) on exit.
DISPLAY_PID=""
trap 'kill "$DISPLAY_PID" 2>/dev/null || true; tput cnorm 2>/dev/null || true' EXIT

# Drains stray keystrokes left over from the xero-install.sh -> here
# transition (no confirm/read of our own to protect any more, but check_root
# and the step loop below still shouldn't inherit an impatient extra Enter).
drain_stray_keystrokes() {
    while read -r -t 0.05 -n 1000 _ < /dev/tty 2>/dev/null; do :; done
}

print_header() {
    clear
    local cols; cols=$(term_cols)
    local box_width=52
    local pad=$(( (cols - box_width) / 2 ))
    [[ $pad -lt 0 ]] && pad=0
    local indent; indent=$(printf '%*s' "$pad" '')
    # Small top margin so the header doesn't sit glued to row 0 — content
    # below it (per screen) varies in height, so full vertical centering
    # of the whole screen isn't possible from here alone.
    print_vpad "$(( $(term_lines) / 10 ))"
    echo -e "${indent}${PINK_ACCENT}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${indent}${PINK_ACCENT}║                                                ║${NC}"
    echo -e "${indent}${PINK_ACCENT}║${CYAN_ACCENT}     ✨ XeroLinux KDE Plasma Installer ✨       ${PINK_ACCENT}║${NC}"
    echo -e "${indent}${PINK_ACCENT}║                                                ║${NC}"
    echo -e "${indent}${PINK_ACCENT}╚════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step()    { echo -e "${BLUE}➜${NC} ${CYAN}$1${NC}"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error()   { echo -e "${RED}✗${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }

# ── Environment detection ─────────────────────────────────────────────────────

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
    else
        SUDO_CMD="sudo"
    fi
}

# This script must NOT run as root outside a chroot (AUR builds refuse to
# run as root; files need to land with the user's own ownership) —
# opposite check from xero-install.sh, which requires root.
check_root() {
    if [[ ${EUID:-0} -eq 0 ]] && ! detect_chroot; then
        print_error "Do not run this script as root outside a chroot!"
        exit 1
    fi
    setup_sudo
}

# ── Package install helpers ───────────────────────────────────────────────────

# Shared by install_group/install_group_required below. Bulk-installs a
# package group, retrying individually on failure so one bad package can't
# block the rest. `return`, not `exit`: this runs inside run_step_visual's
# redirected "$func" call, and `exit` would skip its failure-display branch.
_install_group_impl() {
    local group_name="$1" required="$2"; shift 2
    local pkgs=("$@")

    print_step "[$group_name] Installing ${#pkgs[@]} packages${required:+ (required)}..."

    if $SUDO_CMD pacman -S --needed --noconfirm "${pkgs[@]}" 2>/dev/null; then
        print_success "[$group_name] Done!"
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

    { [[ ${#failed[@]} -gt 0 ]] && print_warning "[$group_name] Skipped (${#failed[@]}): ${failed[*]}"; } || true

    if [[ -n "$required" && $installed -eq 0 ]]; then
        print_error "[$group_name] Critical: zero packages installed — aborting!"
        return 1
    fi

    print_success "[$group_name] Done — $installed installed, ${#failed[@]} skipped."
    return 0
}

install_group() {
    local group_name="$1"; shift
    _install_group_impl "$group_name" "" "$@"
}

install_group_required() {
    local group_name="$1"; shift
    _install_group_impl "$group_name" "required" "$@"
}

# ── Service helpers ───────────────────────────────────────────────────────────

# Enable a service only if its unit file is present
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

# Enable a service only if its package is installed
enable_if_installed() {
    local pkg="$1"
    local svc="${2:-$1}"
    if $SUDO_CMD pacman -Qq "$pkg" &>/dev/null; then
        enable_service_if_available "$svc"
    else
        print_warning "Package $pkg not installed — skipping $svc"
    fi
}

# ── Locale helpers (LibreOffice package resolution) ───────────────────────────
# LO_HUNSPELL only comes back empty from configure_extra_packages' CUSTOM
# locale path — every other choice there already carries its exact hunspell
# package name. Resolution happens here (not in xero-install.sh) because it
# needs THIS target's own pacman database, which doesn't exist yet on the
# live ISO.

normalize_locale() {
    local loc="$1"
    loc="${loc%%.*}"
    loc="${loc%%@*}"
    echo "$loc"
}

hunspell_from_locale() {
    local loc; loc="$(normalize_locale "$1")"
    local lang="${loc%%_*}" region=""
    [[ "$loc" == *"_"* ]] && region="${loc#*_}"
    lang="${lang,,}"; region="${region,,}"
    case "$lang" in
        en) [[ -n "$region" ]] && echo "hunspell-en_${region}" || echo "hunspell-en_us" ;;
        es) [[ -n "$region" ]] && echo "hunspell-es_${region}" || echo "hunspell-es_any" ;;
        zh|ja|ko) echo "" ;;
        pt) [[ "$region" == "br" ]] && echo "hunspell-pt_br" || echo "hunspell-pt_pt" ;;
        *) [[ -n "$region" ]] && echo "hunspell-${lang}_${region}" || echo "hunspell-$lang" ;;
    esac
}

lo_langpack_from_locale() {
    local loc; loc="$(normalize_locale "$1")"
    loc="${loc,,}"; loc="${loc/_/-}"
    local lang="${loc%%-*}" region=""
    [[ "$loc" == *"-"* ]] && region="${loc#*-}"
    local candidates=()
    [[ -n "$region" ]] && candidates+=("${lang}-${region}")
    candidates+=("${lang}")
    local c
    for c in "${candidates[@]}"; do
        if pacman -Si "libreoffice-fresh-$c" &>/dev/null; then
            echo "libreoffice-fresh-$c"
            return 0
        fi
    done
    echo ""
}

# ── Live progress display (pure bash/tput/printf — no gum) ────────────────────
# gum is a separate process per call with its own CLI-argument-parsing
# engine, which turned out to be a real liability in xero-install.sh's
# equivalent hot redraw loop — three distinct gum-internal panics were hit
# there. Plain shell builtins have none of that surface, and gum isn't
# installed into the target yet at the point this first runs anyway.

# Big block-letter "XEROLINUX" wordmark, 53 cols wide — same glyphs as
# xero-install.sh's copy, kept in sync manually since the two scripts share
# no library file. Skipped on a narrow terminal (see draw_progress_bar).
XEROLOGO=(
    "█   █ █████ ████   ███  █     █████ █   █ █   █ █   █"
    " █ █  █     █   █ █   █ █       █   ██  █ █   █  █ █ "
    "  █   ████  ████  █   █ █       █   █ █ █ █   █   █  "
    " █ █  █     █  █  █   █ █       █   █  ██ █   █  █ █ "
    "█   █ █████ █   █  ███  █████ █████ █   █  ███  █   █"
)

draw_progress_bar() {
    local pct="$1" step_num="$2" total="$3" title="$4"
    # $5 lets the caller pin the column width for the whole redraw loop
    # instead of re-querying term_cols() every 0.3s, which occasionally
    # flickered between values across frames and (since frames are never
    # cleared between redraws) left two widths' text visible at once.
    local cols="${5:-$(term_cols)}"
    local width=50
    [[ $width -gt $(( cols - 10 )) ]] && width=$(( cols - 10 ))
    [[ $width -lt 10 ]] && width=10
    local filled=$(( pct * width / 100 ))
    local empty=$(( width - filled ))
    local bar=""
    [[ $filled -gt 0 ]] && bar+=$(printf '█%.0s' $(seq 1 "$filled"))
    [[ $empty -gt 0 ]] && bar+=$(printf '░%.0s' $(seq 1 "$empty"))

    # Wordmark only fits a real terminal, not the narrowest ones this still
    # has to support — skipped below that width rather than wrapped/clipped.
    if [[ $cols -ge 58 ]]; then
        local logo_line
        for logo_line in "${XEROLOGO[@]}"; do
            printf '\033[38;5;198m\033[1m%s\033[0m\033[K\n' "$(center_pad "$logo_line" "$cols")"
        done
        printf '\033[K\n'
    fi

    # \033[K (erase to end of line) after each line: center_pad only adds
    # LEADING padding to center text, never trailing — without this, a
    # wider previous frame's tail past where this frame's shorter text
    # ends would never actually get overwritten.
    printf '\033[38;5;198m\033[1m%s\033[0m\033[K\n' "$(center_pad "${pct}%" "$cols")"
    printf '\033[K\n'
    printf '\033[38;5;45m%s\033[0m\033[K\n' "$(center_pad "$bar" "$cols")"
    printf '\033[K\n'
    printf '\033[38;5;45m\033[1m%s\033[0m\033[K\n' "$(center_pad "$PART_LABEL" "$cols")"
    printf '\033[38;5;212m\033[1m%s\033[0m\033[K\n' "$(center_pad "Step $step_num of $total: $title" "$cols")"
    printf '\033[K\n'
    printf '\033[38;5;245m%s\033[0m\033[K\n' "$(center_pad "(Be patient while system installs. If it looks stuck it's normal.)" "$cols")"
}

run_step_visual() {
    # Runs a function/command in the CURRENT shell (no subshell), so any
    # globals it sets persist. Shows a live percent bar + step title,
    # vertically centered on screen.
    local step_num="$1" total="$2" title="$3"
    shift 3
    local func="$1"; shift

    local logfile
    logfile=$(mktemp)

    # Percent range this step owns: from where the previous step left off up
    # to where the next step starts. Real progress *within* the range is
    # approximated from how much output the step has produced so far.
    local base_pct=$(( (step_num - 1) * 100 / total ))
    local next_pct=$(( step_num * 100 / total ))
    local range=$(( next_pct - base_pct ))
    [[ $range -lt 1 ]] && range=1

    # Content height must match what draw_progress_bar actually prints:
    # 8 lines (pct/blank/bar/blank/part-label/title/blank/subtext) plus 6
    # more (5-row logo + spacer) when the terminal is wide enough to show it.
    local cols; cols=$(term_cols)
    local content_height=8
    [[ $cols -ge 58 ]] && content_height=$(( content_height + 6 ))
    local top_row; top_row=$(vpad_for "$content_height")

    clear
    tput civis
    (
        while true; do
            tput cup "$top_row" 0
            local lines sub live_pct
            lines=$(wc -l < "$logfile" 2>/dev/null || echo 0)
            sub=$(( lines / 4 ))
            [[ $sub -gt $(( range - 1 )) ]] && sub=$(( range - 1 ))
            [[ $sub -lt 0 ]] && sub=0
            live_pct=$(( base_pct + sub ))
            draw_progress_bar "$live_pct" "$step_num" "$total" "$title" "$cols"
            sleep 0.3
        done
    ) &
    local display_pid=$!
    DISPLAY_PID="$display_pid"

    "$func" "$@" > "$logfile" 2>&1
    local status=$?

    # `wait` on a job we just killed reports its SIGTERM exit status (143) —
    # expected, not a real failure.
    kill "$display_pid" 2>/dev/null || true
    wait "$display_pid" 2>/dev/null || true
    DISPLAY_PID=""
    tput cnorm

    if [[ $status -ne 0 ]]; then
        clear
        print_vpad "$top_row"
        draw_progress_bar "$base_pct" "$step_num" "$total" "$title" "$cols"
        print_error "Step failed: $title"
        # No live output box any more (by design) — on an actual failure,
        # show the tail of what the step actually printed before it died,
        # otherwise a real error is completely invisible.
        if [[ -s "$logfile" ]]; then
            echo ""
            echo "Last output before failure:"
            tail -n 15 "$logfile"
        fi
        rm -f "$logfile"
        return $status
    fi
    rm -f "$logfile"
    return 0
}

# ── Step B: Install packages ──────────────────────────────────────────────────

install_packages() {
    print_step "Syncing and updating system..."
    $SUDO_CMD pacman -Syu --noconfirm || { print_error "System update failed!"; return 1; }
    print_success "System updated!"

    print_step "Installing AUR helper ($AUR_HELPER)..."
    $SUDO_CMD pacman -S --needed --noconfirm "$AUR_HELPER" \
        || { print_error "AUR helper ($AUR_HELPER) installation failed!"; return 1; }
    print_success "AUR helper ($AUR_HELPER) installed!"

    # ── KDE Plasma Core (required — fails the step if nothing installs) ───────
    install_group_required "KDE Plasma Core" \
        kf6 qt6 kde-system libplasma \
        kwin krdp milou breeze oxygen drkonqi kwrited \
        kgamma kscreen kmenuedit bluedevil kpipewire plasma-nm plasma-pa \
        plasma-sdk libkscreen breeze-gtk breeze-cursors breeze-icons powerdevil \
        kinfocenter flatpak-kcm kdecoration ksshaskpass kwallet-pam \
        libksysguard plasma-vault ksystemstats kde-cli-tools oxygen-sounds \
        kscreenlocker kglobalacceld systemsettings kde-gtk-config layer-shell-qt \
        plasma-desktop polkit-kde-agent plasma-workspace kdeplasma-addons \
        ocean-sound-theme qqc2-breeze-style kactivitymanagerd \
        plasma-integration plasma-thunderbolt plasma-systemmonitor \
        xdg-desktop-portal-kde plasma-browser-integration plasma-keyboard \
        || return 1

    # ── KDE Applications ──────────────────────────────────────────────────────
    install_group "KDE Applications" \
        krdc krfb smb4k alligator kdeconnect kio-admin kio-extras kio-gdrive \
        konversation kio-zeroconf kdenetwork-filesharing signon-kwallet-extension \
        okular kamera svgpart skanlite gwenview spectacle colord-kde kcolorchooser \
        kimagemapeditor kdegraphics-thumbnailers \
        ark kate kgpg kfind sweeper konsole kdialog yakuake skanpage filelight \
        kmousetool kcharselect markdownpart qalculate-qt keditbookmarks kdebugsettings \
        kwalletmanager dolphin-plugins \
        k3b kamoso audiotube plasmatube audiocd-kio

    # ── Wayland & Display ─────────────────────────────────────────────────────
    install_group "Wayland & Display" \
        waypipe egl-wayland qt6-wayland lib32-wayland wayland-protocols \
        kwayland-integration plasma-wayland-protocols ocrad

    # ── Power & GPU Utilities ─────────────────────────────────────────────────
    install_group "Power & GPU Utilities" \
        switcheroo-control power-profiles-daemon brightnessctl

    # ── System Utilities (split into two calls to reduce transaction size) ─────
    install_group "System Utilities A" \
        duf gcc npm yad zip xdo gum inxi lzop nmon tree vala btop glfw htop lshw \
        cblas expac fuse3 lhasa meson unace unrar unzip p7zip iftop nvtop rhash sshfs \
        vnstat nodejs cronie hwinfo arandr assimp netpbm wmctrl grsync libmtp polkit \
        sysprof semver zenity gparted plocate jsoncpp fuseiso gettext node-gyp \
        intltool graphviz pkgstats pciutils inetutils downgrade s3fs-fuse playerctl \
        asciinema oniguruma ventoy-bin cifs-utils lsb-release python-dbus dconf-editor \
        laptop-detect perl-xml-parser gnome-disk-utility appmenu-gtk-module \
        parallel xsettingsd polkit-qt6 systemdgenie \
        yt-dlp wavpack unarchiver rate-mirrors gnustep-base ocs-url xmlstarlet \
        libgsf tumbler freetype2 libopenraw poppler-qt6 poppler-glib ffmpegthumbnailer \
        gvfs mtpfs udiskie udisks2 libldm gvfs-afc gvfs-mtp gvfs-nfs gvfs-smb \
        gvfs-goa gvfs-wsdd gvfs-dnssd gvfs-gphoto2 gvfs-onedrive \
        flatpak topgrade appstream-qt pacman-contrib pacman-bintrans \
        ffmpeg ffmpegthumbs ffnvcodec-headers

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
        kwin-zones kde-wallpapers kwin-scripts-kzones tela-circle-icon-theme-purple \
        kvantum fastfetch adw-gtk-theme oh-my-posh-bin gnome-themes-extra \
        kwin-effect-rounded-corners-git

    # ── Language Servers ──────────────────────────────────────────────────────
    install_group "Language Servers" \
        bash-language-server typescript-language-server vscode-json-languageserver

    # ── XeroLinux Packages ────────────────────────────────────────────────────
    install_group "XeroLinux Packages" \
        xero-toolkit xpm-gui extra-scripts desktop-config

    # ── Btrfs GUI tools (only when installed on Btrfs) ────────────────────────
    if [[ "$FILESYSTEM" == "btrfs" ]]; then
        install_group "Btrfs Assistant" btrfs-assistant
    fi
}

# ── Step D: Install user-selected packages ────────────────────────────────────

install_user_packages() {
    local LIBREOFFICE=""
    if [[ "$WANTS_LIBREOFFICE" == "yes" ]]; then
        local lo_pkgs="hunspell libreoffice-fresh libreoffice-extension-texmaths libreoffice-extension-writer2latex"
        local hunspell_pkg="$LO_HUNSPELL"
        [[ -z "$hunspell_pkg" ]] && hunspell_pkg="$(hunspell_from_locale "$LO_LOCALE")"
        if [[ -n "$hunspell_pkg" ]]; then
            if pacman -Si "$hunspell_pkg" &>/dev/null; then
                lo_pkgs="$lo_pkgs $hunspell_pkg"
            else
                print_warning "Package not found in repos, skipping: $hunspell_pkg"
            fi
        fi
        local langpack; langpack="$(lo_langpack_from_locale "$LO_LOCALE")"
        [[ -n "$langpack" ]] && lo_pkgs="$lo_pkgs $langpack"
        LIBREOFFICE="$(echo $lo_pkgs | xargs)"
    fi

    # shellcheck disable=SC2086
    { [[ -n "$BROWSER" ]]     && install_group "Browsers"          $BROWSER; } || true
    { [[ -n "$SOCIAL" ]]      && install_group "Social Apps"       $SOCIAL; } || true
    { [[ -n "$LIBREOFFICE" ]] && install_group "LibreOffice"       $LIBREOFFICE; } || true
    { [[ -n "$DEV" ]]         && install_group "Dev Tools"         $DEV; } || true
    { [[ -n "$PASS" ]]        && install_group "Password Managers" $PASS; } || true
    { [[ -n "$IMAGING" ]]     && install_group "Creative Apps"     $IMAGING; } || true
    { [[ -n "$MUSIC" ]]       && install_group "Music & Audio"     $MUSIC; } || true
    { [[ -n "$VIDEO" ]]       && install_group "Video Apps"        $VIDEO; } || true

    print_success "User-selected packages installed!"
}

# ── Step E: Finalize system ───────────────────────────────────────────────────

finalize_system() {
    print_step "Updating initramfs..."
    $SUDO_CMD mkinitcpio -P \
        && print_success "Initramfs updated!" \
        || print_warning "mkinitcpio had errors — system may still boot, check manually"

    print_step "Updating GRUB configuration..."
    $SUDO_CMD update-grub \
        && print_success "GRUB configuration updated!" \
        || print_warning "update-grub had errors — check bootloader config manually"

    # ── Core services ─────────────────────────────────────────────────────────
    print_step "Enabling core services..."
    enable_service_if_available cups.socket
    enable_service_if_available saned.socket
    enable_service_if_available bluetooth
    enable_service_if_available wpa_supplicant
    enable_service_if_available sshd
    print_success "Core services enabled!"

    # ── Conditional services (package must be installed) ──────────────────────
    print_step "Enabling conditional services..."
    enable_if_installed power-profiles-daemon
    enable_if_installed switcheroo-control
    { [[ "$FILESYSTEM" == "btrfs" ]] && enable_service_if_available grub-btrfsd; } || true
    print_success "Conditional services processed!"

    # ── GPU tools (separate transaction to avoid rollback contamination) ───────
    print_step "Installing xero-gpu-tools..."
    $SUDO_CMD pacman -S --needed --noconfirm xero-gpu-tools \
        && enable_service_if_available xero-gpu-check \
        || print_warning "xero-gpu-tools install failed (non-critical)"

    # ── Disable live-environment services ─────────────────────────────────────
    print_step "Disabling live-environment services..."
    $SUDO_CMD systemctl disable iwd           2>/dev/null || true
    $SUDO_CMD systemctl disable dhcpcd        2>/dev/null || true
    $SUDO_CMD systemctl disable reflector     2>/dev/null || true
    $SUDO_CMD systemctl disable pacman-init   2>/dev/null || true
    $SUDO_CMD systemctl disable systemd-time-wait-sync 2>/dev/null || true
    print_success "Live-environment services disabled!"
}

# ── Step F: Apply XeroLinux configurations ────────────────────────────────────

copy_skel_to_user() {
    # Determine the actual user (not root) — try every reliable method
    local ACTUAL_USER=""
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

    local ACTUAL_HOME; ACTUAL_HOME="$(getent passwd "$ACTUAL_USER" | cut -d: -f6)"

    if [[ -z "${ACTUAL_HOME:-}" || ! -d "$ACTUAL_HOME" ]]; then
        print_warning "User home directory not found for $ACTUAL_USER ($ACTUAL_HOME), skipping user config copy"
        return 1
    fi

    print_step "Copying /etc/skel configurations to $ACTUAL_HOME for user $ACTUAL_USER..."
    if ! $SUDO_CMD cp -Rf /etc/skel/. "$ACTUAL_HOME"/; then
        print_error "Failed to copy /etc/skel to $ACTUAL_HOME!"
        return 1
    fi
    $SUDO_CMD chown -R "$ACTUAL_USER:$ACTUAL_USER" "$ACTUAL_HOME"

    print_step "Fetching XeroLinux .bashrc..."
    curl -4 --connect-timeout 5 --max-time 20 -fsSL "https://raw.githubusercontent.com/xerolinux/XeroBuild/main/FOSS/airootfs/etc/skel/.bashrc" \
        -o "$ACTUAL_HOME/.bashrc" 2>/dev/null \
        && print_success ".bashrc applied!" \
        || print_warning "Failed to fetch .bashrc (non-critical)"

    local OMP_LINE='eval "$(oh-my-posh init bash --config $HOME/.config/ohmyposh/xero.omp.json)"'
    if ! grep -qF "oh-my-posh init bash" "$ACTUAL_HOME/.bashrc" 2>/dev/null; then
        echo "" >> "$ACTUAL_HOME/.bashrc"
        echo "# Oh-My-Posh Config" >> "$ACTUAL_HOME/.bashrc"
        echo "$OMP_LINE" >> "$ACTUAL_HOME/.bashrc"
    fi

    if ! grep -qF "clear && fastfetch" "$ACTUAL_HOME/.bashrc" 2>/dev/null; then
        echo "" >> "$ACTUAL_HOME/.bashrc"
        echo "# Fastfetch on terminal start" >> "$ACTUAL_HOME/.bashrc"
        echo "clear && fastfetch" >> "$ACTUAL_HOME/.bashrc"
    fi

    $SUDO_CMD chown -R "$ACTUAL_USER:$ACTUAL_USER" "$ACTUAL_HOME"
    print_success "XeroLinux configurations applied to $ACTUAL_HOME!"

    print_step "Copying /etc/skel configurations to /root..."
    $SUDO_CMD cp -Rf /etc/skel/. /root/
    print_success "Configurations copied to /root!"

    print_step "Setting up XeroLinux Toolkit autostart..."
    $SUDO_CMD mkdir -p /etc/xdg/autostart
    if [[ -f /usr/share/applications/xero-toolkit.desktop ]]; then
        $SUDO_CMD cp /usr/share/applications/xero-toolkit.desktop /etc/xdg/autostart/
        print_success "XeroLinux Toolkit added to autostart!"
    else
        print_warning "xero-toolkit.desktop not found, skipping autostart setup (non-critical)"
    fi

    # Apply GRUB theme from xero-layan-git. We do NOT call the repo's
    # Grub.sh because it checks $UID (real UID), not $EUID (effective
    # UID) — under `sudo`, $UID stays as the invoking user's UID, so
    # Grub.sh thinks it lacks root and falls into an interactive password
    # prompt that times out and exits 1. Replicate its three steps directly.
    print_step "Applying GRUB theme..."
    local WORKDIR="/tmp/xero-layan-git"
    $SUDO_CMD rm -rf "$WORKDIR"

    if timeout 30 git clone --depth=1 https://github.com/xerolinux/xero-layan-git.git "$WORKDIR" 2>/dev/null; then
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
                print_warning "grub-mkconfig failed — theme is configured but grub.cfg may be stale"
            fi
        else
            print_warning "XeroLayan theme directory or theme.txt missing in repo — skipping"
        fi

        [[ -d "$WORKDIR/Configs/System" ]] && \
            $SUDO_CMD cp -Rf "$WORKDIR/Configs/System/." / 2>/dev/null || true

        $SUDO_CMD rm -rf "$WORKDIR"
    else
        print_warning "Failed to clone xero-layan-git — GRUB theme not applied (non-critical)"
    fi

    print_step "Setting distro identity files..."

    fetch_file() {
        local url="$1" dest="$2"
        if command -v wget >/dev/null 2>&1; then
            $SUDO_CMD wget -4 --timeout=20 -qO "$dest" "$url"
        elif command -v curl >/dev/null 2>&1; then
            $SUDO_CMD curl -4 --connect-timeout 5 --max-time 20 -fsSL "$url" -o "$dest"
        else
            return 1
        fi
    }

    local ID_URL_BASE="https://raw.githubusercontent.com/XeroLinux/XeroBuild/refs/heads/main/FOSS/airootfs/etc"
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

    print_success "All requested post-install config steps completed."
}

# ── Step G: Install and configure SDDM ────────────────────────────────────────

select_login_manager() {
    print_step "Installing SDDM..."
    $SUDO_CMD pacman -S --needed --noconfirm sddm sddm-kcm || { print_error "Failed to install SDDM!"; return 1; }
    print_success "SDDM installed!"

    print_step "Installing XeroDark SDDM theme..."
    if $SUDO_CMD timeout 30 git clone https://github.com/xerolinux/XeroDark.git /usr/share/sddm/themes/XeroDark; then
        print_success "XeroDark theme installed!"
    else
        print_warning "Failed to clone XeroDark theme"
    fi

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

    print_step "Enabling sddm.service..."
    $SUDO_CMD systemctl enable sddm.service || { print_error "Failed to enable sddm.service!"; return 1; }
    print_success "sddm.service enabled!"
}

# ── Completion ────────────────────────────────────────────────────────────────

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

# ── Main ──────────────────────────────────────────────────────────────────────

drain_stray_keystrokes
check_root

kde_step_labels=(
    "Installing KDE Plasma packages"
    "Installing AUR/user packages"
    "Finalizing system configuration"
    "Applying XeroLinux user config"
    "Installing display manager"
)
kde_step_funcs=(
    install_packages
    install_user_packages
    finalize_system
    copy_skel_to_user
    select_login_manager
)
kde_total_steps=${#kde_step_labels[@]}
for kde_step_i in "${!kde_step_labels[@]}"; do
    # No `set -e` in this script, so a failed step would otherwise fall
    # through into the next one instead of stopping — explicit check
    # required here (unlike xero-install.sh, which relies on errexit).
    run_step_visual "$((kde_step_i + 1))" "$kde_total_steps" \
        "${kde_step_labels[$kde_step_i]}" "${kde_step_funcs[$kde_step_i]}" || exit 1
done

show_completion

# Self-destruct: remove this script and its state file after a successful run
if [[ -n "$SCRIPT_PATH" && -f "$SCRIPT_PATH" ]]; then
    rm -f "$SCRIPT_PATH"
fi
rm -f "$STATE_FILE" 2>/dev/null || true
