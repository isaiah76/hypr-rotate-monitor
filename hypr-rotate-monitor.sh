#!/bin/bash

# find target monitor
if [ -n "$1" ]; then
  MONITOR="$1"
else
  MONITOR=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name')
fi

if [ -z "$MONITOR" ]; then
  notify-send "Rotation Error" "Could not detect active monitor"
  exit 1
fi

# get current monitor
MON_INFO=$(hyprctl monitors -j | jq -r --arg m "$MONITOR" '.[] | select(.name == $m)')

if [ -z "$MON_INFO" ]; then
  notify-send "Rotation Error" "Monitor $MONITOR not found"
  exit 1
fi

read -r NATIVE_WIDTH NATIVE_HEIGHT REFRESH SCALE X_POS Y_POS CURRENT_TRANSFORM <<<$(echo "$MON_INFO" | jq -r '
    .scale as $s |
    .width as $wp |
    .height as $hp |
    ([$wp, $hp] | max | floor) as $native_w |
    ([$wp, $hp] | min | floor) as $native_h |
    "\($native_w) \($native_h) \(.refreshRate) \($s) \(.x) \(.y) \(.transform)"
')

# 0: Normal, 1: 90 deg, 2: 180 deg, 3: 270 deg
NEXT_TRANSFORM=$(((CURRENT_TRANSFORM + 1) % 4))

# apply rotation
hyprctl keyword monitor "$MONITOR,${NATIVE_WIDTH}x${NATIVE_HEIGHT}@${REFRESH},${X_POS}x${Y_POS},$SCALE,transform,$NEXT_TRANSFORM"

# notification
ROTATION_NAMES=("Normal (Landscape)" "90° (Portrait)" "180° (Inverted Landscape)" "270° (Inverted Portrait)")
notify-send "Rotated $MONITOR" "${ROTATION_NAMES[$NEXT_TRANSFORM]}"
