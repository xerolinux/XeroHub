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
echo "#                  Fixes/Tweaks                 #"
echo "#################################################"
tput sgr0
echo
echo "Hello $USER, what would you like to do today ?"
echo
echo "1. Install & Activate Firewald."
echo "2. Clear Pacman Cache (Free Space)."
echo "3. Restart PipeWire/PipeWire-Pulse."
echo "4. Launch Grub Theme Installer TUI."
echo "5. Unlock Pacman DB (In case of DB error)."
echo "6. Activate Flatpak Theming (Required If used)."
echo "7. Activate OS-Prober for Dual-Booting with other OS."
echo "8. Install/Activate Power Daemon for Laptops/Desktops."
echo
echo "Type Your Selection. Or type q to return to main menu."
echo

while :; do

read CHOICE

case $CHOICE in

    1 )
      echo
	  sleep 2
      sudo pacman -S --needed --noconfirm firewalld python-pyqt5 python-capng
      echo
      sudo systemctl enable --now firewalld.service
      sleep 2
      echo
      clear && sh $0

      ;;

    2 )
      echo
	  sleep 2
      sudo pacman -Scc
      sleep 2
      echo
      clear && sh $0

      ;;


    3 )
      echo
	  sleep 2
	  echo "#################################"
      echo "       Restarting PipeWire       "
      echo "#################################"
      sleep 1.5
      systemctl --user restart pipewire
      systemctl --user restart pipewire-pulse
      sleep 1.5
      echo
      echo "#################################"
      echo "        All Done, Try now       "
      echo "#################################"
	  sleep 2
      clear && sh $0

      ;;


    4)
      echo
	  sleep 2
	  cd ~ && git clone https://github.com/xerolinux/xero-grubs && cd ~/xero-grubs/ && sudo sh install.sh
	  sleep 2
      clear && sh $0

      ;;

    5 )
      echo
	  sleep 2
	  sudo rm /var/lib/pacman/db.lck
	  sleep 2
      clear && sh $0

      ;;


    6 )
      echo
	  sleep 2
	  echo "#####################################"
      echo "#    Activating Flatpak Theming.    #"
      echo "#####################################"
      sleep 3
      sudo flatpak override --filesystem=$HOME/.themes
      sudo flatpak override --filesystem=xdg-config/gtk-3.0:ro
      sudo flatpak override --filesystem=xdg-config/gtk-4.0:ro
      sleep 2
      echo
      echo "#####################################"
      echo "#     Flatpak Theming Activated     #"
      echo "#####################################"
	  sleep 3
      clear && sh $0

      ;;


    7 )
      echo
	  sleep 2
	  echo "#####################################"
      echo "#   Activating OS-Prober in Grub.   #"
      echo "#####################################"
      sleep 3
      sudo pacman -S --noconfirm os-prober
      sudo sed -i 's/#\s*GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' '/etc/default/grub'
      sudo os-prober
      sudo grub-mkconfig -o /boot/grub/grub.cfg
      sleep 2
      echo
      echo "#####################################"
      echo "#        Done! Reboot n Test        #"
      echo "#####################################"
	  sleep 3
      clear && sh $0

      ;;
        
    8 )
      echo
	  sleep 2
      sudo pacman -S --needed --noconfirm power-profiles-daemon
      echo
      sudo systemctl enable --now power-profiles-daemon
      echo
      sudo groupadd power && sudo usermod -aG power $(whoami)
      sleep 2
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
