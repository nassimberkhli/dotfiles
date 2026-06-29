if status is-interactive
    # Init
    # ~/Desktop/scripts/init.sh

    # Variable
    set -gx MONITOR "$(hyprctl monitors -j | jq -r '.[0].name')" 

    # Run script
    alias cpf "~/Desktop/scripts/copyFile.sh"
    alias sp "~/Desktop/scripts/simplePush.sh"
    alias search "~/Desktop/scripts/search.sh"
    alias replace "~/Desktop/scripts/replace.sh"
    alias rmpyc "~/Desktop/scripts/rm_pychache.sh"
    alias ai_code "~/Desktop/scripts/code_generate_by_ai.sh"
    alias ts "~/Desktop/scripts/temporary.sh"

    # Open file
    alias ots "nv ~/Desktop/scripts/temporary.sh"
    alias oac "nv ~/Desktop/scripts/ai_code_param.txt"
    alias ocf "nv ~/.config/fish/config.fish"

    # CD
    alias cds "cd ~/Desktop/scripts"
    alias cdp "cd ~/Desktop/prompt"
    alias cdd "cd ~/Downloads"

    # copy prompt
    alias cpac "cat ~/Desktop/prompt/ai_code.txt | wl-copy"
    alias cpan "cat ~/Desktop/prompt/analyse_code.txt | wl-copy"
    alias cpen "cat ~/Desktop/prompt/enclosed.txt | wl-copy"
    alias cppa "cat ~/Desktop/prompt/paths.txt | wl-copy"
    alias cppl "cat ~/Desktop/prompt/plan.txt | wl-copy"

    # Raccourci
    alias light "brightnessctl -d amdgpu_bl1 set"
    alias nv "nvim"
    alias rundb "pgcli -h 127.0.0.1 -p 5432 -U nassinux -d"
    alias getdb "pg_dump -h 127.0.0.1 -p 5432 -U nassinux -d"
    alias batt 'upower -i $(upower -e | grep "BAT") | grep -E "state|to\ full|percentage"'
    alias pp 'playerctl play-pause'
    alias pb 'playerctl position 20-'
    alias chess 'chess-tui -l $LICHESS_TOKEN'
    alias color "~/.config/color.sh"
    alias ccs 'claude --dangerously-skip-permissions --model claude-sonnet-4.6'
    alias cco 'claude --dangerously-skip-permissions --model claude-opus-4-6'
    alias cch 'claude --dangerously-skip-permissions --model claude-haiku-4.5'
    alias ccf 'claude --dangerously-skip-permissions --model claude-fable-5'

    cd ~/Desktop/projects
end

# Created by `pipx` on 2026-01-31 12:46:07
set PATH $PATH /home/nojo/.local/bin
