#!/bin/sh

systemctl --user start wireplumber pipewire pipewire-pulse
chsh -s /usr/bin/fish

cd ~
cd .ssh
ssh-keygen -a 100 -t ed25519
ssh -vT git@github.com

git config --global user.email "nassim.berkhli@outlook.com"
git config --global user.name "nojo"
