#!/bin/bash
#
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║                      ✨ Xero Arch Installer v1.7 ✨                           ║
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

VERSION="1.7"
SCRIPT_NAME="Xero Arch Installer"

# URLs for fetching scripts
XERO_KDE_URL="https://xerolinux.xyz/script/xero-install/xero-kde.sh"

# Mountpoint for installation
MOUNTPOINT="/mnt"

# Colors (fallback)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

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
CONFIG[uefi]="no"
CONFIG[boot_part]=""
CONFIG[root_part]=""
CONFIG[root_device]=""
CONFIG[partition_mode]="auto"
CONFIG[reuse_efi]="no"

# ────────────────────────────────────────────────────────────────────────────────
# ERROR HANDLING
# ────────────────────────────────────────────────────────────────────────────────

have_gum() { command -v gum &>/dev/null; }

on_err() {
    local exit_code=$?
    local line_no=${1:-?}
    local cmd=${2:-?}

    if have_gum; then
        gum style --foreground 196 --bold --margin "1 2" \
            "❌ ERROR (exit=$exit_code) at line $line_no" \
            "$cmd"
        echo ""
        gum style --foreground 245 --margin "0 2" \
            "Tip: If this was during formatting, it's often missing partitions (udev timing) or empty device paths."
        echo ""
        gum input --placeholder "Press Enter to exit..."
    else
        echo -e "${RED}ERROR (exit=$exit_code) at line $line_no${NC}"
        echo -e "${RED}$cmd${NC}"
    fi

    exit "$exit_code"
}

trap 'on_err "$LINENO" "$BASH_COMMAND"' ERR

# ────────────────────────────────────────────────────────────────────────────────
# UTILITY FUNCTIONS
# ────────────────────────────────────────────────────────────────────────────────

# Detect if running in chroot environment
detect_chroot() {
    if [ "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/.)" ] 2>/dev/null; then
        return 0  # In chroot
    elif [ -f /etc/arch-chroot ]; then
        return 0  # In chroot
    elif [ "${EUID:-0}" -eq 0 ] && [ -z "${SUDO_USER:-}" ]; then
        return 0  # Running as root without sudo (likely chroot)
    else
        return 1  # Not in chroot
    fi
}

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

    # Used by this script:
    command -v sgdisk &>/dev/null || deps_needed+=("gptfdisk")
    command -v mkfs.btrfs &>/dev/null || deps_needed+=("btrfs-progs")
    command -v mkfs.fat &>/dev/null || deps_needed+=("dosfstools")
    command -v mkfs.ext4 &>/dev/null || deps_needed+=("e2fsprogs")
    command -v mkfs.xfs &>/dev/null || deps_needed+=("xfsprogs")
    command -v cryptsetup &>/dev/null || deps_needed+=("cryptsetup")
    command -v curl &>/dev/null || deps_needed+=("curl")

    if [[ ${#deps_needed[@]} -gt 0 ]]; then
        echo -e "${CYAN}Installing required dependencies...${NC}"
        pacman -Sy --noconfirm "${deps_needed[@]}" &>/dev/null
    fi
}

# ────────────────────────────────────────────────────────────────────────────────
# GUM UI HELPERS
# ────────────────────────────────────────────────────────────────────────────────

show_header() {
    clear
    gum style \
        --foreground 212 --border-foreground 212 --border double \
        --align center --width 70 --margin "1 2" --padding "1 2" \
        "✨ $SCRIPT_NAME v$VERSION ✨" \
        "" \
        "A beautiful Arch Linux installer for XeroLinux"
}

show_submenu_header() {
    local title="$1"
    gum style \
        --foreground 212 --bold --margin "1 2" \
        "$title"
}

show_info() {
    gum style \
        --foreground 81 --margin "0 2" \
        "$1"
}

show_success() {
    gum style --foreground 82 "  ✓ $1"
}

show_error() {
    gum style --foreground 196 "  ✗ $1"
}

show_warning() {
    gum style --foreground 214 "  ⚠ $1"
}

confirm_action() {
    gum confirm --affirmative "Yes" --negative "No" "$1"
}

run_step() {
    # Runs a function/command in the CURRENT shell (no subshell),
    # so CONFIG changes persist. If it fails, the ERR trap prints details.
    local title="$1"
    shift
    show_info "$title"
    "$@"
    show_success "${title%...}"
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
        gum input --placeholder "Press Enter to continue..."
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
        gum input --placeholder "Press Enter to continue..."
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
        gum input --placeholder "Press Enter to continue..."
        return
    fi

    CONFIG[filesystem]=$(echo "$fs_selection" | awk '{print $1}')
    show_success "Filesystem: ${CONFIG[filesystem]}"

    # ── Encryption ───────────────────────────────────────────────────────────
    echo ""
    show_info "Root Partition Encryption (LUKS2)"
    echo ""

    if confirm_action "Enable encryption on the root partition?"; then
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
        gum input --placeholder "Press Enter to exit..."
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

    if confirm_action "Enable full disk encryption?"; then
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
        show_header

        local boot_mode="BIOS"
        [[ "${CONFIG[uefi]}" == "yes" ]] && boot_mode="UEFI"

        gum style --foreground 245 --margin "0 2" \
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

        local menu_items=(
            ""
            "1. 🌐 Installer Language    │ ${CONFIG[installer_lang]}"
            "2. 🗺️ Locales               │ ${CONFIG[locale]} / ${CONFIG[keyboard]}"
            "3. 💾 Disk Configuration    │ $disk_info"
            "4. 🔄 Swap                  │ ${CONFIG[swap]}"
            "5. 💻 Hostname              │ ${CONFIG[hostname]}"
            "6. 🎮 Graphics Driver       │ ${CONFIG[gfx_driver]}"
            "7. 👤 Authentication        │ ${CONFIG[username]:-Not configured}"
            "8. 🕐 Timezone              │ ${CONFIG[timezone]}"
            "9. ⚡ Parallel Downloads    │ ${CONFIG[parallel_downloads]}"
            "─────────────────────────────────────────────"
            "10. ✅ Start Installation"
            "0.  ❌ Exit"
        )

        local selection=""
        selection=$(printf '%s\n' "${menu_items[@]}" | gum choose --height 16 --header $'Configure your installation:\n') || true

        case "$selection" in
            "1."*) select_installer_language ;;
            "2."*) select_locales ;;
            "3."*) select_partitioning_mode ;;
            "4."*) configure_swap ;;
            "5."*) configure_hostname ;;
            "6."*) select_graphics_driver ;;
            "7."*) configure_authentication ;;
            "8."*) select_timezone ;;
            "9."*) configure_parallel_downloads ;;
            "10."*)
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
        gum input --placeholder "Press Enter to continue..."
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
            "Graphics:         ${CONFIG[gfx_driver]}" \
            "Boot Mode:        $boot_mode" \
            "Bootloader:       GRUB (on ${CONFIG[disk]})" \
            "Downloads:        ${CONFIG[parallel_downloads]} parallel"

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
            "Graphics:         ${CONFIG[gfx_driver]}" \
            "Boot Mode:        $boot_mode" \
            "Bootloader:       GRUB" \
            "Downloads:        ${CONFIG[parallel_downloads]} parallel"

        echo ""
        gum style --foreground 196 --bold --margin "0 2" \
            "⚠️  ALL DATA ON ${CONFIG[disk]} WILL BE PERMANENTLY ERASED!"
    fi
    echo ""
}

# ────────────────────────────────────────────────────────────────────────────────
# INSTALLATION
# ────────────────────────────────────────────────────────────────────────────────

perform_installation() {
    show_header
    gum style --foreground 212 --bold --margin "1 2" \
        "🚀 Starting Installation..."
    echo ""

    # IMPORTANT: run stateful functions in THIS shell (no gum spin subshell).
    run_step "Partitioning disk..." partition_disk

    if [[ "${CONFIG[encrypt]}" == "yes" ]]; then
        run_step "Setting up encryption..." setup_encryption
    fi

    run_step "Formatting partitions..." format_partitions
    run_step "Mounting filesystems..." mount_filesystems

    show_info "Installing base system (this may take a while)..."
    install_base_system
    show_success "Base system installed"

    show_info "Adding XeroLinux and Chaotic-AUR repositories..."
    add_repos
    show_success "Repositories configured"

    run_step "Configuring system..." configure_system
    run_step "Installing GRUB bootloader..." install_bootloader
    run_step "Creating user account..." create_user
    run_step "Installing graphics drivers..." install_graphics
    run_step "Configuring swap..." setup_swap_system

    show_info "Preparing XeroLinux KDE installer..."
    prepare_kde_installer
    show_success "KDE installer ready"

    echo ""
    gum style --foreground 82 --bold --border double --border-foreground 82 \
        --align center --width 60 --margin "1 2" --padding "1 2" \
        "🎉 Base Installation Complete! 🎉" \
        "" \
        "The system will now chroot into your new installation" \
        "to run the XeroLinux KDE setup script."

    echo ""
    gum input --placeholder "Press Enter to continue to KDE installation..."

    run_kde_installer

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

    [[ -n "$disk" ]] || { echo "ERROR: CONFIG[disk] is empty"; exit 1; }

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
        exit 1
    fi
    if [[ ! -b "${CONFIG[root_part]}" ]]; then
        echo "ERROR: Root partition not ready after partitioning."
        echo "  root_part='${CONFIG[root_part]}' block? no"
        lsblk -f "$disk" || true
        exit 1
    fi
}

setup_encryption() {
    [[ "${CONFIG[encrypt]}" == "yes" ]] || return 0

    [[ -n "${CONFIG[encrypt_password]}" ]] || { echo "ERROR: Encryption enabled but password is empty"; exit 1; }
    [[ -b "${CONFIG[root_part]}" ]] || { echo "ERROR: root_part '${CONFIG[root_part]}' is not a block device"; exit 1; }

    echo -n "${CONFIG[encrypt_password]}" | cryptsetup luksFormat --type luks2 "${CONFIG[root_part]}" - 2>/dev/null
    echo -n "${CONFIG[encrypt_password]}" | cryptsetup open "${CONFIG[root_part]}" cryptroot -

    CONFIG[root_device]="/dev/mapper/cryptroot"

    [[ -b "${CONFIG[root_device]}" ]] || { echo "ERROR: cryptroot mapper not created"; exit 1; }
}

format_partitions() {
    local root_device="${CONFIG[root_part]}"
    [[ "${CONFIG[encrypt]}" == "yes" ]] && root_device="${CONFIG[root_device]}"

    [[ -b "$root_device" ]] || { echo "ERROR: root device '$root_device' is not a block device"; exit 1; }

    # Format boot partition (skipped for BIOS encrypted boot or when reusing existing EFI)
    if [[ -n "${CONFIG[boot_part]}" ]]; then
        [[ -b "${CONFIG[boot_part]}" ]] || { echo "ERROR: boot_part '${CONFIG[boot_part]}' is not a block device"; exit 1; }

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
        *)     echo "ERROR: Unknown filesystem '${CONFIG[filesystem]}'"; exit 1 ;;
    esac
}

mount_filesystems() {
    local root_device="${CONFIG[root_part]}"
    [[ "${CONFIG[encrypt]}" == "yes" ]] && root_device="${CONFIG[root_device]}"

    [[ -b "$root_device" ]] || { echo "ERROR: root device '$root_device' is not a block device"; exit 1; }

    if [[ "${CONFIG[filesystem]}" == "btrfs" ]]; then
        mount "$root_device" "$MOUNTPOINT"
        btrfs subvolume create "$MOUNTPOINT/@"
        btrfs subvolume create "$MOUNTPOINT/@home"
        btrfs subvolume create "$MOUNTPOINT/@var"
        btrfs subvolume create "$MOUNTPOINT/@tmp"
        btrfs subvolume create "$MOUNTPOINT/@snapshots"
        umount "$MOUNTPOINT"

        mount -o noatime,compress=zstd,subvol=@ "$root_device" "$MOUNTPOINT"
        mkdir -p "$MOUNTPOINT"/{home,var,tmp,.snapshots,boot}
        mount -o noatime,compress=zstd,subvol=@home "$root_device" "$MOUNTPOINT/home"
        mount -o noatime,compress=zstd,subvol=@var "$root_device" "$MOUNTPOINT/var"
        mount -o noatime,compress=zstd,subvol=@tmp "$root_device" "$MOUNTPOINT/tmp"
        mount -o noatime,compress=zstd,subvol=@snapshots "$root_device" "$MOUNTPOINT/.snapshots"
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

add_temp_repo() {
    # Enable multilib repo on live ISO
    sed -i '/^#\[multilib\]/{N;s/#\[multilib\]\n#Include/[multilib]\nInclude/}' /etc/pacman.conf

    # Temporarily add xerolinux and chaotic-aur repos to live ISO for pacstrap access
    if ! grep -q "\[xerolinux\]" /etc/pacman.conf; then
        echo -e '\n[xerolinux]\nSigLevel = Optional TrustAll\nServer = https://repos.xerolinux.xyz/$repo/$arch' >> /etc/pacman.conf
    fi

    if ! grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
        pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
        pacman-key --lsign-key 3056513887B78AEB
        pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
        pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
        echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' >> /etc/pacman.conf
    fi

    apply_parallel_downloads /etc/pacman.conf
    configure_pacman_options /etc/pacman.conf
    pacman -Sy
}

install_base_system() {
    # Add xerolinux and chaotic-aur repos to live ISO first
    add_temp_repo

    local packages="base base-devel linux mkinitcpio-fw linux-headers linux-atm"

    if grep -q "GenuineIntel" /proc/cpuinfo; then
        packages+=" intel-ucode"
    elif grep -q "AuthenticAMD" /proc/cpuinfo; then
        packages+=" amd-ucode"
    fi

    # Boot & filesystem
    packages+=" grub efibootmgr os-prober grub-hooks update-grub"
    packages+=" btrfs-progs dosfstools e2fsprogs xfsprogs gptfdisk"

    # Base utilities
    packages+=" sudo nano vim git wget curl"

    # Network
    packages+=" networkmanager iw iwd ppp lftp ldns avahi samba netctl dhcpcd openssh"
    packages+=" openvpn dnsmasq dhclient openldap nss-mdns smbclient net-tools"
    packages+=" darkhttpd reflector pptpclient cloud-init openconnect traceroute"
    packages+=" b43-fwcutter nm-cloud-setup wireless-regdb wireless_tools wpa_supplicant"
    packages+=" modemmanager-qt openpgp-card-tools xl2tpd"

    # Bluetooth
    packages+=" bluez bluez-libs bluez-utils bluez-tools bluez-hid2hci"

    # Audio (PipeWire)
    packages+=" pipewire wireplumber pipewire-jack pipewire-support lib32-pipewire-jack"
    packages+=" alsa-utils alsa-plugins alsa-firmware pavucontrol-qt libdvdcss"

    # GStreamer
    packages+=" gstreamer gst-libav gst-plugins-bad gst-plugins-base gst-plugins-ugly"
    packages+=" gst-plugins-good gst-plugins-espeak gst-plugin-pipewire"

    # Printing & scanning
    packages+=" cups hplip print-manager scanner-support printer-support"

    # Input devices & accessibility
    packages+=" orca onboard libinput xf86-input-void xf86-input-evdev iio-sensor-proxy"
    packages+=" game-devices-udev xf86-input-vmmouse xf86-input-libinput xf86-input-synaptics"
    packages+=" xf86-input-elographics"

    # Xorg
    packages+=" xorg-apps xorg-xinit xorg-server xorg-xwayland"

    # Firmware
    packages+=" fwupd mkinitcpio-fw sof-firmware linux-firmware-intel"

    pacstrap -K "$MOUNTPOINT" $packages
    genfstab -U "$MOUNTPOINT" >> "$MOUNTPOINT/etc/fstab"
}

add_repos() {
    sed -i '/^#\[multilib\]/{N;s/#\[multilib\]\n#Include/[multilib]\nInclude/}' "$MOUNTPOINT/etc/pacman.conf"

    if ! grep -q "\[xerolinux\]" "$MOUNTPOINT/etc/pacman.conf"; then
        echo -e '\n[xerolinux]\nSigLevel = Optional TrustAll\nServer = https://repos.xerolinux.xyz/$repo/$arch' >> "$MOUNTPOINT/etc/pacman.conf"
    fi

    if ! grep -q "\[chaotic-aur\]" "$MOUNTPOINT/etc/pacman.conf"; then
        arch-chroot "$MOUNTPOINT" pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
        arch-chroot "$MOUNTPOINT" pacman-key --lsign-key 3056513887B78AEB

        arch-chroot "$MOUNTPOINT" pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
        arch-chroot "$MOUNTPOINT" pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

        echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' >> "$MOUNTPOINT/etc/pacman.conf"
    fi

    apply_parallel_downloads "$MOUNTPOINT/etc/pacman.conf"
    configure_pacman_options "$MOUNTPOINT/etc/pacman.conf"
    arch-chroot "$MOUNTPOINT" pacman -Sy
}

configure_system() {
    arch-chroot "$MOUNTPOINT" ln -sf "/usr/share/zoneinfo/${CONFIG[timezone]}" /etc/localtime
    arch-chroot "$MOUNTPOINT" hwclock --systohc

    echo "${CONFIG[locale]} UTF-8" >> "$MOUNTPOINT/etc/locale.gen"
    echo "en_US.UTF-8 UTF-8" >> "$MOUNTPOINT/etc/locale.gen"
    arch-chroot "$MOUNTPOINT" locale-gen
    echo "LANG=${CONFIG[locale]}" > "$MOUNTPOINT/etc/locale.conf"

    echo "KEYMAP=${CONFIG[keyboard]}" > "$MOUNTPOINT/etc/vconsole.conf"

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
                --removable \
                --recheck \
                --modules="part_gpt part_msdos luks2 cryptodisk gcry_rijndael gcry_sha256"
        else
            # Root-only encryption or no encryption: boot is unencrypted
            arch-chroot "$MOUNTPOINT" grub-install \
                --target=x86_64-efi \
                --efi-directory="$efi_dir" \
                --bootloader-id=XeroLinux \
                --removable \
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

create_user() {
    echo "root:${CONFIG[root_password]}" | arch-chroot "$MOUNTPOINT" chpasswd

    # Create required groups if they don't exist
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
        arch-chroot "$MOUNTPOINT" pacman -S --noconfirm --needed $packages
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
# KDE INSTALLER
# ────────────────────────────────────────────────────────────────────────────────

prepare_kde_installer() {
    if [[ -f "/root/xero-kde.sh" ]]; then
        cp /root/xero-kde.sh "$MOUNTPOINT/home/${CONFIG[username]}/xero-kde.sh"
    else
        curl -fsSL "$XERO_KDE_URL" -o "$MOUNTPOINT/home/${CONFIG[username]}/xero-kde.sh" || {
            cat > "$MOUNTPOINT/home/${CONFIG[username]}/xero-kde.sh" << 'KDESCRIPT'
#!/bin/bash
echo "XeroLinux KDE installer placeholder"
echo "Please download the actual script from: https://github.com/xerolinux/xero-scripts"
KDESCRIPT
        }
    fi

    chmod +x "$MOUNTPOINT/home/${CONFIG[username]}/xero-kde.sh"
    arch-chroot "$MOUNTPOINT" chown "${CONFIG[username]}:${CONFIG[username]}" "/home/${CONFIG[username]}/xero-kde.sh"
}

run_kde_installer() {
    show_header
    gum style --foreground 212 --bold --margin "1 2" \
        "🎨 Running XeroLinux KDE Setup (as ${CONFIG[username]})..."
    echo ""

    local user="${CONFIG[username]}"
    local user_home="/home/${user}"
    local script_path="${user_home}/xero-kde.sh"

    # Ensure script exists
    if [[ ! -f "${MOUNTPOINT}${script_path}" ]]; then
        show_error "KDE script not found at ${script_path}"
        return 1
    fi

    # Ensure user exists inside chroot
    if ! arch-chroot "$MOUNTPOINT" id "$user" &>/dev/null; then
        show_error "User '${user}' does not exist in target system yet."
        return 1
    fi

    # Ensure correct ownership (avoid root-owned dotfiles/configs)
    arch-chroot "$MOUNTPOINT" chown -R "${user}:${user}" "${user_home}"

    # Temporarily allow passwordless sudo so the KDE script can install packages.
    echo "${user} ALL=(ALL:ALL) NOPASSWD: ALL" > "$MOUNTPOINT/etc/sudoers.d/99-xero-installer"
    chmod 0440 "$MOUNTPOINT/etc/sudoers.d/99-xero-installer"

    # Run as the created user. Use a single su -l (login shell) to set up
    # HOME/USER/XDG correctly, and pass the script path directly — avoids
    # the nested runuser -> bash -lc chain that broke stdin/TTY passthrough.
    arch-chroot "$MOUNTPOINT" su -l "$user" -c "bash '${script_path}'"

    # Remove temporary sudo rule
    rm -f "$MOUNTPOINT/etc/sudoers.d/99-xero-installer"
}

# ────────────────────────────────────────────────────────────────────────────────
# MAIN ENTRY POINT
# ────────────────────────────────────────────────────────────────────────────────

main() {
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
