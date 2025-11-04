#!/usr/bin/env bash

declare -A FILES

# ~/.config
FILES["hypr"]="$HOME/.config/hypr"
FILES["kitty"]="$HOME/.config/kitty"
FILES["waybar"]="$HOME/.config/waybar"
FILES["fish"]="$HOME/.config/fish"
FILES["nvim"]="$HOME/.config/nvim"

# /etc
FILES["environment"]="/etc/environment"
FILES["51-disable-powersave-analog.lua"]="/etc/wireplumber/main.lua.d/51-disable-powersave-analog.lua"
FILES["51-disable-alsa-suspend.conf"]="/etc/wireplumber/wireplumber.conf.d/51-disable-alsa-suspend.conf"
FILES["51-disable-analog-suspend.conf"]="/etc/wireplumber/wireplumber.conf.d/51-disable-analog-suspend.conf"
FILES["sddm.conf"]="/etc/sddm.conf"

# /usr/share
FILES["HOMOARAK.TTF"]="/usr/share/fonts/HOMOARAK.TTF"
FILES["sddm_spiderman"]="/usr/share/sddm/themes/sddm_spiderman"
FILES["backgrounds"]="/usr/share/backgrounds"
FILES["tlp"]="/usr/share/tlp"

get_dest() {
    local key="$1"
    echo "${FILES[$key]}"
}
