#!/usr/bin/env bash

SRC="file"

mkdir -p ~/.config

rm -rf ~/.config/hypr ~/.config/kitty ~/.config/waybar

cp -r "$SRC/hypr" ~/.config/
cp -r "$SRC/kitty" ~/.config/
cp -r "$SRC/waybar" ~/.config/

sudo mkdir -p /etc/wireplumber/main.lua.d
sudo mkdir -p /etc/wireplumber/wireplumber.conf.d
sudo mkdir -p /usr/share/sddm/themes

sudo cp "$SRC/environment" /etc/environment
sudo cp "$SRC/51-disable-powersave-analog.lua" /etc/wireplumber/main.lua.d/51-disable-powersave-analog.lua
sudo cp "$SRC/51-disable-alsa-suspend.conf"   /etc/wireplumber/wireplumber.conf.d/51-disable-alsa-suspend.conf
sudo cp "$SRC/51-disable-analog-suspend.conf" /etc/wireplumber/wireplumber.conf.d/51-disable-analog-suspend.conf

sudo cp "$SRC/HOMOARAK.TTF" ~/.local/share/fonts/

sudo cp "$SRC/sddm.conf" /etc/sddm.conf
sudo cp -r "$SRC/sddm_spiderman" /usr/share/sddm/themes/sddm_spiderman
sudo cp -r "$SRC/backgrounds" /usr/share/backgrounds
