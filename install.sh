#!/bin/sh

./install_command.sh

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
