-- Auto-start config
-- if you dont use UWSM add your auto start programs here, otherwise use XDG autostart https://wiki.archlinux.org/title/XDG_Autostart

hl.on("hyprland.start", function ()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("noctalia")
    hl.exec_cmd("xhost +SI:localuser:root")

    -- Tablet mode: auto-rotate screen + touch input (needs iio-sensor-proxy, which
    -- runs system-wide already), and the squeekboard on-screen keyboard.
    -- Both are launched here (Hyprland's own autostart), not as system-enabled
    -- services, so they only ever run inside a Hyprland session, never COSMIC.
    -- (auto-rotate.sh replaces iio-hyprland, which is broken on this Hyprland
    -- build -- see comment in the script itself)
    hl.exec_cmd("~/.config/hypr/scripts/auto-rotate.sh")
    hl.exec_cmd("squeekboard")
end)
