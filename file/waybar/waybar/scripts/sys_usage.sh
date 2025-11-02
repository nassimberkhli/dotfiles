#!/usr/bin/env bash
# Outputs JSON for Waybar custom module:
# { "text": "", "tooltip": "CPU: 23% | MEM: 45% | 62°C" }

icon=""    # alt options:   󰍛  󰘚

# ---- CPU percent (sample /proc/stat twice) ----
read -r cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
total1=$((user+nice+system+idle+iowait+irq+softirq+steal))
idle1=$idle
sleep 0.4
read -r cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
total2=$((user+nice+system+idle+iowait+irq+softirq+steal))
idle2=$idle
dt=$((total2-total1))
di=$((idle2-idle1))
cpu_perc=0
if [ "$dt" -gt 0 ]; then
  cpu_perc=$(( (100*(dt-di)) / dt ))
fi

# ---- Memory percent (use MemAvailable) ----
# Avoid swap/free double-counting; MemAvailable is best indicator.
mem_total_kb=$(grep -i '^MemTotal:' /proc/meminfo | awk '{print $2}')
mem_avail_kb=$(grep -i '^MemAvailable:' /proc/meminfo | awk '{print $2}')
mem_used_perc=0
if [ -n "$mem_total_kb" ] && [ "$mem_total_kb" -gt 0 ] && [ -n "$mem_avail_kb" ]; then
  mem_used_perc=$(( (100*(mem_total_kb - mem_avail_kb)) / mem_total_kb ))
fi

# ---- Temperature (°C): try hwmon, fallback to thermal_zone, else "N/A" ----
get_temp() {
  # Prefer highest CPU-related temp from hwmon
  for hw in /sys/class/hwmon/hwmon*/temp*_input; do
    [ -r "$hw" ] || continue
    t=$(cat "$hw" 2>/dev/null)
    if [ -n "$t" ] && [ "$t" -gt 0 ]; then
      echo "$t"
    fi
  done
}
temps=($(get_temp))
if [ "${#temps[@]}" -eq 0 ]; then
  # fallback to thermal zones
  for tz in /sys/class/thermal/thermal_zone*/temp; do
    [ -r "$tz" ] || continue
    t=$(cat "$tz" 2>/dev/null)
    [ -n "$t" ] && temps+=("$t")
  done
fi
temp_c="N/A"
if [ "${#temps[@]}" -gt 0 ]; then
  max_t=0
  for t in "${temps[@]}"; do
    [ "$t" -gt "$max_t" ] && max_t="$t"
  done
  # values are usually in millidegrees
  if [ "$max_t" -gt 1000 ]; then
    temp_c=$((max_t/1000))
  else
    temp_c=$max_t
  fi
fi

tooltip="CPU: ${cpu_perc}% | MEM: ${mem_used_perc}% | ${temp_c}°C"

printf '{"text":"%s","tooltip":"%s"}\n' "$icon" "$tooltip"

