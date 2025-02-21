#!/bin/bash
#set -e
##################################################################################################################
# Written to be used on 64 bits computers
# Author 	: 	DarkXero
# Website 	: 	http://xerolinux.xyz
##################################################################################################################
clear
tput setaf 3
echo "##############################################################################"
echo "#                               Device Drivers                               #"
echo "##############################################################################"
tput sgr0
echo
echo "Hello $USER, Please Select What Drivers to install."
echo
echo "################## GPU / Printing ##################"
echo
echo "g. GPU Drivers (Forum Link)."
echo "p. Printing Essential Tools."
echo "h. HP Drivers and Tools (AUR)."
echo "e. Epson Drivers and Tools (AUR)."
echo
echo "################# Game Controllers #################"
echo
echo "d. DualShock 4 Controller Driver (AUR)."
echo "s. PS5 DualSense Controller Driver (AUR)."
echo "x. Xbox One Wireless Gamepad Driver (AUR)."
echo
echo "Type Your Selection. Or type q to return to main menu."
echo

while :; do

read CHOICE

case $CHOICE in

    g )
      echo
      sleep 2
      xdg-open "https://forum.xerolinux.xyz/thread-364.html"  > /dev/null 2>&1
      sleep 3
      echo
      clear && sh $0
      ;;

    p )
      echo
      echo "###########################################"
      echo "      Installing Printing Essentials       "
      echo "###########################################"
      sleep 3
      echo
      echo "Please wait while packages install... "
      sudo pacman -S --needed --noconfirm ghostscript gsfonts cups cups-filters cups-pdf system-config-printer avahi system-config-printer foomatic-db-engine foomatic-db foomatic-db-ppds foomatic-db-nonfree foomatic-db-nonfree-ppds gutenprint foomatic-db-gutenprint-ppds > /dev/null 2>&1
      echo
      sudo systemctl enable --now avahi-daemon cups.socket
      echo
      sudo groupadd lp && sudo groupadd cups && sudo usermod -aG sys,lp,cups $(whoami)
      sleep 3
      echo
      echo "#######################################"
      echo "                 Done !                "
      echo "#######################################"
            clear && sh $0
      ;;

    h )
      echo
      echo "###########################################"
      echo "        Installing HP Drivers/Tools        "
      echo "###########################################"
      sleep 3
      echo
      $AUR_HELPER -S --needed python-pyqt5 hplip hplip-plugin
      sleep 3
      echo
      echo "#######################################"
      echo "                 Done !                "
      echo "#######################################"
            clear && sh $0
      ;;

    e )
      echo
      echo "############################################"
      echo "       Installing Epson Drivers/Tools       "
      echo "############################################"
      sleep 3
      echo
      $AUR_HELPER -S --needed epson-inkjet-printer-escpr epson-inkjet-printer-escpr2 epson-inkjet-printer-201310w epson-inkjet-printer-201204w imagescan
      sleep 3
      echo
      echo "#######################################"
      echo "                 Done !                "
      echo "#######################################"
            clear && sh $0
      ;;

    d )
      echo
      echo "#################################################"
      echo "#          Installing DualShock 4 Driver        #"
      echo "#################################################"
      echo
      $aur_helper -S --noconfirm aur/ds4drv aur/game-devices-udev
      echo
      echo "#################################################"
      echo "#        Done ! Returning to main menu..        #"
      echo "#################################################"
      clear && sh $0

      ;;

    s )
      echo
      echo "#################################################"
      echo "#  Installing PS-5 DualSense controller Driver  #"
      echo "#################################################"
      echo
      $aur_helper -S --noconfirm aur/dualsensectl
      echo
      echo "#################################################"
      echo "#        Done ! Returning to main menu..        #"
      echo "#################################################"
      clear && sh $0

      ;;
    
    x )
      echo
      echo "#################################################"
      echo "#  Installing Xbox One Wireless Gamepad Driver  #"
      echo "#################################################"
      echo
      $aur_helper -S --noconfirm aur/xpadneo-dkms
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
