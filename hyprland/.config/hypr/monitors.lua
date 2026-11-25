------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- > hyprctl monitors all

hl.env("GDK_SCALE", "1.75")

-- Match by make/model/serial, not connector: DP-1/DP-2 swap between the screens.
-- Left monitor, horizontal: the main screen.
local main = "desc:LG Electronics LG HDR 4K 0x00052A41"
hl.monitor({
    output   = main,
    mode     = "highres",
    position = "0x0",
    scale    = 1.25,
})

-- Start each session on the main screen. Without this, the vertical screen
-- comes first and gets workspace 1 and the cursor, and focus follows the cursor.
-- The vertical screen skips workspace 1 because it is bound here, and takes 2.
hl.workspace_rule({ workspace = "1", monitor = main, default = true })
-- Warps the cursor to the middle of the main screen at startup and focuses it.
hl.config({ cursor = { default_monitor = main } })

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
