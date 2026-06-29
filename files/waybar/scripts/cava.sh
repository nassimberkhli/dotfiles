#!/usr/bin/env bash

# Wait for PipeWire/PulseAudio to be ready at boot (up to 30 s)
for _i in $(seq 1 30); do
    pactl info >/dev/null 2>&1 && break
    sleep 1
done

config_file="${XDG_RUNTIME_DIR:-/tmp}/waybar_cava_config"

cat >"$config_file" <<EOF
[general]
bars = 5
framerate = 30
autosens = 1

[input]
channels = mono

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
EOF

printf '▁▁▁▁▁\n'

bars='▁▂▃▄▅▆▇█'

while true; do
    cava -p "$config_file" 2>/tmp/waybar-cava.err | python3 -c "
import sys
bars = '▁▂▃▄▅▆▇█'
for line in sys.stdin:
    line = line.strip().rstrip(';')
    if not line:
        continue
    try:
        out = ''.join(bars[int(v)] for v in line.split(';') if v.isdigit() and 0 <= int(v) <= 7)
        if out:
            print(out, flush=True)
    except Exception:
        pass
"
    printf '▁▁▁▁▁\n'
    sleep 1
done
