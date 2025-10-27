#!/bin/sh

git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si

sudo pacman -S pipewire\
	pipewire-pulse\
	pavucontrol\
	neovim\
	fish\
	nvidia\
	xdg-desktop-portal-hyprland\
	network-manager-applet\
	waybar\
	dunst\
	grim slurp wl-clipboard\
	git\
	hyprpicker\
	thunar\
	nwg-look\
	rofi\
	tree\
	btop\
	ncdu\
	bat\
	eza\
	yazi
