#!/bin/bash
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}Checking dependencies...${NC}"
if ! command -v jq &>/dev/null; then
  echo "jq is missing. Attempting to install..."
  if [ -f /etc/arch-release ]; then
    sudo pacman -S --noconfirm jq
  elif [ -f /etc/debian_version ]; then
    sudo apt update && sudo apt install -y jq
  elif [ -f /etc/fedora-release ]; then
    sudo dnf install -y jq
  elif [ -f /etc/SUSE-brand ]; then
    sudo zypper install -y jq
  else
    echo -e "${RED}Error: Unsupported distribution. Install 'jq' manually.${NC}"
    exit 1
  fi
  echo -e "${GREEN}jq installed successfully.${NC}"
else
  echo -e "${GREEN}jq is already installed.${NC}"
fi

INSTALL_DIR="$HOME/.local/bin"
SCRIPT_NAME="hypr-rotate-monitor"
TARGET_FILE="$INSTALL_DIR/$SCRIPT_NAME"

mkdir -p "$INSTALL_DIR"
echo -e "\n${BLUE}Installing script to $TARGET_FILE...${NC}"

cat <<'EOF' >"$TARGET_FILE"
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

read -r NATIVE_WIDTH NATIVE_HEIGHT REFRESH SCALE X_POS Y_POS CURRENT_TRANSFORM <<< $(echo "$MON_INFO" | jq -r '
    .scale as $s |
    .width as $wp |
    .height as $hp |
    ([$wp, $hp] | max | floor) as $native_w |
    ([$wp, $hp] | min | floor) as $native_h |
    "\($native_w) \($native_h) \(.refreshRate) \($s) \(.x) \(.y) \(.transform)"
')

# 0: Normal, 1: 90 deg, 2: 180 deg, 3: 270 deg
NEXT_TRANSFORM=$(( (CURRENT_TRANSFORM + 1) % 4 ))

# apply rotation
hyprctl keyword monitor "$MONITOR,${NATIVE_WIDTH}x${NATIVE_HEIGHT}@${REFRESH},${X_POS}x${Y_POS},$SCALE,transform,$NEXT_TRANSFORM"

# notification
ROTATION_NAMES=("Normal (Landscape)" "90° (Portrait)" "180° (Inverted Landscape)" "270° (Inverted Portrait)")
notify-send "Rotated $MONITOR" "${ROTATION_NAMES[$NEXT_TRANSFORM]}"
EOF

chmod +x "$TARGET_FILE"
echo ""
echo -e "${GREEN}Installation Complete!${NC}"
echo "Location: $TARGET_FILE"
echo ""
echo -e "${YELLOW}USAGE:${NC}"
echo -e "${BLUE}1. Use from the terminal:${NC}"
echo "hypr-rotate-monitor"
echo ""
echo -e "${BLUE}2. Set as keybind and add the following to your hyprland.conf:${NC}"
echo "bind = SUPER, R, exec, $TARGET_FILE"
