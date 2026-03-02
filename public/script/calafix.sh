#!/usr/bin/env bash
clear
sudo tee /etc/calamares/modules/shellprocess-update.conf << 'EOF'
i18n:
    name: "Updating system packages..."
dontChroot: false
timeout: 7200
script:
    - command: "pacman -Syy --noconfirm"
      timeout: 600
    - command: "sed 's/^SigLevel.*/SigLevel = Never/' /etc/pacman.conf > /tmp/pacman-nosig.conf"
      timeout: 10
    - command: "pacman -S --noconfirm --needed --config /tmp/pacman-nosig.conf archlinux-keyring"
      timeout: 300
    - command: "rm -f /tmp/pacman-nosig.conf"
      timeout: 10
    - command: "pacman-key --populate archlinux"
      timeout: 120
    - command: "pacman -Su --noconfirm --disable-download-timeout"
      timeout: 5400
EOF
