#!/bin/sh
# ──────────────────────────────────────────────────────────────────────
#  packages.sh — AMORÇAGE uniquement.
#
#  La liste des paquets n'est PLUS ici : elle est dynamique, générée par
#  `./update.sh --repos` dans files/pkglist-officiel.txt (pacman) et
#  files/pkglist-aur.txt (AUR), puis installée par install.sh.
#
#  Ce script installe seulement ce que les listes ne peuvent PAS capturer :
#    - de quoi construire des paquets AUR (base-devel, git)
#    - yay (nécessaire AVANT d'installer depuis pkglist-aur.txt)
#    - les curseurs Vimix (build git, ce n'est pas un paquet)
# ──────────────────────────────────────────────────────────────────────
set -e

# Prérequis pour construire des paquets AUR
sudo pacman -S --needed --noconfirm base-devel git

# yay (helper AUR) — uniquement s'il n'est pas déjà là
if ! command -v yay >/dev/null 2>&1; then
    cd /tmp || exit 1
    rm -rf yay-bin
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin || exit 1
    makepkg -si --noconfirm
fi

# Curseurs Vimix (build git -> non capturé par pacman -Qqem)
cd /tmp || exit 1
rm -rf Vimix-cursors
git clone https://github.com/vinceliuice/Vimix-cursors.git
cd Vimix-cursors || exit 1
sudo ./install.sh
cd /tmp || exit 1
rm -rf Vimix-cursors
