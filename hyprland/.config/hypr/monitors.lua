------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- > hyprctl monitors all

hl.env("GDK_SCALE", "1.75")

-- Match by make/model/serial, not connector: DP-1/DP-2 swap between the screens.
-- Left monitor, horizontal
hl.monitor({
    output   = "desc:LG Electronics LG HDR 4K 0x00052A41",
    mode     = "highres",
    position = "0x0",
    scale    = 1.25,
})

-- Right monitor, rotated 270 deg
hl.monitor({
    output    = "desc:Acer Technologies V277U TDCAA002852A",
    mode      = "highres",
    position  = "3072x-450",
    scale     = 1,
    transform = 3,
})

-- Any other display: preferred mode, auto-placed, never rotated
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})
