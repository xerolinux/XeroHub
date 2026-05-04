#!/bin/bash
#
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║                   ✨ XeroHyprNoc Installer v1.0 ✨                           ║
# ║                                                                               ║
# ║     A beautiful Arch Linux installer → Hyprland + Noctalia Shell             ║
# ║                                                                               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
#
# Author: XeroLinux Team
# License: GPL-3.0

set -Eeuo pipefail

# ────────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
# ────────────────────────────────────────────────────────────────────────────────

VERSION="1.0"
SCRIPT_NAME="XeroHyprNoc Installer"

# URL for the Hyprland + Noctalia post-install script (runs inside chroot)
XERO_HYPRNOC_URL="https://xerolinux.xyz/script/xero-install/xero-hyprnoc.sh"

# Mountpoint for installation
MOUNTPOINT="/mnt"

# Colors (fallback)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Installation configuration
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

    command -v gum       &>/dev/null || deps_needed+=("gum")
    command -v parted    &>/dev/null || deps_needed+=("parted")
    command -v arch-chroot &>/dev/null || deps_needed+=("arch-install-scripts")
    command -v sgdisk    &>/dev/null || deps_needed+=("gptfdisk")
    command -v mkfs.btrfs &>/dev/null || deps_needed+=("btrfs-progs")
    command -v mkfs.fat  &>/dev/null || deps_needed+=("dosfstools")
    command -v mkfs.ext4 &>/dev/null || deps_needed+=("e2fsprogs")
    command -v mkfs.xfs  &>/dev/null || deps_needed+=("xfsprogs")
    command -v cryptsetup &>/dev/null || deps_needed+=("cryptsetup")
    command -v curl      &>/dev/null || deps_needed+=("curl")

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
        "Arch Linux → Hyprland + Noctalia Shell"
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
# 2. LOCALES
# ────────────────────────────────────────────────────────────────────────────────

select_locales() {
    show_header
    show_submenu_header "🗺️ System Locales"
    echo ""
    show_info "Select your system locale (language & encoding)"
    echo ""

    local locales=(
        "en_US.UTF-8" "en_GB.UTF-8" "de_DE.UTF-8" "fr_FR.UTF-8"
        "es_ES.UTF-8" "it_IT.UTF-8" "pt_BR.UTF-8" "pt_PT.UTF-8"
        "ru_RU.UTF-8" "ja_JP.UTF-8" "ko_KR.UTF-8" "zh_CN.UTF-8"
        "zh_TW.UTF-8" "ar_SA.UTF-8" "pl_PL.UTF-8" "nl_NL.UTF-8"
        "tr_TR.UTF-8" "vi_VN.UTF-8" "sv_SE.UTF-8" "da_DK.UTF-8"
        "fi_FI.UTF-8" "nb_NO.UTF-8" "cs_CZ.UTF-8" "hu_HU.UTF-8"
        "el_GR.UTF-8" "he_IL.UTF-8" "th_TH.UTF-8" "id_ID.UTF-8"
        "uk_UA.UTF-8" "ro_RO.UTF-8"
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
        "us" "uk" "de" "fr" "es" "it" "pt-latin9" "br-abnt2"
        "ru" "pl" "cz" "hu" "se" "no" "dk" "fi" "nl" "be" "ch" "at"
        "jp106" "kr" "ara" "tr" "gr" "il" "latam" "dvorak" "colemak"
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
# 3a. PARTITIONING MODE
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

    gum style --foreground 245 --margin "0 2" \
        "$(lsblk -o NAME,SIZE,FSTYPE,LABEL,TYPE,MOUNTPOINT 2>/dev/null)"
    echo ""

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

        show_header
        show_submenu_header "💾 Manual Partitioning"
        echo ""
        gum style --foreground 245 --margin "0 2" "Updated disk layout:"
        echo ""
        gum style --foreground 245 --margin "0 2" \
            "$(lsblk -o NAME,SIZE,FSTYPE,LABEL,TYPE,MOUNTPOINT 2>/dev/null)"
        echo ""
    fi

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

    # Boot/EFI partition
    echo ""
    if [[ "${CONFIG[uefi]}" == "yes" ]]; then
        show_info "Select EFI System Partition (ESP)"
    else
        show_info "Select boot partition (or skip to keep /boot on root)"
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
        show_info "No separate boot partition — /boot will live on root"
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

    # Root partition
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

    local parent_disk
    parent_disk=$(lsblk -no PKNAME "${CONFIG[root_part]}" 2>/dev/null | head -1)
    if [[ -n "$parent_disk" ]]; then
        CONFIG[disk]="/dev/$parent_disk"
    else
        CONFIG[disk]="${CONFIG[root_part]}"
    fi

    # Filesystem
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

    # Encryption
    echo ""
    show_info "Root Partition Encryption (LUKS2)"
    echo ""

    if confirm_action "Enable encryption on the root partition?"; then
        CONFIG[encrypt]="yes"
        CONFIG[encrypt_boot]="no"

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
# 3c. AUTO DISK SELECTION
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
# 4. SWAP
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
            "intel")              gum style --foreground 245 --margin "0 2" "Packages: intel-drv" ;;
            "amd")                gum style --foreground 245 --margin "0 2" "Packages: amd-drv" ;;
            "nvidia-turing")
                gum style --foreground 245 --margin "0 2" "Packages: nvidia-open-dkms nvidia-utils + extras"
                gum style --foreground 214 --margin "0 2" "⚠ Will configure: mkinitcpio modules + GRUB parameters"
                ;;
            "nvidia-legacy")
                gum style --foreground 245 --margin "0 2" "Packages: nvidia-580xx-dkms nvidia-580xx-utils + extras"
                gum style --foreground 214 --margin "0 2" "⚠ Will configure: mkinitcpio modules + GRUB parameters"
                ;;
            "intel-amd")          gum style --foreground 245 --margin "0 2" "Packages: intel-drv + amd-drv" ;;
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
            "vm")                 gum style --foreground 245 --margin "0 2" "Packages: Mesa + guest utils" ;;
        esac
    fi

    sleep 0.5
}

# ────────────────────────────────────────────────────────────────────────────────
# 7. AUTHENTICATION
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
    show_info "Select the AUR helper to install during Hyprland setup"
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
        show_header

        local boot_mode="BIOS"
        [[ "${CONFIG[uefi]}" == "yes" ]] && boot_mode="UEFI"

        gum style --foreground 245 --margin "0 2" \
            "Boot Mode: $boot_mode"
        echo ""

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
            "1.  🌐 Installer Language   │ ${CONFIG[installer_lang]}"
            "2.  🗺️  Locales              │ ${CONFIG[locale]} / ${CONFIG[keyboard]}"
            "3.  💾 Disk Configuration   │ $disk_info"
            "4.  🔄 Swap                 │ ${CONFIG[swap]}"
            "5.  💻 Hostname             │ ${CONFIG[hostname]}"
            "6.  🎮 Graphics Driver      │ ${CONFIG[gfx_driver]}"
            "7.  👤 Authentication       │ ${CONFIG[username]:-Not configured}"
            "8.  🕐 Timezone             │ ${CONFIG[timezone]}"
            "9.  ⚡ Parallel Downloads   │ ${CONFIG[parallel_downloads]}"
            "10. 📦 AUR Helper           │ ${CONFIG[aur_helper]}"
            "─────────────────────────────────────────────"
            "11. ✅ Start Installation"
            "0.  ❌ Exit"
        )

        local selection=""
        selection=$(printf '%s\n' "${menu_items[@]}" | gum choose --height 18 --header $'Configure your installation:\n') || true

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
            "11."*)
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

    [[ -z "${CONFIG[username]}" ]]      && errors+=("User account not configured")
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
            "Desktop:          Hyprland + Noctalia Shell" \
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
            "Desktop:          Hyprland + Noctalia Shell" \
            "Downloads:        ${CONFIG[parallel_downloads]} parallel"

        echo ""
        gum style --foreground 196 --bold --margin "0 2" \
            "⚠️  ALL DATA ON ${CONFIG[disk]} WILL BE PERMANENTLY ERASED!"
    fi
    echo ""
}

# ────────────────────────────────────────────────────────────────────────────────
# INSTALLATION ORCHESTRATION
# ────────────────────────────────────────────────────────────────────────────────

perform_installation() {
    show_header
    gum style --foreground 212 --bold --margin "1 2" \
        "🚀 Starting Installation..."
    echo ""

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

    show_info "Preparing Hyprland + Noctalia installer..."
    prepare_hyprnoc_installer
    show_success "Hyprland installer ready"

    echo ""
    gum style --foreground 82 --bold --border double --border-foreground 82 \
        --align center --width 60 --margin "1 2" --padding "1 2" \
        "🎉 Base Installation Complete! 🎉" \
        "" \
        "The system will now chroot into your new installation" \
        "to run the Hyprland + Noctalia Shell setup script."

    echo ""
    gum input --placeholder "Press Enter to continue to Hyprland installation..."

    run_hyprnoc_installer

    show_header
    gum style --foreground 82 --bold --border double --border-foreground 82 \
        --align center --width 60 --margin "1 2" --padding "1 2" \
        "✨ Installation Complete! ✨" \
        "" \
        "Your XeroHyprNoc system is ready!" \
        "" \
        "Remove the installation media and reboot:" \
        "  sudo reboot"
    echo ""
}

# ────────────────────────────────────────────────────────────────────────────────
# DISK OPERATIONS
# ────────────────────────────────────────────────────────────────────────────────

partition_disk() {
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
        parted -s "$disk" mklabel msdos
        parted -s "$disk" mkpart primary 1MiB 100%
    else
        parted -s "$disk" mklabel msdos
        parted -s "$disk" mkpart primary ext4 1MiB 2049MiB
        parted -s "$disk" set 1 boot on
        parted -s "$disk" mkpart primary 2049MiB 100%
    fi

    partprobe "$disk" || true
    udevadm settle
    sleep 1

    if [[ "${CONFIG[encrypt]}" == "yes" && "${CONFIG[encrypt_boot]}" == "yes" && "${CONFIG[uefi]}" != "yes" ]]; then
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

    if [[ -n "${CONFIG[boot_part]}" && ! -b "${CONFIG[boot_part]}" ]]; then
        echo "ERROR: Boot partition not ready after partitioning."
        lsblk -f "$disk" || true
        exit 1
    fi
    if [[ ! -b "${CONFIG[root_part]}" ]]; then
        echo "ERROR: Root partition not ready after partitioning."
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
        mount -o noatime,compress=zstd,subvol=@var  "$root_device" "$MOUNTPOINT/var"
        mount -o noatime,compress=zstd,subvol=@tmp  "$root_device" "$MOUNTPOINT/tmp"
        mount -o noatime,compress=zstd,subvol=@snapshots "$root_device" "$MOUNTPOINT/.snapshots"
    else
        mount "$root_device" "$MOUNTPOINT"
        mkdir -p "$MOUNTPOINT/boot"
    fi

    if [[ "${CONFIG[uefi]}" == "yes" ]]; then
        if [[ "${CONFIG[encrypt]}" == "yes" && "${CONFIG[encrypt_boot]}" == "no" ]]; then
            mkdir -p "$MOUNTPOINT/boot"
            mount "${CONFIG[boot_part]}" "$MOUNTPOINT/boot"
        else
            mkdir -p "$MOUNTPOINT/boot/efi"
            mount "${CONFIG[boot_part]}" "$MOUNTPOINT/boot/efi"
        fi
    elif [[ -n "${CONFIG[boot_part]}" ]]; then
        mount "${CONFIG[boot_part]}" "$MOUNTPOINT/boot"
    fi
}

# ────────────────────────────────────────────────────────────────────────────────
# BASE SYSTEM INSTALLATION
# ────────────────────────────────────────────────────────────────────────────────

import_chaotic_key() {
    local keyid="3056513887B78AEB"
    local keyservers=("keyserver.ubuntu.com" "keys.openpgp.org" "pgp.mit.edu")
    local imported=0

    for ks in "${keyservers[@]}"; do
        if pacman-key --recv-key "$keyid" --keyserver "$ks" 2>/dev/null; then
            imported=1
            break
        fi
        show_warning "Keyserver $ks failed, trying next..."
    done

    if [[ $imported -eq 0 ]]; then
        show_warning "All keyservers failed — trying hkps fallback..."
        pacman-key --recv-key "$keyid" \
            --keyserver hkps://keyserver.ubuntu.com 2>/dev/null || true
    fi

    pacman-key --lsign-key "$keyid" || true
}

add_temp_repo() {
    # Enable multilib
    sed -i '/^#\[multilib\]/{N;s/#\[multilib\]\n#Include/[multilib]\nInclude/}' /etc/pacman.conf

    # XeroLinux repo on live ISO
    if ! grep -q "\[xerolinux\]" /etc/pacman.conf; then
        echo -e '\n[xerolinux]\nSigLevel = Optional TrustAll\nServer = https://repos.xerolinux.xyz/$repo/$arch' >> /etc/pacman.conf
    fi

    # Chaotic-AUR on live ISO
    if ! grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
        import_chaotic_key
        pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
            || show_warning "chaotic-keyring install failed — repo may not work fully"
        pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' \
            || show_warning "chaotic-mirrorlist install failed"
        echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' >> /etc/pacman.conf
    fi

    apply_parallel_downloads /etc/pacman.conf
    configure_pacman_options /etc/pacman.conf
    pacman -Sy
}

install_base_system() {
    add_temp_repo

    # Critical packages — pacstrap aborts if these fail
    local critical="base base-devel linux linux-headers mkinitcpio-fw linux-atm"

    if grep -q "GenuineIntel" /proc/cpuinfo 2>/dev/null; then
        critical+=" intel-ucode"
    elif grep -q "AuthenticAMD" /proc/cpuinfo 2>/dev/null; then
        critical+=" amd-ucode"
    fi

    critical+=" grub efibootmgr os-prober grub-hooks update-grub"
    critical+=" btrfs-progs dosfstools e2fsprogs xfsprogs gptfdisk"
    critical+=" sudo nano vim git wget curl"
    critical+=" networkmanager iw iwd ppp lftp ldns avahi samba netctl dhcpcd openssh"
    critical+=" openvpn dnsmasq dhclient openldap nss-mdns smbclient net-tools"
    critical+=" darkhttpd reflector pptpclient cloud-init openconnect traceroute"
    critical+=" b43-fwcutter nm-cloud-setup wireless-regdb wireless_tools wpa_supplicant"
    critical+=" modemmanager-qt openpgp-card-tools xl2tpd"
    critical+=" bluez bluez-libs bluez-utils bluez-tools bluez-hid2hci"
    critical+=" pipewire wireplumber pipewire-jack pipewire-support lib32-pipewire-jack"
    critical+=" alsa-utils alsa-plugins alsa-firmware pavucontrol-qt libdvdcss"
    critical+=" gstreamer gst-libav gst-plugins-bad gst-plugins-base gst-plugins-ugly"
    critical+=" gst-plugins-good gst-plugins-espeak gst-plugin-pipewire"
    critical+=" cups hplip print-manager scanner-support printer-support"
    critical+=" xorg-apps xorg-xinit xorg-server xorg-xwayland"
    critical+=" libinput xf86-input-void xf86-input-libinput"

    # shellcheck disable=SC2086
    pacstrap -K "$MOUNTPOINT" $critical

    # Optional packages — failures are non-fatal
    local optional=""
    optional+=" orca onboard xf86-input-evdev iio-sensor-proxy"
    optional+=" game-devices-udev xf86-input-vmmouse xf86-input-synaptics"
    optional+=" xf86-input-elographics"
    optional+=" fwupd sof-firmware linux-firmware-intel"

    show_info "Installing optional base packages (failures non-fatal)..."
    # shellcheck disable=SC2086
    pacstrap -K "$MOUNTPOINT" $optional 2>/dev/null || \
        show_warning "Some optional base packages failed — continuing"

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
            if arch-chroot "$MOUNTPOINT" pacman-key --recv-key "$keyid" --keyserver "$ks" 2>/dev/null; then
                imported=1
                break
            fi
            show_warning "Keyserver $ks failed, trying next..."
        done

        [[ $imported -eq 0 ]] && \
            arch-chroot "$MOUNTPOINT" pacman-key --recv-key "$keyid" \
                --keyserver hkps://keyserver.ubuntu.com 2>/dev/null || true

        arch-chroot "$MOUNTPOINT" pacman-key --lsign-key "$keyid" || true

        arch-chroot "$MOUNTPOINT" pacman -U --noconfirm \
            'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
            || show_warning "chaotic-keyring install failed — repo may not work fully"

        arch-chroot "$MOUNTPOINT" pacman -U --noconfirm \
            'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' \
            || show_warning "chaotic-mirrorlist install failed"

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
    echo "en_US.UTF-8 UTF-8"       >> "$MOUNTPOINT/etc/locale.gen"
    arch-chroot "$MOUNTPOINT" locale-gen
    echo "LANG=${CONFIG[locale]}" > "$MOUNTPOINT/etc/locale.conf"

    echo "KEYMAP=${CONFIG[keyboard]}" > "$MOUNTPOINT/etc/vconsole.conf"

    local xkb_layout="${CONFIG[keyboard]}"
    local xkb_variant=""
    case "${CONFIG[keyboard]}" in
        pt-latin9) xkb_layout="pt" ;;
        br-abnt2)  xkb_layout="br" ;;
        jp106)     xkb_layout="jp" ;;
        dvorak)    xkb_layout="us"; xkb_variant="dvorak" ;;
        colemak)   xkb_layout="us"; xkb_variant="colemak" ;;
    esac

    mkdir -p "$MOUNTPOINT/etc/X11/xorg.conf.d"
    cat > "$MOUNTPOINT/etc/X11/xorg.conf.d/00-keyboard.conf" << EOF
Section "InputClass"
    Identifier "system-keyboard"
    MatchIsKeyboard "on"
    Option "XkbLayout" "${xkb_layout}"
$([ -n "$xkb_variant" ] && echo "    Option \"XkbVariant\" \"${xkb_variant}\"")
EndSection
EOF

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
        if [[ "${CONFIG[encrypt]}" == "yes" && "${CONFIG[encrypt_boot]}" == "no" ]]; then
            efi_dir="/boot"
        else
            efi_dir="/boot/efi"
        fi

        mkdir -p "$MOUNTPOINT$efi_dir"
        if ! mountpoint -q "$MOUNTPOINT$efi_dir"; then
            mount "${CONFIG[boot_part]}" "$MOUNTPOINT$efi_dir"
        fi

        if [[ "${CONFIG[encrypt_boot]}" == "yes" && "${CONFIG[encrypt]}" == "yes" ]]; then
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
            arch-chroot "$MOUNTPOINT" grub-install \
                --target=x86_64-efi \
                --efi-directory="$efi_dir" \
                --bootloader-id=XeroLinux \
                --recheck
        fi
    else
        if [[ "${CONFIG[encrypt_boot]}" == "yes" && "${CONFIG[encrypt]}" == "yes" ]]; then
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

    sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3 nvme_load=yes"/' \
        "$MOUNTPOINT/etc/default/grub"
    sed -i 's/^GRUB_DISTRIBUTOR=.*/GRUB_DISTRIBUTOR="XeroLinux"/' "$MOUNTPOINT/etc/default/grub"
    sed -i 's/^#*GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=false/' "$MOUNTPOINT/etc/default/grub"

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
            local vm_type=""
            vm_type=$(systemd-detect-virt 2>/dev/null || echo "unknown")
            case "$vm_type" in
                "qemu"|"kvm") packages+=" spice-vdagent qemu-guest-agent" ;;
                "vmware")     packages+=" open-vm-tools" ;;
                "oracle")     packages+=" virtualbox-guest-utils" ;;
                *)            packages+=" spice-vdagent qemu-guest-agent open-vm-tools virtualbox-guest-utils" ;;
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
        "none") ;;
    esac
}

# ────────────────────────────────────────────────────────────────────────────────
# HYPRLAND + NOCTALIA INSTALLER
# ────────────────────────────────────────────────────────────────────────────────

prepare_hyprnoc_installer() {
    local user_home="$MOUNTPOINT/home/${CONFIG[username]}"
    local script_dest="${user_home}/xero-hyprnoc.sh"

    # 1. Check if script is alongside this installer (same dir / ISO layout)
    local script_dir
    script_dir="$(dirname "$(readlink -f "$0")")"
    if [[ -f "${script_dir}/xero-hyprnoc.sh" ]]; then
        cp "${script_dir}/xero-hyprnoc.sh" "${script_dest}"
        show_success "Copied local xero-hyprnoc.sh"
    # 2. Try to download from XeroLinux servers
    elif curl -fsSL --connect-timeout 10 "$XERO_HYPRNOC_URL" -o "${script_dest}" 2>/dev/null; then
        show_success "Downloaded xero-hyprnoc.sh from server"
    # 3. Write fully embedded copy — script is self-contained, no network needed
    else
        show_warning "No local copy and download failed — writing embedded xero-hyprnoc.sh"
        write_embedded_hyprnoc "${script_dest}"
    fi

    chmod +x "${script_dest}"
    arch-chroot "$MOUNTPOINT" chown "${CONFIG[username]}:${CONFIG[username]}" "/home/${CONFIG[username]}/xero-hyprnoc.sh"
}

write_embedded_hyprnoc() {
    cat > "$1" << 'XERO_HYPRNOC_SCRIPT_END'
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
    echo -e "  ${BLUE}•${NC} SDDM display manager (default theme)"
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
        network-manager-applet blueman \
        dolphin dolphin-plugins kwrite konsole qalculate-qt

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

BROWSER="" SOCIAL="" DEV="" PASS="" IMAGING="" MUSIC="" VIDEO="" LIBREOFFICE=""

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

install_user_packages() {
    print_header
    print_step "Installing user-selected packages..."
    echo ""
    # Use AUR helper for all — handles both official and AUR packages
    [[ -n "$BROWSER" ]]     && install_aur_group "Browsers"          $BROWSER
    [[ -n "$SOCIAL" ]]      && install_aur_group "Social Apps"       $SOCIAL
    [[ -n "$LIBREOFFICE" ]] && install_aur_group "LibreOffice"       $LIBREOFFICE
    [[ -n "$DEV" ]]         && install_aur_group "Dev Tools"         $DEV
    [[ -n "$PASS" ]]        && install_aur_group "Password Managers" $PASS
    [[ -n "$IMAGING" ]]     && install_group     "Creative Apps"     $IMAGING
    [[ -n "$MUSIC" ]]       && install_aur_group "Music & Audio"     $MUSIC
    [[ -n "$VIDEO" ]]       && install_aur_group "Video Apps"        $VIDEO
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
XERO_HYPRNOC_SCRIPT_END
}

run_hyprnoc_installer() {
    show_header
    gum style --foreground 212 --bold --margin "1 2" \
        "🎨 Running Hyprland + Noctalia Setup (as ${CONFIG[username]})..."
    echo ""

    local user="${CONFIG[username]}"
    local user_home="/home/${user}"
    local script_path="${user_home}/xero-hyprnoc.sh"

    if [[ ! -f "${MOUNTPOINT}${script_path}" ]]; then
        show_error "Hyprland script not found at ${script_path}"
        return 1
    fi

    if ! arch-chroot "$MOUNTPOINT" id "$user" &>/dev/null; then
        show_error "User '${user}' does not exist in target system yet."
        return 1
    fi

    # Ensure correct ownership before script runs
    arch-chroot "$MOUNTPOINT" chown -R "${user}:${user}" "${user_home}"

    # Temporarily allow passwordless sudo inside chroot for package installs
    echo "${user} ALL=(ALL:ALL) NOPASSWD: ALL" > "$MOUNTPOINT/etc/sudoers.d/99-xero-installer"
    chmod 0440 "$MOUNTPOINT/etc/sudoers.d/99-xero-installer"

    # Run as created user — pass AUR helper as $1 (same convention as xero-kde.sh)
    arch-chroot "$MOUNTPOINT" su -l "$user" -c "bash '${script_path}' '${CONFIG[aur_helper]}'"

    # Remove temporary sudo rule
    rm -f "$MOUNTPOINT/etc/sudoers.d/99-xero-installer"
}

# ────────────────────────────────────────────────────────────────────────────────
# MAIN ENTRY POINT
# ────────────────────────────────────────────────────────────────────────────────

main() {
    check_root
    check_uefi
    if ! command -v gum &>/dev/null; then
        check_internet
        ensure_dependencies
    fi
    show_main_menu
}

main "$@"
