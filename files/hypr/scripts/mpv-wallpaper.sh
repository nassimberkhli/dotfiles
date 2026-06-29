#!/usr/bin/env bash
# Fond d'écran : mpvpaper (animé) sur secteur, hyprpaper (statique) sur batterie.
#
# IMPORTANT : mpvpaper et hyprpaper ne peuvent PAS tourner en même temps.
# hyprpaper occupe la même couche de fond et MASQUE mpvpaper :
#   mpvpaper avertit lui-même « hyprpaper is running. This may block mpvpaper ».
# On bascule donc STRICTEMENT de l'un à l'autre :
#   - secteur  -> on coupe hyprpaper, on lance mpvpaper (animé, visible)
#   - batterie -> on coupe mpvpaper, on (re)lance hyprpaper (statique, sobre)
#
# Le wildcard "*" cible TOUS les écrans dynamiquement : aucun nom d'écran
# (eDP-1, HDMI-A-1...) n'est codé en dur, ça suit le branchement automatiquement.

VIDEO="${1:-$HOME/.local/share/wallpapers/surfer-1080p.mp4}"
MONITORS="*"
MPV_OPTS="--loop --no-audio --hwdec=auto-safe --vo=gpu --really-quiet"

# Vrai si au moins une alimentation secteur (type "Mains") est branchée.
ac_online() {
    local has_battery=0
    for t in /sys/class/power_supply/*/type; do
        [ "$(cat "$t" 2>/dev/null)" = "Battery" ] && has_battery=1
    done
    # Tour sans batterie → toujours sur secteur → fond animé
    [ "$has_battery" = "0" ] && return 0
    for t in /sys/class/power_supply/*/type; do
        [ "$(cat "$t" 2>/dev/null)" = "Mains" ] || continue
        [ "$(cat "${t%type}online" 2>/dev/null)" = "1" ] && return 0
    done
    return 1
}

# Secteur : fond animé. hyprpaper doit être coupé sinon mpvpaper reste invisible.
start_wall() {
    pkill -x hyprpaper 2>/dev/null
    pgrep -x mpvpaper >/dev/null 2>&1 && return
    mpvpaper -f -p -o "$MPV_OPTS" "$MONITORS" "$VIDEO"
}

# Batterie : fond statique. On coupe mpvpaper et on rétablit hyprpaper.
stop_wall() {
    pkill -x mpvpaper 2>/dev/null
    pgrep -x hyprpaper >/dev/null 2>&1 || hyprpaper >/dev/null 2>&1 &
}

# Boucle de surveillance de l'alimentation (coût CPU négligeable).
prev=""
while :; do
    ac_online && state=ac || state=bat
    if [ "$state" != "$prev" ]; then
        [ "$state" = ac ] && start_wall || stop_wall
        prev="$state"
    fi
    sleep 15
done
