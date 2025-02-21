#!/bin/bash
#set -e
echo "######################################"
echo "Setting up ZSH With p10k & OMZ Plugins"
echo "######################################"
sleep 2
echo "Step 1 - Grabing Necessary Fonts"
echo "################################"
sudo pacman -S --needed --noconfirm zsh grml-zsh-config
$AUR_HELPER -S --noconfirm ttf-meslo-nerd siji-git ttf-unifont noto-color-emoji-fontconfig xorg-fonts-misc ttf-dejavu ttf-meslo-nerd-font-powerlevel10k noto-fonts-emoji powerline-fonts zsh-theme-powerlevel10k
sleep 2
echo "Step 2 - Grabing OhMyZsh & Plugins"
echo "##################################"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
sleep 2
echo "Step 3 - Grabing PowerLevel10k Theme"
echo "#####################################"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
cd $HOME/ && wget https://raw.githubusercontent.com/xerolinux/xero-fixes/main/conf/.p10k.zsh \
&& wget https://raw.githubusercontent.com/xerolinux/xero-fixes/main/conf/.zshrc
sleep 2
echo "Step 4 - Setting Default Shell to ZSH"
echo "#####################################"
sudo chsh $USER -s /bin/zsh
echo "#####################################"
echo "     Done ! Now Logout & back in     "
echo "#####################################"
