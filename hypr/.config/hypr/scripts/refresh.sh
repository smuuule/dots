#!/bin/bash

# Kill already running processes
_ps=(waybar rofi)
for _prs in "${_ps[@]}"; do
  if pidof "${_prs}" >/dev/null; then
    pkill "${_prs}"
  fi
done

sleep 0.3
# Relaunch waybar
waybar &

exit 0
