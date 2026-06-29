#!/usr/bin/env fish
# try-caelestia.fish — teste le shell Caelestia (fork ~/.config/quickshell/caelestia)
# par-dessus la config actuelle, de façon NON destructive et TEST-ONLY.
#
# Pendant le test :
#   - Waybar et dunst sont mis en pause (Caelestia prend la barre + les notifs)
#   - Win+R ouvre le launcher Caelestia (temporaire)
#   - bordure colorée sur la fenêtre focus (temporaire ; ton border_size=0 est forcé)
# Ctrl-C restaure TOUT (hyprctl reload + relance waybar/dunst). Rien de permanent.

set -g ACCENT "rgba(00ffaaee)"   # teal = bordure focus de test

function cleanup --on-signal INT --on-signal TERM
    echo ""
    echo "→ Restauration de la config d'origine…"
    caelestia shell -k 2>/dev/null
    pkill -f 'qs -c caelestia' 2>/dev/null
    # recharge Hypr : annule les binds/bordures temporaires (non écrits dans la config)
    hyprctl reload >/dev/null 2>&1
    if not pgrep -x waybar >/dev/null
        waybar >/dev/null 2>&1 &; disown
        echo "  Waybar relancée."
    end
    if not pgrep -x dunst >/dev/null
        dunst >/dev/null 2>&1 &; disown
        echo "  dunst relancé."
    end
    echo "  Terminé. Setup d'origine restauré."
    exit 0
end

if not command -v caelestia >/dev/null
    echo "✗ caelestia absent. Installe d'abord : yay -S caelestia-shell"
    exit 1
end

echo "=== Test Caelestia (fork, non destructif, test-only) ==="

# 1. Libère la barre et le bus de notifications
pgrep -x waybar >/dev/null; and echo "→ pause Waybar…"; and killall waybar 2>/dev/null
pgrep -x dunst  >/dev/null; and echo "→ pause dunst (notifs Caelestia)…"; and killall dunst 2>/dev/null

# 2. Binds/bordures TEMPORAIRES (annulés par hyprctl reload à la sortie)
echo "→ éditeur de couleurs en fenêtre flottante centrée (temporaire)…"
hyprctl keyword windowrulev2 "float, class:^(caelestia-coloreditor)\$" >/dev/null 2>&1
hyprctl keyword windowrulev2 "center, class:^(caelestia-coloreditor)\$" >/dev/null 2>&1
hyprctl keyword windowrulev2 "size 640 520, class:^(caelestia-coloreditor)\$" >/dev/null 2>&1
hyprctl keyword windowrulev2 "float, class:^(caelestia-timeeditor)\$" >/dev/null 2>&1
hyprctl keyword windowrulev2 "center, class:^(caelestia-timeeditor)\$" >/dev/null 2>&1
hyprctl keyword windowrulev2 "size 560 440, class:^(caelestia-timeeditor)\$" >/dev/null 2>&1

echo "→ Win+R → launcher Caelestia (temporaire)…"
hyprctl keyword unbind "SUPER, R" >/dev/null 2>&1
hyprctl keyword bind "SUPER, R, exec, caelestia shell drawers toggle launcher" >/dev/null 2>&1
echo "→ bordure colorée sur la fenêtre focus (temporaire)…"
hyprctl keyword general:border_size 2 >/dev/null 2>&1
hyprctl keyword general:col.active_border "$ACCENT" >/dev/null 2>&1
hyprctl keyword general:col.inactive_border "rgba(00000000)" >/dev/null 2>&1  # fenêtres non focus : pas de bordure

# 3. Lance le shell (qs -c caelestia → utilise le fork ~/.config/quickshell/caelestia)
echo ""
echo "   *** Ctrl-C ici pour tout arrêter et restaurer ***"
echo ""
caelestia shell

cleanup
