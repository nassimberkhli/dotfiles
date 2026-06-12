#!/usr/bin/env bash
# Confirmation Oui/Non via rofi avant extinction (comme $mod+M dans Hyprland).
# -i force la correspondance insensible à la casse, et on normalise en plus
# le résultat en minuscules pour gérer explicitement le problème majuscule/minuscule.

choice=$(printf 'Non\nOui' | rofi -dmenu -i -p "Éteindre ?")

# Normalisation : tout en minuscules, on accepte oui / o / yes / y
case "${choice,,}" in
    oui|o|yes|y) systemctl poweroff ;;
    *) exit 0 ;;
esac
