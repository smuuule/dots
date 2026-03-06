#!/bin/bash
scripts="$HOME/.config/hypr/scripts"
swww_conf="$HOME/.config/hypr/wallpapers.conf"

focused_monitor=$(hyprctl monitors | awk '/^Monitor/{name=$2} /focused: yes/{print name}')
mapfile -t MONITORS < <(hyprctl monitors | awk '/^Monitor/{print $2}')

# WALLPAPERS PATH
wallDIR="$HOME/Pictures/wallpapers"
declare -A SAVED_WALLPAPERS

load_saved_wallpapers() {
  [[ -f "$swww_conf" ]] || return 0

  while IFS= read -r line; do
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "$line" ]] && continue
    local monitor image
    monitor="${line%%=*}"
    image="${line#*=}"
    monitor="${monitor#"${monitor%%[![:space:]]*}"}"
    monitor="${monitor%"${monitor##*[![:space:]]}"}"
    image="${image#"${image%%[![:space:]]*}"}"
    image="${image%"${image##*[![:space:]]}"}"
    [[ -n "$monitor" && -n "$image" ]] || continue
    SAVED_WALLPAPERS["$monitor"]="$image"
  done < "$swww_conf"
}

write_conf() {
  local tmp_conf
  tmp_conf="$(mktemp)"

  {
    for monitor in "${!SAVED_WALLPAPERS[@]}"; do
      local image
      image="${SAVED_WALLPAPERS[$monitor]}"
      [[ -n "$image" ]] && echo "$monitor=$image"
    done
  } > "$tmp_conf"

  mv "$tmp_conf" "$swww_conf"
}

persist_wallpaper() {
  local target_monitor="$1"
  local image_path="$2"
  SAVED_WALLPAPERS["$target_monitor"]="$image_path"
  write_conf
}

ensure_swww() {
  if ! pgrep -x swww-daemon >/dev/null; then
    swww-daemon >/dev/null 2>&1 &
    disown
    sleep 0.5
  fi
}

set_wallpaper() {
  local target_monitor="$1"
  local image_path="$2"

  swww img -o "$target_monitor" "$image_path" --transition-type wipe --transition-fps 60 --transition-duration 2
}

apply_wallpaper() {
  local target_monitor="$1"
  local image_path="$2"

  set_wallpaper "$target_monitor" "$image_path"
  persist_wallpaper "$target_monitor" "$image_path"
}

restore_wallpapers() {
  load_saved_wallpapers
  ensure_swww

  for monitor in "${!SAVED_WALLPAPERS[@]}"; do
    local image
    image="${SAVED_WALLPAPERS[$monitor]}"
    [[ -n "$monitor" && -n "$image" && -f "$image" ]] || continue
    set_wallpaper "$monitor" "$image"
  done
}

# Retrieve image files
#PICS=($(ls "${wallDIR}" | grep -E ".jpg$|.jpeg$|.png$|.gif$")) # Non-recusrive
mapfile -t PICS < <(find "${wallDIR}" -type d -name "Dynamic-Wallpapers" -prune -o -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) -printf "%P\n")
RANDOM_PIC="${PICS[$((RANDOM % ${#PICS[@]}))]}"
RANDOM_PIC_NAME="${#PICS[@]}. random"

# Rofi command
rofi_command="rofi -i -show -dmenu"

menu() {
  for i in "${!PICS[@]}"; do
    # Displaying .gif to indicate animated images
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
  ensure_swww

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
