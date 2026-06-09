#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────
#  color.sh — applique une palette unique à toute l'interface
#  (waybar, rofi, dunst, cava, kitty, fish, neovim).
#
#  Édite UNIQUEMENT la palette ci-dessous, puis lance :  ./color.sh
# ──────────────────────────────────────────────────────────────────────
set -euo pipefail

# ── Palette (les 5 couleurs + le fond) ──────────────────────────────────
# ── Thème « vert phosphore » 8-bit (modifie librement) ──────────────────
COLOR_BG="#000000" # fond noir (rofi, dunst, kitty)
COLOR_1="#ffffff"  # vert phosphore — texte/premier plan (waybar:first, fish:end, kitty:fg)
COLOR_2="#0000ff"  # cyan — accent principal (waybar:second, cava:grad1,
#   fish:command, kitty:selection, rofi:accent, dunst:normal)
COLOR_3="#aaff00" # lime — secondaire (waybar:third, fish:prompt 🕷,
#   nvim:accent2, rofi:warn, dunst:low fg)
COLOR_4="#00ffaa" # vert-cyan — accent 2 (nvim:accent, fish:param/folder,
#   kitty:cursor, rofi:accent2, dunst:low frame)
COLOR_5="#ff2e88" # magenta — alerte (cava:grad2, fish:error, rofi/dunst:urgent)
COLOR_6="#cdca00" # divers fish (comment, cwd, quote…) — vert sombre
COLOR_7="#fc6603"

# ── Dossier de configuration (robuste, pas de ~ non étendu) ─────────────
CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

_ansi_fg() {
    printf '38;2;%s' "$(_hex_rgb "$1")"
}

# Petit utilitaire : remplacement in-place tolérant.
# On n'utilise PAS `sed -i` car il crée un fichier temporaire DANS le dossier
# cible — ce qui échoue si le dossier appartient à root (ex: ~/.config/cava).
# Ici on écrit directement dans le fichier (temp dans /tmp), il suffit donc
# que le FICHIER soit inscriptible, pas le dossier.
_sed() { # $1 = expression sed, $2 = fichier
    if [ ! -f "$2" ]; then
        echo "  ⚠ ignoré (absent) : $2" >&2
        return 0
    fi
    if [ ! -w "$2" ]; then
        echo "  ⚠ ignoré (lecture seule, essaie: sudo chown $USER \"$2\") : $2" >&2
        return 0
    fi
    local tmp
    tmp="$(mktemp)"
    if sed "$1" "$2" >"$tmp" 2>/dev/null; then
        cat "$tmp" >"$2" # redirection -> écrit le fichier, pas le dossier
    else
        echo "  ⚠ échec sed sur : $2" >&2
    fi
    rm -f "$tmp"
    return 0
}

# Convertit #RRGGBB -> "R;G;B" (pour LS_COLORS / EZA_COLORS en 24 bits)
_hex_rgb() {
    local h=${1#\#}
    printf '%d;%d;%d' "0x${h:0:2}" "0x${h:2:2}" "0x${h:4:2}"
}

# ── Waybar ──────────────────────────────────────────────────────────────
color_waybar() {
    local f="$CONF_DIR/waybar/colors.css"
    _sed "s|@define-color first .*|@define-color first  $COLOR_1;|" "$f"
    _sed "s|@define-color second .*|@define-color second $COLOR_3;|" "$f"
    _sed "s|@define-color third .*|@define-color third $COLOR_4;|" "$f"
    _sed "s|@define-color background .*|@define-color background $COLOR_BG;|" "$f"
}

# ── Cava ────────────────────────────────────────────────────────────────
color_cava() {
    local f="$CONF_DIR/cava/config"
    _sed "s|gradient_color_1 = .*|gradient_color_1 = '$COLOR_2'|" "$f"
    _sed "s|gradient_color_2 = .*|gradient_color_2 = '$COLOR_3'|" "$f"
}

# ── Neovim ──────────────────────────────────────────────────────────────
color_nvim() {
    local f="$CONF_DIR/nvim/lua/core/palette.lua"
    _sed "s|M.accent = .*|M.accent = \"$COLOR_2\"|" "$f"
    _sed "s|M.accent2 = .*|M.accent2 = \"$COLOR_3\"|" "$f"
}

# ── Fish ────────────────────────────────────────────────────────────────
# ── Fish ────────────────────────────────────────────────────────────────
color_fish() {
    local theme="$CONF_DIR/fish/conf.d/fish_frozen_theme.fish"
    local prompt="$CONF_DIR/fish/functions/fish_prompt.fish"
    local extra="$CONF_DIR/fish/conf.d/fish_theme_extra.fish"

    # fish veut les couleurs SANS le '#'
    local c1=${COLOR_1#\#} c2=${COLOR_2#\#} c3=${COLOR_3#\#}
    local c4=${COLOR_4#\#} c5=${COLOR_5#\#} c6=${COLOR_6#\#}
    local c7=${COLOR_1#\#}

    # Syntax highlighting fish
    _sed "s|set --global fish_color_param .*|set --global fish_color_param $c4|" "$theme"
    _sed "s|set --global fish_color_command .*|set --global fish_color_command --bold $c1|" "$theme"
    _sed "s|set --global fish_color_end .*|set --global fish_color_end $c3|" "$theme"
    _sed "s|set --global fish_color_error .*|set --global fish_color_error $c5|" "$theme"
    _sed "s|set --global fish_color_comment .*|set --global fish_color_comment $c6|" "$theme"
    _sed "s|set --global fish_color_quote .*|set --global fish_color_quote $c6|" "$theme"
    _sed "s|set --global fish_color_cwd .*|set --global fish_color_cwd $c2|" "$theme"
    _sed "s|set --global fish_color_redirection .*|set --global fish_color_redirection $c6|" "$theme"
    _sed "s|set --global fish_color_status .*|set --global fish_color_status $c5|" "$theme"

    # Prompt : deux couleurs distinctes, ancrées par commentaire
    # '# folder' = couleur du chemin pwd
    # '# spider' = couleur de l'araignée 🕷
    _sed "s|set_color [0-9A-Fa-f]\{6\} # folder|set_color $c2 # folder|" "$prompt"
    _sed "s|set_color [0-9A-Fa-f]\{6\} # spider|set_color $c6 # spider|" "$prompt"

    # Couleurs ls / eza
    # di = directories
    # 38;2;R;G;B = couleur foreground 24 bits
    local dir_fg file_fg white_fg
    dir_fg="1;$(_ansi_fg "$COLOR_4")"
    file_fg="$(_ansi_fg "$COLOR_1")"
    white_fg="$(_ansi_fg "$COLOR_1")"

    local listing_colors
    listing_colors="di=$dir_fg"
    listing_colors="$listing_colors:*.md=$file_fg"
    listing_colors="$listing_colors:*.markdown=$file_fg"
    listing_colors="$listing_colors:*.json=$file_fg"
    listing_colors="$listing_colors:*.js=$file_fg"
    listing_colors="$listing_colors:*.mjs=$file_fg"
    listing_colors="$listing_colors:*.cjs=$file_fg"
    listing_colors="$listing_colors:*.ts=$file_fg"
    listing_colors="$listing_colors:*.tsx=$file_fg"
    listing_colors="$listing_colors:*.jsx=$file_fg"
    listing_colors="$listing_colors:*.config.js=$file_fg"
    listing_colors="$listing_colors:*.config.ts=$file_fg"
    listing_colors="$listing_colors:*.yml=$white_fg"
    listing_colors="$listing_colors:*.yaml=$white_fg"
    listing_colors="$listing_colors:Dockerfile=$white_fg"
    listing_colors="$listing_colors:Dockerfile.*=$white_fg"
    listing_colors="$listing_colors:Makefile=$file_fg"

    _sed "s|^set -gx EZA_COLORS .*|set -gx EZA_COLORS \"$listing_colors\"|" "$extra"
    _sed "s|^set -gx LS_COLORS .*|set -gx LS_COLORS \"$listing_colors\"|" "$extra"
}

# ── Kitty ───────────────────────────────────────────────────────────────
color_kitty() {
    local f="$CONF_DIR/kitty/kitty.conf"
    _sed "s|^[[:space:]]*cursor[[:space:]].*|cursor $COLOR_1|" "$f"
    _sed "s|^[[:space:]]*foreground[[:space:]].*|foreground $COLOR_1|" "$f"
    _sed "s|^[[:space:]]*background[[:space:]].*|background $COLOR_BG|" "$f"
    _sed "s|^[[:space:]]*selection_foreground[[:space:]].*|selection_foreground $COLOR_BG|" "$f"
    _sed "s|^[[:space:]]*selection_background[[:space:]].*|selection_background $COLOR_4|" "$f"
}

# ── Rofi (pop-up / lanceur) ─────────────────────────────────────────────
color_rofi() {
    local f="$CONF_DIR/rofi/colors.rasi"
    _sed "s|bg:.*|bg:      $COLOR_BG;|" "$f"
    _sed "s|fg:.*|fg:      $COLOR_1;|" "$f"
    _sed "s|accent:.*|accent:  $COLOR_2;|" "$f"
    _sed "s|accent2:.*|accent2: $COLOR_4;|" "$f"
    _sed "s|warn:.*|warn:    $COLOR_3;|" "$f"
    _sed "s|urgent:.*|urgent:  $COLOR_5;|" "$f"
}

# ── Dunst (notifications / alertes) ─────────────────────────────────────
# Les clés foreground/frame_color sont identiques d'une section à l'autre,
# on utilise donc awk pour réécrire selon la section [urgency_*] courante.
color_dunst() {
    local f="$CONF_DIR/dunst/dunstrc"
    [ -f "$f" ] || return 0
    local tmp
    tmp="$(mktemp)"
    awk \
        -v bg="$COLOR_BG" \
        -v low_fg="$COLOR_3" -v low_fr="$COLOR_4" \
        -v nor_fg="$COLOR_1" -v nor_fr="$COLOR_2" \
        -v cri_fg="$COLOR_1" -v cri_fr="$COLOR_5" '
        /^\[/ { sec=$0 }
        {
            if (sec=="[urgency_low]") {
                if ($1=="background")  { print "    background = \"" bg "\"";     next }
                if ($1=="foreground")  { print "    foreground = \"" low_fg "\""; next }
                if ($1=="frame_color") { print "    frame_color = \"" low_fr "\"";next }
            } else if (sec=="[urgency_normal]") {
                if ($1=="background")  { print "    background = \"" bg "\"";     next }
                if ($1=="foreground")  { print "    foreground = \"" nor_fg "\""; next }
                if ($1=="frame_color") { print "    frame_color = \"" nor_fr "\"";next }
            } else if (sec=="[urgency_critical]") {
                if ($1=="background")  { print "    background = \"" bg "\"";     next }
                if ($1=="foreground")  { print "    foreground = \"" cri_fg "\""; next }
                if ($1=="frame_color") { print "    frame_color = \"" cri_fr "\"";next }
            }
            print
        }
    ' "$f" >"$tmp" && cat "$tmp" >"$f"
    rm -f "$tmp"
}

# ── SDDM (écran de connexion) ───────────────────────────────────────────
# Le theme.conf vit dans /usr/share (appartient à root) -> écriture via sudo.
# On ne touche QU'AUX couleurs (foreground=COLOR_1, accent=COLOR_2),
# pas au fond (clé 'background' laissée intacte = choix manuel).
color_sddm() {
    local f="/usr/share/sddm/themes/minimal-video/theme.conf"
    if [ ! -e "$f" ]; then
        echo "  ⚠ SDDM ignoré (thème minimal-video non installé) : $f" >&2
        return 0
    fi
    if sudo sed -i \
        -e "s|^foreground=.*|foreground=$COLOR_1|" \
        -e "s|^accent=.*|accent=$COLOR_2|" \
        "$f" 2>/dev/null; then
        echo "  ✓ SDDM (minimal-video) : foreground=$COLOR_1, accent=$COLOR_2"
    else
        echo "  ⚠ SDDM non mis à jour (sudo requis / refusé)" >&2
    fi
    return 0
}

# ── Application ─────────────────────────────────────────────────────────
color_waybar
color_cava
color_nvim
color_fish
color_kitty
color_rofi
color_dunst
color_sddm

# ── Rechargement à chaud (silencieux si l'appli n'est pas lancée) ───────
# NB: la syntaxe du signal pour pkill est -USR2 / -USR1 (PAS -SIGUSR2).
reload_all() {
    pkill -USR2 -x waybar 2>/dev/null || true # waybar relit tout son CSS
    pkill -USR1 -x kitty 2>/dev/null || true  # kitty recharge kitty.conf
    if command -v dunstctl >/dev/null 2>&1; then
        dunstctl reload 2>/dev/null || true # dunst relit dunstrc
    fi
    echo "  ↻ rechargé à chaud : waybar, kitty, dunst"
    # cava est un TUI : il faut le relancer toi-même dans son terminal (q puis cava).
    if pgrep -x cava >/dev/null 2>&1; then
        echo "  ⚠ cava tourne : relance-le manuellement pour voir le nouveau gradient"
    fi
}
reload_all

echo "✓ Palette appliquée : waybar, rofi, dunst, cava, kitty, fish (prompt 🕷 + dossiers), nvim, sddm."
echo "  (ouvre un nouveau shell fish pour le prompt 🕷, relance cava si utilisé ;"
echo "   les couleurs SDDM seront visibles au prochain écran de connexion)"
