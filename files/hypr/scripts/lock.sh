#!/bin/sh

export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"

VIDEO="/usr/share/backgrounds/space/blackhole.mp4"
FONT="Homoarakhn"

# pkill mpvpaper 2>/dev/null

swaylock-plugin \
    --command "mpvpaper -f -o '--loop --no-audio' '$MONITOR' '$VIDEO'" \
    --ignore-empty-password \
    --indicator-idle-visible \
    --indicator-radius 120 \
    --indicator-thickness 8 \
    --font "$FONT" \
    --font-size 24 \
    --ring-color ffffffaa \
    --ring-ver-color F6C39Aff \
    --ring-wrong-color ff0000cc \
    --ring-clear-color ffffff55 \
    --inside-color 00000000 \
    --inside-ver-color 00000000 \
    --inside-wrong-color 00000000 \
    --inside-clear-color 00000000 \
    --line-color 00000000 \
    --line-ver-color 00000000 \
    --line-wrong-color 00000000 \
    --line-clear-color 00000000 \
    --separator-color 00000000 \
    --key-hl-color F6C39Aff \
    --bs-hl-color ff0000cc \
    --text-color ffffffff \
    --text-ver-color F6C39Aff \
    --text-wrong-color ff0000ff \
    --text-clear-color ffffffaa \
    --text-ver "Verification…" \
    --text-wrong "Wrong password" \
    --show-failed-attempts \
    --grace 0
