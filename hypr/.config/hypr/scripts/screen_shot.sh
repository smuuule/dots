#!/bin/bash
iDIR="$HOME/.config/swaync/icons"
sDIR="$HOME/.config/hypr/scripts"

dir="$(xdg-user-dir)/Pictures/Screenshots"

notify_view() {
  notify-send -h string:x-canonical-private-synchronous:shot-notify -u low -i ${iDIR}/picture.png "Screenshot Captured."
}

tmpfile=$(mktemp)
grim -g "$(slurp)" - >"$tmpfile" && "${sDIR}/Sounds.sh" --screenshot && notify_view "swappy"
swappy -f - <"$tmpfile"
rm "$tmpfile"

if [[ ! -d "$dir" ]]; then
  mkdir -p "$dir"
fi
