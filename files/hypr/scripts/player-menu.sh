#!/usr/bin/env bash
# Menu rofi central de contrôle média.
# Chaque action passe par swayosd-client --playerctl (donc l'OSD s'affiche aussi).
# Esc fait disparaître l'interface.

# Cible le lecteur ACTIF suivi par playerctld (celui que le menu affiche), en le
# nommant EXPLICITEMENT : le « --player auto » de swayosd 0.3.1 fait sa propre
# sélection MPRIS et peut viser un autre lecteur (ex. mpv alors que le menu
# affiche Firefox) → l'OSD s'affiche mais rien ne se passe sur la bonne vidéo.
LOG=/tmp/player-menu.log
osd() {
    local player action=$1
    player=$(playerctl metadata --format '{{playerInstance}}' 2>/dev/null)
    # Firefox gère mal « Stop » : son contrôleur média se désynchronise, l'instance
    # MPRIS disparaît puis revient cassée (Pause ignoré jusqu'au rechargement de
    # l'onglet). On convertit donc Stop en Pause pour Firefox.
    case "$player" in firefox*) [ "$action" = stop ] && action=pause ;; esac
    {
        echo "=== $(date +%T) action=$action player=${player:-auto} ==="
        echo "players: $(playerctl -l 2>&1 | tr '\n' ' ')"
        echo "status avant: $(playerctl status 2>&1)"
        swayosd-client --playerctl "$action" --player "${player:-auto}"
        echo "swayosd exit: $?"
        sleep 0.4
        echo "status apres: $(playerctl status 2>&1)"
    } >>"$LOG" 2>&1
}

# Lit une URL / playlist (YouTube, etc.) SANS ouvrir de navigateur : mpv joue le
# flux en audio via yt-dlp, et expose une interface MPRIS (grâce à mpv-mpris) —
# donc playerctl et ce menu peuvent ensuite la contrôler (play/pause, suivant…).
SOCK="${XDG_RUNTIME_DIR:-/tmp}/player-menu-mpv.sock"
play_url() {
    command -v mpv >/dev/null || {
        notify-send "player-menu" "mpv n'est pas installé"
        return
    }
    command -v yt-dlp >/dev/null ||
        notify-send "player-menu" "yt-dlp manquant : sudo pacman -S yt-dlp mpv-mpris"
    local url mpris
    url=$(printf '' | rofi -dmenu -p "URL / playlist" \
        -mesg "YouTube, SoundCloud, fichier… (audio, sans navigateur)")
    [ -z "$url" ] && return
    # mpv-mpris est auto-chargé depuis /etc/mpv/scripts/ → pas besoin de --script.
    # Remplace une éventuelle lecture précédente lancée depuis ce menu.
    pkill -f "player-menu-mpv.sock" 2>/dev/null
    setsid -f mpv --no-video --force-window=no --idle=no \
        --input-ipc-server="$SOCK" \
        --ytdl-format="bestaudio/best" \
        -- "$url" >/dev/null 2>&1
}

while true; do
    status=$(playerctl status 2>/dev/null || echo "Aucun lecteur")
    title=$(playerctl metadata --format '{{ artist }} — {{ title }}' 2>/dev/null)
    [ -z "$title" ] && title="—"

    choice=$(printf '%s\n' \
        "⏯  Play / Pause" \
        "⏭  Suivant" \
        "⏮  Précédent" \
        "⏹  Stop" \
        "⇄  Shuffle" \
        "⊕  Lire une URL / playlist (mpv)" |
        rofi -dmenu -i -no-case-sensitive -normalize-match \
            -p "♪ $status" -mesg "$title" -no-custom)

    case "$choice" in
    "⏯  Play / Pause") osd play-pause ;;
    "⏭  Suivant") osd next ;;
    "⏮  Précédent") osd prev ;;
    "⏹  Stop") osd stop ;;
    "⇄  Shuffle") osd shuffle ;;
    "⊕  Lire une URL / playlist (mpv)") play_url ;;
    *) exit 0 ;; # Esc
    esac
done
