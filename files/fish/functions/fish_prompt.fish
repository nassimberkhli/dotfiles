# ──────────────────────────────────────────────────────────────
#  Prompt fish — minimaliste, deux lignes (précédées d'une ligne vide) :
#
#    [user🕷host] ················································ [path]
#    > _
#
#  [user🕷host] à gauche, [path] aligné à droite, puis « > » à la ligne.
#  Tout en color_3 + gras. Couleurs pilotées par ~/.config/color.sh
#  (color_fish) :  # p-user  # p-path  # p-arrow
# ──────────────────────────────────────────────────────────────
function fish_prompt

    # Path : seulement les 3 derniers dossiers (… si tronqué) pour éviter
    # les chemins trop longs.
    set -l dirs (string split -n / -- $PWD)
    set -l n (count $dirs)
    set -l shown /
    if test $n -gt 3
        set shown (string join / $dirs[(math $n - 2)..-1])
    else if test $n -gt 0
        set shown (string join / $dirs)
    end

    set -l left "[$shown]"
    set -l right "[$USER@"(prompt_hostname)"]"

    # Remplissage pour aligner [path] à droite. Le « - 1 » réserve une marge à
    # droite ET compense l'araignée 🕷 (rendue sur 2 colonnes par le terminal
    # alors que fish la compte pour 1) → évite tout débordement / retour ligne.
    set -l cols $COLUMNS
    test -z "$cols"; and set cols 80
    set -l pad (math "$cols - 1 - "(string length --visible -- $left)" - "(string length --visible -- $right))
    test $pad -lt 1; and set pad 1

    echo # ligne vide avant le prompt
    set_color --bold aaff00 # p-user
    echo -n $left
    echo -n (string repeat -n $pad ' ')
    set_color --bold ffffff # p-path
    echo -n $right
    set_color normal

    echo
    set_color --bold 0000ff # p-arrow
    echo -n '>> '
    set_color normal
end
