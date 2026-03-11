#!/bin/bash
#
# Xero Arch Installer - Quick Launch Script
# 
# Run with: curl -fsSL https://xerolinux.xyz/script/xero-install/install.sh | bash
#
# Or: bash <(curl -fsSL https://xero.link/install)
#

set +e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${PURPLE}"
clear
cat << 'EOF'
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║                        ✨ Xero Arch Installer v1.6 ✨                         ║
║                                                                               ║
║          A beautiful, streamlined Arch Linux installer for XeroLinux          ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Error: This script must be run as root${NC}"
    echo ""
    echo "Please run:"
    echo -e "  ${CYAN}sudo bash <(curl -fsSL https://xerolinux.xyz/script/xero-install/install.sh)${NC}"
    exit 1
fi

# Check for internet connection
echo -e "${CYAN}Checking internet connection (might take a bit)...${NC}"
if ! ping -c 1 -W 3 xerolinux.xyz &>/dev/null; then
    echo -e "${RED}Error: No internet connection${NC}"
    echo "Please connect to the internet and try again."
    echo ""
    echo "For WiFi, use: iwctl"
    exit 1
fi
echo -e "${GREEN}✓ Internet connected${NC}"

# Check if we're on Arch Linux ISO
if [[ ! -f /etc/arch-release ]]; then
    echo -e "${RED}Error: This script must be run from the Arch Linux live ISO${NC}"
    exit 1
fi

# Install dependencies
echo -e "${CYAN}Installing dependencies...${NC}"
pacman -Sy --noconfirm --needed gum arch-install-scripts parted dosfstools btrfs-progs &>/dev/null || true
echo -e "${GREEN}✓ Dependencies installed${NC}"

# Create temp directory with cleanup trap
INSTALL_DIR=$(mktemp -d)
trap 'rm -rf "$INSTALL_DIR"' EXIT
cd "$INSTALL_DIR"

# Download main installer
echo -e "${CYAN}Downloading Xero Arch Installer...${NC}"
INSTALLER_URL="https://xerolinux.xyz/script/xero-install/xero-install.sh"
curl -fsSL "$INSTALLER_URL" -o xero-install.sh
if [[ ! -s xero-install.sh ]]; then
    echo -e "${RED}Error: Failed to download installer (empty file)${NC}"
    exit 1
fi
chmod +x xero-install.sh
echo -e "${GREEN}✓ Installer downloaded${NC}"

# Download KDE script
echo -e "${CYAN}Downloading XeroLinux KDE script...${NC}"
KDE_URL="https://xerolinux.xyz/script/xero-install/xero-kde.sh"
curl -fsSL "$KDE_URL" -o /root/xero-kde.sh 2>/dev/null || {
    echo -e "${CYAN}Note: KDE script will be downloaded during installation${NC}"
}
[[ -f /root/xero-kde.sh ]] && chmod +x /root/xero-kde.sh
echo -e "${GREEN}✓ Ready to install${NC}"

echo ""
echo -e "${PURPLE}Starting installer...${NC}"
sleep 1

# Run the installer
exec bash xero-install.sh
