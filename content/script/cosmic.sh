#!/usr/bin/env bash
clear
set -euo pipefail
echo "==============================================================="
echo "                   XeroCosmic Install Script                   "
echo "       This will install XeroLinux Cosmic Configuration        "
echo "==============================================================="
echo
read -rp "Proceed with installation ? (Might take a while) [y/N]: " proceed
if [[ ! "$proceed" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 1
fi

# Enable multilib if disabled
enable_multilib() {
  if grep -Pq '^\[multilib\]' /etc/pacman.conf; then
    echo "multilib repository already enabled."
  else
    echo "Enabling multilib repository..."
    sudo cp /etc/pacman.conf /etc/pacman.conf.bak-xerocosmic
    sudo sed -i '/#\[multilib\]/,+1s/^#//' /etc/pacman.conf
  fi
}
echo
# Add XeroLinux repo if missing
add_xerolinux_repo() {
  if grep -Pq '^\[xerolinux\]' /etc/pacman.conf; then
    echo "XeroLinux repo already present."
  else
    echo "Adding XeroLinux repository..."
    echo -e "\n[xerolinux]\nSigLevel = Optional TrustAll\nServer = https://repos.xerolinux.xyz/\$repo/\$arch" | sudo tee -a /etc/pacman.conf >/dev/null
  fi
}
echo
# Function to add the Chaotic-AUR repository
add_chaotic_aur() {
    if ! grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
        echo
        echo "Adding The Chaotic-AUR Repository..."
        sleep 3
        echo
        sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
        sudo pacman-key --lsign-key 3056513887B78AEB
        sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
        sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
        echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' | sudo tee -a /etc/pacman.conf
        echo
        echo "Chaotic-AUR Repository added!"
        echo
        sleep 3
    else
        echo "Chaotic-AUR Repository already added."
        echo
        sleep 3
    fi
}
echo
# Detect or install AUR helper
setup_aur_helper() {
  if command -v paru >/dev/null 2>&1; then
    AUR_HELPER="paru"
  elif command -v yay >/dev/null 2>&1; then
    AUR_HELPER="yay"
  else
    echo "No AUR helper found."
    echo
    echo "Choose AUR helper to install:"
    echo
    select choice in "paru" "yay"; do
      case "$choice" in
        paru|yay)
          sudo pacman -Syy "$choice"
          AUR_HELPER="$choice"
          break
          ;;
        *)
          echo "Invalid choice."
          ;;
      esac
    done
  fi
  echo
  echo "Using AUR helper: $AUR_HELPER"
}

# Step 1: Configure pacman
enable_multilib
add_xerolinux_repo
add_chaotic_aur
sudo pacman -Syy
echo
# Step 2: Install pacman packages
echo "Installing official packages..."
echo
sudo pacman -S --noconfirm --needed \
  cosmic-desktop-config firefox rust qt6ct kvantum fastfetch adw-gtk-theme \
  gnome-themes-extra ttf-fira-code nordic-wallpapers xero-hooks grub-hooks \
  otf-libertinus tex-gyre-fonts ttf-hack-nerd xero-fonts-git extra-scripts \
  ttf-ubuntu-font-family awesome-terminal-fonts ttf-jetbrains-mono-nerd \
  adobe-source-sans-pro-fonts bat bat-extras jq figlet bash-completion \
  brightnessctl acpi upower gtk-update-icon-cache

# Step 3: Install AUR packages
setup_aur_helper
echo "Installing AUR packages..."
$AUR_HELPER -S --noconfirm --needed \
  tela-icon-theme oh-my-posh-bin cosmic-applet-arch cosmic-ext-tweaks cosmic-ext-forecast-git \
  system76-power xdg-terminal-exec-git pacseek topgrade cosmic-ext-applet-caffeine-git

# Step 4: Enable services
echo "Enabling services..."
sudo systemctl enable sshd com.system76.PowerDaemon

# Step 6: Copy /etc/skel to home
echo "Copying /etc/skel to user home..."
USER_HOME="/home/$USER"
cp -r /etc/skel/. "$USER_HOME/"

# Step 7: OhMyPosh Setup
echo "Injecting OMP to .bashrc"

# Define the lines to be added
line1='# Oh-My-Posh Config'
line2='eval "$(oh-my-posh init bash --config $HOME/.config/ohmyposh/xero.omp.json)"'

# Define the .bashrc file
bashrc_file="$HOME/.bashrc"

# Function to add lines if not already present
add_lines() {
  if ! grep -qxF "$line1" "$bashrc_file"; then
    echo "" >> "$bashrc_file" # Add an empty line before line1
    echo "$line1" >> "$bashrc_file"
  fi
  if ! grep -qxF "$line2" "$bashrc_file"; then
    echo "$line2" >> "$bashrc_file"
    echo "" >> "$bashrc_file" # Add an empty line after line2
  fi
}

# Run the function to add lines
add_lines

echo
echo "Installation complete."
echo
read -rp "Reboot now? [y/N]: " reboot_confirm
if [[ "$reboot_confirm" =~ ^[Yy]$ ]]; then
  echo "Rebooting..."
  sudo reboot
else
  echo
  echo "Reboot later to apply changes."
fi
