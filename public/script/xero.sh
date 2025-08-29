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
  clear
  echo -e "${BOLD}${BLUE}"
  if command -v figlet &>/dev/null; then
    figlet -f small "XeroLinux Installer"
  else
    echo "╔════════════════════════════════════════════════════╗"
    echo "║                 XEROLINUX INSTALLER                ║"
    echo "╚════════════════════════════════════════════════════╝"
  fi
  echo -e "${RESET}"
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
    echo -e "${RED}This script is for Plain Arch Linux only. Exiting.${RESET}"
    exit 1
  fi
}

check_existing_de() {
  local known_de_packages=(
    plasma-desktop gnome-shell xfce4-session hyprland cosmic-session-git
    budgie-desktop cinnamon pantheon-session deepin kde-applications lxqt-session
    sway i3-wm openbox awesome enlightenment mate-session
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
  # Safely detect VM without triggering script exit on real hardware
  local virt
  if ! virt=$(systemd-detect-virt 2>/dev/null); then
    virt="none"
  fi

  if [[ "$virt" != "none" ]]; then
    echo -e "\n${YELLOW}🖥️ VM detected — installing guest tools...${RESET}"
    sleep 6
    case "$virt" in
      oracle)
        install_packages virtualbox-guest-utils
        ;;
      kvm)
        install_packages qemu-guest-agent spice-vdagent
        ;;
      microsoft)
        echo
        echo -e "${YELLOW}⚠️ WSL detected — GUI support is limited.${RESET}"
        ;;
      *)
        echo
        echo -e "${YELLOW}⚠️ Unknown VM type: ${virt}${RESET}"
        ;;
    esac
  else
    echo
    echo -e "${GREEN}✅ Running on physical hardware. Skipping VM setup.${RESET}"
  fi
}

start_point() {
  if [[ -f /tmp/.xapi_lock ]]; then return; fi

  # Ensure curl and git are available
  for cmd in curl git; do
    if ! command -v "$cmd" &>/dev/null; then
      echo -e "${YELLOW}⚠️ '$cmd' not found. Installing required tools...${RESET}"
      sudo pacman -Syy --noconfirm git curl || {
        echo -e "${RED}❌ Failed to install dependencies. Exiting.${RESET}"
        exit 1
      }
      break
    fi
  done

  echo -e "${GREEN}Fetching XeroLinux Toolkit & AUR Helper...${RESET}"

  curl -fsSL https://xerolinux.xyz/script/xapi.sh -o /tmp/xapi.sh || {
    echo -e "${RED}❌ Failed to download xapi.sh. Exiting.${RESET}"
    exit 1
  }

  chmod +x /tmp/xapi.sh
  bash -i /tmp/xapi.sh
  touch /tmp/.xapi_lock
}

install_packages() {
  local failed_packages=()
  local spinner=("|" "/" "-" "\\")

  for pkg in "$@"; do
    local i=0

    echo -ne "${CYAN}[ ] Installing ${pkg}...${RESET}"

    # Start spinner in background
    (
      while true; do
        echo -ne "\r${CYAN}[${spinner[i]}] Installing ${pkg}...${RESET}"
        i=$(( (i + 1 ) % 4 ))
      done
    ) &
    SPIN_PID=$!

    # Run pacman silently in background
    if sudo pacman -S --noconfirm --needed "$pkg" &> /tmp/xero-install.log; then
      RESULT=true
    else
      RESULT=false
    fi

    # Stop spinner and clean up line
    kill "$SPIN_PID" &>/dev/null
    wait "$SPIN_PID" 2>/dev/null || true
    echo -ne "\r\033[2K"  # clear spinner line

    if $RESULT; then
      echo -e "${GREEN}[✔] Installed ${pkg}${RESET}"
    else
      echo -e "${RED}[✘] Failed ${pkg}${RESET}"
      failed_packages+=("$pkg")
    fi
  done

  if [[ ${#failed_packages[@]} -gt 0 ]]; then
    echo -e "${RED}The following packages failed to install:${RESET}"
    for pkg in "${failed_packages[@]}"; do
      echo -e "${RED}- $pkg${RESET}"
    done
  fi
}

install_plasma() {
  clear && print_section "XERO-KDE"
  install_packages kf6 power-profiles-daemon jq kimageformats qt5-imageformats qt6-3d qt6-5compat qt6-base qt6-charts qt6-connectivity qt6-declarative qt6-graphs qt6-grpc qt6-httpserver qt6-imageformats qt6-languageserver qt6-location qt6-lottie qt6-multimedia qt6-networkauth qt6-positioning qt6-quick3d qt6-quick3dphysics qt6-quickeffectmaker qt6-quicktimeline qt6-remoteobjects qt6-scxml qt6-sensors qt6-serialbus qt6-serialport qt6-shadertools qt6-speech qt6-svg qt6-tools qt6-translations qt6-virtualkeyboard qt6-wayland qt6-webchannel qt6-webengine qt6-websockets qt6-webview plasma-desktop packagekit-qt6 packagekit dolphin kcron khelpcenter kio-admin ksystemlog breeze plasma-workspace plasma-workspace-wallpapers powerdevil plasma-nm kaccounts-integration kdeplasma-addons plasma-pa plasma-integration plasma-browser-integration plasma-wayland-protocols plasma-systemmonitor kpipewire keysmith krecorder kweather plasmatube plasma-pass ocean-sound-theme qqc2-breeze-style plasma5-integration kdeconnect kdenetwork-filesharing kget kio-extras kio-gdrive kio-zeroconf colord-kde gwenview kamera kcolorchooser kdegraphics-thumbnailers kimagemapeditor kolourpaint okular spectacle svgpart ark kate kcalc kcharselect kdebugsettings kdf kdialog keditbookmarks kfind kgpg konsole markdownpart yakuake audiotube elisa ffmpegthumbs dolphin-plugins pim-data-exporter pim-sieve-editor emoji-font gcc-libs glibc icu kauth kbookmarks kcmutils kcodecs kcompletion kconfig kconfigwidgets kcoreaddons kcrash kdbusaddons kdeclarative kglobalaccel kguiaddons ki18n kiconthemes kio kirigami kirigami-addons kitemmodels kitemviews kjobwidgets kmenuedit knewstuff knotifications knotifyconfig kpackage krunner kservice ksvg kwidgetsaddons kwindowsystem kxmlgui libcanberra libksysguard libplasma libx11 libxcb libxcursor libxi libxkbcommon libxkbfile plasma-activities plasma-activities-stats plasma5support polkit polkit-kde-agent sdl2 solid sonnet systemsettings wayland xcb-util-keysyms xdg-user-dirs scim extra-cmake-modules intltool wayland-protocols xf86-input-libinput sddm-kcm bluedevil breeze-gtk drkonqi kde-gtk-config kinfocenter kscreen ksshaskpass breeze-grub flatpak-kcm networkmanager-qt quota-tools qt5-x11extras gpsd pacman-contrib cmake falkon desktop-config kde-wallpapers tela-circle-icon-theme-purple amarok kwin krdp milou breeze oxygen aurorae kwrited kgamma sddm-kcm krdc krfb smb4k alligator kget konversation signon-kwallet-extension skanlite filelight kmousetool sweeper skanpage kcharselect markdownpart kdebugsettings kwalletmanager k3b kamoso audiocd-kio akregator waypipe dwayland egl-wayland qt6-wayland lib32-wayland wayland-protocols kwayland-integration plasma-wayland-protocols pavucontrol-qt polkit-qt6 lsb-release oh-my-posh-bin
  sudo systemctl enable sddm power-profiles-daemon &>/dev/null || echo -e "${YELLOW}Warning: sddm not found.${RESET}"
  echo
  echo "Applying KDE Config..."
  git clone https://github.com/xerolinux/xero-layan-git
  cd xero-layan-git/ && ./install.sh
  cd .. && rm -rf xero-layan-git
  sudo rm /etc/lsb-release
  sudo wget https://raw.githubusercontent.com/XeroLinuxDev/xero-build/refs/heads/main/XeroKDE/airootfs/etc/xerolinux-release -O /etc/lsb-release
}

install_gnome() {
  clear && print_section "XERO-GNOME"
  install_packages evince extension-manager epiphany gdm gnome-appfolders-manager gnome-bluetooth-3.0 gnome-desktop-common gnome-browser-connector gnome-subtitles gnac gmtk gnome-applets gnome-backgrounds gnome-calculator gnome-calendar gnome-characters gnome-clocks gnome-color-manager gnome-music gnome-connections gnome-firmware gnome-photos ptyxis gnome-contacts gnome-control-center gnome-font-viewer  gnome-keyring gnome-logs gnome-maps gnome-menus gnome-network-displays gnome-nettool gnome-power-manager gnome-remote-desktop gnome-session gnome-settings-daemon gnome-shell gnome-multi-writer gnome-system-monitor gnome-text-editor gnome-tweaks gnome-user-share gnome-weather grilo-plugins gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-onedrive gvfs-smb gvfs-wsdd loupe nautilus rygel power-profiles-daemon simple-scan snapshot sushi tecla totem xdg-desktop-portal-gnome xdg-user-dirs-gtk jq libadwaita adwaita-fonts adwaita-cursors adwaita-icon-theme adwaita-icon-theme-legacy xdg-terminal-exec-git pika-backup qt5ct qt6ct kvantum fastfetch adw-gtk-theme tela-circle-icon-theme-purple kvantum-theme-libadwaita-git baobab cheese gnome-usage gnome-autoar tracker3-miners gitg d-spy geary gedit glade mousai sysprof ptyxis commit showtime shortwave evolution endeavour impression file-roller dconf-editor gnome-desktop gnome-builder gnome-podcasts gnome-dictionary gnome-sound-recorder gnome-online-accounts gnome-epub-thumbnailer nautilus-share nautilus-compare nautilus-admin-gtk4 nautilus-open-in-ptyxis nautilus-image-converter gnome-shell-extensions gnome-shell-extension-arc-menu gnome-shell-extension-caffeine gnome-shell-extension-gsconnect gnome-shell-extension-arch-update gnome-shell-extension-blur-my-shell gnome-shell-extension-appindicator gnome-shell-extension-dash-to-dock gnome-shell-extension-weather-oclock gnome-shell-extension-desktop-icons-ng pacseek waypipe rate-mirrors qalculate-gtk libappindicator-gtk3 desktop-config-gnome pavucontrol lsb-release
  echo
  sudo systemctl enable gdm power-profiles-daemon &>/dev/null || echo -e "${YELLOW}Warning: gdm not found.${RESET}"
  echo
  echo "Applying Xero Gnome Settings..."
  echo
  cp -Rf /etc/skel/. ~
  sleep 2
  sudo mkdir -p /usr/share/defaultbg && sudo cp $HOME/.local/share/backgrounds/Xero-G4.png /usr/share/defaultbg/XeroG.png
  sleep 2
  dconf load /org/gnome/ < /etc/skel/.config/xero-dconf.conf
  sleep 1.5
  dconf load /com/github/stunkymonkey/nautilus-open-any-terminal/ < /etc/skel/.config/term.conf
  sleep 1.5
  dconf load /org/gnome/Ptyxis/ < /etc/skel/.config/Ptyxis.conf
  sleep 1.5
  dconf write /org/gnome/Ptyxis/Profiles/a8419c1b5f17fef263add7d367cd68cf/opacity 0.85
  rm ~/.config/autostart/dconf-load.desktop
  sleep 2
  cd ~ && mv .bashrc .bashrc.bk && wget https://raw.githubusercontent.com/XeroLinuxDev/xero-build/refs/heads/main/XeroG/airootfs/etc/skel/.bashrc
  sudo rm /etc/lsb-release
  sudo wget https://raw.githubusercontent.com/XeroLinuxDev/xero-build/refs/heads/main/XeroG/airootfs/etc/xerolinux-release -O /etc/lsb-release
  git clone https://github.com/xerolinux/xero-grubs
  cd xero-grubs/XeroSimple/ && sudo ./install.sh
  cd .. && rm -rf xero-grubs
}

echo

post_install() {
  clear && print_section "Grub Bootloader..."
  install_packages grub os-prober grub-hooks update-grub
  sudo sed -i 's/^GRUB_DISTRIBUTOR="Arch"/GRUB_DISTRIBUTOR="XeroLinux"/' /etc/default/grub
  sudo grub-mkconfig -o /boot/grub/grub.cfg

  clear && print_section "Bluetooth Stuff..."
  install_packages bluez bluez-utils bluez-plugins bluez-hid2hci bluez-cups bluez-libs bluez-tools blueberry
  sudo systemctl enable bluetooth
  sudo mkdir /var/lib/flatpak/overrides/
  sudo wget https://raw.githubusercontent.com/XeroLinuxDev/xero-build/refs/heads/main/XeroKDE/airootfs/var/lib/flatpak/overrides/global -O /var/lib/flatpak/overrides/global

  clear && print_section "System Stuff..."
  install_packages linux-headers linux-atm linux-firmware-intel linux-firmware-amdgpu mkinitcpio mkinitcpio-fw mkinitcpio-utils mkinitcpio-archiso mkinitcpio-openswap mkinitcpio-nfs-utils meld timeshift mpv gnome-disk-utility btop nano rust eza downgrade ntp most wget dnsutils logrotate gtk-update-icon-cache dex bash-completion bat bat-extras ttf-fira-code otf-libertinus tex-gyre-fonts ttf-hack-nerd ttf-ubuntu-font-family awesome-terminal-fonts ttf-jetbrains-mono-nerd adobe-source-sans-pro-fonts gtk-engines gtk-engine-murrine gnome-themes-extra ntfs-3g gvfs mtpfs udiskie udisks2 ldmtool gvfs-afc gvfs-mtp gvfs-nfs gvfs-smb gvfs-gphoto2 libgsf tumbler freetype2 libopenraw ffmpegthumbnailer python-pip repoctl python-cffi python-numpy python-docopt python-pyaudio python-pyparted python-pygments python-websockets xmlstarlet yt-dlp wavpack unarchiver gnustep-base parallel gnome-keyring duf gcc zip xdo lzop nmon tree vala htop lshw cmake cmake-extras cblas expac fuse3 lhasa meson unace unrar unzip 7zip rhash sshfs vnstat nodejs cronie hwinfo assimp netpbm wmctrl grsync libmtp polkit sysprof semver zenity gparted hddtemp mlocate jsoncpp fuseiso gettext node-gyp intltool graphviz pkgstats inetutils s3fs-fuse playerctl oniguruma cifs-utils dbus-python laptop-detect perl-xml-parser appmenu-gtk-module preload piper iwd fastfetch flatpak pacman-bintrans pacseek openssh inxi rate-mirrors libappindicator-gtk3 b43-fwcutter rsync gptfdisk xfsprogs tpm2-tss udftools fatresize nfs-utils e2fsprogs dosfstools exfatprogs tpm2-tools fsarchiver squashfs-tools gpart dmraid parted hdparm usbmuxd usbutils testdisk ddrescue partclone partimage clonezilla usb_modeswitch tmux brltty msedit nvme-cli terminus-font foot-terminfo kitty-terminfo pv mc gpm nbd lvm2 bolt bind less lynx tldr nmap irssi wvdial hyperv mtools lsscsi ndisc6 screen man-db xl2tpd tcpdump ethtool xdotool pcsclite espeakup libfido2 xdg-utils man-pages diffutils mmc-utils sg3_utils efibootmgr sequoia-sq edk2-shell libusb-compat smartmontools wireguard-tools xdg-terminal-exec-git hblock cryptsetup brightnessctl bash make libxinerama xorg-apps xorg-xinit xorg-server xorg-xwayland fwupd mesa autorandr mesa-utils lib32-mesa xf86-video-qxl xf86-video-fbdev lib32-mesa-utils qemu-hw-display-qxl orca onboard fprintd libinput gestures xf86-input-void xf86-input-evdev iio-sensor-proxy libinput-gestures xf86-input-vmmouse xf86-input-libinput xf86-input-synaptics libinput-gestures-qt xf86-input-elographics hplip print-manager printer-support scanner-support gstreamer gst-libav gst-plugins-bad gst-plugins-base gst-plugins-ugly gst-plugins-good gst-plugin-pipewire libdvdcss alsa-utils wireplumber alsa-plugins alsa-firmware pipewire-jack pipewire-support lib32-pipewire-jack iw ppp lftp ldns avahi samba dhcpcd openvpn dnsmasq dhclient openldap nss-mdns smbclient net-tools openresolv darkhttpd reflector pptpclient cloud-init openconnect traceroute modemmanager networkmanager nm-cloud-setup wireless-regdb wireless_tools wpa_supplicant openpgp-card-tools jq figlet ostree lolcat numlockx lm_sensors appstream-glib lib32-lm_sensors xero-fonts-git bash-language-server typescript-language-server vscode-json-languageserver kvantum ffmpeg ffmpegthumbs ffnvcodec-headers topgrade appstream-qt pacman-contrib poppler-qt6 poppler-glib xsettingsd systemdgenie vi npm yad gum glfw p7zip iftop nvtop wlr-randr asciinema ventoy-bin
  echo
  sudo usermod -aG lp,realtime,sambashare,power,video,network,storage,cups,adm,wheel,audio,optical,rfkill,scanner,sys $USER &>/dev/null
  sudo systemctl enable preload sshd fstrim.timer cups.socket saned.socket NetworkManager dhcpcd &>/dev/null
  sudo systemctl disable systemd-time-wait-sync reflector pacman-init &>/dev/null
}

# Menu stub
main_menu() {
  clear && print_title
  echo -e "${BOLD}${BOLD}"
  echo "╭────────────────────────────────────────────────────╮"
  echo "│       Choose a XeroLinux Version to Install        │"
  echo "├────────────────────────────────────────────────────┤"
  echo "│  [1]  XERO-KDE      - Sleek, modern, customizable  │"
  echo "│  [2]  XERO-GNOME    - Simple, elegant, GTK-based   │"
  echo "│                                                    │"
  echo "│  [3]  Exit          - Abort installation           │"
  echo "╰────────────────────────────────────────────────────╯"
  echo -e "${RESET}"
  read -rp "Enter your choice [1-3]: " choice
  echo

  case "$choice" in
    1) clear && install_plasma ;;
    2) clear && install_gnome ;;
    3) echo -e "${GREEN}Bye!${RESET}"; exit 0 ;;
    *) echo -e "${RED}Invalid choice.${RESET}"; exit 1 ;;
  esac
}

main() {
  print_title
  check_vanilla_arch
  check_existing_de
  check_vm_environment
  start_point

  # Ensure figlet is installed early for banner output
  if ! command -v figlet &>/dev/null; then
    echo -e "${YELLOW}Installing 'figlet' for banner display...${RESET}"
    if sudo pacman -Syy --noconfirm figlet &>/dev/null; then
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
  sudo reboot
}

run() {
  trap 'echo -e "${RED}An error occurred. Exiting...${RESET}"; exit 1' ERR
  main "$@"
}

run "$@"
