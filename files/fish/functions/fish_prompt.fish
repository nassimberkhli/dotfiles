function fish_prompt
    echo
    set_color 00f # folder
    echo -n (prompt_pwd)
    set_color cdca00 # spider
    echo -n ' 🕷  '
    set_color --bold normal
end
