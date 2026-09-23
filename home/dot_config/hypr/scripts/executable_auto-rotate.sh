#!/bin/bash
# Auto-rotate the screen + touchscreen to match physical orientation, driven
# by iio-sensor-proxy's accelerometer readings.
#
# Replaces `iio-hyprland`: that tool only speaks the legacy `hyprctl keyword`
# protocol, which silently no-ops on this Hyprland build's native Lua config
# ("keyword can't work with non-legacy parsers. Use eval."). This does the
# same job via `hyprctl eval`, calling the Lua config API directly.
#
# Orientation -> transform mapping matches Hyprland's own device:transform
# values (0=normal, 1=left-up, 2=bottom-up, 3=right-up), which reuses the same
# enum for monitor transform. If the screen ends up rotated backwards from
# how you physically turned the device, swap the 1 and 3 cases below.

MONITOR="eDP-1"

apply_orientation() {
    local t="$1"
    hyprctl eval "hl.monitor({ output = '$MONITOR', mode = 'preferred', position = 'auto', scale = 'auto', transform = $t })" >/dev/null
    hyprctl eval "hl.device({ name = 'touchdevice', transform = $t })" >/dev/null
}

monitor-sensor --accel 2>/dev/null | while read -r line; do
    [[ "$line" == *orientation* ]] || continue
    case "$line" in
        *normal*)    apply_orientation 0 ;;
        *left-up*)   apply_orientation 1 ;;
        *bottom-up*) apply_orientation 2 ;;
        *right-up*)  apply_orientation 3 ;;
    esac
done
