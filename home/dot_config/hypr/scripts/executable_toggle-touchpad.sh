#!/bin/bash
# Bound to XF86TouchpadToggle (Fn+F10). Tracks state in a runtime flag file
# since Hyprland's device JSON doesn't reliably report live enabled state.
STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/hypr-touchpad-enabled"
TP_NAME=$(hyprctl devices -j | jq -r '.mice[] | select(.name | test("touchpad"; "i")) | .name' | head -1)

if [ -z "$TP_NAME" ]; then
    notify-send "Touchpad" "No touchpad device found" 2>/dev/null
    exit 1
fi

if [ -f "$STATE_FILE" ] && [ "$(cat "$STATE_FILE")" = "disabled" ]; then
    hyprctl keyword device:"$TP_NAME":enabled true
    echo "enabled" > "$STATE_FILE"
    notify-send "Touchpad" "Enabled" 2>/dev/null
else
    hyprctl keyword device:"$TP_NAME":enabled false
    echo "disabled" > "$STATE_FILE"
    notify-send "Touchpad" "Disabled" 2>/dev/null
fi
