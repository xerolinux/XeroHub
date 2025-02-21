#!/bin/bash
#set -e
##################################################################################################################
# Written to be used on 64 bits computers
# Author 	: 	DarkXero
# Website 	: 	http://xerolinux.xyz
##################################################################################################################
clear
tput setaf 3
echo "##############################################################"
echo "#        XeroLinux Distrobox/Docker/Virt-Manager Tool        #"
echo "##############################################################"
tput sgr0
echo
echo "Hello $USER, what would you like to do today ?"
echo
echo "################## Distrobox & Docker Setup ##################"
echo
echo "d. Install/Configure Docker."
echo "b. Install/Configure Distrobox."
echo
echo "################### Top 5 Distrobox Images ###################"
echo "#### Both Options d and b are required for below to work. ####"
echo
echo "1. Debian."
echo "2. Fedora."
echo "3. Void Linux."
echo "4. Tumbleweed."
echo
echo "u. Update all Containers (Might take a while)."
echo
echo "Type Your Selection. Or type q to return to main menu."
echo

while :; do

read CHOICE

case $CHOICE in

    d )
      echo
      sleep 2
      echo "Installing & Srtting up Docker..."
      echo
      sudo pacman -S --noconfirm docker docker-compose docker-buildx
      sleep 2
      echo
      echo "Enabling Services & Adding you to group"
      echo
      sudo systemctl enable --now docker
      sudo usermod -aG docker $USER
      sleep 2
      echo
      # Prompt the user to reboot
        tput setaf 1
        read -p "All done. Reboot is required. Reboot now? (y/n): " reboot_response
        tput setaf 0
      echo
        # Check the user's response
        if [[ $reboot_response == "y" || $reboot_response == "yes" ]]; then
          sudo reboot
        else
          echo
          tput setaf 2
          echo "Please manually reboot your system before using Docker."
          sleep 3
          clear && sh $0
          tput sgr0
        fi

      ;;

    b )
      echo
      sleep 2
      echo "Installing Dostrobox..."
      echo
      sudo pacman -S --noconfirm distrobox
      sleep 3
      echo
      clear && sh $0

      ;;

    1 )
      echo
      sleep 2
      echo "Pulling Latest Debian Image with label Debian, Please Wait..."
      echo
      distrobox create -i quay.io/toolbx-images/debian-toolbox:latest -n "Debian"
      sleep 10
      echo
      clear && sh $0

      ;;

    2 )
      echo
      sleep 2
      echo "Pulling Latest Fedora Image with label Fedora, Please Wait..."
      echo
      distrobox create -i registry.fedoraproject.org/fedora-toolbox:latest -n "Fedora"
      sleep 10
      echo
      clear && sh $0

      ;;

    3 )
      echo
      sleep 2
      echo "Pulling Latest Void Linux Image with label VoidLinux, Please Wait..."
      echo
      distrobox create -i ghcr.io/void-linux/void-linux:latest-full-x86_64 -n "VoidLinux"
      sleep 10
      echo
      clear && sh $0

      ;;
    
    4 )
      echo
      sleep 2
      echo "Pulling Latest Tumbleweed Image with label OpenSuse..."
      echo
      distrobox create -i registry.opensuse.org/opensuse/tumbleweed:latest -n "OpenSuse"
      sleep 10
      echo
      clear && sh $0

      ;;

    u )
      echo
      sleep 2
      echo "Upgrading all Containers Please Wait..."
      echo
      distrobox-upgrade --all
      sleep 3
      echo
      clear && sh $0

      ;;

    q )
      clear && exec ~/.local/bin/xero-cli

      ;;

    * )
      echo "#################################"
      echo "    Choose the correct number    "
      echo "#################################"
      ;;
esac
done
