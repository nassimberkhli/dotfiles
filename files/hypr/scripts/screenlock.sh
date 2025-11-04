#!/bin/sh
export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"

VIDEO="/usr/share/backgrounds/spiderman/milesChill.mp4"
MONITOR="HDMI-A-1"
FONT="Homoarakhn"
SESSION_NAME="${USER}@$(hostname)"

swaylock-plugin \
  --command "mpvpaper $MONITOR $VIDEO --loop --no-audio" \
  --font "$FONT" \
  --ring-color 00000000 \
  --ring-ver-color 00000000 \
  --ring-wrong-color ff0000aa \
  --inside-color 00000000 \
  --inside-ver-color 00000000 \
  --inside-wrong-color 00000000 \
  --line-color 00000000 \
  --separator-color 00000000 \
  --text-color ffffff \
  --text-ver "Vérification…" \
  --text-wrong "Mot de passe incorrect" \
  --grace 0 \
