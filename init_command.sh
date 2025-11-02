#!/bin/sh

systemctl --user start wireplumber pipewire pipewire-pulse
chsh -s /usr/bin/fish

sudo systemctl disable systemd-resolved
sudo systemctl disable systemd-networkd
sudo systemctl enable NetworkManager
sudo systemctl start NetworkManager
