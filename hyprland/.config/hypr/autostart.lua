-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
-- hyprpaper runs as a user service: systemctl --user enable --now hyprpaper.service

hl.on("hyprland.start", function()
    hl.exec_cmd("~/.config/hypr/scripts/launch-waybar.sh")
    hl.exec_cmd("nm-applet & blueman-applet &")
end)
