-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
-- hyprpaper runs as a user service: systemctl --user enable --now hyprpaper.service

-- The bar is Quickshell, a user service: systemctl --user enable --now quickshell.

hl.on("hyprland.start", function()
    hl.exec_cmd("nm-applet & blueman-applet &")
end)
