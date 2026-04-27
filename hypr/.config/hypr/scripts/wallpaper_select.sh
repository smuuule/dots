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

  while IFS= read -r line; do
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "$line" ]] && continue

    if [[ "$line" =~ ^[[:space:]]*wallpaper[[:space:]]*= ]]; then
      local mapping="${line#*=}"
      mapping="${mapping#"${mapping%%[![:space:]]*}"}"

      local monitor="${mapping%%,*}"
      local image="${mapping#*,}"

      monitor="${monitor#"${monitor%%[![:space:]]*}"}"
      monitor="${monitor%"${monitor##*[![:space:]]}"}"
      image="${image#"${image%%[![:space:]]*}"}"
      image="${image%"${image##*[![:space:]]}"}"

      [[ -n "$monitor" && -n "$image" ]] || continue
      SAVED_WALLPAPERS["$monitor"]="$image"
    fi
  done <"$hyprpaper_conf"
}

write_conf() {
  {
    local -A preloaded
    for monitor in "${!SAVED_WALLPAPERS[@]}"; do
      local image="${SAVED_WALLPAPERS[$monitor]}"
      [[ -n "$image" ]] || continue
      if [[ -z "${preloaded[$image]:-}" ]]; then
        echo "preload = $image"
        preloaded["$image"]=1
      fi
    done

    echo ""

    for monitor in "${!SAVED_WALLPAPERS[@]}"; do
      local image="${SAVED_WALLPAPERS[$monitor]}"
      [[ -n "$image" ]] && echo "wallpaper = $monitor,$image"
    done

    echo ""
    echo "splash = false"
  } >"$hyprpaper_conf"
}

persist_wallpaper() {
  local target_monitor="$1"
  local image_path="$2"

  local desc
  desc=$(get_monitor_desc "$target_monitor")
  if [[ -n "$desc" ]]; then
    SAVED_WALLPAPERS["desc:$desc"]="$image_path"
    unset "SAVED_WALLPAPERS[$target_monitor]"
  else
    SAVED_WALLPAPERS["$target_monitor"]="$image_path"
  fi
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

  hyprctl hyprpaper preload "$image_path"
  hyprctl hyprpaper wallpaper "$target_monitor,$image_path"
}

apply_wallpaper() {
  local target_monitor="$1"
  local image_path="$2"

  set_wallpaper "$target_monitor" "$image_path"
  persist_wallpaper "$target_monitor" "$image_path"
}

restore_wallpapers() {
  load_saved_wallpapers
  ensure_hyprpaper

  pkill -x hyprpaper
  hyprpaper >/dev/null 2>&1 &
  disown
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
if [[ "${1:-}" == "--restore" ]]; then
  restore_wallpapers
  exit 0
fi

if pidof rofi >/dev/null; then
  pkill rofi
  exit 0
fi

main

sleep 0.5
${scripts}/refresh.sh
