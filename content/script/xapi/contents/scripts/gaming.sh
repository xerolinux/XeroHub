#!/bin/bash
#set -e
##################################################################################################################
# Written to be used on 64 bits computers
# Author 	: 	DarkXero
# Website 	: 	http://xerolinux.xyz
##################################################################################################################
clear
tput setaf 3
echo "#################################################"
echo "#             The Gaming Essentials.            #"
echo "#################################################"
tput sgr0
echo
echo "Hello $USER, what would you like to install ?"
echo
echo "################# Game Launchers #################"
echo
echo "s. Steam (Native)."
echo "l. Lutris (Native)."
echo "h. Heroic (Flathub)."
echo "b. Bottles (Flathub)."
echo
echo "################### Game Tools ###################"
echo
echo "1.  Mangohud (Native)."
echo "2.  Goverlay (Flathub)."
echo "3.  Protonup-qt (Flathub)."
echo "4.  Vulkan Compatibility Layer (AMD)."
echo "5.  Vulkan Compatibility Layer (nVidia)."
echo
echo "Type Your Selection. Or type q to return to main menu."
echo

while :; do

read CHOICE

case $CHOICE in

    s )
      echo
      echo "#################################################"
      echo "#            Installing Steam Launcher          #"
      echo "#################################################"
      echo
      sudo pacman -S --noconfirm steam
      sleep 3
      echo
      echo "Applying Download Speed Enhancement Patch..."
      echo -e "@nClientDownloadEnableHTTP2PlatformLinux 0\n@fDownloadRateImprovementToAddAnotherConnection 1.0" > ~/.steam/steam/steam_dev.cfg
      echo
      echo "#################################################"
      echo "#        Done ! Returning to main menu..        #"
      echo "#################################################"
      clear && sh $0

      ;;

    l )
      echo
      echo "#################################################"
      echo "#           Installing Lutris Launcher          #"
      echo "#################################################"
      echo
      sudo pacman -S --noconfirm lutris wine-staging
      echo
      echo "Applying vm-max-map-count patch for better performance..."
      echo
      echo "vm.max_map_count=2147483642" | sudo tee /etc/sysctl.d/99-sysctl.conf >/dev/null
      echo
      echo "#################################################"
      echo "#        Done ! Returning to main menu..        #"
      echo "#################################################"
      clear && sh $0

      ;;

    h )
      echo
      echo "#################################################"
      echo "#           Installing Heroic Launcher          #"
      echo "#################################################"
      echo
      flatpak install com.heroicgameslauncher.hgl
      echo
      echo "#################################################"
      echo "#        Done ! Returning to main menu..        #"
      echo "#################################################"
      clear && sh $0

      ;;

    b )
      echo
      echo "#################################################"
      echo "#          Installing Bottles Launcher          #"
      echo "#################################################"
      echo
      flatpak install com.usebottles.bottles
      echo
      echo "#################################################"
      echo "#        Done ! Returning to main menu..        #"
      echo "#################################################"
      clear && sh $0

      ;;

    1 )
      echo
      echo "#################################################"
      echo "#               Installing Mangohud             #"
      echo "#################################################"
      echo
      sudo pacman -S --noconfirm mangohud
      echo
      echo "#################################################"
      echo "#        Done ! Returning to main menu..        #"
      echo "#################################################"
      clear && sh $0

      ;;

    2 )
      echo
      echo "#################################################"
      echo "#               Installing Goverlay             #"
      echo "#################################################"
      echo
      sudo pacman -S --noconfirm goverlay
      echo
      echo "#################################################"
      echo "#        Done ! Returning to main menu..        #"
      echo "#################################################"
      clear && sh $0

      ;;

    3 )
      echo
      echo "#################################################"
      echo "#             Installing ProtonUp-QT            #"
      echo "#################################################"
      echo
      flatpak install net.davidotek.pupgui2
      echo
      echo "#################################################"
      echo "#        Done ! Returning to main menu..        #"
      echo "#################################################"
      clear && sh $0

      ;;

    4 )
      echo
      echo "#################################################"
      echo "#               Installing DXVK-bin             #"
      echo "#################################################"
      echo
      $AUR_HELPER dxvk-bin
      echo
      echo "#################################################"
      echo "#        Done ! Returning to main menu..        #"
      echo "#################################################"
      clear && sh $0

      ;;

    5 )
      echo
      echo "#################################################"
      echo "#                Installing nvdxvk              #"
      echo "#################################################"
      echo
      $AUR_HELPER dxvk-nvapi-mingw
      echo
      echo "#################################################"
      echo "#        Done ! Returning to main menu..        #"
      echo "#################################################"
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
