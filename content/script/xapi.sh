#!/usr/bin/env bash

##################################################################################################################
# Written to be used on 64 bits computers
# Author   :   DarkXero
# Website  :   http://xerolinux.xyz
##################################################################################################################

clear
tput setaf 5
echo "#######################################################################"
echo "#          Welcome to XeroLinux Arch Toolkit install script.          #"
echo "#                                                                     #"
echo "#   This will add the Required XeroLinux & Chaotic-AUR repositories   #"
echo "#        AUR helper and more. Just CTRL+C if you do not agree.        #"
echo "#######################################################################"
tput sgr0
sleep 2

# AUR Helper Options
aur_helpers=("yay" "paru")
aur_helper="NONE"

# Check if AUR helper is already installed
for helper in "${aur_helpers[@]}"; do
  if command -v "$helper" &> /dev/null; then
    aur_helper="$helper"
    echo -e "[✔] AUR helper '${helper}' already installed. Skipping selection."
    break
  fi
done

# Enable Chaotic-AUR (before trying to install yay/paru from it)
if ! grep -q '\[chaotic-aur\]' /etc/pacman.conf; then
  echo -e "[~] Enabling Chaotic-AUR..."
  sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
  sudo pacman-key --lsign-key 3056513887B78AEB
  sudo pacman -U --noconfirm 'https://cdn.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
  sudo pacman -U --noconfirm 'https://cdn.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
  echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" | sudo tee -a /etc/pacman.conf
fi

# Add XeroLinux Repo
if ! grep -q '\[xerolinux\]' /etc/pacman.conf; then
  echo -e "[~] Adding XeroLinux repo..."
  echo -e "\n[xerolinux]\nSigLevel = Optional TrustAll\nServer = https://raw.githubusercontent.com/xerolinux/xerolinux-repo/main/\$arch" | sudo tee -a /etc/pacman.conf
fi

# Set mirrorlist with Reflector
echo -e "[~] Setting up mirrorlist with Reflector..."
sudo pacman -S --noconfirm --needed reflector
sudo reflector --verbose --latest 20 --sort rate --save /etc/pacman.d/mirrorlist

# Sync updated pacman databases
sudo pacman -Syy

# Prompt user if no AUR helper is installed
if [[ "$aur_helper" == "NONE" ]]; then
  echo
  echo "No AUR-Helper detected, please choose one. Select yay for Hyprland."
  echo
  echo "1 - Yay  (Written in Go-lang)"
  echo "2 - Paru (Written in Rust-lang)"
  echo

  read -rp "Choose your Helper [1-2]: " number_chosen

  case "$number_chosen" in
    1)
      aur_helper="yay"
      sudo pacman -Syy --noconfirm yay xlapit-cli
      yay -Y --devel --save
      yay -Y --gendb
      ;;
    2)
      aur_helper="paru"
      sudo pacman -Syy --noconfirm paru xlapit-cli
      paru --gendb
      ;;
    *)
      echo -e "[✘] Invalid option. Exiting to prevent script errors."
      exit 1
      ;;
  esac

  echo -e "[✔] ${aur_helper} installed and configured via Chaotic-AUR."
fi

echo -e "[✔] All repositories and AUR helper are now configured."
