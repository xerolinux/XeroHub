#!/bin/bash
#
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║                     ✨ Xero Arch Installer v1.9.1 ✨                          ║
# ║                                                                               ║
# ║          A beautiful, streamlined Arch Linux installer for XeroLinux         ║
# ║                                                                               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
#
# Author: XeroLinux Team
# License: GPL-3.0
#

set -Eeuo pipefail

# ────────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
# ────────────────────────────────────────────────────────────────────────────────

VERSION="1.9.1"
SCRIPT_NAME="Xero Arch Installer"
PART_LABEL="Part 1 - Pacstrap"

# Mountpoint for installation
MOUNTPOINT="/mnt"

# Colors (fallback)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BLUE='\033[0;34m'
NC='\033[0m'

# ── Screen-size-aware centering ────────────────────────────────────────────────
# Real terminal width, not a hardcoded guess — so centering actually centers on
# whatever console resolution the ISO booted into, not just an assumed 80 cols.
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

# Number of blank lines to print above a block of $1 lines so it sits
# vertically centered on the real terminal height, instead of pinned to
# the top row.
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

# Pads $1 with leading spaces to center it within $2 columns (default: real
# terminal width). Used for gum choose/filter lists, which have no native
# alignment flag of their own — gum renders each line's text exactly as
# given, so centering the text itself is what actually centers the list.
center_pad() {
    local text="$1" width="${2:-$(term_cols)}"
    local len=${#text}
    local pad=$(( (width - len) / 2 ))
    [[ $pad -lt 0 ]] && pad=0
    printf '%*s%s' "$pad" '' "$text"
}

# Installation configuration (associative array)
declare -A CONFIG
CONFIG[installer_lang]="English"
CONFIG[locale]="en_US.UTF-8"
CONFIG[keyboard]="us"
CONFIG[timezone]="UTC"
CONFIG[hostname]="xerolinux"
CONFIG[username]=""
CONFIG[user_password]=""
CONFIG[root_password]=""
CONFIG[disk]=""
CONFIG[filesystem]="btrfs"
CONFIG[encrypt]="no"
CONFIG[encrypt_boot]="no"
CONFIG[encrypt_password]=""
CONFIG[swap]="zram"
CONFIG[swap_algo]="zstd"
CONFIG[gfx_driver]="mesa"
CONFIG[parallel_downloads]="5"
CONFIG[aur_helper]="paru"
CONFIG[extra_kernel]=""
CONFIG[uefi]="no"
CONFIG[boot_part]=""
CONFIG[root_part]=""
CONFIG[root_device]=""
CONFIG[partition_mode]="auto"
CONFIG[reuse_efi]="no"
# Desktop-phase extra packages (picked from the main menu, installed later
# by install_user_packages once the desktop phase runs as the new user).
CONFIG[extra_browser]=""
CONFIG[extra_social]=""
CONFIG[extra_dev]=""
CONFIG[extra_pass]=""
CONFIG[extra_imaging]=""
CONFIG[extra_music]=""
CONFIG[extra_video]=""
CONFIG[wants_libreoffice]="no"
CONFIG[lo_locale]=""
CONFIG[lo_hunspell]=""

# ────────────────────────────────────────────────────────────────────────────────
# ERROR HANDLING
# ────────────────────────────────────────────────────────────────────────────────

have_gum() { command -v gum &>/dev/null; }

on_err() {
    local exit_code=$?
    local line_no=${1:-?}
    local cmd=${2:-?}

    # run_step_visual redirects each step's stdout/stderr to a logfile, so
    # without this an error here would vanish into it instead of the user.
    exec > /dev/tty 2>&1 || true
    tput cnorm 2>/dev/null || true

    if have_gum; then
        gum style --foreground 196 --bold --margin "1 2" \
            "❌ ERROR (exit=$exit_code) at line $line_no" \
            "$cmd"
        echo ""
        gum style --foreground 245 --margin "0 2" \
            "Tip: If this was during formatting, it's often missing partitions (udev timing) or empty device paths."
        echo ""
        gum input --placeholder "Press Enter to exit..." --width 50
    else
        echo -e "${RED}ERROR (exit=$exit_code) at line $line_no${NC}"
        echo -e "${RED}$cmd${NC}"
    fi

    exit "$exit_code"
}

trap 'on_err "$LINENO" "$BASH_COMMAND"' ERR
# Always restore the cursor and kill run_step_visual's background redraw
# loop (a forked process, not a child that dies on its own) on any exit.
DISPLAY_PID=""
trap 'kill "$DISPLAY_PID" 2>/dev/null || true; tput cnorm 2>/dev/null || true' EXIT

# ────────────────────────────────────────────────────────────────────────────────
# UTILITY FUNCTIONS
# ────────────────────────────────────────────────────────────────────────────────

# Set up sudo command (empty if running as root/in chroot)
setup_sudo() {
    if [ "${EUID:-0}" -eq 0 ]; then
        SUDO_CMD=""
    else
        SUDO_CMD="sudo"
    fi
}

check_root() {
    if [[ ${EUID:-0} -ne 0 ]]; then
        echo -e "${RED}Error: This script must be run as root${NC}"
        echo "Please run: sudo $0"
        exit 1
    fi
    setup_sudo
}

check_uefi() {
    if [[ -d /sys/firmware/efi/efivars ]]; then
        CONFIG[uefi]="yes"
    else
        CONFIG[uefi]="no"
    fi
}

# Cache so we never "re-check" during the same run
INTERNET_OK="no"

check_internet() {
    [[ "$INTERNET_OK" == "yes" ]] && return 0

    if ping -c 1 -W 3 archlinux.org &>/dev/null; then
        INTERNET_OK="yes"
        return 0
    fi

    echo -e "${RED}Error: No internet connection (or DNS is broken)${NC}"
    echo "Fix networking, then re-run the installer."
    exit 1
}

ensure_dependencies() {
    local deps_needed=()

    command -v gum &>/dev/null || deps_needed+=("gum")
    command -v parted &>/dev/null || deps_needed+=("parted")
    command -v arch-chroot &>/dev/null || deps_needed+=("arch-install-scripts")

    command -v sgdisk &>/dev/null || deps_needed+=("gptfdisk")
    command -v mkfs.btrfs &>/dev/null || deps_needed+=("btrfs-progs")
    command -v mkfs.fat &>/dev/null || deps_needed+=("dosfstools")
    command -v mkfs.ext4 &>/dev/null || deps_needed+=("e2fsprogs")
    command -v mkfs.xfs &>/dev/null || deps_needed+=("xfsprogs")
    command -v cryptsetup &>/dev/null || deps_needed+=("cryptsetup")
    command -v curl &>/dev/null || deps_needed+=("curl")

    if [[ ${#deps_needed[@]} -gt 0 ]]; then
        echo -e "${CYAN}Installing required dependencies...${NC}"
        pacman -Sy --noconfirm "${deps_needed[@]}" &>/dev/null || true
    fi
}

# ────────────────────────────────────────────────────────────────────────────────
# GUM UI HELPERS
# ────────────────────────────────────────────────────────────────────────────────

show_splash() {
    local cols; cols=$(term_cols)
    clear
    tput civis
    # Content height: title (padding "2 0" = 2+1+2=5) + subtitle (1) +
    # blank (1) + version (1) = 8 lines.
    print_vpad "$(vpad_for 8)"
    gum style --foreground 198 --bold --align center --width "$cols" --padding "2 0" \
        "X E R O L I N U X"
    gum style --foreground 45 --align center --width "$cols" \
        "A R C H   I N S T A L L E R"
    echo ""
    gum style --foreground 245 --align center --width "$cols" \
        "v$VERSION"
    sleep 3

    # Discard any keystrokes buffered during the sleep (an impatient Enter
    # meant to skip the splash) so they can't leak into the main menu's
    # gum choose right after and get consumed as a selection before the
    # user ever sees the menu. Drains /dev/tty, never fd0: when launched
    # via `curl | bash` (no file argument), fd0 IS bash's own script
    # source being read incrementally — draining it here could eat bytes
    # of the script itself that bash hasn't consumed yet.
    while read -r -t 0.05 -n 1000 _ < /dev/tty 2>/dev/null; do :; done
}

show_header() {
    clear
    local cols; cols=$(term_cols)
    local box_width=$(( cols - 4 ))
    [[ $box_width -lt 40 ]] && box_width=40
    # Small top margin so the header doesn't sit glued to row 0 on
    # submenu screens (whose own content below varies in height, so it
    # can't be fully vertically centered here without knowing that).
    print_vpad "$(( $(term_lines) / 10 ))"
    gum style \
        --foreground 212 --border-foreground 212 --border double \
        --align center --width "$box_width" --margin "0 2" --padding "1 2" \
        "✨ $SCRIPT_NAME v$VERSION ✨" \
        "" \
        "Installs XeroLinux exactly as the official ISO does (KDE Plasma)," \
        "with more configuration options than the ISO installer." \
        "For experienced Arch/Linux users. NOT beginner-friendly."
}

show_submenu_header() {
    local title="$1"
    gum style \
        --foreground 212 --bold --margin "1 2" \
        "$title"
}

# Fall back to plain echo when gum isn't installed yet (true early in the
# desktop phase, which reuses these same helpers before install_packages runs).
show_info() {
    if have_gum; then
        gum style --foreground 81 --margin "0 2" "$1"
    else
        echo "$1"
    fi
}

show_success() {
    if have_gum; then
        gum style --foreground 82 "  ✓ $1"
    else
        echo "  OK: $1"
    fi
}

show_error() {
    if have_gum; then
        gum style --foreground 196 "  ✗ $1"
    else
        echo "  ERROR: $1"
    fi
}

show_warning() {
    if have_gum; then
        gum style --foreground 214 "  ⚠ $1"
    else
        echo "  WARN: $1"
    fi
}

confirm_action() {
    # $2="no" focuses the "No" button by default — used for encryption
    # prompts so an impatient double Enter can't silently turn it on.
    if [[ "${2:-}" == "no" ]]; then
        gum confirm --affirmative "Yes" --negative "No" --default=false "$1"
    else
        gum confirm --affirmative "Yes" --negative "No" "$1"
    fi
}

# Big block-letter "XEROLINUX" wordmark, 53 cols wide — drawn with the same
# U+2588 FULL BLOCK used by the progress bar itself, so it's exactly as
# console-safe as the bar already proven to render correctly here. Skipped
# entirely on a narrow terminal (see draw_progress_bar) rather than wrapped.
XEROLOGO=(
    "█   █ █████ ████   ███  █     █████ █   █ █   █ █   █"
    " █ █  █     █   █ █   █ █       █   ██  █ █   █  █ █ "
    "  █   ████  ████  █   █ █       █   █ █ █ █   █   █  "
    " █ █  █     █  █  █   █ █       █   █  ██ █   █  █ █ "
    "█   █ █████ █   █  ███  █████ █████ █   █  ███  █   █"
)

# Pure bash/tput/printf, no gum — redrawn many times a second from
# run_step_visual's background loop, and gum (a separate process per call)
# hit real panics there under rapid repeated invocation.
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

    # \033[K erases to end of line: center_pad only adds leading padding,
    # so without this a wider previous frame's tail would never get
    # overwritten (frames are never cleared between redraws, to avoid flicker).
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
    # Runs a function/command in the CURRENT shell (no subshell), so CONFIG
    # changes persist. Additionally shows a live percent bar + step title +
    # a live-scrolling box of the step's own command output while it runs.
    local step_num="$1" total="$2" title="$3"
    shift 3
    local func="$1"; shift

    local logfile
    logfile=$(mktemp)

    # Percent range this step owns, from where the previous step left off to
    # where the next starts. Progress within it is approximated from how
    # much log output has appeared so far, capped short of the next step's
    # value so it never overshoots before the step actually finishes.
    local base_pct=$(( (step_num - 1) * 100 / total ))
    local next_pct=$(( step_num * 100 / total ))
    local range=$(( next_pct - base_pct ))
    [[ $range -lt 1 ]] && range=1

    # Redraws reposition to the top (`tput cup`) instead of re-clearing —
    # frames are a fixed size, so this avoids visible flicker. Content
    # height must match what draw_progress_bar prints at this width: 6
    # extra lines for the logo when the terminal is wide enough to show it.
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
    # that's expected, not a real failure, but under `set -e` a bare nonzero
    # return here would trigger the global ERR trap and kill the whole
    # installer. `|| true` on both is required, not cosmetic.
    kill "$display_pid" 2>/dev/null || true
    wait "$display_pid" 2>/dev/null || true
    DISPLAY_PID=""
    tput cnorm

    if [[ $status -ne 0 ]]; then
        clear
        print_vpad "$top_row"
        draw_progress_bar "$base_pct" "$step_num" "$total" "$title" "$cols"
        show_error "Step failed: $title"
        # The live output box is gone by design, but on an actual failure
        # "Step failed: X" with no detail at all is worse than the box —
        # show the tail of what the step actually printed before it died.
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

# ────────────────────────────────────────────────────────────────────────────────
# 1. INSTALLER LANGUAGE
# ────────────────────────────────────────────────────────────────────────────────

select_installer_language() {
    show_header
    show_submenu_header "🌐 Installer Language"
    echo ""
    show_info "Select the language for this installer interface"
    echo ""

    local languages=(
        "English"
        "Deutsch (German)"
        "Español (Spanish)"
        "Français (French)"
        "Italiano (Italian)"
        "Português (Portuguese)"
        "Русский (Russian)"
        "日本語 (Japanese)"
        "中文 (Chinese)"
        "한국어 (Korean)"
        "العربية (Arabic)"
        "Polski (Polish)"
        "Nederlands (Dutch)"
        "Türkçe (Turkish)"
    )

    local selection=""
    selection=$(printf '%s\n' "${languages[@]}" | gum choose --height 15 --header "Choose language:") || true

    if [[ -n "$selection" ]]; then
        CONFIG[installer_lang]="$selection"
        show_success "Language set to: $selection"
    fi

    sleep 0.5
}

# ────────────────────────────────────────────────────────────────────────────────
# 2. LOCALES (System Language + Keyboard)
# ────────────────────────────────────────────────────────────────────────────────

select_locales() {
    show_header
    show_submenu_header "🗺️ System Locales"
    echo ""

    show_info "Select your system locale (language & encoding)"
    echo ""

    local locales=(
        "en_US.UTF-8"
        "en_GB.UTF-8"
        "de_DE.UTF-8"
        "fr_FR.UTF-8"
        "es_ES.UTF-8"
        "it_IT.UTF-8"
        "pt_BR.UTF-8"
        "pt_PT.UTF-8"
        "ru_RU.UTF-8"
        "ja_JP.UTF-8"
        "ko_KR.UTF-8"
        "zh_CN.UTF-8"
        "zh_TW.UTF-8"
        "ar_SA.UTF-8"
        "pl_PL.UTF-8"
        "nl_NL.UTF-8"
        "tr_TR.UTF-8"
        "vi_VN.UTF-8"
        "sv_SE.UTF-8"
        "da_DK.UTF-8"
        "fi_FI.UTF-8"
        "nb_NO.UTF-8"
        "cs_CZ.UTF-8"
        "hu_HU.UTF-8"
        "el_GR.UTF-8"
        "he_IL.UTF-8"
        "th_TH.UTF-8"
        "id_ID.UTF-8"
        "uk_UA.UTF-8"
        "ro_RO.UTF-8"
    )

    local locale_selection=""
    locale_selection=$(printf '%s\n' "${locales[@]}" | gum filter --placeholder "Search locale..." --height 12) || true

    if [[ -n "$locale_selection" ]]; then
        CONFIG[locale]="$locale_selection"
        show_success "System locale: $locale_selection"
    fi

    echo ""

    show_info "Select your keyboard layout"
    echo ""

    local keyboards=(
        "us"
        "uk"
        "de"
        "fr"
        "es"
        "it"
        "pt-latin9"
        "br-abnt2"
        "ru"
        "pl"
        "cz"
        "hu"
        "se"
        "no"
        "dk"
        "fi"
        "nl"
        "be"
        "ch"
        "at"
        "jp106"
        "kr"
        "ara"
        "tr"
        "gr"
        "il"
        "latam"
        "dvorak"
        "colemak"
    )

    local kb_selection=""
    kb_selection=$(printf '%s\n' "${keyboards[@]}" | gum filter --placeholder "Search keyboard layout..." --height 12) || true

    if [[ -n "$kb_selection" ]]; then
        CONFIG[keyboard]="$kb_selection"
        loadkeys "$kb_selection" 2>/dev/null || true
        show_success "Keyboard layout: $kb_selection"
    fi

    sleep 0.5
}

# ────────────────────────────────────────────────────────────────────────────────
# 3. DISK CONFIGURATION
# ────────────────────────────────────────────────────────────────────────────────

# ────────────────────────────────────────────────────────────────────────────────
# 3a. PARTITIONING MODE SELECTION
# ────────────────────────────────────────────────────────────────────────────────

select_partitioning_mode() {
    show_header
    show_submenu_header "💾 Disk Configuration"
    echo ""

    local mode_options=(
        "Auto    │ Wipe entire disk and partition automatically (Recommended)"
        "Manual  │ Choose existing partitions (dual-boot, custom layouts)"
    )

    local mode_sel=""
    mode_sel=$(printf '%s\n' "${mode_options[@]}" | gum choose --height 4 \
        --header "Select partitioning mode:") || true

    if [[ "$mode_sel" == "Manual"* ]]; then
        CONFIG[partition_mode]="manual"
        manual_partitioning
    else
        CONFIG[partition_mode]="auto"
        select_disk
    fi
}

# ────────────────────────────────────────────────────────────────────────────────
# 3b. MANUAL PARTITIONING
# ────────────────────────────────────────────────────────────────────────────────

manual_partitioning() {
    show_header
    show_submenu_header "💾 Manual Partitioning"
    echo ""

    gum style --foreground 226 --bold --margin "0 2" \
        "ℹ️  Your partitions will not be wiped — only the ones you assign will be formatted."
    echo ""

    # Show current layout
    gum style --foreground 245 --margin "0 2" \
        "$(lsblk -o NAME,SIZE,FSTYPE,LABEL,TYPE,MOUNTPOINT 2>/dev/null)"
    echo ""

    # Optionally launch cfdisk so the user can create partitions first
    if confirm_action "Launch cfdisk to create or modify partitions first?"; then
        local disks=()
        while IFS= read -r line; do
            [[ -n "$line" ]] && disks+=("$line")
        done < <(lsblk -dpno NAME,SIZE,MODEL 2>/dev/null \
            | { grep -E '^/dev/(sd|nvme|vd|mmcblk)' || true; } | sed 's/  */ /g')

        if [[ ${#disks[@]} -gt 0 ]]; then
            local disk_sel=""
            disk_sel=$(printf '%s\n' "${disks[@]}" | gum choose --height 10 \
                --header "Select disk to open in cfdisk:") || true
            if [[ -n "$disk_sel" ]]; then
                local target_disk
                target_disk=$(echo "$disk_sel" | awk '{print $1}')
                cfdisk "$target_disk" || true
                partprobe "$target_disk" || true
                udevadm settle
            fi
        fi

        # Refresh view after cfdisk
        show_header
        show_submenu_header "💾 Manual Partitioning"
        echo ""
        gum style --foreground 245 --margin "0 2" "Updated disk layout:"
        echo ""
        gum style --foreground 245 --margin "0 2" \
            "$(lsblk -o NAME,SIZE,FSTYPE,LABEL,TYPE,MOUNTPOINT 2>/dev/null)"
        echo ""
    fi

    # Build list of all available partitions
    local partitions=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && partitions+=("$line")
    done < <(lsblk -lpno NAME,SIZE,FSTYPE,LABEL 2>/dev/null \
        | { grep -E '^/dev/(sd|nvme|vd|mmcblk)[^ ]*[0-9]' || true; } \
        | sed 's/  */ /g')

    if [[ ${#partitions[@]} -eq 0 ]]; then
        show_error "No partitions found. Create partitions first and try again."
        gum input --placeholder "Press Enter to continue..." --width 50
        return
    fi

    # ── Boot / EFI partition ──────────────────────────────────────────────────
    echo ""
    if [[ "${CONFIG[uefi]}" == "yes" ]]; then
        show_info "Select EFI System Partition (ESP)"
    else
        show_info "Select boot partition  (or skip to keep /boot on the root partition)"
    fi
    echo ""

    local boot_options=("-- Skip (no separate boot partition) --")
    for p in "${partitions[@]}"; do boot_options+=("$p"); done

    local boot_sel=""
    boot_sel=$(printf '%s\n' "${boot_options[@]}" | gum choose --height 14 \
        --header "Boot / EFI partition:") || true

    if [[ "$boot_sel" == "-- Skip"* ]]; then
        CONFIG[boot_part]=""
        CONFIG[reuse_efi]="no"
        show_info "No separate boot partition — /boot will live on the root partition"
    else
        CONFIG[boot_part]=$(echo "$boot_sel" | awk '{print $1}')
        show_success "Boot/EFI partition: ${CONFIG[boot_part]}"

        if [[ "${CONFIG[uefi]}" == "yes" ]]; then
            echo ""
            gum style --foreground 226 --bold --margin "0 2" \
                "Dual-boot tip: If this ESP already contains Windows boot files, choose 'Reuse'." \
                "Choosing 'Format' will wipe the ESP and break the Windows boot entry."
            echo ""

            local efi_action=""
            efi_action=$(printf '%s\n' \
                "Format  │ Wipe and format as FAT32  (single-OS or new ESP)" \
                "Reuse   │ Mount without formatting   (Windows dual-boot)" \
                | gum choose --height 4 --header "What to do with this EFI partition:") || true

            if [[ "$efi_action" == "Reuse"* ]]; then
                CONFIG[reuse_efi]="yes"
                show_success "EFI partition will be reused — dual-boot safe"
            else
                CONFIG[reuse_efi]="no"
                show_success "EFI partition will be formatted as FAT32"
            fi
        fi
    fi

    # ── Root partition ────────────────────────────────────────────────────────
    echo ""
    show_info "Select root partition"
    echo ""

    local root_sel=""
    root_sel=$(printf '%s\n' "${partitions[@]}" | gum choose --height 14 \
        --header "Root ( / ) partition:") || true

    if [[ -z "$root_sel" ]]; then
        show_error "No root partition selected."
        gum input --placeholder "Press Enter to continue..." --width 50
        return
    fi

    CONFIG[root_part]=$(echo "$root_sel" | awk '{print $1}')
    show_success "Root partition: ${CONFIG[root_part]}"

    # Derive parent disk for GRUB install
    local parent_disk
    parent_disk=$(lsblk -no PKNAME "${CONFIG[root_part]}" 2>/dev/null | head -1)
    if [[ -n "$parent_disk" ]]; then
        CONFIG[disk]="/dev/$parent_disk"
    else
        CONFIG[disk]="${CONFIG[root_part]}"
    fi

    # ── Filesystem ───────────────────────────────────────────────────────────
    echo ""
    show_info "Select filesystem for root partition"
    echo ""

    local filesystems=(
        "btrfs    │ Modern CoW filesystem with snapshots (Recommended)"
        "ext4     │ Traditional reliable filesystem"
        "xfs      │ High-performance filesystem"
    )

    local fs_selection=""
    fs_selection=$(printf '%s\n' "${filesystems[@]}" | gum choose --height 5 \
        --header "Filesystem:") || true

    if [[ -z "$fs_selection" ]]; then
        show_error "No filesystem selected."
        gum input --placeholder "Press Enter to continue..." --width 50
        return
    fi

    CONFIG[filesystem]=$(echo "$fs_selection" | awk '{print $1}')
    show_success "Filesystem: ${CONFIG[filesystem]}"

    # ── Encryption ───────────────────────────────────────────────────────────
    echo ""
    show_info "Root Partition Encryption (LUKS2)"
    echo ""

    if confirm_action "Enable encryption on the root partition?" "no"; then
        CONFIG[encrypt]="yes"
        CONFIG[encrypt_boot]="no"   # manual mode: root-only encryption only

        echo ""
        local enc_pass1="" enc_pass2=""
        enc_pass1=$(gum input --password --placeholder "Enter encryption password" --width 50) || true
        enc_pass2=$(gum input --password --placeholder "Confirm encryption password" --width 50) || true

        if [[ "$enc_pass1" == "$enc_pass2" && -n "$enc_pass1" ]]; then
            CONFIG[encrypt_password]="$enc_pass1"
            show_success "Root encryption enabled"
        else
            show_error "Passwords don't match or empty. Encryption disabled."
            CONFIG[encrypt]="no"
            CONFIG[encrypt_password]=""
        fi
    else
        CONFIG[encrypt]="no"
        CONFIG[encrypt_boot]="no"
        CONFIG[encrypt_password]=""
        show_info "Encryption disabled"
    fi

    sleep 0.5
}

# ────────────────────────────────────────────────────────────────────────────────
# 3c. AUTO DISK SELECTION (original select_disk)
# ────────────────────────────────────────────────────────────────────────────────

select_disk() {
    show_header
    show_submenu_header "💾 Disk Configuration"
    echo ""

    gum style --foreground 196 --bold --margin "0 2" \
        "⚠️  WARNING: The selected disk will be COMPLETELY ERASED!"
    echo ""

    show_info "Select the target disk for installation"
    echo ""

    local disks=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && disks+=("$line")
    done < <(lsblk -dpno NAME,SIZE,MODEL 2>/dev/null | { grep -E '^/dev/(sd|nvme|vd|mmcblk)' || true; } | sed 's/  */ /g')

    if [[ ${#disks[@]} -eq 0 ]]; then
        show_error "No suitable disks found!"
        gum input --placeholder "Press Enter to exit..." --width 50
        exit 1
    fi

    local disk_selection=""
    disk_selection=$(printf '%s\n' "${disks[@]}" | gum choose --height 10 --header "Available disks:") || true

    if [[ -n "$disk_selection" ]]; then
        CONFIG[disk]=$(echo "$disk_selection" | awk '{print $1}')
        show_success "Selected disk: ${CONFIG[disk]}"

        echo ""
        gum style --foreground 245 --margin "0 2" \
            "$(lsblk "${CONFIG[disk]}" 2>/dev/null)"
    fi

    echo ""

    show_info "Select filesystem type"
    echo ""

    local filesystems=(
        "btrfs    │ Modern CoW filesystem with snapshots (Recommended)"
        "ext4     │ Traditional reliable filesystem"
        "xfs      │ High-performance filesystem"
    )

    local fs_selection=""
    fs_selection=$(printf '%s\n' "${filesystems[@]}" | gum choose --height 5 --header "Filesystem:") || true

    if [[ -n "$fs_selection" ]]; then
        CONFIG[filesystem]=$(echo "$fs_selection" | awk '{print $1}')
        show_success "Filesystem: ${CONFIG[filesystem]}"
    fi

    echo ""

    show_info "Disk Encryption (LUKS2)"
    echo ""

    if confirm_action "Enable full disk encryption?" "no"; then
        CONFIG[encrypt]="yes"

        echo ""
        local enc_pass1="" enc_pass2=""
        enc_pass1=$(gum input --password --placeholder "Enter encryption password" --width 50) || true
        enc_pass2=$(gum input --password --placeholder "Confirm encryption password" --width 50) || true

        if [[ "$enc_pass1" == "$enc_pass2" && -n "$enc_pass1" ]]; then
            CONFIG[encrypt_password]="$enc_pass1"
            show_success "Disk encryption enabled"

            echo ""
            show_info "Choose what to encrypt:"
            echo ""

            local encrypt_options=(
                "root      │ Encrypt root only  (Faster boot, single password prompt)"
                "root+boot │ Encrypt root & boot (More secure, GRUB asks for password)"
            )

            local enc_selection=""
            enc_selection=$(printf '%s\n' "${encrypt_options[@]}" | gum choose --height 4 --header "Encryption scope:") || true

            if [[ "$enc_selection" == "root+boot"* ]]; then
                CONFIG[encrypt_boot]="yes"
                show_success "Encrypting root & boot"
            else
                CONFIG[encrypt_boot]="no"
                show_success "Encrypting root only"
            fi
        else
            show_error "Passwords don't match or empty. Encryption disabled."
            CONFIG[encrypt]="no"
            CONFIG[encrypt_boot]="no"
            CONFIG[encrypt_password]=""
        fi
    else
        CONFIG[encrypt]="no"
        CONFIG[encrypt_boot]="no"
        CONFIG[encrypt_password]=""
        show_info "Disk encryption disabled"
    fi

    sleep 0.5
}

# ────────────────────────────────────────────────────────────────────────────────
# 4. SWAP CONFIGURATION
# ────────────────────────────────────────────────────────────────────────────────

configure_swap() {
    show_header
    show_submenu_header "🔄 Swap Configuration"
    echo ""

    show_info "Select swap type for your system"
    echo ""

    local swap_options=(
        "zram     │ Compressed RAM swap (Recommended, fast)"
        "file     │ Traditional swap file on disk"
        "none     │ No swap (not recommended)"
    )

    local swap_selection=""
    swap_selection=$(printf '%s\n' "${swap_options[@]}" | gum choose --height 5 --header "Swap type:") || true

    if [[ -n "$swap_selection" ]]; then
        CONFIG[swap]=$(echo "$swap_selection" | awk '{print $1}')
        show_success "Swap type: ${CONFIG[swap]}"

        if [[ "${CONFIG[swap]}" == "zram" ]]; then
            echo ""
            show_info "Select zram compression algorithm"
            echo ""

            local algos=(
                "zstd     │ Best compression ratio (Recommended)"
                "lz4      │ Fastest compression"
                "lzo      │ Balanced speed/ratio"
            )

            local algo_selection=""
            algo_selection=$(printf '%s\n' "${algos[@]}" | gum choose --height 5 --header "Algorithm:") || true

            if [[ -n "$algo_selection" ]]; then
                CONFIG[swap_algo]=$(echo "$algo_selection" | awk '{print $1}')
                show_success "Compression: ${CONFIG[swap_algo]}"
            fi
        fi
    fi

    sleep 0.5
}

# ────────────────────────────────────────────────────────────────────────────────
# 5. HOSTNAME
# ────────────────────────────────────────────────────────────────────────────────

configure_hostname() {
    show_header
    show_submenu_header "💻 Hostname"
    echo ""

    show_info "Enter a hostname for your system"
    show_info "(lowercase letters, numbers, and hyphens only)"
    echo ""

    local hostname=""
    hostname=$(gum input --placeholder "xerolinux" --value "${CONFIG[hostname]}" --width 40 --header "Hostname:") || true

    if [[ "$hostname" =~ ^[a-z][a-z0-9-]*$ && ${#hostname} -le 63 ]]; then
        CONFIG[hostname]="$hostname"
        show_success "Hostname: ${CONFIG[hostname]}"
    else
        show_warning "Invalid hostname, using default: xerolinux"
        CONFIG[hostname]="xerolinux"
    fi

    sleep 0.5
}

# ────────────────────────────────────────────────────────────────────────────────
# 6. GRAPHICS DRIVER
# ────────────────────────────────────────────────────────────────────────────────

select_graphics_driver() {
    show_header
    show_submenu_header "🎮 Graphics Driver"
    echo ""

    local is_vm="no"
    if systemd-detect-virt -q 2>/dev/null; then
        is_vm="yes"
        gum style --foreground 82 --margin "0 2" "🔍 Virtual Machine detected."
        echo ""
    fi

    show_info "Select the graphics driver configuration for your system"
    echo ""

    # If VM, put "vm" first (better UX)
    local drivers=()
    if [[ "$is_vm" == "yes" ]]; then
        drivers+=("vm                   │ Virtual Machine")
    fi
    drivers+=(
        "intel                │ Intel Graphics"
        "amd                  │ AMD Graphics"
        "nvidia-turing        │ NVIDIA Turing+ (RTX 20/30/40, GTX 1650+)"
        "nvidia-legacy        │ NVIDIA Legacy (GTX 900/1000 series)"
        "intel-amd            │ Intel + AMD (Hybrid)"
        "intel-nvidia-turing  │ Intel + NVIDIA Turing+ (Optimus)"
        "intel-nvidia-legacy  │ Intel + NVIDIA Legacy (Optimus)"
        "amd-nvidia-turing    │ AMD + NVIDIA Turing+ (Hybrid)"
        "amd-nvidia-legacy    │ AMD + NVIDIA Legacy (Hybrid)"
    )
    if [[ "$is_vm" != "yes" ]]; then
        drivers+=("vm                   │ Virtual Machine")
    fi

    local driver_selection=""
    driver_selection=$(printf '%s\n' "${drivers[@]}" | gum choose --height 12 --header "Graphics driver:") || true

    if [[ -n "$driver_selection" ]]; then
        CONFIG[gfx_driver]=$(echo "$driver_selection" | awk '{print $1}')
        show_success "Graphics driver: ${CONFIG[gfx_driver]}"

        echo ""
        case "${CONFIG[gfx_driver]}" in
            "intel")
                gum style --foreground 245 --margin "0 2" "Packages: intel-drv"
                ;;
            "amd")
                gum style --foreground 245 --margin "0 2" "Packages: amd-drv"
                ;;
            "nvidia-turing")
                gum style --foreground 245 --margin "0 2" "Packages: nvidia-open-dkms nvidia-utils + extras"
                gum style --foreground 214 --margin "0 2" "⚠ Will configure: mkinitcpio modules + GRUB parameters"
                ;;
            "nvidia-legacy")
                gum style --foreground 245 --margin "0 2" "Packages: nvidia-580xx-dkms nvidia-580xx-utils + extras"
                gum style --foreground 214 --margin "0 2" "⚠ Will configure: mkinitcpio modules + GRUB parameters"
                ;;
            "intel-amd")
                gum style --foreground 245 --margin "0 2" "Packages: intel-drv + amd-drv"
                ;;
            "intel-nvidia-turing")
                gum style --foreground 245 --margin "0 2" "Packages: intel-drv + nvidia-open-dkms + extras"
                gum style --foreground 214 --margin "0 2" "⚠ Will configure: mkinitcpio modules + GRUB parameters"
                ;;
            "intel-nvidia-legacy")
                gum style --foreground 245 --margin "0 2" "Packages: intel-drv + nvidia-580xx-dkms + extras"
                gum style --foreground 214 --margin "0 2" "⚠ Will configure: mkinitcpio modules + GRUB parameters"
                ;;
            "amd-nvidia-turing")
                gum style --foreground 245 --margin "0 2" "Packages: amd-drv + nvidia-open-dkms + extras"
                gum style --foreground 214 --margin "0 2" "⚠ Will configure: mkinitcpio modules + GRUB parameters"
                ;;
            "amd-nvidia-legacy")
                gum style --foreground 245 --margin "0 2" "Packages: amd-drv + nvidia-580xx-dkms + extras"
                gum style --foreground 214 --margin "0 2" "⚠ Will configure: mkinitcpio modules + GRUB parameters"
                ;;
            "vm")
                gum style --foreground 245 --margin "0 2" "Packages: Foss"
                ;;
        esac
    fi

    sleep 0.5
}

# ────────────────────────────────────────────────────────────────────────────────
# 7. AUTHENTICATION (Users & Root)
# ────────────────────────────────────────────────────────────────────────────────

configure_authentication() {
    show_header
    show_submenu_header "👤 User Account Setup"
    echo ""

    show_info "Create your user account"
    echo ""

    local username=""
    username=$(gum input --placeholder "username" --width 40 --header "Username (lowercase):") || true

    if [[ ! "$username" =~ ^[a-z_][a-z0-9_-]*$ || ${#username} -gt 32 || -z "$username" ]]; then
        show_warning "Invalid username. Using 'user'"
        username="user"
    fi
    CONFIG[username]="$username"
    show_success "Username: ${CONFIG[username]}"

    echo ""

    local user_pass1="" user_pass2=""
    user_pass1=$(gum input --password --placeholder "Password for $username" --width 50) || true
    user_pass2=$(gum input --password --placeholder "Confirm password" --width 50) || true

    if [[ "$user_pass1" == "$user_pass2" && ${#user_pass1} -ge 1 ]]; then
        CONFIG[user_password]="$user_pass1"
        show_success "User password set"
    else
        show_error "Passwords don't match. Please reconfigure."
        sleep 1
        configure_authentication
        return
    fi

    echo ""
    show_submenu_header "🔐 Root Password"
    echo ""

    if confirm_action "Use same password for root?"; then
        CONFIG[root_password]="${CONFIG[user_password]}"
        show_success "Root password set (same as user)"
    else
        local root_pass1="" root_pass2=""
        root_pass1=$(gum input --password --placeholder "Root password" --width 50) || true
        root_pass2=$(gum input --password --placeholder "Confirm root password" --width 50) || true

        if [[ "$root_pass1" == "$root_pass2" && -n "$root_pass1" ]]; then
            CONFIG[root_password]="$root_pass1"
            show_success "Root password set"
        else
            show_warning "Passwords don't match. Using user password for root."
            CONFIG[root_password]="${CONFIG[user_password]}"
        fi
    fi

    sleep 0.5
}

# ────────────────────────────────────────────────────────────────────────────────
# 8. TIMEZONE
# ────────────────────────────────────────────────────────────────────────────────

select_timezone() {
    show_header
    show_submenu_header "🕐 Timezone"
    echo ""

    show_info "Select your timezone"
    echo ""

    local regions=""
    regions=$(find /usr/share/zoneinfo -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | \
              grep -vE '^(\+|posix|right|zoneinfo)$' | sort) || true

    local region=""
    region=$(echo "$regions" | gum filter --placeholder "Search region..." --height 12 --header "Select region:") || true

    if [[ -n "$region" ]]; then
        local cities=""
        cities=$(find "/usr/share/zoneinfo/$region" -type f -printf '%f\n' 2>/dev/null | sort) || true

        if [[ -n "$cities" ]]; then
            echo ""
            local city=""
            city=$(echo "$cities" | gum filter --placeholder "Search city..." --height 12 --header "Select city:") || true

            if [[ -n "$city" ]]; then
                CONFIG[timezone]="$region/$city"
            else
                CONFIG[timezone]="$region"
            fi
        else
            CONFIG[timezone]="$region"
        fi

        show_success "Timezone: ${CONFIG[timezone]}"
    fi

    sleep 0.5
}

# ────────────────────────────────────────────────────────────────────────────────
# 9. PARALLEL DOWNLOADS
# ────────────────────────────────────────────────────────────────────────────────

configure_parallel_downloads() {
    show_header
    show_submenu_header "⚡ Parallel Downloads"
    echo ""

    show_info "Set number of parallel package downloads (speeds up installation)"
    echo ""

    local options=(
        "3      │ Conservative (slow connections)"
        "5      │ Default (recommended)"
        "10     │ Fast (good connections)"
        "15     │ Maximum (excellent connections)"
    )

    local selection=""
    selection=$(printf '%s\n' "${options[@]}" | gum choose --height 6 --header "Parallel downloads:") || true

    if [[ -n "$selection" ]]; then
        CONFIG[parallel_downloads]=$(echo "$selection" | awk '{print $1}')
        show_success "Parallel downloads: ${CONFIG[parallel_downloads]}"
    fi

    sleep 0.5
}

# ────────────────────────────────────────────────────────────────────────────────
# 10. AUR HELPER
# ────────────────────────────────────────────────────────────────────────────────

select_aur_helper() {
    show_header
    show_submenu_header "📦 AUR Helper"
    echo ""
    show_info "Select the AUR helper to install during KDE setup"
    echo ""

    local helpers=(
        "paru   │ Rust-based, feature-rich (Recommended)"
        "yay    │ Go-based, popular choice"
    )

    local selection=""
    selection=$(printf '%s\n' "${helpers[@]}" | gum choose --height 4 --header "AUR Helper:") || true

    if [[ -n "$selection" ]]; then
        CONFIG[aur_helper]=$(echo "$selection" | awk '{print $1}')
        show_success "AUR helper: ${CONFIG[aur_helper]}"
    fi

    sleep 0.5
}

# ────────────────────────────────────────────────────────────────────────────────
# 11. ADDITIONAL KERNEL
# ────────────────────────────────────────────────────────────────────────────────

select_extra_kernel() {
    show_header
    show_submenu_header "🐧 Additional Kernel"
    echo ""

    gum style --foreground 220 --bold --border normal --border-foreground 220 \
        --align left --margin "0 2" --padding "0 1" \
        "These kernels install ALONGSIDE the default linux kernel." \
        "Do NOT select too many — each takes ~100 MB on the boot partition."
    echo ""

    local options=(
        "None"
        "linux-cachyos   │ CachyOS optimized kernel  (Chaotic-AUR)"
        "linux-lts       │ Long Term Support kernel   (official repos)"
    )

    local selections=""
    selections=$(printf '%s\n' "${options[@]}" | gum choose --no-limit \
        --header "Additional kernels (Space to toggle, Enter to confirm):") || true

    CONFIG[extra_kernel]=""
    if [[ -z "$selections" ]] || echo "$selections" | grep -q "^None$"; then
        show_success "No additional kernel selected"
        sleep 0.5
        return
    fi

    while IFS= read -r line; do
        case "$line" in
            "linux-cachyos"*) CONFIG[extra_kernel]+="linux-cachyos linux-cachyos-headers " ;;
            "linux-lts"*)     CONFIG[extra_kernel]+="linux-lts linux-lts-headers " ;;
        esac
    done <<< "$selections"

    CONFIG[extra_kernel]="${CONFIG[extra_kernel]% }"
    show_success "Extra kernels queued: ${CONFIG[extra_kernel]}"
    sleep 0.5
}

# ────────────────────────────────────────────────────────────────────────────────
# EXTRA PACKAGES (desktop-phase optional apps, picked up front like every
# other setting instead of mid-KDE-install — the actual `pacman -S` calls
# for these happen later, in install_user_packages, once the desktop phase
# is running as the target user with a real chroot pacman database; nothing
# here queries package existence, it only records the choice)
# ────────────────────────────────────────────────────────────────────────────────

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

configure_extra_packages() {
    show_header
    show_submenu_header "📦 Extra Packages"
    echo ""
    show_info "To select hit x, to save hit Enter key."
    echo ""

    # Label -> package lookup, scoped per category below.
    declare -A PKG_MAP=(
        ["Floorp"]="floorp" ["Firefox"]="firefox" ["Brave"]="brave-bin"
        ["LibreWolf"]="librewolf" ["Vivaldi"]="vivaldi-meta" ["Tor Browser"]="tor-browser-bin"
        ["Mullvad Browser"]="mullvad-browser-bin" ["Ungoogled Chromium"]="ungoogled-chromium-bin"
        ["FileZilla"]="filezilla" ["Helium Browser"]="helium-browser-bin" ["Zen Browser"]="zen-browser-bin"
        ["ZapZap (WhatsApp)"]="zapzap" ["Discord"]="discord" ["Vesktop"]="vesktop"
        ["Telegram"]="telegram-desktop" ["Ferdium (All-in-one)"]="ferdium-bin"
        ["Hugo"]="hugo" ["Meld (diff viewer)"]="meld" ["VSCodium"]="vscodium" ["GitHub Desktop"]="github-desktop"
        ["KeePassXC"]="keepassxc" ["Bitwarden"]="bitwarden" ["pass"]="pass"
        ["GIMP"]="gimp" ["Krita"]="krita" ["Inkscape"]="inkscape"
        ["MPV"]="mpv" ["Amarok"]="amarok" ["Spotify"]="spotify"
        ["Tenacity"]="tenacity" ["JamesDSP"]="jamesdsp" ["EasyEffects"]="easyeffects"
        ["MakeMKV"]="makemkv" ["Kdenlive"]="kdenlive" ["Avidemux"]="avidemux-qt" ["MKVToolNix"]="mkvtoolnix-gui"
    )

    # Checkbox picker for one category; echoes chosen package names. Header
    # goes through gum's own --header, not a plain echo above it — gum
    # choose repaints its draw region on start and would wipe that.
    pick_category() {
        local color="$1" label="$2"; shift 2
        local sel line out=""
        sel=$(printf '%s\n' "$@" | gum choose --no-limit --height 12 \
            --header="-- ${label} --" --header.foreground "$color" \
            --selected-prefix "[x] " --unselected-prefix "[ ] " \
            --selected.foreground "198") || true
        while IFS= read -r line; do
            [[ -n "$line" ]] && out="$out ${PKG_MAP[$line]-}"
        done <<< "$sel"
        echo ""
        echo "$out"
    }

    local browser social dev pass imaging music video wants_lo=""

    browser=$(pick_category 6 "WEB BROWSERS" \
        "Floorp" "Firefox" "Brave" "LibreWolf" "Vivaldi" "Tor Browser" \
        "Mullvad Browser" "Ungoogled Chromium" "FileZilla" "Helium Browser" "Zen Browser")

    social=$(pick_category 2 "SOCIAL & COMMUNICATION" \
        "ZapZap (WhatsApp)" "Discord" "Vesktop" "Telegram" "Ferdium (All-in-one)")

    dev=$(pick_category 5 "DEVELOPMENT TOOLS" \
        "Hugo" "Meld (diff viewer)" "VSCodium" "GitHub Desktop")

    pass=$(pick_category 3 "PASSWORD MANAGERS" \
        "KeePassXC" "Bitwarden" "pass")

    imaging=$(pick_category 4 "CREATIVE & IMAGING" \
        "GIMP" "Krita" "Inkscape")

    music=$(pick_category 1 "MUSIC & AUDIO" \
        "MPV" "Amarok" "Spotify" "Tenacity" "JamesDSP" "EasyEffects")

    video=$(pick_category 2 "VIDEO EDITING" \
        "MakeMKV" "Kdenlive" "Avidemux" "MKVToolNix")

    local office_sel=""
    office_sel=$(printf '%s\n' "LibreOffice" | gum choose --no-limit --height 3 \
        --header="-- OFFICE --" --header.foreground 6 \
        --selected-prefix "[x] " --unselected-prefix "[ ] " \
        --selected.foreground "198") || true
    echo ""
    [[ "$office_sel" == "LibreOffice" ]] && wants_lo="yes"

    CONFIG[extra_browser]="$(echo $browser)"
    CONFIG[extra_social]="$(echo $social)"
    CONFIG[extra_dev]="$(echo $dev)"
    CONFIG[extra_pass]="$(echo $pass)"
    CONFIG[extra_imaging]="$(echo $imaging)"
    CONFIG[extra_music]="$(echo $music)"
    CONFIG[extra_video]="$(echo $video)"
    CONFIG[wants_libreoffice]="${wants_lo:-no}"
    CONFIG[lo_locale]=""
    CONFIG[lo_hunspell]=""

    if [[ "${CONFIG[wants_libreoffice]}" == "yes" ]]; then
        echo ""
        show_info "LibreOffice selected — choose your language (UI + spellcheck):"
        echo ""

        local i idx label loc sys_loc
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

        local lang_choice=""
        read -r -p "Enter choice (default: English US): " lang_choice < /dev/tty
        [[ -z "$lang_choice" ]] && lang_choice=2
        if ! [[ "$lang_choice" =~ ^[0-9]+$ ]] || (( lang_choice < 1 || lang_choice > ${#LO_LANG_MENU[@]} )); then
            lang_choice=2
        fi

        local hunspell_selected=""
        IFS='|' read -r _ loc hunspell_selected <<< "${LO_LANG_MENU[$((lang_choice - 1))]}"

        if [[ "$loc" == "SYSTEM" ]]; then
            loc="$(locale 2>/dev/null | awk -F= '/^LANG=/{print $2}' | tr -d '"')"
            loc="${loc:-en_US}"
        elif [[ "$loc" == "CUSTOM" ]]; then
            read -r -p "Enter locale code (examples: en_US, en_GB, fr_FR, es_MX, ru_RU, zh_CN): " loc < /dev/tty
            loc="${loc:-en_US}"
            hunspell_selected=""
        fi

        CONFIG[lo_locale]="$loc"
        CONFIG[lo_hunspell]="$hunspell_selected"
    fi

    echo ""
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Selection Summary:${NC}"
    [[ -n "${CONFIG[extra_browser]}" ]]  && echo -e "  Browsers:    ${CYAN}${CONFIG[extra_browser]}${NC}"
    [[ -n "${CONFIG[extra_social]}" ]]   && echo -e "  Social:      ${CYAN}${CONFIG[extra_social]}${NC}"
    [[ -n "${CONFIG[extra_dev]}" ]]      && echo -e "  Dev Tools:   ${CYAN}${CONFIG[extra_dev]}${NC}"
    [[ -n "${CONFIG[extra_pass]}" ]]     && echo -e "  Passwords:   ${CYAN}${CONFIG[extra_pass]}${NC}"
    [[ -n "${CONFIG[extra_imaging]}" ]]  && echo -e "  Creative:    ${CYAN}${CONFIG[extra_imaging]}${NC}"
    [[ -n "${CONFIG[extra_music]}" ]]    && echo -e "  Music/Audio: ${CYAN}${CONFIG[extra_music]}${NC}"
    [[ -n "${CONFIG[extra_video]}" ]]    && echo -e "  Video:       ${CYAN}${CONFIG[extra_video]}${NC}"
    [[ "${CONFIG[wants_libreoffice]}" == "yes" ]] && echo -e "  LibreOffice: ${CYAN}yes (${CONFIG[lo_locale]})${NC}"
    if [[ -z "${CONFIG[extra_browser]}${CONFIG[extra_social]}${CONFIG[extra_dev]}${CONFIG[extra_pass]}${CONFIG[extra_imaging]}${CONFIG[extra_music]}${CONFIG[extra_video]}" && "${CONFIG[wants_libreoffice]}" != "yes" ]]; then
        echo -e "  ${YELLOW}(no extra packages selected)${NC}"
    fi
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    gum input --placeholder "Press Enter to continue..." --width 50
}

# ────────────────────────────────────────────────────────────────────────────────
# PACMAN HELPERS
# ────────────────────────────────────────────────────────────────────────────────

apply_parallel_downloads() {
    local conf="$1"
    local count="${CONFIG[parallel_downloads]}"
    if grep -q '^#*ParallelDownloads' "$conf"; then
        sed -i "s/^#*ParallelDownloads.*/ParallelDownloads = $count/" "$conf"
    else
        sed -i '/^\[options\]/a ParallelDownloads = '"$count" "$conf"
    fi
}

configure_pacman_options() {
    local conf="$1"
    local simple_opts=(Color ILoveCandy VerbosePkgLists DisableDownloadTimeout)

    for opt in "${simple_opts[@]}"; do
        if grep -q "^#\s*${opt}" "$conf"; then
            sed -i "s/^#\s*${opt}.*/${opt}/" "$conf"
        elif ! grep -q "^${opt}" "$conf"; then
            sed -i '/^\[options\]/a '"${opt}" "$conf"
        fi
    done

    if grep -q '^#*DownloadUser' "$conf"; then
        sed -i 's/^#*DownloadUser.*/DownloadUser = alpm/' "$conf"
    elif ! grep -q '^DownloadUser' "$conf"; then
        sed -i '/^\[options\]/a DownloadUser = alpm' "$conf"
    fi
}

# ────────────────────────────────────────────────────────────────────────────────
# MAIN MENU
# ────────────────────────────────────────────────────────────────────────────────

show_main_menu() {
    while true; do
        clear
        local cols; cols=$(term_cols)
        local box_width=$(( cols - 4 ))
        [[ $box_width -lt 40 ]] && box_width=40

        # Vertically center the WHOLE screen (header + boot mode line +
        # the choose list) as one block, instead of centering the header
        # alone and leaving everything below it pinned under it — header
        # (border 2 + padding 2 + 5 text lines = 9) + boot-mode line (1)
        # + blank (1) + the choose widget's fixed --height 20 = 31.
        print_vpad "$(vpad_for 31)"

        gum style \
            --foreground 212 --border-foreground 212 --border double \
            --align center --width "$box_width" --margin "0 2" --padding "1 2" \
            "✨ $SCRIPT_NAME v$VERSION ✨" \
            "" \
            "Installs XeroLinux exactly as the official ISO does (KDE Plasma)," \
            "with more configuration options than the ISO installer." \
            "For experienced Arch/Linux users. NOT beginner-friendly."

        local boot_mode="BIOS"
        [[ "${CONFIG[uefi]}" == "yes" ]] && boot_mode="UEFI"

        gum style --foreground 245 --align center --width "$cols" \
            "Boot Mode: $boot_mode"
        echo ""

        # Build disk info line for menu display
        local disk_info=""
        if [[ "${CONFIG[partition_mode]}" == "manual" ]]; then
            if [[ -n "${CONFIG[root_part]}" ]]; then
                disk_info="Manual: root=${CONFIG[root_part]}"
                [[ -n "${CONFIG[boot_part]}" ]] && disk_info+=" boot=${CONFIG[boot_part]}"
                disk_info+=" (${CONFIG[filesystem]}"
                [[ "${CONFIG[encrypt]}" == "yes" ]] && disk_info+=", encrypted"
                disk_info+=")"
            else
                disk_info="Manual: Not configured"
            fi
        else
            disk_info="${CONFIG[disk]:-Not configured}"
            if [[ -n "${CONFIG[disk]}" ]]; then
                disk_info+=" (${CONFIG[filesystem]}"
                if [[ "${CONFIG[encrypt]}" == "yes" && "${CONFIG[encrypt_boot]}" == "yes" ]]; then
                    disk_info+=", encrypted root+boot"
                elif [[ "${CONFIG[encrypt]}" == "yes" ]]; then
                    disk_info+=", encrypted root"
                fi
                disk_info+=")"
            fi
        fi

        local kernel_label="None"
        if [[ "${CONFIG[extra_kernel]}" == *"linux-cachyos"* && "${CONFIG[extra_kernel]}" == *"linux-lts"* ]]; then
            kernel_label="CachyOS + LTS"
        elif [[ "${CONFIG[extra_kernel]}" == *"linux-cachyos"* ]]; then
            kernel_label="CachyOS"
        elif [[ "${CONFIG[extra_kernel]}" == *"linux-lts"* ]]; then
            kernel_label="LTS"
        fi

        local extra_pkg_count=0
        for _grp in extra_browser extra_social extra_dev extra_pass extra_imaging extra_music extra_video; do
            [[ -n "${CONFIG[$_grp]}" ]] && (( extra_pkg_count += $(wc -w <<< "${CONFIG[$_grp]}") ))
        done
        [[ "${CONFIG[wants_libreoffice]}" == "yes" ]] && (( extra_pkg_count++ ))
        local extra_pkg_label="None"
        [[ $extra_pkg_count -gt 0 ]] && extra_pkg_label="$extra_pkg_count selected"

        local menu_items=(
            ""
            "1.  Installer Language    │ ${CONFIG[installer_lang]}"
            "2.  Locales               │ ${CONFIG[locale]} / ${CONFIG[keyboard]}"
            "3.  Disk Configuration    │ $disk_info"
            "4.  Swap                  │ ${CONFIG[swap]}"
            "5.  Hostname              │ ${CONFIG[hostname]}"
            "6.  Graphics Driver       │ ${CONFIG[gfx_driver]}"
            "7.  Authentication        │ ${CONFIG[username]:-Not configured}"
            "8.  Timezone              │ ${CONFIG[timezone]}"
            "9.  Parallel Downloads    │ ${CONFIG[parallel_downloads]}"
            "10. AUR Helper            │ ${CONFIG[aur_helper]}"
            "11. Additional Kernel     │ $kernel_label"
            "12. Extra Packages        │ $extra_pkg_label"
            "──────────────────────────────────────────────"
            "13. Start Installation"
            "0.  Exit"
        )

        # gum choose has no alignment/centering flag, but --padding wraps
        # the WHOLE widget (header, every item, footer help text) in a
        # uniform box — unlike padding each item's own text, this also
        # doesn't get stripped off the highlighted cursor line the way
        # manual leading-space padding does (a genuine gum quirk: the
        # cursor line's own leading whitespace gets trimmed, so a manually
        # left-padded item snaps back to column 0 the moment it's
        # selected; verified empirically).
        local max_len=0 item
        for item in "${menu_items[@]}"; do
            [[ ${#item} -gt $max_len ]] && max_len=${#item}
        done
        local block_pad=$(( ($(term_cols) - max_len) / 2 ))
        [[ $block_pad -lt 0 ]] && block_pad=0

        local selection=""
        selection=$(printf '%s\n' "${menu_items[@]}" | gum choose --height 20 \
            --padding "0 $block_pad" --header "Configure your installation:"$'\n') || true

        case "$selection" in
            "1."*)  select_installer_language ;;
            "2."*)  select_locales ;;
            "3."*)  select_partitioning_mode ;;
            "4."*)  configure_swap ;;
            "5."*)  configure_hostname ;;
            "6."*)  select_graphics_driver ;;
            "7."*)  configure_authentication ;;
            "8."*)  select_timezone ;;
            "9."*)  configure_parallel_downloads ;;
            "10."*) select_aur_helper ;;
            "11."*) select_extra_kernel ;;
            "12."*) configure_extra_packages ;;
            "13."*)
                if validate_config; then
                    show_summary
                    local confirm_msg=""
                    if [[ "${CONFIG[partition_mode]}" == "manual" ]]; then
                        confirm_msg="Start installation? ${CONFIG[root_part]} will be formatted as root"
                    else
                        confirm_msg="Start installation? THIS WILL ERASE ${CONFIG[disk]}"
                    fi
                    if confirm_action "$confirm_msg"; then
                        perform_installation
                        break
                    fi
                fi
                ;;
            "0."*)
                if confirm_action "Exit installer?"; then
                    echo "Installation cancelled."
                    exit 0
                fi
                ;;
        esac
    done
}

# ────────────────────────────────────────────────────────────────────────────────
# VALIDATION
# ────────────────────────────────────────────────────────────────────────────────

validate_config() {
    local errors=()

    if [[ "${CONFIG[partition_mode]}" == "manual" ]]; then
        [[ -z "${CONFIG[root_part]}" ]] && errors+=("Root partition not configured (Manual mode)")
        [[ -n "${CONFIG[root_part]}" && ! -b "${CONFIG[root_part]}" ]] && \
            errors+=("Root partition '${CONFIG[root_part]}' is not a valid block device")
        [[ -n "${CONFIG[boot_part]}" && ! -b "${CONFIG[boot_part]}" ]] && \
            errors+=("Boot partition '${CONFIG[boot_part]}' is not a valid block device")
    else
        [[ -z "${CONFIG[disk]}" ]] && errors+=("Disk not configured")
    fi

    [[ -z "${CONFIG[username]}" ]] && errors+=("User account not configured")
    [[ -z "${CONFIG[user_password]}" ]] && errors+=("User password not set")
    [[ -z "${CONFIG[root_password]}" ]] && errors+=("Root password not set")

    if [[ ${#errors[@]} -gt 0 ]]; then
        show_header
        gum style --foreground 196 --bold --margin "1 2" \
            "❌ Configuration Incomplete"
        echo ""
        for error in "${errors[@]}"; do
            show_error "$error"
        done
        echo ""
        gum input --placeholder "Press Enter to continue..." --width 50
        return 1
    fi

    return 0
}

# ────────────────────────────────────────────────────────────────────────────────
# SUMMARY
# ────────────────────────────────────────────────────────────────────────────────

show_summary() {
    show_header
    show_submenu_header "📋 Installation Summary"
    echo ""

    local encrypt_status="No"
    if [[ "${CONFIG[encrypt]}" == "yes" && "${CONFIG[encrypt_boot]}" == "yes" ]]; then
        encrypt_status="Yes (LUKS2, root + boot)"
    elif [[ "${CONFIG[encrypt]}" == "yes" ]]; then
        encrypt_status="Yes (LUKS2, root only)"
    fi

    local boot_mode="BIOS/Legacy"
    [[ "${CONFIG[uefi]}" == "yes" ]] && boot_mode="UEFI"

    local extra_pkg_summary="None"
    local _epc=0 _grp
    for _grp in extra_browser extra_social extra_dev extra_pass extra_imaging extra_music extra_video; do
        [[ -n "${CONFIG[$_grp]}" ]] && (( _epc += $(wc -w <<< "${CONFIG[$_grp]}") ))
    done
    [[ "${CONFIG[wants_libreoffice]}" == "yes" ]] && (( _epc++ ))
    [[ $_epc -gt 0 ]] && extra_pkg_summary="$_epc selected"

    if [[ "${CONFIG[partition_mode]}" == "manual" ]]; then
        local efi_note=""
        [[ "${CONFIG[reuse_efi]}" == "yes" ]] && efi_note=" (reused, not formatted)"
        local boot_line="None (boot on root)"
        [[ -n "${CONFIG[boot_part]}" ]] && boot_line="${CONFIG[boot_part]}$efi_note"

        gum style --border rounded --border-foreground 212 --padding "1 2" --margin "0 2" \
            "Locale:           ${CONFIG[locale]}" \
            "Keyboard:         ${CONFIG[keyboard]}" \
            "Timezone:         ${CONFIG[timezone]}" \
            "Hostname:         ${CONFIG[hostname]}" \
            "" \
            "Username:         ${CONFIG[username]}" \
            "" \
            "Partition mode:   Manual" \
            "Root partition:   ${CONFIG[root_part]}" \
            "Boot partition:   $boot_line" \
            "Filesystem:       ${CONFIG[filesystem]}" \
            "Encryption:       $encrypt_status" \
            "Swap:             ${CONFIG[swap]}" \
            "" \
            "Desktop:          KDE Plasma" \
            "AUR Helper:       ${CONFIG[aur_helper]}" \
            "Graphics:         ${CONFIG[gfx_driver]}" \
            "Boot Mode:        $boot_mode" \
            "Bootloader:       GRUB (on ${CONFIG[disk]})" \
            "Downloads:        ${CONFIG[parallel_downloads]} parallel" \
            "Extra Packages:   $extra_pkg_summary"

        echo ""
        gum style --foreground 196 --bold --margin "0 2" \
            "⚠️  ${CONFIG[root_part]} will be FORMATTED as the root partition!"
        [[ "${CONFIG[reuse_efi]}" != "yes" && -n "${CONFIG[boot_part]}" ]] && \
            gum style --foreground 196 --bold --margin "0 2" \
                "⚠️  ${CONFIG[boot_part]} will be FORMATTED as the boot/EFI partition!"
    else
        gum style --border rounded --border-foreground 212 --padding "1 2" --margin "0 2" \
            "Locale:           ${CONFIG[locale]}" \
            "Keyboard:         ${CONFIG[keyboard]}" \
            "Timezone:         ${CONFIG[timezone]}" \
            "Hostname:         ${CONFIG[hostname]}" \
            "" \
            "Username:         ${CONFIG[username]}" \
            "" \
            "Partition mode:   Auto (whole disk)" \
            "Target Disk:      ${CONFIG[disk]}" \
            "Filesystem:       ${CONFIG[filesystem]}" \
            "Encryption:       $encrypt_status" \
            "Swap:             ${CONFIG[swap]}" \
            "" \
            "Desktop:          KDE Plasma" \
            "AUR Helper:       ${CONFIG[aur_helper]}" \
            "Graphics:         ${CONFIG[gfx_driver]}" \
            "Boot Mode:        $boot_mode" \
            "Bootloader:       GRUB" \
            "Downloads:        ${CONFIG[parallel_downloads]} parallel" \
            "Extra Packages:   $extra_pkg_summary"

        echo ""
        gum style --foreground 196 --bold --margin "0 2" \
            "⚠️  ALL DATA ON ${CONFIG[disk]} WILL BE PERMANENTLY ERASED!"
    fi
    echo ""
}

# ────────────────────────────────────────────────────────────────────────────────
# INSTALLATION
# ────────────────────────────────────────────────────────────────────────────────

install_extra_kernels() {
    # shellcheck disable=SC2086
    arch-chroot "$MOUNTPOINT" pacman -S --needed --noconfirm ${CONFIG[extra_kernel]} \
        || echo "Some extra kernel packages failed — continuing"
    arch-chroot "$MOUNTPOINT" grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || true
}

perform_installation() {
    # Build the ordered step list dynamically based on config, so the
    # percent bar's total always matches what will actually run.
    local step_labels=() step_funcs=()

    step_labels+=("Partitioning disk");            step_funcs+=("partition_disk")
    if [[ "${CONFIG[encrypt]}" == "yes" ]]; then
        step_labels+=("Setting up encryption");    step_funcs+=("setup_encryption")
    fi
    step_labels+=("Formatting partitions");         step_funcs+=("format_partitions")
    step_labels+=("Mounting filesystems");          step_funcs+=("mount_filesystems")
    step_labels+=("Installing base system");        step_funcs+=("install_base_system")
    step_labels+=("Adding repositories");           step_funcs+=("add_repos")
    if [[ -n "${CONFIG[extra_kernel]}" ]]; then
        step_labels+=("Installing additional kernels"); step_funcs+=("install_extra_kernels")
    fi
    step_labels+=("Configuring system");            step_funcs+=("configure_system")
    step_labels+=("Installing GRUB bootloader");    step_funcs+=("install_bootloader")
    step_labels+=("Configuring Btrfs snapshots");   step_funcs+=("setup_snapper")
    step_labels+=("Creating user account");         step_funcs+=("create_user")
    step_labels+=("Installing graphics drivers");   step_funcs+=("install_graphics")
    step_labels+=("Configuring swap");              step_funcs+=("setup_swap_system")
    step_labels+=("Preparing desktop installer");   step_funcs+=("prepare_desktop_installer")

    local total=${#step_labels[@]}
    local i
    for i in "${!step_labels[@]}"; do
        run_step_visual "$((i + 1))" "$total" "${step_labels[$i]}" "${step_funcs[$i]}"
    done

    # Straight into Part 2 (xero-kde.sh) — no banner/pause/gate here, the
    # user already agreed to everything destructive earlier.
    if ! run_desktop_installer; then
        show_header
        gum style --foreground 214 --bold --border double --border-foreground 214 \
            --align center --width 60 --margin "1 2" --padding "1 2" \
            "⚠ Desktop Setup Did Not Complete ⚠" \
            "" \
            "The base system is installed, but the KDE Plasma setup" \
            "script exited early or was cancelled." \
            "" \
            "Reboot into your system and re-run it manually:" \
            "  bash ~/xero-kde.sh"
        return 0
    fi

    show_header
    gum style --foreground 82 --bold --border double --border-foreground 82 \
        --align center --width 60 --margin "1 2" --padding "1 2" \
        "✨ Installation Complete! ✨" \
        "" \
        "Your XeroLinux system is ready!" \
        "" \
        "Remove the installation media and reboot:" \
        "  sudo reboot"
    echo ""
}

# ────────────────────────────────────────────────────────────────────────────────
# DISK OPERATIONS
# ────────────────────────────────────────────────────────────────────────────────

partition_disk() {
    # Manual mode: user already selected partitions — nothing to partition
    [[ "${CONFIG[partition_mode]}" == "manual" ]] && return 0

    local disk="${CONFIG[disk]}"

    # A prior run against this same disk (aborted, retried without reboot)
    # can leave its old partitions mounted under $MOUNTPOINT — the kernel
    # then refuses to re-read the partition table ("... unable to inform
    # the kernel of the change, probably because it/they are in use"),
    # failing `parted mklabel` outright. Clear that state before wiping.
    swapoff -a 2>/dev/null || true
    umount -R "$MOUNTPOINT" 2>/dev/null || true
    [[ -e /dev/mapper/cryptroot ]] && cryptsetup close cryptroot 2>/dev/null || true

    [[ -n "$disk" ]] || { echo "ERROR: CONFIG[disk] is empty"; return 1; }

    wipefs -af "$disk" 2>/dev/null || true
    sgdisk -Z "$disk" &>/dev/null || true

    if [[ "${CONFIG[uefi]}" == "yes" ]]; then
        parted -s "$disk" mklabel gpt
        parted -s "$disk" mkpart ESP fat32 1MiB 2049MiB
        parted -s "$disk" set 1 esp on
        parted -s "$disk" mkpart primary 2049MiB 100%
    elif [[ "${CONFIG[encrypt]}" == "yes" && "${CONFIG[encrypt_boot]}" == "yes" ]]; then
        # BIOS + encrypted boot: single partition, GRUB uses post-MBR gap
        parted -s "$disk" mklabel msdos
        parted -s "$disk" mkpart primary 1MiB 100%
    else
        parted -s "$disk" mklabel msdos
        parted -s "$disk" mkpart primary ext4 1MiB 2049MiB
        parted -s "$disk" set 1 boot on
        parted -s "$disk" mkpart primary 2049MiB 100%
    fi

    # Make sure kernel/udev creates partition nodes (common VM timing issue)
    partprobe "$disk" || true
    udevadm settle
    sleep 1

    if [[ "${CONFIG[encrypt]}" == "yes" && "${CONFIG[encrypt_boot]}" == "yes" && "${CONFIG[uefi]}" != "yes" ]]; then
        # BIOS encrypted boot: single partition, no separate boot
        CONFIG[boot_part]=""
        if [[ "$disk" == *"nvme"* || "$disk" == *"mmcblk"* ]]; then
            CONFIG[root_part]="${disk}p1"
        else
            CONFIG[root_part]="${disk}1"
        fi
    else
        if [[ "$disk" == *"nvme"* || "$disk" == *"mmcblk"* ]]; then
            CONFIG[boot_part]="${disk}p1"
            CONFIG[root_part]="${disk}p2"
        else
            CONFIG[boot_part]="${disk}1"
            CONFIG[root_part]="${disk}2"
        fi
    fi

    # Validate partitions exist as block devices BEFORE formatting
    if [[ -n "${CONFIG[boot_part]}" && ! -b "${CONFIG[boot_part]}" ]]; then
        echo "ERROR: Boot partition not ready after partitioning."
        echo "  boot_part='${CONFIG[boot_part]}' block? no"
        lsblk -f "$disk" || true
        return 1
    fi
    if [[ ! -b "${CONFIG[root_part]}" ]]; then
        echo "ERROR: Root partition not ready after partitioning."
        echo "  root_part='${CONFIG[root_part]}' block? no"
        lsblk -f "$disk" || true
        return 1
    fi
}

setup_encryption() {
    [[ "${CONFIG[encrypt]}" == "yes" ]] || return 0

    [[ -n "${CONFIG[encrypt_password]}" ]] || { echo "ERROR: Encryption enabled but password is empty"; return 1; }
    [[ -b "${CONFIG[root_part]}" ]] || { echo "ERROR: root_part '${CONFIG[root_part]}' is not a block device"; return 1; }

    echo -n "${CONFIG[encrypt_password]}" | cryptsetup luksFormat --type luks2 "${CONFIG[root_part]}" - 2>/dev/null
    echo -n "${CONFIG[encrypt_password]}" | cryptsetup open "${CONFIG[root_part]}" cryptroot -

    CONFIG[root_device]="/dev/mapper/cryptroot"

    [[ -b "${CONFIG[root_device]}" ]] || { echo "ERROR: cryptroot mapper not created"; return 1; }
}

format_partitions() {
    local root_device="${CONFIG[root_part]}"
    [[ "${CONFIG[encrypt]}" == "yes" ]] && root_device="${CONFIG[root_device]}"

    [[ -b "$root_device" ]] || { echo "ERROR: root device '$root_device' is not a block device"; return 1; }

    # Format boot partition (skipped for BIOS encrypted boot or when reusing existing EFI)
    if [[ -n "${CONFIG[boot_part]}" ]]; then
        [[ -b "${CONFIG[boot_part]}" ]] || { echo "ERROR: boot_part '${CONFIG[boot_part]}' is not a block device"; return 1; }

        if [[ "${CONFIG[reuse_efi]}" == "yes" ]]; then
            echo "Reusing existing EFI partition ${CONFIG[boot_part]} — skipping format"
        elif [[ "${CONFIG[uefi]}" == "yes" ]]; then
            wipefs -af "${CONFIG[boot_part]}" &>/dev/null
            mkfs.fat -F32 "${CONFIG[boot_part]}"
        else
            wipefs -af "${CONFIG[boot_part]}" &>/dev/null
            mkfs.ext4 -F "${CONFIG[boot_part]}"
        fi
    fi

    wipefs -af "$root_device" &>/dev/null
    case "${CONFIG[filesystem]}" in
        btrfs) mkfs.btrfs -f "$root_device" ;;
        ext4)  mkfs.ext4 -F "$root_device" ;;
        xfs)   mkfs.xfs -f "$root_device" ;;
        *)     echo "ERROR: Unknown filesystem '${CONFIG[filesystem]}'"; return 1 ;;
    esac
}

mount_filesystems() {
    local root_device="${CONFIG[root_part]}"
    [[ "${CONFIG[encrypt]}" == "yes" ]] && root_device="${CONFIG[root_device]}"

    [[ -b "$root_device" ]] || { echo "ERROR: root device '$root_device' is not a block device"; return 1; }

    if [[ "${CONFIG[filesystem]}" == "btrfs" ]]; then
        mount "$root_device" "$MOUNTPOINT"
        btrfs subvolume create "$MOUNTPOINT/@"
        btrfs subvolume create "$MOUNTPOINT/@home"
        btrfs subvolume create "$MOUNTPOINT/@var"
        btrfs subvolume create "$MOUNTPOINT/@tmp"
        # @snapshots NOT created here — snapper creates /.snapshots as a nested
        # child subvolume of @ in setup_snapper(). A top-level sibling subvolume
        # breaks snapper's subvolume relationship check and prevents snapshot creation.
        umount "$MOUNTPOINT"

        mount -o noatime,compress=zstd,subvol=@ "$root_device" "$MOUNTPOINT"
        mkdir -p "$MOUNTPOINT"/{home,var,tmp,boot}
        mount -o noatime,compress=zstd,subvol=@home "$root_device" "$MOUNTPOINT/home"
        mount -o noatime,compress=zstd,subvol=@var "$root_device" "$MOUNTPOINT/var"
        mount -o noatime,compress=zstd,subvol=@tmp "$root_device" "$MOUNTPOINT/tmp"
    else
        mount "$root_device" "$MOUNTPOINT"
        mkdir -p "$MOUNTPOINT/boot"
    fi

    if [[ "${CONFIG[uefi]}" == "yes" ]]; then
        if [[ "${CONFIG[encrypt]}" == "yes" && "${CONFIG[encrypt_boot]}" == "no" ]]; then
            # UEFI root-only encryption: ESP is /boot so kernel+initramfs stay unencrypted
            mkdir -p "$MOUNTPOINT/boot"
            mount "${CONFIG[boot_part]}" "$MOUNTPOINT/boot"
        else
            # UEFI encrypted boot or no encryption: ESP at /boot/efi
            mkdir -p "$MOUNTPOINT/boot/efi"
            mount "${CONFIG[boot_part]}" "$MOUNTPOINT/boot/efi"
        fi
    elif [[ -n "${CONFIG[boot_part]}" ]]; then
        # BIOS with separate boot partition
        mount "${CONFIG[boot_part]}" "$MOUNTPOINT/boot"
    fi
    # else: BIOS encrypted boot — /boot is a dir on encrypted root, no separate mount
}

# ────────────────────────────────────────────────────────────────────────────────
# SYSTEM INSTALLATION
# ────────────────────────────────────────────────────────────────────────────────

# Import chaotic-aur key with fallback keyservers and retries
import_chaotic_key() {
    local keyid="3056513887B78AEB"
    local keyservers=(
        "keyserver.ubuntu.com"
        "keys.openpgp.org"
        "pgp.mit.edu"
    )
    local imported=0

    for ks in "${keyservers[@]}"; do
        if timeout 20 pacman-key --recv-key "$keyid" --keyserver "$ks" 2>/dev/null; then
            imported=1
            break
        fi
        show_warning "Keyserver $ks failed, trying next..."
    done

    if [[ $imported -eq 0 ]]; then
        show_warning "All keyservers failed — trying hkps fallback..."
        timeout 20 pacman-key --recv-key "$keyid" \
            --keyserver hkps://keyserver.ubuntu.com 2>/dev/null || true
    fi

    pacman-key --lsign-key "$keyid" || true
}

add_temp_repo() {
    sed -i '/^#\[multilib\]/{N;s/#\[multilib\]\n#Include/[multilib]\nInclude/}' /etc/pacman.conf

    if ! grep -q "\[xerolinux\]" /etc/pacman.conf; then
        echo -e '\n[xerolinux]\nSigLevel = Optional TrustAll\nServer = https://repos.xerolinux.xyz/$repo/$arch' >> /etc/pacman.conf
    fi

    if ! grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
        import_chaotic_key
        pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
            || show_warning "chaotic-keyring install failed — repo may not work fully"
        pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' \
            || show_warning "chaotic-mirrorlist install failed"
        # chaotic-aur is a bonus repo — a transient CDN outage on either
        # package above must not wire pacman.conf to a nonexistent Include
        # file, which would hard-fail every subsequent pacman call.
        if [[ -f /etc/pacman.d/chaotic-mirrorlist ]]; then
            echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' >> /etc/pacman.conf
        else
            show_warning "chaotic-mirrorlist missing — skipping chaotic-aur repo for this install"
        fi
    fi

    apply_parallel_downloads /etc/pacman.conf
    configure_pacman_options /etc/pacman.conf
    pacman -Sy || show_warning "pacman -Sy had errors — continuing"
}

install_base_system() {
    add_temp_repo

    # ── Critical base (pacstrap aborts if these fail) ─────────────────────────
    local critical="base base-devel linux linux-headers mkinitcpio-fw linux-atm"

    # Microcode (auto-detect)
    if grep -q "GenuineIntel" /proc/cpuinfo 2>/dev/null; then
        critical+=" intel-ucode"
    elif grep -q "AuthenticAMD" /proc/cpuinfo 2>/dev/null; then
        critical+=" amd-ucode"
    fi

    # Boot & filesystems
    critical+=" grub efibootmgr os-prober grub-hooks update-grub"
    critical+=" btrfs-progs dosfstools e2fsprogs xfsprogs gptfdisk"

    # Base utilities
    critical+=" sudo nano vim git wget curl"

    # Network stack
    critical+=" networkmanager iw iwd ppp lftp ldns avahi samba netctl dhcpcd openssh"
    critical+=" openvpn dnsmasq dhclient openldap nss-mdns smbclient net-tools"
    critical+=" darkhttpd reflector pptpclient cloud-init openconnect traceroute"
    critical+=" b43-fwcutter nm-cloud-setup wireless-regdb wireless_tools wpa_supplicant"
    critical+=" modemmanager-qt openpgp-card-tools xl2tpd"

    # Bluetooth
    critical+=" bluez bluez-libs bluez-utils bluez-tools bluez-hid2hci"

    # Audio (PipeWire)
    critical+=" pipewire wireplumber pipewire-jack pipewire-support lib32-pipewire-jack"
    critical+=" alsa-utils alsa-plugins alsa-firmware pavucontrol-qt libdvdcss"

    # GStreamer
    critical+=" gstreamer gst-libav gst-plugins-bad gst-plugins-base gst-plugins-ugly"
    critical+=" gst-plugins-good gst-plugins-espeak gst-plugin-pipewire"

    # Printing & scanning
    critical+=" cups hplip print-manager scanner-support printer-support"

    # Xorg & input
    critical+=" xorg-apps xorg-xinit xorg-server xorg-xwayland"
    critical+=" libinput xf86-input-void xf86-input-libinput"

    # Install critical packages — abort on failure. --noconfirm is explicit
    # here (not just relying on pacstrap's own default) so nothing can ever
    # block waiting on stdin; stdbuf forces line-buffered output since
    # pacman fully-buffers once it detects stdout isn't a real terminal,
    # which otherwise made output arrive in large delayed chunks instead of
    # scrolling live in the progress display.
    # shellcheck disable=SC2086
    stdbuf -oL -eL pacstrap -K "$MOUNTPOINT" --noconfirm $critical

    # ── Optional packages (failures logged, install continues) ────────────────
    local optional=""

    # Extra input / accessibility
    optional+=" orca onboard xf86-input-evdev iio-sensor-proxy"
    optional+=" game-devices-udev xf86-input-vmmouse xf86-input-synaptics"
    optional+=" xf86-input-elographics"

    # Firmware (some may not apply to all hardware)
    optional+=" fwupd sof-firmware linux-firmware-intel"

    show_info "Installing optional base packages (failures non-fatal)..."
    # shellcheck disable=SC2086
    stdbuf -oL -eL pacstrap -K "$MOUNTPOINT" --noconfirm $optional 2>/dev/null || \
        show_warning "Some optional base packages failed — continuing"

    # Btrfs snapshot support — only when btrfs is selected
    if [[ "${CONFIG[filesystem]}" == "btrfs" ]]; then
        show_info "Installing Btrfs snapshot support..."
        # snap-pac omitted here — its pacman hooks would fire on every package install
        # during the chroot setup phase, creating unwanted snapshots before first login.
        # It gets installed by xero-snapper-init on first boot instead.
        stdbuf -oL -eL pacstrap -K "$MOUNTPOINT" --noconfirm snapper grub-btrfs inotify-tools 2>/dev/null || \
            show_warning "Some Btrfs snapshot packages failed — continuing"
    fi

    genfstab -U "$MOUNTPOINT" >> "$MOUNTPOINT/etc/fstab"
}

add_repos() {
    sed -i '/^#\[multilib\]/{N;s/#\[multilib\]\n#Include/[multilib]\nInclude/}' "$MOUNTPOINT/etc/pacman.conf"

    if ! grep -q "\[xerolinux\]" "$MOUNTPOINT/etc/pacman.conf"; then
        echo -e '\n[xerolinux]\nSigLevel = Optional TrustAll\nServer = https://repos.xerolinux.xyz/$repo/$arch' >> "$MOUNTPOINT/etc/pacman.conf"
    fi

    if ! grep -q "\[chaotic-aur\]" "$MOUNTPOINT/etc/pacman.conf"; then
        local keyid="3056513887B78AEB"
        local keyservers=("keyserver.ubuntu.com" "keys.openpgp.org" "pgp.mit.edu")
        local imported=0

        for ks in "${keyservers[@]}"; do
            if timeout 20 arch-chroot "$MOUNTPOINT" pacman-key --recv-key "$keyid" --keyserver "$ks" 2>/dev/null; then
                imported=1
                break
            fi
            show_warning "Keyserver $ks failed, trying next..."
        done

        [[ $imported -eq 0 ]] && \
            timeout 20 arch-chroot "$MOUNTPOINT" pacman-key --recv-key "$keyid" \
                --keyserver hkps://keyserver.ubuntu.com 2>/dev/null || true

        arch-chroot "$MOUNTPOINT" pacman-key --lsign-key "$keyid" || true

        arch-chroot "$MOUNTPOINT" pacman -U --noconfirm \
            'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
            || show_warning "chaotic-keyring install failed — repo may not work fully"

        arch-chroot "$MOUNTPOINT" pacman -U --noconfirm \
            'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' \
            || show_warning "chaotic-mirrorlist install failed"

        # chaotic-aur is a bonus repo, not required for the install to
        # succeed — a transient CDN outage on either package above (a real
        # 503 from cdn-mirror.chaotic.cx has been observed live) must not
        # wire pacman.conf to an Include file that doesn't exist, which
        # would hard-fail every subsequent `pacman -Sy`/-S for the rest of
        # the install over a repo nobody asked to depend on.
        if [[ -f "$MOUNTPOINT/etc/pacman.d/chaotic-mirrorlist" ]]; then
            echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' >> "$MOUNTPOINT/etc/pacman.conf"
        else
            show_warning "chaotic-mirrorlist missing — skipping chaotic-aur repo for this install"
        fi
    fi

    apply_parallel_downloads "$MOUNTPOINT/etc/pacman.conf"
    configure_pacman_options "$MOUNTPOINT/etc/pacman.conf"
    arch-chroot "$MOUNTPOINT" pacman -Sy || show_warning "pacman -Sy had errors — continuing"
}

configure_system() {
    arch-chroot "$MOUNTPOINT" ln -sf "/usr/share/zoneinfo/${CONFIG[timezone]}" /etc/localtime
    arch-chroot "$MOUNTPOINT" hwclock --systohc

    echo "${CONFIG[locale]} UTF-8" >> "$MOUNTPOINT/etc/locale.gen"
    echo "en_US.UTF-8 UTF-8" >> "$MOUNTPOINT/etc/locale.gen"
    arch-chroot "$MOUNTPOINT" locale-gen
    echo "LANG=${CONFIG[locale]}" > "$MOUNTPOINT/etc/locale.conf"

    echo "KEYMAP=${CONFIG[keyboard]}" > "$MOUNTPOINT/etc/vconsole.conf"

    # Map console keymap names to X11 layout names where they differ
    local xkb_layout="${CONFIG[keyboard]}"
    local xkb_variant=""
    case "${CONFIG[keyboard]}" in
        pt-latin9) xkb_layout="pt" ;;
        br-abnt2)  xkb_layout="br" ;;
        jp106)     xkb_layout="jp" ;;
        dvorak)    xkb_layout="us"; xkb_variant="dvorak" ;;
        colemak)   xkb_layout="us"; xkb_variant="colemak" ;;
    esac

    # X11/Wayland keyboard config — read by systemd-localed (used by KWin via D-Bus)
    mkdir -p "$MOUNTPOINT/etc/X11/xorg.conf.d"
    cat > "$MOUNTPOINT/etc/X11/xorg.conf.d/00-keyboard.conf" << EOF
Section "InputClass"
    Identifier "system-keyboard"
    MatchIsKeyboard "on"
    Option "XkbLayout" "${xkb_layout}"
$([ -n "$xkb_variant" ] && echo "    Option \"XkbVariant\" \"${xkb_variant}\"")
EndSection
EOF

    # Wayland-native XKB env vars — read directly by libxkbcommon / KWin Wayland
    {
        echo "XKB_DEFAULT_LAYOUT=${xkb_layout}"
        [ -n "$xkb_variant" ] && echo "XKB_DEFAULT_VARIANT=${xkb_variant}"
    } >> "$MOUNTPOINT/etc/environment"

    echo "${CONFIG[hostname]}" > "$MOUNTPOINT/etc/hostname"
    cat > "$MOUNTPOINT/etc/hosts" << EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${CONFIG[hostname]}.localdomain ${CONFIG[hostname]}
EOF

    arch-chroot "$MOUNTPOINT" systemctl enable NetworkManager

    # Force NetworkManager to use wpa_supplicant for WiFi (not iwd)
    mkdir -p "$MOUNTPOINT/etc/NetworkManager/conf.d"
    cat > "$MOUNTPOINT/etc/NetworkManager/conf.d/wifi-backend.conf" << EOF
[device]
wifi.backend=wpa_supplicant
EOF

    if [[ "${CONFIG[encrypt]}" == "yes" ]]; then
        sed -i 's/^HOOKS=.*/HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)/' "$MOUNTPOINT/etc/mkinitcpio.conf"
        arch-chroot "$MOUNTPOINT" mkinitcpio -P
    fi
}

install_bootloader() {
    local efi_dir="/boot/efi"

    if [[ "${CONFIG[uefi]}" == "yes" ]]; then
        # Determine EFI directory based on encryption scope
        if [[ "${CONFIG[encrypt]}" == "yes" && "${CONFIG[encrypt_boot]}" == "no" ]]; then
            # Root-only encryption: ESP is /boot
            efi_dir="/boot"
        else
            # Encrypted boot or no encryption: ESP at /boot/efi
            efi_dir="/boot/efi"
        fi

        mkdir -p "$MOUNTPOINT$efi_dir"

        if ! mountpoint -q "$MOUNTPOINT$efi_dir"; then
            mount "${CONFIG[boot_part]}" "$MOUNTPOINT$efi_dir"
        fi

        if [[ "${CONFIG[encrypt_boot]}" == "yes" && "${CONFIG[encrypt]}" == "yes" ]]; then
            # Encrypted boot: GRUB must unlock LUKS to read /boot
            if grep -q '^GRUB_ENABLE_CRYPTODISK=' "$MOUNTPOINT/etc/default/grub"; then
                sed -i 's/^GRUB_ENABLE_CRYPTODISK=.*/GRUB_ENABLE_CRYPTODISK=y/' "$MOUNTPOINT/etc/default/grub"
            else
                echo 'GRUB_ENABLE_CRYPTODISK=y' >> "$MOUNTPOINT/etc/default/grub"
            fi

            if grep -q '^GRUB_PRELOAD_MODULES=' "$MOUNTPOINT/etc/default/grub"; then
                sed -i 's/^GRUB_PRELOAD_MODULES=.*/GRUB_PRELOAD_MODULES="part_gpt part_msdos luks2 cryptodisk gcry_rijndael gcry_sha256"/' \
                    "$MOUNTPOINT/etc/default/grub"
            else
                echo 'GRUB_PRELOAD_MODULES="part_gpt part_msdos luks2 cryptodisk gcry_rijndael gcry_sha256"' >> "$MOUNTPOINT/etc/default/grub"
            fi

            arch-chroot "$MOUNTPOINT" grub-install \
                --target=x86_64-efi \
                --efi-directory="$efi_dir" \
                --bootloader-id=XeroLinux \
                --recheck \
                --modules="part_gpt part_msdos luks2 cryptodisk gcry_rijndael gcry_sha256"
        else
            # Root-only encryption or no encryption: boot is unencrypted
            arch-chroot "$MOUNTPOINT" grub-install \
                --target=x86_64-efi \
                --efi-directory="$efi_dir" \
                --bootloader-id=XeroLinux \
                --recheck
        fi
    else
        # BIOS install
        if [[ "${CONFIG[encrypt_boot]}" == "yes" && "${CONFIG[encrypt]}" == "yes" ]]; then
            # Encrypted boot: GRUB must unlock LUKS to read /boot from encrypted root
            if grep -q '^GRUB_ENABLE_CRYPTODISK=' "$MOUNTPOINT/etc/default/grub"; then
                sed -i 's/^GRUB_ENABLE_CRYPTODISK=.*/GRUB_ENABLE_CRYPTODISK=y/' "$MOUNTPOINT/etc/default/grub"
            else
                echo 'GRUB_ENABLE_CRYPTODISK=y' >> "$MOUNTPOINT/etc/default/grub"
            fi

            if grep -q '^GRUB_PRELOAD_MODULES=' "$MOUNTPOINT/etc/default/grub"; then
                sed -i 's/^GRUB_PRELOAD_MODULES=.*/GRUB_PRELOAD_MODULES="part_gpt part_msdos luks2 cryptodisk gcry_rijndael gcry_sha256"/' \
                    "$MOUNTPOINT/etc/default/grub"
            else
                echo 'GRUB_PRELOAD_MODULES="part_gpt part_msdos luks2 cryptodisk gcry_rijndael gcry_sha256"' >> "$MOUNTPOINT/etc/default/grub"
            fi

            arch-chroot "$MOUNTPOINT" grub-install \
                --target=i386-pc \
                --recheck \
                --modules="part_msdos luks2 cryptodisk gcry_rijndael gcry_sha256" \
                "${CONFIG[disk]}"
        else
            arch-chroot "$MOUNTPOINT" grub-install --target=i386-pc "${CONFIG[disk]}"
        fi
    fi

    # Set default kernel parameters
    sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3 nvme_load=yes"/' \
        "$MOUNTPOINT/etc/default/grub"

    # Set distributor and enable os-prober
    sed -i 's/^GRUB_DISTRIBUTOR=.*/GRUB_DISTRIBUTOR="XeroLinux"/' "$MOUNTPOINT/etc/default/grub"
    sed -i 's/^#*GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=false/' "$MOUNTPOINT/etc/default/grub"

    # If encrypted, set LUKS2 kernel cmdline for sd-encrypt hook
    if [[ "${CONFIG[encrypt]}" == "yes" ]]; then
        local uuid=""
        uuid=$(blkid -s UUID -o value "${CONFIG[root_part]}")
        sed -i "s|^GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX=\"rd.luks.name=${uuid}=cryptroot root=/dev/mapper/cryptroot\"|" \
            "$MOUNTPOINT/etc/default/grub"
    fi

    arch-chroot "$MOUNTPOINT" grub-mkconfig -o /boot/grub/grub.cfg
}

setup_snapper() {
    [[ "${CONFIG[filesystem]}" != "btrfs" ]] && return 0

    show_info "Configuring Snapper for Btrfs..."

    # snapper create-config requires dbus/PolicyKit — not available in a bare chroot.
    # Write the config file and create the subvolume directly instead; functionally
    # identical to what snapper create-config produces.

    # 1. Write snapper config file directly into the mounted system
    mkdir -p "$MOUNTPOINT/etc/snapper/configs"
    cat > "$MOUNTPOINT/etc/snapper/configs/root" << 'SNAPCFG'
SUBVOLUME="/"
FSTYPE="btrfs"
QGROUP=""
SPACE_LIMIT="0.5"
FREE_LIMIT="0.2"
ALLOW_USERS=""
ALLOW_GROUPS=""
SYNC_ACL="no"
BACKGROUND_COMPARISON="yes"
NUMBER_CLEANUP="yes"
NUMBER_MIN_AGE="1800"
NUMBER_LIMIT="50"
NUMBER_LIMIT_IMPORTANT="10"
TIMELINE_CREATE="yes"
TIMELINE_CLEANUP="yes"
TIMELINE_MIN_AGE="1800"
TIMELINE_LIMIT_HOURLY="5"
TIMELINE_LIMIT_DAILY="7"
TIMELINE_LIMIT_WEEKLY="0"
TIMELINE_LIMIT_MONTHLY="0"
TIMELINE_LIMIT_QUARTERLY="0"
TIMELINE_LIMIT_YEARLY="0"
EMPTY_PRE_POST_CLEANUP="yes"
EMPTY_PRE_POST_MIN_AGE="1800"
SNAPCFG

    # 2. Register config name with snapper's conf.d so it knows it exists
    mkdir -p "$MOUNTPOINT/etc/conf.d"
    if [[ -f "$MOUNTPOINT/etc/conf.d/snapper" ]]; then
        sed -i 's/^SNAPPER_CONFIGS=.*/SNAPPER_CONFIGS="root"/' "$MOUNTPOINT/etc/conf.d/snapper"
    else
        echo 'SNAPPER_CONFIGS="root"' > "$MOUNTPOINT/etc/conf.d/snapper"
    fi

    # 3. Create /.snapshots as a btrfs subvolume nested inside @ from the host side —
    #    no dbus needed, no chroot needed, just a direct btrfs command on the mountpoint.
    if ! btrfs subvolume create "$MOUNTPOINT/.snapshots" 2>/dev/null; then
        show_warning "Could not create /.snapshots subvolume — snapshot support may not work"
        return 0
    fi
    chmod 750 "$MOUNTPOINT/.snapshots"

    # 4. Add /.snapshots to fstab so rollbacks don't swallow the snapshots dir.
    #    The subvolume path inside the btrfs pool is @/.snapshots.
    local root_uuid=""
    if [[ "${CONFIG[encrypt]}" == "yes" ]]; then
        root_uuid=$(blkid -s UUID -o value /dev/mapper/cryptroot 2>/dev/null)
    else
        root_uuid=$(blkid -s UUID -o value "${CONFIG[root_part]}" 2>/dev/null)
    fi
    if [[ -n "$root_uuid" ]]; then
        echo "UUID=$root_uuid  /.snapshots  btrfs  noatime,compress=zstd,subvol=@/.snapshots  0  0" \
            >> "$MOUNTPOINT/etc/fstab"
    fi

    # 5. Defer snapper timers + grub-btrfsd to first desktop login via a oneshot service.
    #    Enabling them here (in a bare chroot) causes them to fire before the user's
    #    filesystem is fully settled and before btrfs-assistant is available.
    mkdir -p "$MOUNTPOINT/usr/local/bin"
    cat > "$MOUNTPOINT/usr/local/bin/xero-snapper-init" << 'SNAPINIT'
#!/bin/bash
# Install snap-pac now — its pacman hooks will fire on the NEXT package operation,
# which is the first real user-initiated install, not during system setup.
pacman -S --needed --noconfirm snap-pac
systemctl enable --now snapper-timeline.timer
systemctl enable --now snapper-cleanup.timer
systemctl enable --now grub-btrfsd
touch /var/lib/xero-snapper-initialized
systemctl disable xero-snapper-init.service
SNAPINIT
    chmod +x "$MOUNTPOINT/usr/local/bin/xero-snapper-init"

    cat > "$MOUNTPOINT/etc/systemd/system/xero-snapper-init.service" << 'SVCEOF'
[Unit]
Description=Initialize Snapper timers on first boot (XeroLinux)
ConditionPathExists=!/var/lib/xero-snapper-initialized
After=sysinit.target local-fs.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/xero-snapper-init

[Install]
WantedBy=multi-user.target
SVCEOF

    arch-chroot "$MOUNTPOINT" systemctl enable xero-snapper-init.service 2>/dev/null || true

    show_success "Snapper configured — timers activate on first boot."
}

create_user() {
    echo "root:${CONFIG[root_password]}" | arch-chroot "$MOUNTPOINT" chpasswd

    local groups_to_create="sys network scanner power cups realtime sambashare rfkill lp users video storage kvm optical audio wheel adm falcond"
    for grp in $groups_to_create; do
        arch-chroot "$MOUNTPOINT" groupadd -f "$grp" 2>/dev/null || true
    done

    arch-chroot "$MOUNTPOINT" useradd -m -G sys,network,scanner,power,cups,realtime,sambashare,rfkill,lp,users,video,storage,kvm,optical,audio,wheel,adm,falcond -s /bin/bash "${CONFIG[username]}"
    echo "${CONFIG[username]}:${CONFIG[user_password]}" | arch-chroot "$MOUNTPOINT" chpasswd

    sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' "$MOUNTPOINT/etc/sudoers"
}

install_graphics() {
    local packages=""
    local needs_nvidia_config="no"

    # Base mesa/VM drivers (installed for all configurations)
    local base_drivers="mesa autorandr mesa-utils lib32-mesa xf86-video-qxl xf86-video-fbdev lib32-mesa-utils"

    case "${CONFIG[gfx_driver]}" in
        "intel")
            packages="intel-drv $base_drivers"
            ;;
        "amd")
            packages="amd-drv $base_drivers"
            ;;
        "nvidia-turing")
            packages="libvdpau nvidia-utils opencl-nvidia libvdpau-va-gl nvidia-settings nvidia-open-dkms vulkan-icd-loader lib32-nvidia-utils lib32-opencl-nvidia linux-firmware-nvidia lib32-vulkan-icd-loader $base_drivers"
            needs_nvidia_config="yes"
            ;;
        "nvidia-legacy")
            packages="nvidia-580xx-dkms nvidia-580xx-utils opencl-nvidia-580xx lib32-opencl-nvidia-580xx lib32-nvidia-580xx-utils $base_drivers"
            needs_nvidia_config="yes"
            ;;
        "intel-amd")
            packages="intel-drv amd-drv $base_drivers"
            ;;
        "intel-nvidia-turing")
            packages="intel-drv libvdpau nvidia-utils opencl-nvidia libvdpau-va-gl nvidia-settings nvidia-open-dkms vulkan-icd-loader lib32-nvidia-utils lib32-opencl-nvidia linux-firmware-nvidia lib32-vulkan-icd-loader $base_drivers"
            needs_nvidia_config="yes"
            ;;
        "intel-nvidia-legacy")
            packages="intel-drv nvidia-580xx-dkms nvidia-580xx-utils opencl-nvidia-580xx lib32-opencl-nvidia-580xx lib32-nvidia-580xx-utils $base_drivers"
            needs_nvidia_config="yes"
            ;;
        "amd-nvidia-turing")
            packages="amd-drv libvdpau nvidia-utils opencl-nvidia libvdpau-va-gl nvidia-settings nvidia-open-dkms vulkan-icd-loader lib32-nvidia-utils lib32-opencl-nvidia linux-firmware-nvidia lib32-vulkan-icd-loader $base_drivers"
            needs_nvidia_config="yes"
            ;;
        "amd-nvidia-legacy")
            packages="amd-drv nvidia-580xx-dkms nvidia-580xx-utils opencl-nvidia-580xx lib32-opencl-nvidia-580xx lib32-nvidia-580xx-utils $base_drivers"
            needs_nvidia_config="yes"
            ;;
        "vm")
            packages="$base_drivers xorg-server xorg-xinit"
            # Auto-detect VM type and install appropriate guest utilities
            local vm_type=""
            vm_type=$(systemd-detect-virt 2>/dev/null || echo "unknown")
            case "$vm_type" in
                "qemu"|"kvm")
                    packages+=" spice-vdagent qemu-guest-agent"
                    ;;
                "vmware")
                    packages+=" open-vm-tools"
                    ;;
                "oracle")
                    packages+=" virtualbox-guest-utils"
                    ;;
                *)
                    # Install all if we can't detect
                    packages+=" spice-vdagent qemu-guest-agent open-vm-tools virtualbox-guest-utils"
                    ;;
            esac
            ;;
    esac

    if [[ -n "$packages" ]]; then
        # shellcheck disable=SC2086
        arch-chroot "$MOUNTPOINT" pacman -S --noconfirm --needed $packages \
            || show_warning "Some graphics packages failed — system may still work with basic drivers"
    fi

    if [[ "$needs_nvidia_config" == "yes" ]]; then
        sed -i 's/^MODULES=(\(.*\))/MODULES=(\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' "$MOUNTPOINT/etc/mkinitcpio.conf"
        sed -i 's/MODULES=( /MODULES=(/' "$MOUNTPOINT/etc/mkinitcpio.conf"
        arch-chroot "$MOUNTPOINT" mkinitcpio -P
        sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nvidia_drm.modeset=1 nvidia_drm.fbdev=1"/' "$MOUNTPOINT/etc/default/grub"
        arch-chroot "$MOUNTPOINT" grub-mkconfig -o /boot/grub/grub.cfg
    fi
}

setup_swap_system() {
    case "${CONFIG[swap]}" in
        "zram")
            arch-chroot "$MOUNTPOINT" pacman -S --noconfirm zram-generator
            cat > "$MOUNTPOINT/etc/systemd/zram-generator.conf" << EOF
[zram0]
zram-size = ram / 2
compression-algorithm = ${CONFIG[swap_algo]}
EOF
            ;;
        "file")
            if [[ "${CONFIG[filesystem]}" == "btrfs" ]]; then
                arch-chroot "$MOUNTPOINT" truncate -s 0 /swapfile
                arch-chroot "$MOUNTPOINT" chattr +C /swapfile
                arch-chroot "$MOUNTPOINT" fallocate -l 4G /swapfile
            else
                arch-chroot "$MOUNTPOINT" dd if=/dev/zero of=/swapfile bs=1M count=4096 status=progress
            fi
            arch-chroot "$MOUNTPOINT" chmod 600 /swapfile
            arch-chroot "$MOUNTPOINT" mkswap /swapfile
            echo "/swapfile none swap defaults 0 0" >> "$MOUNTPOINT/etc/fstab"
            ;;
        "none")
            ;;
    esac
}

# ────────────────────────────────────────────────────────────────────────────────
# DESKTOP INSTALLER — xero-kde.sh is always fetched independently (not
# self-copied), so it works whether xero-install.sh runs as a real file or
# piped straight into bash (`curl .../xero-install.sh | bash`).
# ────────────────────────────────────────────────────────────────────────────────

# Overridable for local testing, e.g. XERO_KDE_URL=http://<local-server>/xero-kde.sh
XERO_KDE_URL="${XERO_KDE_URL:-https://xerolinux.xyz/script/xero-install/xero-kde.sh}"
DESKTOP_STATE_FILE_NAME=".xero-desktop-state"

prepare_desktop_installer() {
    local user="${CONFIG[username]}"
    local user_home="$MOUNTPOINT/home/${user}"

    # Fetch fresh every time — a cached /root/xero-kde.sh is only a fallback
    # for when the fetch fails, never preferred over a current copy.
    if ! curl -4 --connect-timeout 5 --max-time 20 -fsSL "$XERO_KDE_URL" -o "${user_home}/xero-kde.sh"; then
        if [[ -f "/root/xero-kde.sh" ]] && ! grep -q "KDE installer placeholder" /root/xero-kde.sh; then
            show_warning "Could not fetch the latest xero-kde.sh — falling back to a cached copy."
            cp /root/xero-kde.sh "${user_home}/xero-kde.sh"
        else
            show_warning "Could not fetch xero-kde.sh — the KDE phase will NOT actually install anything!"
            cat > "${user_home}/xero-kde.sh" << 'KDESCRIPT'
#!/bin/bash
echo "XeroLinux KDE installer placeholder"
echo "Please download the actual script from: https://github.com/xerolinux/xero-scripts"
KDESCRIPT
        fi
    fi
    chmod +x "${user_home}/xero-kde.sh"

    # Extra-package selections from the main menu travel to xero-kde.sh via
    # a small state file, not positional args — several of these are long
    # space-separated package-name strings, which get unwieldy and
    # escape-prone as args. xero-kde.sh sources this itself; every
    # variable it reads has a safe default there even if this file is
    # missing entirely (e.g. someone runs xero-kde.sh standalone).
    {
        printf 'BROWSER=%q\n' "${CONFIG[extra_browser]}"
        printf 'SOCIAL=%q\n' "${CONFIG[extra_social]}"
        printf 'DEV=%q\n' "${CONFIG[extra_dev]}"
        printf 'PASS=%q\n' "${CONFIG[extra_pass]}"
        printf 'IMAGING=%q\n' "${CONFIG[extra_imaging]}"
        printf 'MUSIC=%q\n' "${CONFIG[extra_music]}"
        printf 'VIDEO=%q\n' "${CONFIG[extra_video]}"
        printf 'WANTS_LIBREOFFICE=%q\n' "${CONFIG[wants_libreoffice]}"
        printf 'LO_LOCALE=%q\n' "${CONFIG[lo_locale]}"
        printf 'LO_HUNSPELL=%q\n' "${CONFIG[lo_hunspell]}"
    } > "${user_home}/${DESKTOP_STATE_FILE_NAME}"

    arch-chroot "$MOUNTPOINT" chown "${user}:${user}" \
        "/home/${user}/xero-kde.sh" "/home/${user}/${DESKTOP_STATE_FILE_NAME}"
}

run_desktop_installer() {
    local user="${CONFIG[username]}"
    local user_home="/home/${user}"
    local script_path="${user_home}/xero-kde.sh"

    # No show_header/status line here — it redrew the whole "Xero Arch
    # Installer" branding box for a single frame right before arch-chroot's
    # own exec clears it again for xero-kde.sh's progress screen: a visible
    # flash with nothing readable in it. Silent straight through instead.
    if [[ ! -f "${MOUNTPOINT}${script_path}" ]]; then
        show_error "Desktop script not found at ${script_path}"
        return 1
    fi

    # The placeholder stub exits 0 after two echo lines — without this
    # check it "succeeds" instantly with nothing installed, and the caller
    # shows the same "Installation Complete!" banner as a real run.
    if grep -q "KDE installer placeholder" "${MOUNTPOINT}${script_path}"; then
        show_error "xero-kde.sh could not be fetched — refusing to run the placeholder stub."
        return 1
    fi

    if ! arch-chroot "$MOUNTPOINT" id "$user" &>/dev/null; then
        show_error "User '${user}' does not exist in target system yet."
        return 1
    fi

    arch-chroot "$MOUNTPOINT" chown -R "${user}:${user}" "${user_home}"

    mkdir -p "$MOUNTPOINT/etc/sudoers.d"
    echo "${user} ALL=(ALL:ALL) NOPASSWD: ALL" > "$MOUNTPOINT/etc/sudoers.d/99-xero-installer"
    chmod 0440 "$MOUNTPOINT/etc/sudoers.d/99-xero-installer"

    arch-chroot "$MOUNTPOINT" su -l "$user" -c "bash '${script_path}' '${CONFIG[aur_helper]}' '${CONFIG[filesystem]}'"
    local kde_status=$?

    rm -f "$MOUNTPOINT/etc/sudoers.d/99-xero-installer"

    return "$kde_status"
}

# ────────────────────────────────────────────────────────────────────────────────
# MAIN ENTRY POINT
# ────────────────────────────────────────────────────────────────────────────────

main() {
    show_splash
    check_root
    check_uefi
    # Skip internet/deps check if launched from install.sh (deps already installed)
    if ! command -v gum &>/dev/null; then
        check_internet
        ensure_dependencies
    fi
    show_main_menu
}

main "$@"
