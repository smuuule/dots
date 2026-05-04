#!/bin/bash
scripts="$HOME/.config/hypr/scripts"
hyprpaper_conf="$HOME/.config/hypr/hyprpaper.conf"

focused_monitor=$(hyprctl monitors | awk '/^Monitor/{name=$2} /focused: yes/{print name}')
mapfile -t MONITORS < <(hyprctl monitors | awk '/^Monitor/{print $2}')

# WALLPAPERS PATH
wallDIR="$HOME/Pictures/wallpapers"
declare -A SAVED_WALLPAPERS

get_monitor_desc() {
  local port="$1"
  hyprctl monitors | awk -v port="$port" '
    /^Monitor/{cur_port=$2}
    /^[[:space:]]*description:/{
      sub(/^[[:space:]]*description:[[:space:]]*/, "");
      if(cur_port==port) {print $0}
    }'
}

load_saved_wallpapers() {
  [[ -f "$hyprpaper_conf" ]] || return 0

  local current_monitor=""
  local current_path=""

  while IFS= read -r line; do
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "$line" ]] && continue

    if [[ "$line" =~ ^[[:space:]]*monitor[[:space:]]*=[[:space:]]*(.*) ]]; then
      current_monitor="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^[[:space:]]*path[[:space:]]*=[[:space:]]*(.*) ]]; then
      current_path="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^[[:space:]]*\} ]]; then
      if [[ -n "$current_monitor" && -n "$current_path" ]]; then
        SAVED_WALLPAPERS["$current_monitor"]="$current_path"
      fi
      current_monitor=""
      current_path=""
    fi
  done <"$hyprpaper_conf"
}

write_conf() {
  {
    for monitor in "${!SAVED_WALLPAPERS[@]}"; do
      local image="${SAVED_WALLPAPERS[$monitor]}"
      [[ -n "$image" ]] || continue

      echo "wallpaper {"
      echo "    monitor = $monitor"
      echo "    path = $image"
      echo "    fit_mode = cover"
      echo "}"
      echo ""
    done
  } >"$hyprpaper_conf"
}

persist_wallpaper() {
  local target_monitor="$1"
  local image_path="$2"

  SAVED_WALLPAPERS["$target_monitor"]="$image_path"
  write_conf
}

ensure_hyprpaper() {
  if ! pgrep -x hyprpaper >/dev/null; then
    hyprpaper >/dev/null 2>&1 &
    disown
    sleep 0.5
  fi
}

set_wallpaper() {
  local target_monitor="$1"
  local image_path="$2"

  if pgrep -x hyprpaper >/dev/null; then
    pkill hyprpaper
    sleep 0.2
  fi
  hyprpaper >/dev/null 2>&1 &
  disown
  sleep 0.2
}

apply_wallpaper() {
  local target_monitor="$1"
  local image_path="$2"

  persist_wallpaper "$target_monitor" "$image_path"
  set_wallpaper "$target_monitor" "$image_path"
}

# Retrieve image files
mapfile -t PICS < <(find "${wallDIR}" -type d -name "Dynamic-Wallpapers" -prune -o -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) -printf "%P\n")
RANDOM_PIC="${PICS[$((RANDOM % ${#PICS[@]}))]}"
RANDOM_PIC_NAME="${#PICS[@]}. random"

# Rofi command
rofi_command="rofi -i -show -dmenu"

menu() {
  for i in "${!PICS[@]}"; do
    if [[ -z $(echo "${PICS[$i]}" | grep .gif$) ]]; then
      printf "$(echo "${PICS[$i]}" | cut -d. -f1)\x00icon\x1f${wallDIR}/${PICS[$i]}\n"
    else
      printf "${PICS[$i]}\n"
    fi
  done

  printf "$RANDOM_PIC_NAME\n"
}

main() {
  load_saved_wallpapers
  ensure_hyprpaper

  choice=$(menu | ${rofi_command})

  # No choice case
  if [[ -z $choice ]]; then
    exit 0
  fi

  # Random choice case
  if [ "$choice" = "$RANDOM_PIC_NAME" ]; then
    for mon in "${MONITORS[@]}"; do
      apply_wallpaper "$mon" "${wallDIR}/${RANDOM_PIC}"
    done
    exit 0
  fi

  # Find the index of the selected file
  pic_index=-1
  for i in "${!PICS[@]}"; do
    if [[ "${PICS[$i]}" == "$choice"* ]]; then
      pic_index=$i
      break
    fi
  done

  if [[ $pic_index -ne -1 ]]; then
    apply_wallpaper "$focused_monitor" "${wallDIR}/${PICS[$pic_index]}"
  else
    echo "Image not found."
    exit 1
  fi
}

# Check if rofi is already running
if pidof rofi >/dev/null; then
  pkill rofi
  exit 0
fi

main

sleep 0.5
${scripts}/refresh.sh
