#!/bin/bash
#
# Xero Arch Installer - Quick Launch Script
# Run with: curl -fsSL https://xerolinux.xyz/script/xero-install/install.sh | bash
# Or:       bash <(curl -fsSL https://xero.link/install)

set +e

# ── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${PURPLE}"
clear
cat << 'EOF'
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║                       ✨ Xero Arch Installer v2.0.0 ✨                        ║
║                                                                               ║
║          A beautiful, streamlined Arch Linux installer for XeroLinux          ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${CYAN}Installs XeroLinux exactly as the official ISO does (KDE Plasma), with more${NC}"
echo -e "${CYAN}configuration options than the ISO installer offers.${NC}"
echo -e "${YELLOW}Intended for experienced Arch/Linux users. NOT recommended for beginners.${NC}"
echo ""

# ── Preflight Checks ─────────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Error: This script must be run as root${NC}"
    echo ""
    echo "Please run:"
    echo -e "  ${CYAN}sudo bash <(curl -fsSL https://xerolinux.xyz/script/xero-install/install.sh)${NC}"
    exit 1
fi

echo -e "${CYAN}Checking internet connection (might take a bit)...${NC}"
# timeout guards the whole check: ping's own -W only bounds the reply wait,
# not a slow/hanging DNS lookup beforehand (a common cause of multi-minute
# hangs here when a network's IPv6 path is broken but IPv6 is still tried).
if ! timeout 8 ping -4 -c 1 -W 3 xerolinux.xyz &>/dev/null; then
    echo -e "${RED}Error: No internet connection${NC}"
    echo "Please connect to the internet and try again."
    echo ""
    echo "For WiFi, use: iwctl"
    exit 1
fi
echo -e "${GREEN}✓ Internet connected${NC}"

if [[ ! -f /etc/arch-release ]]; then
    echo -e "${RED}Error: This script must be run from the Arch Linux live ISO${NC}"
    exit 1
fi

# ── Dependencies ─────────────────────────────────────────────────────────────
# Skip the pacman sync entirely when every tool is already present (true on
# XeroLinux's own live ISO, which ships these preinstalled) — a `pacman -Sy`
# always refreshes package databases from the mirrorlist even when nothing
# ends up installing, and an unranked/slow mirror there is the other common
# cause of a multi-minute delay right at startup.
DEPS_NEEDED=()
for dep_cmd in gum:gum arch-chroot:arch-install-scripts parted:parted mkfs.fat:dosfstools mkfs.btrfs:btrfs-progs; do
    cmd="${dep_cmd%%:*}"; pkg="${dep_cmd##*:}"
    command -v "$cmd" &>/dev/null || DEPS_NEEDED+=("$pkg")
done
if [[ ${#DEPS_NEEDED[@]} -gt 0 ]]; then
    echo -e "${CYAN}Installing dependencies: ${DEPS_NEEDED[*]}...${NC}"
    pacman -Sy --noconfirm --needed "${DEPS_NEEDED[@]}" &>/dev/null || true
fi
echo -e "${GREEN}✓ Dependencies installed${NC}"

# ── Download Installer ────────────────────────────────────────────────────────
# Temp dir is cleaned up automatically on exit
INSTALL_DIR=$(mktemp -d)
trap 'rm -rf "$INSTALL_DIR"' EXIT
cd "$INSTALL_DIR"

echo -e "${CYAN}Downloading Xero Arch Installer...${NC}"
INSTALLER_URL="https://xerolinux.xyz/script/xero-install/xero-install.sh"
curl -4 --connect-timeout 5 --max-time 20 -fsSL "$INSTALLER_URL" -o xero-install.sh
if [[ ! -s xero-install.sh ]]; then
    echo -e "${RED}Error: Failed to download installer (empty file)${NC}"
    exit 1
fi
chmod +x xero-install.sh
echo -e "${GREEN}✓ Installer downloaded${NC}"

# ── Download KDE Script ───────────────────────────────────────────────────────
# Failure is non-fatal - the main installer will re-fetch if needed
echo -e "${CYAN}Downloading XeroLinux KDE script...${NC}"
# Overridable for local testing, same reasoning as xero-install.sh's XERO_KDE_URL.
KDE_URL="${XERO_KDE_URL:-https://xerolinux.xyz/script/xero-install/xero-kde.sh}"
curl -4 --connect-timeout 5 --max-time 20 -fsSL "$KDE_URL" -o /root/xero-kde.sh 2>/dev/null || {
    echo -e "${CYAN}Note: KDE script will be downloaded during installation${NC}"
}
[[ -f /root/xero-kde.sh ]] && chmod +x /root/xero-kde.sh

echo -e "${GREEN}✓ Ready to install${NC}"

# ── Launch ────────────────────────────────────────────────────────────────────
echo -e "${PURPLE}Starting installer...${NC}"
sleep 1
exec bash xero-install.sh
