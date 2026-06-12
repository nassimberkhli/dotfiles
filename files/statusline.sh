#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────
#  Statusline Claude Code — minimaliste, sans jauge.
#  Format : [model@session path] | ctx [NN%] | reset [hh:mm]
#    - model   = modèle Claude courant (Opus / Haiku / Sonnet)
#    - session = 8 premiers caractères du session_id (identité de session)
#    - ctx     = pourcentage de contexte utilisé, COLORÉ selon l'usage :
#                  < 30 %  -> C_CTX_LOW  (calme)   < 70 % -> C_CTX_MID
#                  < 100 % -> C_CTX_HIGH (critique)
#    - reset   = heure de reset de la limite 5 h (--:-- si indisponible)
#
#  Couleurs pilotées par ~/.config/color.sh (color_claude) — ne pas éditer
#  les lignes C_* à la main.
# ──────────────────────────────────────────────────────────────────────────
input=$(cat)

# Palette (hex patchés par color.sh)
C_TEXT="#ffffff"     # libellés ctx / reset   (color_1)
C_ACCENT="#aaff00"   # [user@session path]    (color_3)
C_CTX_LOW="#00ffaa"  # contexte < 30 %        (color_4)
C_CTX_MID="#cdca00"  # contexte < 70 %        (color_6)
C_CTX_HIGH="#ff2e88" # contexte < 100 %       (color_5)
C_DIM="#5a5a5a"      # séparateurs | et reset

ansi() {
    local h=${1#\#}
    printf '\033[38;2;%d;%d;%dm' "0x${h:0:2}" "0x${h:2:2}" "0x${h:4:2}"
}
R=$'\033[0m'
BOLD=$'\033[1m'

# ── Données depuis le JSON stdin ──
# Modèle Claude courant (remplace le nom d'utilisateur) → Opus / Haiku / Sonnet
model_name=$(jq -r '.model.display_name // .model.id // ""' <<<"$input")
case "${model_name,,}" in
*opus*) user="Opus" ;;
*haiku*) user="Haiku" ;;
*sonnet*) user="Sonnet" ;;
*) user="${model_name:-$(whoami)}" ;;
esac
sid=$(jq -r '.session_id // ""' <<<"$input")
sess=${sid:0:8}
[ -z "$sess" ] && sess="—"
dir=$(jq -r '.workspace.current_dir // .cwd // ""' <<<"$input")
# Path : seulement les 3 derniers dossiers (… si tronqué) pour éviter les
# chemins trop longs.
IFS='/' read -r -a _parts <<<"$dir"
comps=()
for c in "${_parts[@]}"; do [ -n "$c" ] && comps+=("$c"); done
n=${#comps[@]}
if ((n > 3)); then
    path="${comps[n - 3]}/${comps[n - 2]}/${comps[n - 1]}"
elif ((n > 0)); then
    path=$(
        IFS=/
        printf '%s' "${comps[*]}"
    )
else
    path="/"
fi
pct=$(jq -r '.context_window.used_percentage // 0' <<<"$input" | cut -d. -f1)
pct=${pct//[^0-9]/}
[ -z "$pct" ] && pct=0

# Tokens de contexte : utilisé (occupation réelle = somme de current_usage)
# / total (taille de la fenêtre de contexte).
read -r t_in t_out t_cc t_cr t_size <<<"$(jq -r '[
    .context_window.current_usage.input_tokens // 0,
    .context_window.current_usage.output_tokens // 0,
    .context_window.current_usage.cache_creation_input_tokens // 0,
    .context_window.current_usage.cache_read_input_tokens // 0,
    .context_window.context_window_size // 0] | @tsv' <<<"$input")"
used_tok=$((${t_in:-0} + ${t_out:-0} + ${t_cc:-0} + ${t_cr:-0}))
total_tok=${t_size:-0}

# Format compact : 1234 -> 1k, 1500000 -> 1.5M (sans .0 inutile).
humanize() {
    local n=$1
    if ((n >= 1000000)); then
        local d=$(((n % 1000000) / 100000))
        if ((d == 0)); then
            printf '%dM' $((n / 1000000))
        else printf '%d.%dM' $((n / 1000000)) "$d"; fi
    elif ((n >= 1000)); then
        printf '%dk' $(((n + 500) / 1000))
    else
        printf '%d' "$n"
    fi
}
tok_used=$(humanize "$used_tok")
tok_total=$(humanize "$total_tok")

# Reset de la limite 5 h (peut être absent → --:--)
reset_epoch=$(jq -r '.rate_limits.five_hour.resets_at // empty' <<<"$input")
if [ -n "$reset_epoch" ]; then
    reset=$(date -d "@$reset_epoch" +%H:%M 2>/dev/null) || reset="--:--"
else
    reset="--:--"
fi

# ── Couleur du contexte selon le seuil d'usage ──
if ((pct < 30)); then
    cc=$C_CTX_LOW
elif ((pct < 70)); then
    cc=$C_CTX_MID
else
    cc=$C_CTX_HIGH
fi

sep="$(ansi "$C_DIM")|"
# Tout en gras : BOLD au début, un seul reset (${R}) à la toute fin.
out="${BOLD}$(ansi "$C_ACCENT")[${user}@${sess} ${path}]"
out+="  ${sep}  $(ansi "$C_TEXT")ctx $(ansi "$cc")[${pct}%]"
out+="  ${sep}  $(ansi "$C_TEXT")tokens $(ansi "$cc")[${tok_used}/${tok_total}]"
out+="  ${sep}  $(ansi "$C_TEXT")reset $(ansi "$cc")[${reset}]"
out+="${R}"
printf '%s\n' "$out"
