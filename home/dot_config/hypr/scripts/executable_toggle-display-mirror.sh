#!/bin/bash
# Bound to SUPER+P (the raw keys the F9 "screen mirroring" Fn-key sends on
# this keyboard's firmware, instead of a real XF86 media key).
# Toggles the first external output between mirroring the internal panel
# and being an extended display.
MONITORS=$(hyprctl monitors -j)
INTERNAL=$(echo "$MONITORS" | jq -r '.[] | select(.name | test("eDP")) | .name' | head -1)
EXTERNAL=$(echo "$MONITORS" | jq -r --arg internal "$INTERNAL" '.[] | select(.name != $internal) | .name' | head -1)

if [ -z "$EXTERNAL" ]; then
    notify-send "Display" "No external display connected" 2>/dev/null
    exit 0
fi

MIRROR_OF=$(echo "$MONITORS" | jq -r --arg ext "$EXTERNAL" '.[] | select(.name == $ext) | .mirrorOf')

if [ "$MIRROR_OF" = "none" ] || [ -z "$MIRROR_OF" ]; then
    hyprctl keyword monitor "$EXTERNAL,preferred,auto,1,mirror,$INTERNAL"
    notify-send "Display" "Mirroring to $EXTERNAL" 2>/dev/null
else
    hyprctl keyword monitor "$EXTERNAL,preferred,auto,1"
    notify-send "Display" "Extended to $EXTERNAL" 2>/dev/null
fi
