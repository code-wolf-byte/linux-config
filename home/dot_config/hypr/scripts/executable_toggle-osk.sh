#!/bin/bash
# Manual show/hide for the squeekboard on-screen keyboard.
# Squeekboard normally pops up on its own via the input-method protocol when a
# text field is focused, but XWayland apps don't support that protocol, so
# this is a fallback bound to a key (see binds.lua).
DEST="sm.puri.OSK0"
PATH_="/sm/puri/OSK0"
IFACE="sm.puri.OSK0"

if ! pgrep -x squeekboard >/dev/null; then
    squeekboard &
    sleep 0.5
fi

CURRENT=$(busctl --user get-property "$DEST" "$PATH_" "$IFACE" Visible 2>/dev/null | awk '{print $2}')

if [ "$CURRENT" = "true" ]; then
    busctl --user call "$DEST" "$PATH_" "$IFACE" SetVisible b false
else
    busctl --user call "$DEST" "$PATH_" "$IFACE" SetVisible b true
fi
