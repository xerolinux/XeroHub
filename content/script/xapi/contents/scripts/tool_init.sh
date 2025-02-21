#!/bin/bash
#set -e
##################################################################################################################
# Written to be used on 64 bits computers
# Author 	: 	DarkXero
# Website 	: 	http://xerolinux.xyz
##################################################################################################################
clear
tput setaf 5
echo "############################################################################"
echo "#                           Initial System Setup                           #"
echo "############################################################################"
tput sgr0
echo
echo "Hello $USER, Please Select What To Do."
echo
echo "############ Initial Setup Section ############"
echo
echo "x. Activate XeroLinux Repo (Req. for some pkgs)."
echo "f. Activate Flathub Repositories (Req. for OBS)."
echo "t. Enable fast multithreaded package compilation."
echo "m. Update Arch Mirrorlist, for faster download speeds."
echo "g. Fix Arch GnuPG Keyring in case of pkg signature issues."
echo
echo "########## GUI Package Managers ##########"
echo
echo "o. Install OctoPi GUI."
echo "p. Install Pamac-All GUI."
echo
echo "Type Your Selection. Or type q to return to main menu."
echo

while :; do

read CHOICE

case $CHOICE in

    x )
      echo
      echo "###########################################"
      echo "             Adding & Xero Repo            "
      echo "###########################################"
      sleep 3
      sudo cp /etc/pacman.conf /etc/pacman.conf.backup && \
      echo -e '\n[xerolinux]\nSigLevel = Optional TrustAll\nServer = https://repos.xerolinux.xyz/$repo/$arch' | sudo tee -a /etc/pacman.conf
      echo
      sudo pacman -Syy
      sleep 3
      echo "#######################################"
      echo "                 Done !                "
      echo "#######################################"
            clear && sh $0
      ;;

    f )
      echo
      echo "##########################################"
      echo "       Adding & Activating Flatpaks       "
      echo "##########################################"
      sleep 3
      echo
      sudo pacman -S --noconfirm flatpak
      sleep 3
      echo "#######################################"
      echo "                 Done !                "
      echo "#######################################"
            clear && sh $0
      ;;

    t )
      echo
      echo "###########################################"
      echo "      Enabling multithread compilation     "
      echo "###########################################"
      sleep 3
      echo
      numberofcores=$(grep -c ^processor /proc/cpuinfo)

      if [ $numberofcores -gt 1 ]
      then
        echo "You have " $numberofcores" cores."
        echo "Changing the makeflags for "$numberofcores" cores."
        sudo sed -i 's/#MAKEFLAGS="-j2"/MAKEFLAGS="-j'$(($numberofcores+1))'"/g' /etc/makepkg.conf;
        echo
        echo "Changing the compression settings for "$numberofcores" cores."
        echo
        sudo sed -i 's/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -z - --threads=0)/g' /etc/makepkg.conf
        sudo sed -i 's/COMPRESSZST=(zstd -c -z -q -)/COMPRESSZST=(zstd -c -z -q - --threads=0)/g' /etc/makepkg.conf
        sudo sed -i "s/PKGEXT='.pkg.tar.xz'/PKGEXT='.pkg.tar.zst'/g" /etc/makepkg.conf
      else
        echo
        echo "No change."
      fi
      sleep 3
      echo
      echo "#######################################"
      echo "                 Done !                "
      echo "#######################################"
            clear && sh $0
      ;;

    m )
      echo
      echo "#################################"
      echo "#   Fixing Pacman Databases..   #"
      echo "#################################"
      sleep 2
      echo
      echo "Step 1 - Deleting Existing Keys.. "
      echo "##################################"
      echo
      sudo rm -r /etc/pacman.d/gnupg/*
      sleep 2
      echo
      echo "Step 2 - Populating Keys.."
      echo "##########################"
      echo
      sudo pacman-key --init && sudo pacman-key --populate
      sleep 2
      echo
      echo "Step 3 - Adding Ubuntu keyserver.."
      echo "##################################"
      echo
      echo "keyserver hkp://keyserver.ubuntu.com:80" | sudo tee --append /etc/pacman.d/gnupg/gpg.conf
      echo
      echo "Step 4 - Updating ArchLinux Keyring.."
      echo "#####################################"
      echo
      sudo pacman -Syy --noconfirm archlinux-keyring
      sleep 3
      echo
      echo "#######################################"
      echo "    Done ! Try Update now & Report     "
      echo "#######################################"
            clear && sh $0
      ;;

    g )
      echo
      echo "##########################################"
      echo "     Updating Mirrors To Fastest Ones     "
      echo "##########################################"
	  sleep 3
	  echo
	  sudo reflector --verbose -phttps -f10 -l10 --sort rate --save /etc/pacman.d/mirrorlist && sudo pacman -Syy
	  sleep 3
	  echo
      echo "#######################################"
      echo "    Done ! Updating should go faster   "
      echo "#######################################"
            clear && sh $0
      ;;

    o )
      echo
      echo "##########################################"
      echo "             Installing Octopi            "
      echo "##########################################"
      sleep 3
      $AUR_HELPER -S octopi alpm_octopi_utils octopi-notifier-noknotify
      sleep 3
      echo "#######################################"
      echo "                 Done !                "
      echo "#######################################"
            clear && sh $0
      ;;

    p )
      echo
      echo "##########################################"
      echo "            Installing Pamac-All          "
      echo "##########################################"
      sleep 3
      $AUR_HELPER -S pamac-all pamac-cli libpamac-full
      sleep 3
      echo "#######################################"
      echo "                 Done !                "
      echo "#######################################"
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
