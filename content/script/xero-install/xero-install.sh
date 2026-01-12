#!/bin/bash
#
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                               ║
# ║                      ✨ Xero Arch Installer v1.0 ✨                           ║
# ║                                                                               ║
# ║          A beautiful, streamlined Arch Linux installer for XeroLinux         ║
# ║                                                                               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
#
# Author: XeroLinux Team
# License: GPL-3.0
#

set -e

# ══════════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════════

VERSION="1.0"
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
CONFIG[encrypt_password]=""
CONFIG[swap]="zram"
CONFIG[swap_algo]="zstd"
CONFIG[gfx_driver]="mesa"
CONFIG[uefi]="no"

# ══════════════════════════════════════════════════════════════════════════════════
# UTILITY FUNCTIONS
# ══════════════════════════════════════════════════════════════════════════════════

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Error: This script must be run as root${NC}"
        echo "Please run: sudo $0"
        exit 1
    fi
}

check_uefi() {
    if [[ -d /sys/firmware/efi/efivars ]]; then
        CONFIG[uefi]="yes"
    else
        CONFIG[uefi]="no"
    fi
}

check_internet() {
    if ! ping -c 1 archlinux.org &>/dev/null; then
        echo -e "${RED}Error: No internet connection${NC}"
        echo "Please connect to the internet and try again."
        exit 1
    fi
}

ensure_dependencies() {
    local deps_needed=()
    
    command -v gum &>/dev/null || deps_needed+=("gum")
    command -v parted &>/dev/null || deps_needed+=("parted")
    command -v arch-chroot &>/dev/null || deps_needed+=("arch-install-scripts")
    
    if [[ ${#deps_needed[@]} -gt 0 ]]; then
        echo -e "${CYAN}Installing required dependencies...${NC}"
        pacman -Sy --noconfirm "${deps_needed[@]}" &>/dev/null
    fi
}

# ══════════════════════════════════════════════════════════════════════════════════
# GUM UI HELPERS
# ══════════════════════════════════════════════════════════════════════════════════

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

run_with_spinner() {
    local msg="$1"
    shift
    gum spin --spinner dot --title "$msg" -- "$@"
}

confirm_action() {
    gum confirm --affirmative "Yes" --negative "No" "$1"
}

# ══════════════════════════════════════════════════════════════════════════════════
# 1. INSTALLER LANGUAGE
# ══════════════════════════════════════════════════════════════════════════════════

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
    
    local selection
    selection=$(printf '%s\n' "${languages[@]}" | gum choose --height 15 --header "Choose language:")
    
    if [[ -n "$selection" ]]; then
        CONFIG[installer_lang]="$selection"
        show_success "Language set to: $selection"
    fi
    
    sleep 0.5
}

# ══════════════════════════════════════════════════════════════════════════════════
# 2. LOCALES (System Language + Keyboard)
# ══════════════════════════════════════════════════════════════════════════════════

select_locales() {
    show_header
    show_submenu_header "🗺️ System Locales"
    echo ""
    
    # System Locale
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
    
    local locale_selection
    locale_selection=$(printf '%s\n' "${locales[@]}" | gum filter --placeholder "Search locale..." --height 12)
    
    if [[ -n "$locale_selection" ]]; then
        CONFIG[locale]="$locale_selection"
        show_success "System locale: $locale_selection"
    fi
    
    echo ""
    
    # Keyboard Layout
    show_info "Select your keyboard layout"
    echo ""
    
    # Common keyboard layouts
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
    
    local kb_selection
    kb_selection=$(printf '%s\n' "${keyboards[@]}" | gum filter --placeholder "Search keyboard layout..." --height 12)
    
    if [[ -n "$kb_selection" ]]; then
        CONFIG[keyboard]="$kb_selection"
        # Apply keyboard layout immediately for testing
        loadkeys "$kb_selection" 2>/dev/null || true
        show_success "Keyboard layout: $kb_selection"
    fi
    
    sleep 0.5
}

# ══════════════════════════════════════════════════════════════════════════════════
# 3. DISK CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════════

select_disk() {
    show_header
    show_submenu_header "💾 Disk Configuration"
    echo ""
    
    gum style --foreground 196 --bold --margin "0 2" \
        "⚠️  WARNING: The selected disk will be COMPLETELY ERASED!"
    echo ""
    
    show_info "Select the target disk for installation"
    echo ""
    
    # Get available disks
    local disks=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && disks+=("$line")
    done < <(lsblk -dpno NAME,SIZE,MODEL 2>/dev/null | grep -E '^/dev/(sd|nvme|vd|mmcblk)' | sed 's/  */ /g')
    
    if [[ ${#disks[@]} -eq 0 ]]; then
        show_error "No suitable disks found!"
        gum input --placeholder "Press Enter to exit..."
        exit 1
    fi
    
    local disk_selection
    disk_selection=$(printf '%s\n' "${disks[@]}" | gum choose --height 10 --header "Available disks:")
    
    if [[ -n "$disk_selection" ]]; then
        CONFIG[disk]=$(echo "$disk_selection" | awk '{print $1}')
        show_success "Selected disk: ${CONFIG[disk]}"
        
        echo ""
        # Show disk info
        gum style --foreground 245 --margin "0 2" \
            "$(lsblk "${CONFIG[disk]}" 2>/dev/null)"
    fi
    
    echo ""
    
    # Filesystem Selection
    show_info "Select filesystem type"
    echo ""
    
    local filesystems=(
        "btrfs    │ Modern CoW filesystem with snapshots (Recommended)"
        "ext4     │ Traditional reliable filesystem"
        "xfs      │ High-performance filesystem"
    )
    
    local fs_selection
    fs_selection=$(printf '%s\n' "${filesystems[@]}" | gum choose --height 5 --header "Filesystem:")
    
    if [[ -n "$fs_selection" ]]; then
        CONFIG[filesystem]=$(echo "$fs_selection" | awk '{print $1}')
        show_success "Filesystem: ${CONFIG[filesystem]}"
    fi
    
    echo ""
    
    # Encryption Option
    show_info "Disk Encryption (LUKS)"
    echo ""
    
    if confirm_action "Enable full disk encryption?"; then
        CONFIG[encrypt]="yes"
        
        echo ""
        local enc_pass1 enc_pass2
        enc_pass1=$(gum input --password --placeholder "Enter encryption password" --width 50)
        enc_pass2=$(gum input --password --placeholder "Confirm encryption password" --width 50)
        
        if [[ "$enc_pass1" == "$enc_pass2" && -n "$enc_pass1" ]]; then
            CONFIG[encrypt_password]="$enc_pass1"
            show_success "Disk encryption enabled"
        else
            show_error "Passwords don't match or empty. Encryption disabled."
            CONFIG[encrypt]="no"
        fi
    else
        CONFIG[encrypt]="no"
        show_info "Disk encryption disabled"
    fi
    
    sleep 0.5
}

# ══════════════════════════════════════════════════════════════════════════════════
# 4. SWAP CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════════

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
    
    local swap_selection
    swap_selection=$(printf '%s\n' "${swap_options[@]}" | gum choose --height 5 --header "Swap type:")
    
    if [[ -n "$swap_selection" ]]; then
        CONFIG[swap]=$(echo "$swap_selection" | awk '{print $1}')
        show_success "Swap type: ${CONFIG[swap]}"
        
        # If zram, ask for compression algorithm
        if [[ "${CONFIG[swap]}" == "zram" ]]; then
            echo ""
            show_info "Select zram compression algorithm"
            echo ""
            
            local algos=(
                "zstd     │ Best compression ratio (Recommended)"
                "lz4      │ Fastest compression"
                "lzo      │ Balanced speed/ratio"
            )
            
            local algo_selection
            algo_selection=$(printf '%s\n' "${algos[@]}" | gum choose --height 5 --header "Algorithm:")
            
            if [[ -n "$algo_selection" ]]; then
                CONFIG[swap_algo]=$(echo "$algo_selection" | awk '{print $1}')
                show_success "Compression: ${CONFIG[swap_algo]}"
            fi
        fi
    fi
    
    sleep 0.5
}

# ══════════════════════════════════════════════════════════════════════════════════
# 5. HOSTNAME
# ══════════════════════════════════════════════════════════════════════════════════

configure_hostname() {
    show_header
    show_submenu_header "💻 Hostname"
    echo ""
    
    show_info "Enter a hostname for your system"
    show_info "(lowercase letters, numbers, and hyphens only)"
    echo ""
    
    local hostname
    hostname=$(gum input --placeholder "xerolinux" --value "${CONFIG[hostname]}" --width 40 --header "Hostname:")
    
    # Validate hostname
    if [[ "$hostname" =~ ^[a-z][a-z0-9-]*$ && ${#hostname} -le 63 ]]; then
        CONFIG[hostname]="$hostname"
        show_success "Hostname: ${CONFIG[hostname]}"
    else
        show_warning "Invalid hostname, using default: xerolinux"
        CONFIG[hostname]="xerolinux"
    fi
    
    sleep 0.5
}

# ══════════════════════════════════════════════════════════════════════════════════
# 6. GRAPHICS DRIVER
# ══════════════════════════════════════════════════════════════════════════════════

select_graphics_driver() {
    show_header
    show_submenu_header "🎮 Graphics Driver"
    echo ""
    
    # Detect GPU
    local gpu_info=""
    if lspci 2>/dev/null | grep -qi nvidia; then
        gpu_info+="NVIDIA detected. "
    fi
    if lspci 2>/dev/null | grep -qi "amd\|radeon"; then
        gpu_info+="AMD detected. "
    fi
    if lspci 2>/dev/null | grep -qi intel; then
        gpu_info+="Intel detected. "
    fi
    if systemd-detect-virt -q 2>/dev/null; then
        gpu_info+="Virtual Machine detected. "
    fi
    
    if [[ -n "$gpu_info" ]]; then
        gum style --foreground 82 --margin "0 2" "🔍 $gpu_info"
        echo ""
    fi
    
    show_info "Select the graphics driver for your system"
    echo ""
    
    local drivers=(
        "mesa-all        │ All open-source drivers (Safe default)"
        "nvidia-prop     │ NVIDIA proprietary (Best for gaming)"
        "nvidia-open     │ NVIDIA open kernel (Turing+ GPUs)"
        "nvidia-nouveau  │ NVIDIA open-source nouveau"
        "amd             │ AMD/ATI open-source"
        "intel           │ Intel open-source"
        "vm              │ Virtual machine drivers"
    )
    
    local driver_selection
    driver_selection=$(printf '%s\n' "${drivers[@]}" | gum choose --height 10 --header "Graphics driver:")
    
    if [[ -n "$driver_selection" ]]; then
        CONFIG[gfx_driver]=$(echo "$driver_selection" | awk '{print $1}')
        show_success "Graphics driver: ${CONFIG[gfx_driver]}"
        
        # Show packages that will be installed
        echo ""
        local packages=""
        case "${CONFIG[gfx_driver]}" in
            "mesa-all")
                packages="mesa xf86-video-amdgpu xf86-video-ati xf86-video-nouveau vulkan-radeon vulkan-intel vulkan-nouveau"
                ;;
            "nvidia-prop")
                packages="nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings"
                ;;
            "nvidia-open")
                packages="nvidia-open-dkms nvidia-utils lib32-nvidia-utils nvidia-settings"
                ;;
            "nvidia-nouveau")
                packages="mesa xf86-video-nouveau vulkan-nouveau"
                ;;
            "amd")
                packages="mesa xf86-video-amdgpu vulkan-radeon lib32-mesa lib32-vulkan-radeon"
                ;;
            "intel")
                packages="mesa vulkan-intel lib32-mesa lib32-vulkan-intel intel-media-driver"
                ;;
            "vm")
                packages="mesa xf86-video-vmware"
                ;;
        esac
        
        gum style --foreground 245 --margin "0 2" "Packages: $packages"
    fi
    
    sleep 0.5
}

# ══════════════════════════════════════════════════════════════════════════════════
# 7. AUTHENTICATION (Users & Root)
# ══════════════════════════════════════════════════════════════════════════════════

configure_authentication() {
    show_header
    show_submenu_header "👤 User Account Setup"
    echo ""
    
    # Username
    show_info "Create your user account"
    echo ""
    
    local username
    username=$(gum input --placeholder "username" --width 40 --header "Username (lowercase):")
    
    # Validate username
    if [[ ! "$username" =~ ^[a-z_][a-z0-9_-]*$ || ${#username} -gt 32 ]]; then
        show_warning "Invalid username. Using 'user'"
        username="user"
    fi
    CONFIG[username]="$username"
    show_success "Username: ${CONFIG[username]}"
    
    echo ""
    
    # User password
    local user_pass1 user_pass2
    user_pass1=$(gum input --password --placeholder "Password for $username" --width 50)
    user_pass2=$(gum input --password --placeholder "Confirm password" --width 50)
    
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
        local root_pass1 root_pass2
        root_pass1=$(gum input --password --placeholder "Root password" --width 50)
        root_pass2=$(gum input --password --placeholder "Confirm root password" --width 50)
        
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

# ══════════════════════════════════════════════════════════════════════════════════
# 8. TIMEZONE
# ══════════════════════════════════════════════════════════════════════════════════

select_timezone() {
    show_header
    show_submenu_header "🕐 Timezone"
    echo ""
    
    show_info "Select your timezone"
    echo ""
    
    # Get regions
    local regions
    regions=$(find /usr/share/zoneinfo -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | \
              grep -vE '^(\+|posix|right|zoneinfo)$' | sort)
    
    local region
    region=$(echo "$regions" | gum filter --placeholder "Search region..." --height 12 --header "Select region:")
    
    if [[ -n "$region" ]]; then
        # Get cities in region
        local cities
        cities=$(find "/usr/share/zoneinfo/$region" -type f -printf '%f\n' 2>/dev/null | sort)
        
        if [[ -n "$cities" ]]; then
            echo ""
            local city
            city=$(echo "$cities" | gum filter --placeholder "Search city..." --height 12 --header "Select city:")
            
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

# ══════════════════════════════════════════════════════════════════════════════════
# MAIN MENU
# ══════════════════════════════════════════════════════════════════════════════════

show_main_menu() {
    while true; do
        show_header
        
        # Show current configuration status
        local boot_mode="BIOS"
        [[ "${CONFIG[uefi]}" == "yes" ]] && boot_mode="UEFI"
        
        gum style --foreground 245 --margin "0 2" \
            "Boot Mode: $boot_mode"
        echo ""
        
        local menu_items=(
            "1. 🌐 Installer Language    │ ${CONFIG[installer_lang]}"
            "2. 🗺️  Locales               │ ${CONFIG[locale]} / ${CONFIG[keyboard]}"
            "3. 💾 Disk Configuration    │ ${CONFIG[disk]:-Not configured}"
            "4. 🔄 Swap                  │ ${CONFIG[swap]}"
            "5. 💻 Hostname              │ ${CONFIG[hostname]}"
            "6. 🎮 Graphics Driver       │ ${CONFIG[gfx_driver]}"
            "7. 👤 Authentication        │ ${CONFIG[username]:-Not configured}"
            "8. 🕐 Timezone              │ ${CONFIG[timezone]}"
            "─────────────────────────────────────────────"
            "9. ✅ Start Installation"
            "0. ❌ Exit"
        )
        
        local selection
        selection=$(printf '%s\n' "${menu_items[@]}" | gum choose --height 15 --header "Configure your installation:")
        echo ""
        case "$selection" in
            "1."*) select_installer_language ;;
            "2."*) select_locales ;;
            "3."*) select_disk ;;
            "4."*) configure_swap ;;
            "5."*) configure_hostname ;;
            "6."*) select_graphics_driver ;;
            "7."*) configure_authentication ;;
            "8."*) select_timezone ;;
            "9."*) 
                if validate_config; then
                    show_summary
                    if confirm_action "Start installation? THIS WILL ERASE ${CONFIG[disk]}"; then
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

# ══════════════════════════════════════════════════════════════════════════════════
# VALIDATION
# ══════════════════════════════════════════════════════════════════════════════════

validate_config() {
    local errors=()
    
    [[ -z "${CONFIG[disk]}" ]] && errors+=("Disk not configured")
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

# ══════════════════════════════════════════════════════════════════════════════════
# SUMMARY
# ══════════════════════════════════════════════════════════════════════════════════

show_summary() {
    show_header
    show_submenu_header "📋 Installation Summary"
    echo ""
    
    local encrypt_status="No"
    [[ "${CONFIG[encrypt]}" == "yes" ]] && encrypt_status="Yes (LUKS)"
    
    local boot_mode="BIOS/Legacy"
    [[ "${CONFIG[uefi]}" == "yes" ]] && boot_mode="UEFI"
    
    gum style --border rounded --border-foreground 212 --padding "1 2" --margin "0 2" \
        "Locale:           ${CONFIG[locale]}" \
        "Keyboard:         ${CONFIG[keyboard]}" \
        "Timezone:         ${CONFIG[timezone]}" \
        "Hostname:         ${CONFIG[hostname]}" \
        "" \
        "Username:         ${CONFIG[username]}" \
        "" \
        "Target Disk:      ${CONFIG[disk]}" \
        "Filesystem:       ${CONFIG[filesystem]}" \
        "Encryption:       $encrypt_status" \
        "Swap:             ${CONFIG[swap]}" \
        "" \
        "Graphics:         ${CONFIG[gfx_driver]}" \
        "Boot Mode:        $boot_mode" \
        "Bootloader:       GRUB"
    
    echo ""
    gum style --foreground 196 --bold --margin "0 2" \
        "⚠️  ALL DATA ON ${CONFIG[disk]} WILL BE PERMANENTLY ERASED!"
    echo ""
}

# ══════════════════════════════════════════════════════════════════════════════════
# INSTALLATION
# ══════════════════════════════════════════════════════════════════════════════════

perform_installation() {
    show_header
    gum style --foreground 212 --bold --margin "1 2" \
        "🚀 Starting Installation..."
    echo ""
    
    # Step 1: Partition disk
    gum spin --spinner dot --title "Partitioning disk..." -- bash -c "partition_disk"
    show_success "Disk partitioned"
    
    # Step 2: Setup encryption (if enabled)
    if [[ "${CONFIG[encrypt]}" == "yes" ]]; then
        gum spin --spinner dot --title "Setting up encryption..." -- bash -c "setup_encryption"
        show_success "Encryption configured"
    fi
    
    # Step 3: Format partitions
    gum spin --spinner dot --title "Formatting partitions..." -- bash -c "format_partitions"
    show_success "Partitions formatted"
    
    # Step 4: Mount filesystems
    gum spin --spinner dot --title "Mounting filesystems..." -- bash -c "mount_filesystems"
    show_success "Filesystems mounted"
    
    # Step 5: Install base system
    show_info "Installing base system (this may take a while)..."
    install_base_system
    show_success "Base system installed"
    
    # Step 6: Configure system
    gum spin --spinner dot --title "Configuring system..." -- bash -c "configure_system"
    show_success "System configured"
    
    # Step 7: Install bootloader
    gum spin --spinner dot --title "Installing GRUB bootloader..." -- bash -c "install_bootloader"
    show_success "Bootloader installed"
    
    # Step 8: Create user
    gum spin --spinner dot --title "Creating user account..." -- bash -c "create_user"
    show_success "User account created"
    
    # Step 9: Install graphics drivers
    gum spin --spinner dot --title "Installing graphics drivers..." -- bash -c "install_graphics"
    show_success "Graphics drivers installed"
    
    # Step 10: Setup swap
    gum spin --spinner dot --title "Configuring swap..." -- bash -c "setup_swap_system"
    show_success "Swap configured"
    
    # Step 11: Download and prepare KDE installer
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
    
    # Run KDE installer in chroot
    run_kde_installer
    
    # Final message
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

# ══════════════════════════════════════════════════════════════════════════════════
# DISK OPERATIONS
# ══════════════════════════════════════════════════════════════════════════════════

partition_disk() {
    local disk="${CONFIG[disk]}"
    
    # Wipe disk
    wipefs -af "$disk" &>/dev/null || true
    sgdisk -Z "$disk" &>/dev/null || true
    
    if [[ "${CONFIG[uefi]}" == "yes" ]]; then
        # GPT for UEFI
        parted -s "$disk" mklabel gpt
        parted -s "$disk" mkpart ESP fat32 1MiB 513MiB
        parted -s "$disk" set 1 esp on
        parted -s "$disk" mkpart primary 513MiB 100%
    else
        # MBR for BIOS
        parted -s "$disk" mklabel msdos
        parted -s "$disk" mkpart primary ext4 1MiB 513MiB
        parted -s "$disk" set 1 boot on
        parted -s "$disk" mkpart primary 513MiB 100%
    fi
    
    sleep 2
    partprobe "$disk"
    sleep 1
    
    # Set partition paths
    if [[ "$disk" == *"nvme"* || "$disk" == *"mmcblk"* ]]; then
        CONFIG[boot_part]="${disk}p1"
        CONFIG[root_part]="${disk}p2"
    else
        CONFIG[boot_part]="${disk}1"
        CONFIG[root_part]="${disk}2"
    fi
}

setup_encryption() {
    if [[ "${CONFIG[encrypt]}" != "yes" ]]; then
        return
    fi
    
    echo -n "${CONFIG[encrypt_password]}" | cryptsetup luksFormat --type luks2 "${CONFIG[root_part]}" -
    echo -n "${CONFIG[encrypt_password]}" | cryptsetup open "${CONFIG[root_part]}" cryptroot -
    
    CONFIG[root_device]="/dev/mapper/cryptroot"
}

format_partitions() {
    local root_device="${CONFIG[root_part]}"
    [[ "${CONFIG[encrypt]}" == "yes" ]] && root_device="/dev/mapper/cryptroot"
    
    # Format boot
    if [[ "${CONFIG[uefi]}" == "yes" ]]; then
        mkfs.fat -F32 "${CONFIG[boot_part]}"
    else
        mkfs.ext4 -F "${CONFIG[boot_part]}"
    fi
    
    # Format root
    case "${CONFIG[filesystem]}" in
        btrfs)
            mkfs.btrfs -f "$root_device"
            ;;
        ext4)
            mkfs.ext4 -F "$root_device"
            ;;
        xfs)
            mkfs.xfs -f "$root_device"
            ;;
    esac
}

mount_filesystems() {
    local root_device="${CONFIG[root_part]}"
    [[ "${CONFIG[encrypt]}" == "yes" ]] && root_device="/dev/mapper/cryptroot"
    
    if [[ "${CONFIG[filesystem]}" == "btrfs" ]]; then
        # Mount and create subvolumes
        mount "$root_device" "$MOUNTPOINT"
        btrfs subvolume create "$MOUNTPOINT/@"
        btrfs subvolume create "$MOUNTPOINT/@home"
        btrfs subvolume create "$MOUNTPOINT/@var"
        btrfs subvolume create "$MOUNTPOINT/@tmp"
        btrfs subvolume create "$MOUNTPOINT/@snapshots"
        umount "$MOUNTPOINT"
        
        # Remount with subvolumes
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
    
    # Mount boot
    if [[ "${CONFIG[uefi]}" == "yes" ]]; then
        mkdir -p "$MOUNTPOINT/boot/efi"
        mount "${CONFIG[boot_part]}" "$MOUNTPOINT/boot/efi"
    else
        mount "${CONFIG[boot_part]}" "$MOUNTPOINT/boot"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════════
# SYSTEM INSTALLATION
# ══════════════════════════════════════════════════════════════════════════════════

install_base_system() {
    # Base packages
    local packages="base base-devel linux linux-firmware linux-headers"
    
    # Add microcode
    if grep -q "GenuineIntel" /proc/cpuinfo; then
        packages+=" intel-ucode"
    elif grep -q "AuthenticAMD" /proc/cpuinfo; then
        packages+=" amd-ucode"
    fi
    
    # Essential packages
    packages+=" grub efibootmgr os-prober"
    packages+=" btrfs-progs dosfstools e2fsprogs"
    packages+=" networkmanager sudo nano vim git wget curl"
    
    pacstrap -K "$MOUNTPOINT" $packages
    
    # Generate fstab
    genfstab -U "$MOUNTPOINT" >> "$MOUNTPOINT/etc/fstab"
}

configure_system() {
    # Timezone
    arch-chroot "$MOUNTPOINT" ln -sf "/usr/share/zoneinfo/${CONFIG[timezone]}" /etc/localtime
    arch-chroot "$MOUNTPOINT" hwclock --systohc
    
    # Locale
    echo "${CONFIG[locale]} UTF-8" >> "$MOUNTPOINT/etc/locale.gen"
    echo "en_US.UTF-8 UTF-8" >> "$MOUNTPOINT/etc/locale.gen"
    arch-chroot "$MOUNTPOINT" locale-gen
    echo "LANG=${CONFIG[locale]}" > "$MOUNTPOINT/etc/locale.conf"
    
    # Keyboard
    echo "KEYMAP=${CONFIG[keyboard]}" > "$MOUNTPOINT/etc/vconsole.conf"
    
    # Hostname
    echo "${CONFIG[hostname]}" > "$MOUNTPOINT/etc/hostname"
    cat > "$MOUNTPOINT/etc/hosts" << EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${CONFIG[hostname]}.localdomain ${CONFIG[hostname]}
EOF
    
    # Enable NetworkManager
    arch-chroot "$MOUNTPOINT" systemctl enable NetworkManager
    
    # Configure mkinitcpio for encryption
    if [[ "${CONFIG[encrypt]}" == "yes" ]]; then
        sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt filesystems fsck)/' "$MOUNTPOINT/etc/mkinitcpio.conf"
        arch-chroot "$MOUNTPOINT" mkinitcpio -P
    fi
}

install_bootloader() {
    if [[ "${CONFIG[uefi]}" == "yes" ]]; then
        arch-chroot "$MOUNTPOINT" grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
    else
        arch-chroot "$MOUNTPOINT" grub-install --target=i386-pc "${CONFIG[disk]}"
    fi
    
    # Configure GRUB for encryption
    if [[ "${CONFIG[encrypt]}" == "yes" ]]; then
        local uuid
        uuid=$(blkid -s UUID -o value "${CONFIG[root_part]}")
        sed -i "s|^GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=$uuid:cryptroot root=/dev/mapper/cryptroot\"|" "$MOUNTPOINT/etc/default/grub"
    fi
    
    arch-chroot "$MOUNTPOINT" grub-mkconfig -o /boot/grub/grub.cfg
}

create_user() {
    # Set root password
    echo "root:${CONFIG[root_password]}" | arch-chroot "$MOUNTPOINT" chpasswd
    
    # Create user
    arch-chroot "$MOUNTPOINT" useradd -m -G wheel,audio,video,storage,optical -s /bin/bash "${CONFIG[username]}"
    echo "${CONFIG[username]}:${CONFIG[user_password]}" | arch-chroot "$MOUNTPOINT" chpasswd
    
    # Enable sudo for wheel group
    sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' "$MOUNTPOINT/etc/sudoers"
}

install_graphics() {
    local packages=""
    
    case "${CONFIG[gfx_driver]}" in
        "mesa-all")
            packages="mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon vulkan-intel lib32-vulkan-intel xf86-video-amdgpu xf86-video-ati xf86-video-nouveau xorg-server xorg-xinit"
            ;;
        "nvidia-prop")
            packages="nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings xorg-server xorg-xinit"
            ;;
        "nvidia-open")
            packages="nvidia-open-dkms nvidia-utils lib32-nvidia-utils nvidia-settings xorg-server xorg-xinit"
            ;;
        "nvidia-nouveau")
            packages="mesa lib32-mesa xf86-video-nouveau vulkan-nouveau xorg-server xorg-xinit"
            ;;
        "amd")
            packages="mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon xf86-video-amdgpu libva-mesa-driver lib32-libva-mesa-driver xorg-server xorg-xinit"
            ;;
        "intel")
            packages="mesa lib32-mesa vulkan-intel lib32-vulkan-intel intel-media-driver xorg-server xorg-xinit"
            ;;
        "vm")
            packages="mesa xf86-video-vmware xorg-server xorg-xinit"
            ;;
    esac
    
    if [[ -n "$packages" ]]; then
        arch-chroot "$MOUNTPOINT" pacman -S --noconfirm --needed $packages
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
            # Create 4GB swap file
            arch-chroot "$MOUNTPOINT" dd if=/dev/zero of=/swapfile bs=1M count=4096 status=progress
            arch-chroot "$MOUNTPOINT" chmod 600 /swapfile
            arch-chroot "$MOUNTPOINT" mkswap /swapfile
            echo "/swapfile none swap defaults 0 0" >> "$MOUNTPOINT/etc/fstab"
            ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════════
# KDE INSTALLER
# ══════════════════════════════════════════════════════════════════════════════════

prepare_kde_installer() {
    # Copy the KDE installer script to the new system
    if [[ -f "/root/xero-kde.sh" ]]; then
        cp /root/xero-kde.sh "$MOUNTPOINT/home/${CONFIG[username]}/xero-kde.sh"
    else
        # Download if not present locally
        curl -fsSL "$XERO_KDE_URL" -o "$MOUNTPOINT/home/${CONFIG[username]}/xero-kde.sh" || {
            # Create a minimal fallback script
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
        "🎨 Running XeroLinux KDE Setup..."
    echo ""
    
    # Run the KDE installer as the new user
    arch-chroot "$MOUNTPOINT" su - "${CONFIG[username]}" -c "bash /home/${CONFIG[username]}/xero-kde.sh"
}

# ══════════════════════════════════════════════════════════════════════════════════
# MAIN ENTRY POINT
# ══════════════════════════════════════════════════════════════════════════════════

main() {
    # Pre-flight checks
    check_root
    check_internet
    ensure_dependencies
    check_uefi
    
    # Show welcome and run main menu
    show_main_menu
}

# Export functions for subshells
export -f partition_disk setup_encryption format_partitions mount_filesystems
export -f install_base_system configure_system install_bootloader create_user
export -f install_graphics setup_swap_system
export CONFIG MOUNTPOINT

# Run main
main "$@"
