#!/usr/bin/env bash
# ~/.local/bin/hypr-spiderman-wall.sh

set -euo pipefail

LOG="/tmp/hypr-spiderman.log"
echo "---- $(date) (start) ----" >> "$LOG"

SIG="${HYPRLAND_INSTANCE_SIGNATURE:-}"
if [[ -z "$SIG" ]]; then
    echo "Pas de HYPRLAND_INSTANCE_SIGNATURE" | tee -a "$LOG"
    exit 1
fi

UID_NUM=$(id -u)

CANDIDATES=(
    "/run/user/${UID_NUM}/hypr/${SIG}/.socket2.sock"
    "/tmp/hypr/${SIG}/.socket2.sock"
)

HYPRSOCK=""
for c in "${CANDIDATES[@]}"; do
    if [[ -S "$c" ]]; then
        HYPRSOCK="$c"
        break
    fi
done

if [[ -z "$HYPRSOCK" ]]; then
    echo "Aucun socket2 trouvé" | tee -a "$LOG"
    exit 1
fi

echo "Socket utilisé: $HYPRSOCK" >> "$LOG"
echo "WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-<vide>}" >> "$LOG"

# workspace initial
CURRENT_WS=$(hyprctl activeworkspace -j | jq -r '.id')
echo "Workspace initial: $CURRENT_WS" >> "$LOG"

# on écoute Hyprland
socat -u "UNIX-CONNECT:${HYPRSOCK}" - | while read -r line; do
    echo "EVENT: $line" >> "$LOG"

    if [[ "$line" == workspace* ]]; then
        NEW_WS=$(echo "$line" | grep -oE '[0-9]+$' || true)
        if [[ -z "$NEW_WS" ]]; then
            NEW_WS=$(hyprctl activeworkspace -j | jq -r '.id')
        fi

        PREV="$CURRENT_WS"
        CURRENT_WS="$NEW_WS"

        echo "WS change: $PREV -> $CURRENT_WS" >> "$LOG"

        VIDEO="/usr/share/backgrounds/spiderman/animate/sp_${PREV}-${CURRENT_WS}.mp4"
        echo "VIDEO attendue: $VIDEO" >> "$LOG"

        if [[ ! -f "$VIDEO" ]]; then
            echo "⚠️  vidéo manquante: $VIDEO" >> "$LOG"
            continue
        fi

        # (facultatif) récupère le premier moniteur
        OUT=$(hyprctl monitors -j | jq -r '.[0].name' 2>/dev/null || echo "*")
        echo "Output utilisé: $OUT" >> "$LOG"

        {
            printf '{"command":["loadfile","%s","replace"]}\n' "$VIDEO"
            printf '{"command":["set_property","pause",false]}\n'
        } | socat - UNIX-CONNECT:/tmp/mpv.sock

        echo "Commande envoyée à mpv pour $VIDEO" >> "$LOG"
    fi
done

