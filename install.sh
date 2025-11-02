#!/bin/sh

sudo pacman -S pipewire\
	pipewire-pulse\
	pavucontrol\
	neovim\
	fish\
	nvidia\
	xdg-desktop-portal-hyprland\
	network-manager-applet\
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
	ffmpeg\
	hyprpaper qt6-5compat qt6-declarative qt6-svg qt6-virtualkeyboard qt6-multimedia-ffmpeg vlc\
	hyprlock

git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si

yay -S mpvpaper-git\
	waybar\
