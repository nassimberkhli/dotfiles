function fish_prompt
    echo
    set_color --bold normal
    echo -n (prompt_pwd)
    set_color EB0560
    echo -n ' 🕷  '
    set_color --bold normal
end
