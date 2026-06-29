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
C_ACCENT="#cdca00"   # [user@session path]    (color_3)
C_CTX_LOW="#00ffaa"  # contexte < 30 %        (color_4)
C_CTX_MID="#16b800"  # contexte < 70 %        (color_6)
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

# ── Tokens & reset GLOBAUX (partagés entre TOUTES les discussions) ──
# La fenêtre de contexte (current_usage) est propre à la session et repart à
# zéro à chaque discussion. On affiche donc à la place l'usage GLOBAL de la
# limite 5 h, commun au compte :
#   - five_hour.used_percentage / resets_at sont globaux mais ABSENTS tant que
#     la discussion n'a pas fait son 1er échange API -> sans cache, ça retombe
#     à 0 / --:-- au début de chaque discussion.
#   - On accumule donc l'usage absolu de chaque session (total_input+output)
#     dans un cache PARTAGÉ ~/.claude/statusline-state.json, on somme pour
#     obtenir l'« utilisé » global, et on dérive le « total » via le
#     pourcentage global. Le cache est purgé au changement de fenêtre 5 h.
STATE="$HOME/.claude/statusline-state.json"
now=$(date +%s)
live_reset=$(jq -r '.rate_limits.five_hour.resets_at // empty' <<<"$input")
live_pct=$(jq -r '.rate_limits.five_hour.used_percentage // empty' <<<"$input")
sess_tok=$(jq -r '(.context_window.total_input_tokens // 0) + (.context_window.total_output_tokens // 0)' <<<"$input")
ctx_size=$(jq -r '.context_window.context_window_size // 0' <<<"$input")

# Mise à jour atomique de l'état partagé (flock : plusieurs sessions en //).
exec 9>"$STATE.lock"
flock 9 2>/dev/null
[ -s "$STATE" ] || printf '{"window_reset":0,"budget":0,"sessions":{},"used":0}' >"$STATE"
upd=$(jq \
    --arg sid "$sid" \
    --argjson sess "${sess_tok:-0}" \
    --arg lreset "${live_reset:-}" \
    --arg lpct "${live_pct:-}" '
    (if $lreset == "" then null else ($lreset|tonumber) end) as $lr
  | (if $lpct   == "" then null else ($lpct|tonumber)   end) as $lp
    # Nouvelle fenetre 5 h detectee -> purge le compteur.
  | (if ($lr != null) and ($lr != .window_reset)
        then .window_reset = $lr | .sessions = {} | .budget = 0
        else . end)
    # Enregistre la contribution absolue de CETTE session (si données live).
  | (if $sess > 0 and ($lr != null or .window_reset > 0)
        then .sessions[$sid] = $sess else . end)
    # Utilisé global = somme des sessions de la fenêtre.
  | .used = (reduce (.sessions|to_entries[]) as $e (0; . + $e.value))
    # Budget global dérivé du % global (assez fiable au-delà de 5 %).
  | (if ($lp != null) and ($lp >= 5) and (.used > 0)
        then .budget = ((.used / ($lp/100)) | round)
        else . end)
  ' "$STATE" 2>/dev/null) && [ -n "$upd" ] && printf '%s' "$upd" >"$STATE"
flock -u 9 2>/dev/null

read -r used_tok total_tok state_reset <<<"$(jq -r '[.used // 0, .budget // 0, .window_reset // 0] | @tsv' "$STATE" 2>/dev/null)"
used_tok=${used_tok:-0}; total_tok=${total_tok:-0}; state_reset=${state_reset:-0}

# Fenêtre 5 h expirée et aucune donnée live -> le budget a réellement été
# remis à zéro : on affiche 0 / --:-- (et non une valeur périmée).
if [ -z "$live_reset" ] && [ "$state_reset" -gt 0 ] 2>/dev/null && [ "$now" -ge "$state_reset" ] 2>/dev/null; then
    used_tok=0; reset="--:--"
elif [ "$state_reset" -gt 0 ] 2>/dev/null; then
    reset=$(date -d "@$state_reset" +%H:%M 2>/dev/null) || reset="--:--"
else
    reset="--:--"
fi
# Filet de sécurité : si le budget n'a pas encore pu être dérivé, on retombe
# sur la taille de la fenêtre de contexte courante pour un « total » lisible.
((total_tok == 0)) && total_tok=${ctx_size:-0}

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
