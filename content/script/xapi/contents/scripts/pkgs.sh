#!/bin/bash
#set -e
##################################################################################################################
# Written to be used on 64 bits computers
# Author 	: 	DarkXero
# Website 	: 	http://xerolinux.xyz
##################################################################################################################
clear
tput setaf 5
echo "###################################################################################"
echo "#                             Essential Pkg Installer                             #"
echo "###################################################################################"
tput sgr0
echo
echo "Hello $USER, this will install extra packages, some require Xero Repo."
echo
echo "################# Various Extra Pkgs #################"
echo
echo "a. PipeWire/Bluetooth Packages."
echo "b. Extra Input and Trackpad Tools."
echo "c. Recommended Tools (AUR & Native)."
echo
echo "################### Virtualization ###################"
echo
echo "v. VirtualBox (Xero Repo)."
echo "k. Virt-Manager (Xero Repo)."
echo
echo "##################### OBS-Studio #####################"
echo
echo "o. Install OBS-Studio + Plugins (Flathub)."
echo "l. Activate v4l2loopback for OBS-VirtualCam."
echo
echo "Type Your Selection. Or type q to return to main menu."
echo

while :; do

read CHOICE

case $CHOICE in

    a )
      echo
      echo "###########################################"
      echo "        Installing Audio/Bluetooth         "
      echo "###########################################"
      echo
      echo "Installing PipeWire packages..."
      echo
      sudo pacman -S --needed gstreamer gst-libav gst-plugins-bad gst-plugins-base gst-plugins-ugly gst-plugins-good gst-plugin-pipewire libdvdcss alsa-utils wireplumber alsa-firmware  pipewire-jack pavucontrol lib32-pipewire-jack pipewire libpipewire  pipewire-alsa pipewire-pulse pipewire-v4l2 pipewire-x11-bell pipewire-zeroconf  realtime-privileges sof-firmware ffmpeg ffmpegthumbs ffnvcodec-headers mesa-utils
      sleep 3
      echo
      echo "Installing Bluetooth packages..."
      echo
      sudo pacman -S --needed bluez bluez-utils bluez-plugins bluez-hid2hci bluez-cups bluez-libs bluez-tools
      sudo systemctl enable --now  bluetooth.service
      echo
      echo "#######################################"
      echo "                 Done !                "
      echo "#######################################"
            clear && sh $0
      ;;

    b )
      echo
      echo "########################################"
      echo "      Installing Input Essentials       "
      echo "########################################"
      echo
      echo "Please wait while packages install... "
      echo
      $AUR_HELPER -S piper xf86-input-void xf86-input-evdev iio-sensor-proxy xf86-input-libinput xf86-input-synaptics xf86-input-elographics gestures libinput-gestures
      echo
      sudo gpasswd -a $USER input
      libinput-gestures-setup autostart
      sleep 3
      echo
      echo "#######################################"
      echo "           Done Plz Reboot !           "
      echo "#######################################"
            clear && sh $0
      ;;

    c )
      echo
      echo "##########################################"
      echo "       Installing Recommended tools       "
      echo "##########################################"
      echo
      echo "Please wait while packages install... "
      echo
      $AUR_HELPER -S downgrade yt-dlg mkinitcpio-firmware hw-probe pkgstats alsi update-grub rate-mirrors-bin ocs-url expac linux-headers linux-firmware-marvell eza numlockx lm_sensors appstream-glib bat bat-extras neofetch pacman-contrib pacman-bintrans pacman-mirrorlist yt-dlp gnustep-base parallel dex bash make libxinerama logrotate bash-completion gtk-update-icon-cache gnome-disk-utility appmenu-gtk-module dconf-editor dbus-python lsb-release asciinema playerctl s3fs-fuse vi duf gcc git yad zip xdo inxi meld lzop nmon mkinitcpio-archiso mkinitcpio-nfs-utils tree vala btop lshw expac fuse3 meson unace unrar unzip p7zip rhash sshfs vnstat nodejs cronie hwinfo arandr assimp netpbm wmctrl grsync libmtp polkit sysprof gparted hddtemp mlocate fuseiso gettext node-gyp graphviz inetutils appstream cifs-utils ntfs-3g nvme-cli exfatprogs f2fs-tools man-db man-pages tldr wget python-pip python-cffi python-numpy python-docopt python-pyaudio
      sleep 3
      echo
      echo "#######################################"
      echo "                 Done !                "
      echo "#######################################"
            clear && sh $0
      ;;
    
    v )
      echo
      sleep 2
      sudo pacman -S virtualbox-meta
      sleep 2
      echo
      echo "#################################"
      echo "        Done, Plz Reboot !       "
      echo "#################################"
      sleep 3
      clear && sh $0

      ;;

    k )
      sleep 2
      sudo pacman -S virt-manager-meta
      sleep 3
      echo
      echo "####################################"
      echo "       Done, Plz Reboot & Run       "
      echo "    sudo virsh net-start default    "
      echo "  sudo virsh net-autostart default  "
      echo "####################################"
      sleep 10
      clear && sh $0

      ;;

    o )
      echo
      echo "###########################################"
      echo "           Installing OBS-Studio           "
      echo "###########################################"
      sleep 3
      flatpak install com.obsproject.Studio com.obsproject.Studio.Plugin.OBSVkCapture com.obsproject.Studio.Plugin.Gstreamer com.obsproject.Studio.Plugin.TransitionTable  com.obsproject.Studio.Plugin.waveform com.obsproject.Studio.Plugin.InputOverlay com.obsproject.Studio.Plugin.SceneSwitcher com.obsproject.Studio.Plugin.MoveTransition com.obsproject.Studio.Plugin.ScaleToSound com.obsproject.Studio.Plugin.WebSocket com.obsproject.Studio.Plugin.DroidCam com.obsproject.Studio.Plugin.BackgroundRemoval com.obsproject.Studio.Plugin.GStreamerVaapi com.obsproject.Studio.Plugin.VerticalCanvas org.freedesktop.Platform.VulkanLayer.OBSVkCapture
      sleep 3
      echo "#######################################"
      echo "                 Done !                "
      echo "#######################################"
      clear && sh $0
      ;;

    l )
      echo
      echo "##########################################"
      echo "          Setting up v4l2loopback         "
      echo "##########################################"
      sleep 3
      sudo pacman -S --noconfirm v4l2loopback-dkms
      sleep 3
      # Create or append to /etc/modules-load.d/v4l2loopback.conf
      echo "v4l2loopback" | sudo tee /etc/modules-load.d/v4l2loopback.conf > /dev/null

      # Create /etc/modprobe.d/v4l2loopback.conf with specified content
      echo 'options v4l2loopback exclusive_caps=1 card_label="OBS Virtual Camera"' | sudo tee /etc/modprobe.d/v4l2loopback.conf > /dev/null

      # Prompt user to reboot
      echo "Please reboot your system for changes to take effect."
      sleep 2
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
