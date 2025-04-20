#!/usr/bin/env bash

set -eo pipefail
trap 'echo -e "${RED}❌ An error occurred on line $LINENO. Exiting.${RESET}"' ERR

# Colors
RED="\e[31m"
GREEN="\e[32m"
BLUE="\e[34m"
YELLOW="\e[33m"
CYAN="\e[36m"
BOLD="\e[1m"
RESET="\e[0m"

# Banner Functions
print_title() {
  echo -e "${BOLD}${BLUE}"
  cat <<'EOF'
╔══════════════════════════════════════════════════════╗
║                🧩  XERO DE INSTALLER  🧩             ║
╚══════════════════════════════════════════════════════╝
EOF
  echo -e "${RESET}"
}

warning() {
  echo -e "\n${RED}⚠️ This DE is still in Alpha stages — use AT YOUR OWN RISK!${RESET}\n"
}


print_section() {
  local msg="$1"
  echo -e "\n${CYAN}"
  figlet -f small "$msg" 2>/dev/null || echo -e "=== $msg ==="
  echo -e "${RESET}"
}

# Pre-checks
check_vanilla_arch() {
  if ! grep -q '^ID=arch' /etc/os-release || ! [ -f /etc/arch-release ]; then
    echo
    echo -e "${RED}This script is for vanilla Arch Linux only. Exiting.${RESET}"
    exit 1
  fi
}

check_existing_de() {
  local known_de_packages=(
    plasma-desktop gnome-shell xfce4-session hyprland cosmic-session-git
    budgie-desktop cinnamon pantheon-session deepin kde-applications lxqt-session
    sway i3-wm openbox awesome enlightenment mate-session gdm sddm lightdm
  )

  for pkg in "${known_de_packages[@]}"; do
    if pacman -Q "$pkg" &>/dev/null; then
      echo -e "${RED}"
      figlet -f slant "DE Detected" 2>/dev/null || echo "DE Detected"
      echo -e "${RESET}"
      echo -e "${CYAN}${pkg}${RESET} is already installed !"
      echo
      echo -e "${YELLOW}This script is for fresh/clean installs only. Exiting.${RESET}"
      echo
      exit 1
    fi
  done
}

check_vm_environment() {
  local virt
  virt=$(systemd-detect-virt)

  if [[ "$virt" != "none" ]]; then
    echo
    echo -e "\n${YELLOW}🖥️ VM detected — installing guest tools...${RESET}"
    echo -e "\n${YELLOW}⚠️ 3D acceleration recommended for best performance.${RESET}\n"
    sleep 6
    case "$virt" in
      oracle)
        install_packages virtualbox-guest-utils
        ;;
      kvm)
        install_packages qemu-guest-agent spice-vdagent
        ;;
      vmware)
        install_packages xf86-video-vmware open-vm-tools xf86-input-vmmouse
        sudo systemctl enable vmtoolsd.service
        ;;
      microsoft)
        echo -e "${YELLOW}⚠️  WSL detected — GUI support is limited.${RESET}"
        ;;
      *)
        echo -e "${YELLOW}⚠️ Unknown VM type: ${virt}${RESET}"
        ;;
    esac
  fi
}

start_point() {
  if [[ -f /tmp/.xapi_lock ]]; then return; fi

  echo -e "${GREEN}Fetching XeroLinux Toolkit & AUR Helper...${RESET}"

  curl -fsSL https://xerolinux.xyz/script/xapi.sh -o /tmp/xapi.sh || {
    echo -e "${RED}❌ Failed to download xapi.sh. Exiting.${RESET}"
    exit 1
  }

  chmod +x /tmp/xapi.sh

  # Run script in interactive shell with clean stdin/stdout
  bash -i /tmp/xapi.sh

  touch /tmp/.xapi_lock
}

install_packages() {
  local total=$#
  local count=1
  local spinner=("|" "/" "-" "\\")
  local failed_packages=()

  for pkg in "$@"; do
    local i=0

    # Start spinner in background
    (
      while true; do
        echo -ne "\r${CYAN}[${spinner[i]}] Installing ${pkg}...${RESET}"
        i=$(( (i + 1) % 4 ))
        sleep 0.1
      done
    ) &
    SPIN_PID=$!

    # Wait for a moment just to show spinner
    sleep 0.4

    # STOP SPINNER *before* sudo, clear line
    kill $SPIN_PID &>/dev/null
    wait $SPIN_PID 2>/dev/null || true
    echo -ne "\r\033[2K"  # clear spinner line fully

    # Now sudo happens on clean line
    if sudo pacman -S --noconfirm --needed "$pkg" &>/dev/null; then
      echo -e "${GREEN}[✔] Installed ${pkg}${RESET}"
    else
      echo -e "${RED}[✘] Failed ${pkg}${RESET}"
      failed_packages+=("$pkg")
    fi

    ((count++))
  done

  if [[ ${#failed_packages[@]} -gt 0 ]]; then
    echo -e "${RED}The following packages failed to install:${RESET}"
    for pkg in "${failed_packages[@]}"; do
      echo -e "${RED}- $pkg${RESET}"
    done
  fi
}

install_plasma() {
  clear && print_section "KDE Plasma"
  check_vm_environment
  start_point
  install_packages linux-headers nano kf6 power-profiles-daemon jq xmlstarlet unrar zip unzip 7zip qt6-3d qt6-5compat qt6-base qt6-charts qt6-connectivity qt6-declarative qt6-graphs qt6-grpc qt6-httpserver qt6-imageformats qt6-languageserver qt6-location qt6-lottie qt6-multimedia qt6-networkauth qt6-positioning qt6-quick3d qt6-quick3dphysics qt6-quickeffectmaker qt6-quicktimeline qt6-remoteobjects qt6-scxml qt6-sensors qt6-serialbus qt6-serialport qt6-shadertools qt6-speech qt6-svg qt6-tools qt6-translations qt6-virtualkeyboard qt6-wayland qt6-webchannel qt6-webengine qt6-websockets qt6-webview plasma-desktop packagekit-qt6 packagekit dolphin kcron khelpcenter kio-admin ksystemlog breeze plasma-workspace plasma-workspace-wallpapers powerdevil plasma-nm kaccounts-integration kdeplasma-addons plasma-pa plasma-integration plasma-browser-integration plasma-wayland-protocols plasma-systemmonitor kpipewire keysmith krecorder kweather plasmatube plasma-pass ocean-sound-theme qqc2-breeze-style plasma5-integration kdeconnect kdenetwork-filesharing kget kio-extras kio-gdrive kio-zeroconf colord-kde gwenview kamera kcolorchooser kdegraphics-thumbnailers kimagemapeditor kolourpaint okular spectacle svgpart ark kate kcalc kcharselect kdebugsettings kdf kdialog keditbookmarks kfind kgpg konsole markdownpart yakuake audiotube elisa ffmpegthumbs plasmatube dolphin-plugins pim-data-exporter pim-sieve-editor emoji-font gcc-libs glibc icu kauth kbookmarks kcmutils kcodecs kcompletion kconfig kconfigwidgets kcoreaddons kcrash kdbusaddons kdeclarative kglobalaccel kguiaddons ki18n kiconthemes kio kirigami kirigami-addons kitemmodels kitemviews kjobwidgets kmenuedit knewstuff knotifications knotifyconfig kpackage krunner kservice ksvg kwidgetsaddons kwindowsystem kxmlgui libcanberra libksysguard libplasma libx11 libxcb libxcursor libxi libxkbcommon libxkbfile plasma-activities plasma-activities-stats plasma5support polkit polkit-kde-agent qt6-5compat qt6-base qt6-declarative qt6-wayland sdl2 solid sonnet systemsettings wayland xcb-util-keysyms xdg-user-dirs scim extra-cmake-modules intltool wayland-protocols xf86-input-libinput sddm-kcm bluedevil breeze-gtk drkonqi kde-gtk-config kdeplasma-addons kinfocenter kscreen ksshaskpass oxygen oxygen-sounds xdg-desktop-portal-kde breeze-grub flatpak-kcm networkmanager-qt quota-tools qt5-x11extras gpsd pacman-contrib cmake falkon openssh
  echo
  sudo systemctl enable sddm.service power-profiles-daemon.service sshd.service || echo -e "${YELLOW}Warning: sddm not found.${RESET}"
}

install_gnome() {
  check_vm_environment
  start_point
  clear && print_section "GNOME"
  install_packages linux-headers evince extension-manager epiphany gdm gnome-subtitles gnac gmtk gnome-backgrounds gnome-calculator gnome-calendar gnome-characters gnome-clocks gnome-color-manager gnome-connections gnome-terminal-transparency gnome-contacts gnome-control-center gnome-disk-utility gnome-font-viewer gnome-gesture-improvements gnome-keyring gnome-logs gnome-maps gnome-menus gnome-network-displays gnome-remote-desktop gnome-session gnome-settings-daemon gnome-shell gnome-shell-extensions gnome-system-monitor gnome-text-editor gnome-themes-extra gnome-tweaks gnome-user-share gnome-weather grilo-plugins gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-onedrive gvfs-smb gvfs-wsdd loupe nautilus rygel power-profiles-daemon simple-scan snapshot sushi tecla totem xdg-desktop-portal-gnome xdg-user-dirs-gtk nano jq xmlstarlet unrar zip unzip 7zip libadwaita adwaita-fonts adwaita-cursors adwaita-icon-theme adwaita-icon-theme-legacy openssh
  echo
  sudo systemctl enable gdm.service power-profiles-daemon.service sshd.service || echo -e "${YELLOW}Warning: gdm not found.${RESET}"
}

install_xfce() {
  check_vm_environment
  start_point
  clear && print_section "XFCE"
  install_packages linux-headers nano xfce4 epiphany mousepad parole ristretto thunar-archive-plugin thunar-media-tags-plugin xfburn xfce4-artwork xfce4-battery-plugin xfce4-clipman-plugin xfce4-cpufreq-plugin xfce4-cpugraph-plugin xfce4-dict xfce4-diskperf-plugin xfce4-eyes-plugin xfce4-fsguard-plugin xfce4-genmon-plugin xfce4-mailwatch-plugin xfce4-mount-plugin xfce4-mpc-plugin xfce4-netload-plugin xfce4-notes-plugin xfce4-notifyd xfce4-places-plugin xfce4-pulseaudio-plugin xfce4-screensaver xfce4-screenshooter xfce4-sensors-plugin xfce4-smartbookmark-plugin xfce4-systemload-plugin xfce4-taskmanager xfce4-time-out-plugin xfce4-timer-plugin xfce4-verve-plugin xfce4-wavelan-plugin xfce4-weather-plugin xfce4-whiskermenu-plugin xfce4-xkb-plugin lightdm lightdm-gtk-greeter power-profiles-daemon unrar zip unzip 7zip openssh
  echo
  sudo systemctl enable lightdm.service power-profiles-daemon.service sshd.service 2>/dev/null || echo "Warning: lightdm.service not found."
}

install_hypr() {
  check_vm_environment
  start_point
  clear && print_section "Hyprland"
  install_packages hyprland hypridle hyprland-protocols hyprlock hyprpaper hyprpicker hyprpolkitagent hyprsunset linux-headers pacman-contrib xdg-desktop-portal-hyprland xdg-user-dirs power-profiles-daemon sddm openssh
  xdg-user-dirs-update
  echo
  sudo systemctl enable power-profiles-daemon.service sddm.service sshd.service
  fi
}

install_cosmic() {
  check_vm_environment
  start_point
  clear && print_section "Cosmic Alpha"
  warning
  sleep 6
  install_packages cosmic-session-git linux-headers pacman-contrib xdg-user-dirs switcheroo-control xdg-desktop-portal-cosmic-git xorg-xwayland just mold cosmic-edit-git cosmic-files-git cosmic-store-git cosmic-term-git cosmic-wallpapers-git wayland-protocols wayland-utils lib32-wayland system76-power system-config-printer clipboard-manager-git cosmic-randr-git cosmic-player-git cosmic-ext-applet-external-monitor-brightness-git cosmic-ext-forecast-git cosmic-ext-tweaks-git cosmic-screenshot-git cosmic-applet-arch openssh
  pacman -Rdd --noconfirm cosmic-store-git
  xdg-user-dirs-update
  echo
  sudo systemctl enable cosmic-greeter.service com.system76.PowerDaemon.service sshd.service 2>/dev/null || echo -e "${YELLOW}cosmic-greeter.service not found.${RESET}"
}

post_install() {
  clear && print_section "Bluetooth..."
  install_packages bluez bluez-utils bluez-plugins bluez-hid2hci bluez-cups bluez-libs bluez-tools
  sudo systemctl enable bluetooth.service
  clear && print_section "Applications..."
  install_packages downgrade update-grub meld timeshift mpv gnome-disk-utility btop nano git rustup eza ntp most wget dnsutils logrotate gtk-update-icon-cache dex bash-completion bat bat-extras ttf-fira-code otf-libertinus tex-gyre-fonts ttf-hack-nerd ttf-ubuntu-font-family awesome-terminal-fonts ttf-jetbrains-mono-nerd adobe-source-sans-pro-fonts gtk-engines gtk-engine-murrine gnome-themes-extra ntfs-3g gvfs mtpfs udiskie udisks2 ldmtool gvfs-afc gvfs-mtp gvfs-nfs gvfs-smb gvfs-gphoto2 libgsf tumbler freetype2 libopenraw ffmpegthumbnailer python-pip python-cffi python-numpy python-docopt python-pyaudio python-pyparted python-pygments python-websockets ocs-url xmlstarlet yt-dlp wavpack unarchiver gnustep-base parallel systemdgenie gnome-keyring ark vi duf gcc yad zip xdo lzop nmon tree vala htop lshw cmake cblas expac fuse3 lhasa meson unace unrar unzip p7zip rhash sshfs vnstat nodejs cronie hwinfo arandr assimp netpbm wmctrl grsync libmtp polkit sysprof semver zenity gparted hddtemp mlocate jsoncpp fuseiso gettext node-gyp intltool graphviz pkgstats inetutils s3fs-fuse playerctl oniguruma cifs-utils lsb-release dbus-python laptop-detect perl-xml-parser appmenu-gtk-module preload
  sudo systemctl enable preload
    clear && print_section "GRUB Bootloader..."
  if command -v grub-mkconfig &> /dev/null; then
    install_packages os-prober grub-hooks update-grub
    sudo sed -i 's/#\s*GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
    sudo os-prober
    sudo grub-mkconfig -o /boot/grub/grub.cfg >/dev/null
  fi
}

# Menu stub
main_menu() {
  echo -e "${BOLD}${CYAN}Choose a Desktop Environment:${RESET}"
  echo -e "${GREEN}"
  echo    " 1) 🧊  Plasma"
  echo    " 2) 🌈  GNOME"
  echo    " 3) 🐭  XFCE"
  echo    " 4) 💥  Hyprland"
  echo    " 5) 🌌  Cosmic Alpha"
  echo
  echo    " 6) ❌  Exit"
  echo
  read -rp "Enter your choice [1-6] : " choice
  case "$choice" in
    1) install_plasma ;;
    2) install_gnome ;;
    3) install_xfce ;;
    4) install_hypr ;;
    5) install_cosmic ;;
    6) echo -e "\n${GREEN}Exiting. Have a nice day!${RESET}"; exit 0 ;;
    *) echo -e "\n${RED}Invalid choice. Exiting.${RESET}"; exit 1 ;;
  esac
}

main() {
  print_title
  check_vanilla_arch
  check_existing_de

  # Ensure figlet is installed early for banner output
  if ! command -v figlet &>/dev/null; then
    echo -e "${YELLOW}Installing 'figlet' for banner display...${RESET}"
    if sudo pacman -S --noconfirm --needed figlet &>/dev/null; then
      echo -e "\n${GREEN}[✔] figlet installed.${RESET}"
    else
      echo -e "\n${RED}[✘] Failed to install figlet.${RESET}"
    fi
  fi

  echo
  main_menu
  post_install
  echo
  echo -e "${GREEN}✔ Done! You may now reboot into your desktop environment.${RESET}"
  echo
  read -rp "Press Enter to reboot now or Ctrl+C to cancel..."
  reboot
}

run() {
  trap 'echo -e "${RED}An error occurred. Exiting...${RESET}"; exit 1' ERR
  main "$@"
}

run "$@"
