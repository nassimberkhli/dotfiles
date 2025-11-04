#!/bin/sh
sudo pacman -S --needed \
    pipewire \
    pipewire-pulse \
    pavucontrol \
    neovim \
    fish \
    nvidia \
    xdg-desktop-portal-hyprland \
    networkmanager \
    network-manager-applet \
    dunst \
    grim \
    slurp \
    wl-clipboard \
    git \
    hyprpicker \
    thunar \
    nwg-look \
    rofi \
    tree \
    btop \
    ncdu \
    bat \
    eza \
    ttf-nerd-fonts-symbols \
    ttf-font-awesome \
    discord \
    ffmpeg \
    hyprpaper \
    qt6-5compat qt6-declarative qt6-svg qt6-virtualkeyboard qt6-multimedia-ffmpeg \
    vlc \
    hyprlock \
    nodejs npm \
    tlp tlp-rdw tp_smapi \
    git curl unzip tar nodejs npm

# yay
cd /tmp || exit 1
if [ ! -d yay-bin ]; then
    git clone https://aur.archlinux.org/yay-bin.git
fi
cd yay-bin || exit 1
makepkg -si --noconfirm

# AUR
yay -S --noconfirm \
    mpvpaper-git \
    waybar

git clone https://github.com/vinceliuice/Vimix-cursors.git
cd Vimix-cursors
sudo ./install.sh
sudo ./build.sh
cd ..
rm -r Vimix-cursors
