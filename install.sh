#!/bin/sh

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
	ttf-nerd-fonts-symbols ttf-font-awesome\
	network-manager-applet networkmanager\
	discord\
	ffmpeg

git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si

yay -S mpvpaper
