if status is-login
	if test -z "$DISPLAY" -a -z "$WAYLAND_DISPLAY"
		if test (tty) = "/dev/tty1"
			exec sway --unsupported-gpu
		end
	end
end

if status is-interactive
	alias volup "pactl set-sink-volume @DEFAULT_SINK@ +5%"
	alias voldown "pactl set-sink-volume @DEFAULT_SINK@ -5%"
	alias mute "pactl set-sink-mute @DEFAULT_SINK@ toggle"
	alias vi "nvim"
end
