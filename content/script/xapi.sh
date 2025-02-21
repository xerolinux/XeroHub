#!/usr/bin/env bash

for i in 2 30; do
    echo -en "\033]${i};XeroLinux Toolkit\007"
done

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

aur_helpers=("yay" "paru")
echo

# Function to add the XeroLinux repository if not already added
add_xerolinux_repo() {
    if ! grep -q "\[xerolinux\]" /etc/pacman.conf; then
        echo
        echo "Adding The Various Repositories..."
        sleep 3
        echo
        echo -e '\n[xerolinux]\nSigLevel = Optional TrustAll\nServer = https://repos.xerolinux.xyz/$repo/$arch' | sudo tee -a /etc/pacman.conf
        sudo sed -i '/^\s*#\s*\[multilib\]/,/^$/ s/^#//' /etc/pacman.conf
        echo
        echo "XeroLinux Repository added!"
        sleep 3
    else
        echo
        echo "XeroLinux Repository already added."
        echo
        sleep 3
    fi
}

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

# Function to update pacman.conf under Misc options
update_pacman_conf() {
    echo
    echo "Updating Pacman Options..."
    echo
    sudo sed -i '/^# Misc options/,/ParallelDownloads = [0-9]*/c\# Misc options\nColor\nILoveCandy\nCheckSpace\n#DisableSandbox\nDownloadUser = alpm\nDisableDownloadTimeout\nParallelDownloads = 10' /etc/pacman.conf
     echo "Updated /etc/pacman.conf under # Misc options"
     echo
}

# Function to install and start the toolkit
install_toolkit() {
    sudo pacman -Syy --noconfirm xlapit-cli
}

aur_helper="NONE"
for helper in "${aur_helpers[@]}"; do
    if command -v "$helper" &> /dev/null; then
        aur_helper="$helper"
        echo
        echo "AUR Helper detected, shall we proceed? (y/n)"
        echo ""

        read -rp "Enter your choice: " CHOICE

        case $CHOICE in
            y)
                add_xerolinux_repo
                add_chaotic_aur
                update_pacman_conf
                install_toolkit
                ;;
            n)
                exit 0
                ;;
            *)
                echo "Invalid choice."
                exit 1
                ;;
        esac
    fi
done

if [[ $aur_helper == "NONE" ]]; then
    echo
    echo "No AUR-Helper detected, please choose one. Select yay for Hyprland."
    echo ""
    echo "1 - Yay  (Written in Go-lang)"
    echo "2 - Paru (Written in Rust-lang)"
    echo ""
    read -rp "Choose your Helper: " number_chosen

    case $number_chosen in
        1)
            echo
            echo "###########################################"
            echo "           You Have Selected YaY           "
            echo "###########################################"
            add_xerolinux_repo
            add_chaotic_aur
            update_pacman_conf
            echo
            echo "Installing YaY & Toolkit..."
            echo
            sudo pacman -Syy --noconfirm yay-git xlapit-cli && yay -Y --devel --save && yay -Y --gendb
            install_toolkit
            ;;
        2)
            echo
            echo "###########################################"
            echo "          You Have Selected Paru           "
            echo "###########################################"
            add_xerolinux_repo
            add_chaotic_aur
            update_pacman_conf
            echo
            echo "Installing Paru & Toolkit..."
            echo
            sudo pacman -Syy --noconfirm paru-git xlapit-cli && paru --gendb
            install_toolkit
            ;;
        *)
            echo "Invalid option."
            ;;
    esac
fi
