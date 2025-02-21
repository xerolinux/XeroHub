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
echo "#              System Customization             #"
echo "#################################################"
tput sgr0
echo
echo "Hello $USER, please select what to do..."
echo
echo "################# Shell / Prompt #################"
echo
echo "z. Install ZSH+OMZ+Powerlevel10k."
echo "s. Install and Apply Starship Bash Prompt."
echo
echo "################# Plasma Stuffs #################"
echo
echo "#################################################"
echo "#          Rices Currently Unavailable.         #"
echo "#      In Process Of Migrating to Plasma 6      #"
echo "#################################################"
echo
echo "p. Install missing Plasma Packages."
echo "m. Apply AppMenu Meta-Key Fix (Kwin/Rices)."
echo "w. Apply xWayland Screen/Window Sharing Fix."
echo
echo "Type Your Selection. Or type q to return to main menu."
echo

while :; do

read CHOICE

case $CHOICE in

    z )
      echo
      echo "###########################################"
      echo "     Installing ZSH+OMZ+Powerlevel10k      "
      echo "###########################################"
      sleep 3
      sh $SCRIPTS_PATH/switch_to_zsh.sh
      sleep 3
      echo "#######################################"
      echo "                 Done !                "
      echo "#######################################"
      clear && sh $0
      ;;

    s )
      echo
      echo "###########################################"
      echo "              Starship Prompt              "
      echo "###########################################"
      sleep 3
      sudo pacman -S starship
      mkdir -p ~/.config/starship && cd ~/.config/starship
      wget https://raw.githubusercontent.com/xerolinux/xero-fixes/main/conf/starship.toml
      sleep 3
      echo "#######################################"
      echo "                 Done !                "
      echo "#######################################"
      clear && sh $0
      ;;

    p )
      echo
	  sleep 2
	  echo "Installing Missing Plasma Packages..."
	  echo
      sleep 3
      $AUR_HELPER -S --noconfirm flatpak-kcm systemd-kcm kdeplasma-addons keditbookmarks kgpg kwalletmanager print-manager yakuake tesseract-data-eus dolphin-plugins gwenview kamera okular spectacle svgpart plasmatube dwayland egl-wayland qt6-wayland glfw-wayland lib32-wayland wayland-protocols kwayland-integration plasma-wayland-session plasma-wayland-protocols
      echo
      sleep 2
      echo "All done, please reboot for good measure !"
	  sleep 3
      clear && sh $0

      ;;

    m )
      echo
	  sleep 2
	  echo "Applying Meta-Key AppMenu fix..."
      echo
      kwriteconfig5 --file ~/.config/kwinrc --group ModifierOnlyShortcuts --key Meta "org.kde.plasmashell,/PlasmaShell,org.kde.PlasmaShell,activateLauncherMenu"
      sleep 3
      echo "Relaunching Kwin..."
      qdbus org.kde.KWin /KWin reconfigure
      echo
      echo "All done, should work now !"
	  sleep 3
      clear && sh $0

      ;;

    w )
      echo
	  sleep 2
	  echo "Installing XWayland Bridge..."
	  echo
      sleep 3
      sudo pacman -S --noconfirm xwaylandvideobridge
      echo
      sleep 2
      echo "All done, please reboot for good measure !"
	  sleep 3
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
