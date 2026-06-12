#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────
#  bar-osd.sh — applique l'action volume/luminosité PUIS pousse la nouvelle
#  valeur vers le daemon d'OSD (bar-osd-daemon.py) via un FIFO.
#
#  Usage :
#    bar-osd.sh volume     raise|lower|mute
#    bar-osd.sh brightness raise|lower
# ──────────────────────────────────────────────────────────────────────────
set -u

FIFO="${XDG_RUNTIME_DIR:-/tmp}/bar-osd.fifo"
DAEMON="$HOME/.config/hypr/scripts/bar-osd-daemon.py"
SINK="@DEFAULT_AUDIO_SINK@"
STEP="5"

# Démarre le daemon s'il n'écoute pas encore.
ensure_daemon() {
    [ -p "$FIFO" ] && pgrep -f "bar-osd-daemon.py" >/dev/null && return
    setsid -f python "$DAEMON" >/dev/null 2>&1
    for _ in 1 2 3 4 5 6 7 8 9 10; do
        [ -p "$FIFO" ] && break
        sleep 0.1
    done
}

# Lit volume (%) + état muet du sink par défaut via wpctl.
read_volume() {
    local raw vol muted
    raw=$(wpctl get-volume "$SINK" 2>/dev/null)   # "Volume: 0.45 [MUTED]"
    vol=$(awk '{printf "%d", $2 * 100}' <<<"$raw")
    muted=0
    [[ "$raw" == *MUTED* ]] && muted=1
    echo "$vol $muted"
}

case "${1:-}" in
    volume)
        case "${2:-}" in
            raise) wpctl set-volume -l 1.0 "$SINK" "${STEP}%+" ;;
            lower) wpctl set-volume "$SINK" "${STEP}%-" ;;
            mute)  wpctl set-mute "$SINK" toggle ;;
            *) exit 1 ;;
        esac
        read -r vol muted < <(read_volume)
        msg="volume $vol $muted"
        ;;
    brightness)
        case "${2:-}" in
            raise) brightnessctl -e4 -n2 set "${STEP}%+" >/dev/null ;;
            lower) brightnessctl -e4 -n2 set "${STEP}%-" >/dev/null ;;
            *) exit 1 ;;
        esac
        pct=$(brightnessctl -m | awk -F, '{gsub("%","",$4); print $4}')
        msg="brightness $pct 0"
        ;;
    *)
        echo "usage: bar-osd.sh volume raise|lower|mute | brightness raise|lower" >&2
        exit 1
        ;;
esac

ensure_daemon
# Écriture non bloquante (FIFO ouvert en read-write côté écrivain aussi).
printf '%s\n' "$msg" 1<>"$FIFO"
