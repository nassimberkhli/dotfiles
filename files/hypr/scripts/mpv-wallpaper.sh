#!/usr/bin/env bash
# Fond d'écran animé mpvpaper, optimisé batterie / chaleur.
#   - décodage matériel (GPU/VCN) au lieu du CPU  -> --hwdec=auto-safe --vo=gpu
#   - auto-pause (-p) : mpv se met en pause quand une fenêtre recouvre le bureau
#   - coupé entièrement sur batterie, relancé automatiquement sur secteur
#
# Le wildcard "*" cible TOUS les écrans dynamiquement : aucun nom d'écran
# (eDP-1, HDMI-A-1...) n'est codé en dur, ça suit le branchement automatiquement.

VIDEO="${1:-$HOME/.local/share/wallpapers/surfer-1080p.mp4}"
MONITORS="*"
MPV_OPTS="--loop --no-audio --hwdec=auto-safe --vo=gpu --really-quiet"

# Vrai si au moins une alimentation secteur (type "Mains") est branchée.
ac_online() {
    for t in /sys/class/power_supply/*/type; do
        [ "$(cat "$t" 2>/dev/null)" = "Mains" ] || continue
        [ "$(cat "${t%type}online" 2>/dev/null)" = "1" ] && return 0
    done
    return 1
}

start_wall() {
    pgrep -x mpvpaper >/dev/null 2>&1 && return
    mpvpaper -f -p -o "$MPV_OPTS" "$MONITORS" "$VIDEO"
}

stop_wall() {
    pkill -x mpvpaper 2>/dev/null
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
