#!/usr/bin/env bash
set -e

# Add this at the start of the script, right after the shebang
trap 'clear && exec "$0"' INT

# Check if being run from xero-cli
if [ -z "$AUR_HELPER" ]; then
    echo
    gum style --border double --align center --width 70 --margin "1 2" --padding "1 2" --border-foreground 196 "$(gum style --foreground 196 'ERROR: This script must be run through the toolkit.')"
    echo
    gum style --border normal --align center --width 70 --margin "1 2" --padding "1 2" --border-foreground 33 "$(gum style --foreground 33 'Or use this command instead:') $(gum style --bold --foreground 47 'clear && xero-cli -m')"
    echo
    exit 1
fi

# Function to display the menu

display_menu() {
    clear
    gum style --foreground 212 --border double --padding "1 1" --margin "1 1" --align center "System Fixes & Tweaks"
    echo
    gum style --foreground 141 "Hello $USER, what would you like to do today?"
    echo
    gum style --foreground 7 "1. Install & Activate Firewalld."
    gum style --foreground 7 "2. Clear Pacman Cache (Free Space)."
    gum style --foreground 7 "3. Unlock Pacman DB (In case of DB error)."
    gum style --foreground 7 "4. Activate v4l2loopback for OBS-VirtualCam."
    gum style --foreground 7 "5. Change Autologin Session X11/Wayland (SDDM)."
    gum style --foreground 7 "6. Disable Debug flag in MAKEPKG (Package Devs)."
    echo
    gum style --foreground 39 "a. Build Updated Arch ISO."
    gum style --foreground 196 "s. Reset KDE/Xero Layout back to Stock."
    gum style --foreground 40 "w. WayDroid Installation Guide (Website Link)."
    gum style --foreground 172 "m. Update Arch Mirrorlist, for faster download speeds."
    gum style --foreground 111 "g. Fix Arch GnuPG Keyring in case of pkg signature issues."
}

# Function for each task

install_firewalld() {
    echo
    gum style --foreground 7 "########## Installing Firewalld ##########"
    echo
    if ! sudo pacman -S --needed --noconfirm firewalld python-pyqt5 python-capng; then
        gum style --foreground 196 "Failed to install packages"
        exit 1
    fi
    if ! sudo systemctl enable --now firewalld.service; then
        gum style --foreground 196 "Failed to enable firewalld service"
        exit 1
    fi
    echo
    gum style --foreground 7 "########## All Done, Enjoy! ##########"
    sleep 3
    main
}

clear_pacman_cache() {
    echo
    sudo pacman -Scc
    sleep 2
    main
}

unlock_pacman_db() {
    echo
    sudo rm /var/lib/pacman/db.lck || exit 1
    sleep 2
    main
}

activate_v4l2loopback() {
    echo
    gum style --foreground 7 "########## Setting up v4l2loopback ##########"
    echo
    sudo pacman -S --noconfirm --needed v4l2loopback-dkms v4l2loopback-utils || exit 1
    echo "v4l2loopback" | sudo tee /etc/modules-load.d/v4l2loopback.conf > /dev/null
    echo 'options v4l2loopback exclusive_caps=1 card_label="OBS Virtual Camera"' | sudo tee /etc/modprobe.d/v4l2loopback.conf > /dev/null
    echo
    gum style --foreground 7 "Please reboot your system for changes to take effect."
    sleep 2
    main
}

change_sddm_autologin() {
    SDDM_CONF="/etc/sddm.conf.d/kde_settings.conf"

    switch_session() {
        echo
        echo "Which session do you want to switch to ?"
        echo
        echo "1) Wayland"
        echo "2) Xorg (X11)"
        echo
        read -rp "Enter your choice [1 or 2]: " choice

        case $choice in
            1)
                echo "Switching to Wayland..."
                sudo sed -i 's|Session=plasmax11|Session=plasma|' "$SDDM_CONF"
                echo "Session switched to Wayland."
                ;;
            2)
                echo "Switching to Xorg (X11)..."
                sudo sed -i 's|Session=plasma|Session=plasmax11|' "$SDDM_CONF"
                echo "Session switched to Xorg (X11)."
                ;;
            *)
                echo "Invalid choice. Please enter 1 or 2."
                switch_session
                ;;
        esac

        echo "Please reboot to apply..."
        sleep 6
        main
    }

    switch_session
}

build_archiso() {
    echo
    gum style --foreground 7 "########## Arch ISO Builder ##########"
    sleep 3
    mkdir -p ~/ArchWork ~/ArchOut
    sleep 3
    echo
    sudo mkarchiso -v -w ~/ArchWork -o ~/ArchOut /usr/share/archiso/configs/releng || exit 1
    echo
    echo "Step 3 - Cleaning up...."
    echo
    sudo rm -rf ~/ArchWork/
    echo
    gum style --foreground 7 "########## Done ! Check ~/ArchOut ##########"
    sleep 6
    main
}

reset_everything() {
   echo
   gum style --foreground 69 "########## Settings Reset Tool ##########"
   echo
   if gum confirm "Are you using the XeroLinux Distro ?"; then
       cp -Rf ~/.config ~/.config-backup-$(date +%Y.%m.%d-%H.%M) && cp -aT /etc/skel/. $HOME/
   else
       cp -Rf ~/.config ~/.config-backup-$(date +%Y.%m.%d-%H.%M) && rm -rf $HOME/.config
   fi

   for i in {15..1}; do
       dialog --infobox "Rebooting in $i seconds..." 3 30
       sleep 1
   done

   reboot || exit 1
}

waydroid_guide() {
   echo
   gum style --foreground 36 "Opening Guide..."
   sleep 3
   xdg-open "https://xerolinux.xyz/posts/waydroid-guide/" > /dev/null 2>&1
   sleep 3
   main
}

update_mirrorlist() {
   echo
   gum style --foreground 69 "########## Updating Mirrors To Fastest Ones ##########"

   if ! command -v rate-mirrors &> /dev/null; then
       echo "rate-mirrors is not installed. Installing..."
       $AUR_HELPER -S --noconfirm --needed rate-mirrors-bin || exit 1
   fi
   echo
   if gum confirm "Do you want to update Chaotic-AUR mirrorlist too?"; then
       rate-mirrors --allow-root --protocol https arch | sudo tee /etc/pacman.d/mirrorlist || exit 1
       rate-mirrors --allow-root --protocol https chaotic-aur | sudo tee /etc/pacman.d/chaotic-mirrorlist || exit 1
   else
       rate-mirrors --allow-root --protocol https arch | sudo tee /etc/pacman.d/mirrorlist || exit 1
   fi

   sudo pacman -Syy || exit 1
   echo
   gum style --foreground 69 "########## Done! Updating should go faster ##########"

   sleep 3
   main
}

fix_gpg_keyring() {
   echo
   gum style --foreground 69 "########## Fixing Pacman Databases.. ##########"
   echo
   sleep 2
   sudo rm -r /etc/pacman.d/gnupg/* || exit 1
   sleep 2
   sudo pacman-key --init && sudo pacman-key --populate || exit 1
   sleep 2
   echo "keyserver hkp://keyserver.ubuntu.com:80" | sudo tee --append /etc/pacman.d/gnupg/gpg.conf
   sleep 2
   sudo pacman -Syy --noconfirm archlinux-keyring || exit 1
   echo
   gum style --foreground 69 "########## Done! Try Update now & Report ##########"

   sleep 3
   main
}

restart() {
    # Notify the user that the system is rebooting
    echo
    gum style --foreground 69 "Rebooting System..."
    sleep 3

    # Countdown from 5 to 1
    for i in {5..1}; do
        dialog --infobox "Rebooting in $i seconds..." 3 30
        sleep 1
    done

    # Execute the reboot command
    reboot
}

disable_debug() {
    echo
    gum style --foreground 69 "Makepkg Debug disabler..."
    sleep 3
    echo
    echo "This script will disable pkg debug flag"
    echo
    read -rp "Are you sure you want to proceed? (y/n) " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        if ! sudo test -w "/etc/makepkg.conf"; then
            gum style --foreground 196 "Error: Cannot write to /etc/makepkg.conf. Are you root?"
            exit 1
        fi

        if grep -q "!debug lto" /etc/makepkg.conf; then
            echo
            gum style --foreground 7 "Debugging is already off - nothing to do"
        else
            echo
            gum style --foreground 7 "Disabling !debug"
            echo
            if ! sudo sed -i "s/debug lto/!debug lto/g" /etc/makepkg.conf; then
                gum style --foreground 196 "Failed to modify makepkg.conf"
                exit 1
            fi
            gum style --foreground 7 "Successfully disabled debug flag"
        fi
    else
        echo
        gum style --foreground 7 "Operation canceled."
    fi
    sleep 2
    main
}

main() {
    # Check if script is run as root
    if [[ $EUID -eq 0 ]]; then
        gum style --foreground 196 "This script should not be run as root"
        exit 1
    fi

    while :; do
        display_menu
        echo
        read -rp "Enter your choice, 'r' to reboot or 'q' for main menu : " CHOICE

        case $CHOICE in
           1) install_firewalld ;;
           2) clear_pacman_cache ;;
           3) unlock_pacman_db ;;
           4) activate_v4l2loopback ;;
           5) change_sddm_autologin ;;
           6) disable_debug ;;
           a) build_archiso ;;
           s) reset_everything ;;
           w) waydroid_guide ;;
           m) update_mirrorlist ;;
           g) fix_gpg_keyring ;;
           r) restart ;;
           q) clear && exec xero-cli -m ;;
           *) gum style --foreground 31 "Invalid choice. Please select a valid option." ;;
        esac

        sleep 3
    done
}

main
