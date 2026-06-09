#!/bin/sh

./packages.sh

# Réinstalle TOUT ce qui était présent sur l'ancienne machine (capturé via ./update.sh --repos)
if [ -f files/pkglist-officiel.txt ]; then
    sudo pacman -S --needed --noconfirm - <files/pkglist-officiel.txt
fi
if [ -f files/pkglist-aur.txt ] && command -v yay >/dev/null 2>&1; then
    yay -S --needed --noconfirm - <files/pkglist-aur.txt
fi

./update.sh --system

systemctl --user start wireplumber pipewire pipewire-pulse

chsh -s /usr/bin/fish

sudo systemctl disable systemd-resolved
sudo systemctl disable systemd-networkd
sudo systemctl enable NetworkManager
sudo systemctl start NetworkManager

fish -c "set -U fish_greeting"

systemctl enable tlp.service
systemctl enable NetworkManager-dispatcher.service
systemctl mask systemd-rfkill.service systemd-rfkill.socket

chmod u+rwx ~/.config/nvim
