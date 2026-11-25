---------------------
---- KEYBINDINGS ----
---------------------

-- https://wiki.hypr.land/Configuring/Basics/Binds/
-- https://wiki.hypr.land/Configuring/Basics/Dispatchers/

local terminal = "ghostty"
-- Launcher trial: Vicinae on SUPER+SPACE, Rofi kept on SUPER+ALT+SPACE until the
-- trial ends (docs/desktop-shell/README.md, launcher).
local launcher = "vicinae toggle"
local menu     = "$HOME/.config/rofi/bin/launcher"

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

local function bind(keys, desc, dispatcher, opts)
    opts = opts or {}
    opts.description = desc
    hl.bind(keys, dispatcher, opts)
end

-- Bind one command to a key's press and another to its release. Adapted from
-- Omarchy's o.bind_hold (default/hypr/helpers.lua).
local function bind_hold(keys, desc, press, release)
    -- Hyprland starts a fresh Lua state on every reload, which forgets a hold
    -- in progress, so its release would never run. A marker file outlives the
    -- reload, and the new state runs the release it would have missed.
    local runtime   = os.getenv("XDG_RUNTIME_DIR")
    local signature = os.getenv("HYPRLAND_INSTANCE_SIGNATURE")
    local marker    = runtime and signature
        and (runtime .. "/hypr/" .. signature .. "/held-" .. keys:gsub("[^%w]", "_"))
    if marker and os.remove(marker) then
        hl.exec_cmd(release)
    end

    local held = false
    local function on_press()
        held = true
        if marker then
            local file = io.open(marker, "w")
            if file then file:close() end
        end
        hl.exec_cmd(press)
    end
    local function on_release()
        if not held then return end
        held = false
        if marker then os.remove(marker) end
        hl.exec_cmd(release)
    end

    -- A modifier's mask differs between its press and its release, so both
    -- halves ignore modifiers. Hyprland skips a plain release bind once another
    -- key is released during the hold, which typing while held would do; a
    -- transparent release bind still fires. Non-consuming keeps the release
    -- from taking the key away from apps.
    bind(keys, desc .. " (start)", on_press, { ignore_mods = true })
    bind(keys, desc .. " (stop)", on_release, {
        release = true, transparent = true, ignore_mods = true, non_consuming = true,
    })
end

bind(mainMod .. " + RETURN", "Terminal",     hl.dsp.exec_cmd(terminal))
bind(mainMod .. " + Q",      "Close window", hl.dsp.window.close())
bind(mainMod .. " + M",      "Exit session", hl.dsp.exit())
bind(mainMod .. " + SPACE",  "Launcher",     hl.dsp.exec_cmd(launcher))
bind(mainMod .. " + ALT + SPACE", "App launcher (Rofi)", hl.dsp.exec_cmd(menu))

-- Copy / Paste (universal — works in terminals too)
bind(mainMod .. " + C", "Copy",  hl.dsp.send_shortcut({ mods = "CTRL",  key = "Insert" }))
bind(mainMod .. " + V", "Paste", hl.dsp.send_shortcut({ mods = "SHIFT", key = "Insert" }))
bind(mainMod .. " + X", "Cut",   hl.dsp.send_shortcut({ mods = "CTRL",  key = "X" }))

-- -- Tiling control --
bind(mainMod .. " + E",        "Toggle split",     hl.dsp.layout("togglesplit"))
bind(mainMod .. " + P",        "Pseudo tile",      hl.dsp.window.pseudo())
bind(mainMod .. " + T",        "Toggle floating",  hl.dsp.window.float())
bind(mainMod .. " + F",        "Fullscreen",       hl.dsp.window.fullscreen({ mode = "fullscreen" }))
bind(mainMod .. " + CTRL + F", "Tiled fullscreen", hl.dsp.window.fullscreen_state({ internal = 0, client = 2 }))
bind(mainMod .. " + ALT + F",  "Full width",       hl.dsp.window.fullscreen({ mode = "maximized" }))
bind(mainMod .. " + O",        "Pop out window (float + pin)", function()
    hl.dispatch(hl.dsp.window.float({ action = "enable" }))
    hl.dispatch(hl.dsp.window.pin())
end)

-- -- Vim focus navigation / window swap / group join / workspace-to-monitor --
local directions = {
    H = { dir = "left",  monitor = "left" },
    L = { dir = "right", monitor = "right" },
    K = { dir = "up",    monitor = "upper" },
    J = { dir = "down",  monitor = "lower" },
}

for key, d in pairs(directions) do
    bind(mainMod .. " + " .. key,               "Focus " .. d.dir,       hl.dsp.focus({ direction = d.dir }))
    bind(mainMod .. " + SHIFT + " .. key,       "Swap window " .. d.dir, hl.dsp.window.swap({ direction = d.dir }))
    bind(mainMod .. " + ALT + " .. key,         "Join group " .. d.dir,  hl.dsp.window.move({ into_group = d.dir }))
    bind(mainMod .. " + SHIFT + ALT + " .. key, "Move workspace to " .. d.monitor .. " monitor", hl.dsp.workspace.move({ monitor = d.dir }))
end

-- -- Window resizing --
bind(mainMod .. " + code:20",         "Shrink window width",  hl.dsp.window.resize({ x = -100, y = 0, relative = true })) -- - key
bind(mainMod .. " + code:21",         "Grow window width",    hl.dsp.window.resize({ x = 100, y = 0, relative = true }))  -- = key
bind(mainMod .. " + SHIFT + code:20", "Shrink window height", hl.dsp.window.resize({ x = 0, y = -100, relative = true }))
bind(mainMod .. " + SHIFT + code:21", "Grow window height",   hl.dsp.window.resize({ x = 0, y = 100, relative = true }))

-- -- Window cycling (ALT+TAB) --
bind("ALT + TAB", "Next window", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.bring_to_top())
end)
bind("ALT + SHIFT + TAB", "Previous window", function()
    hl.dispatch(hl.dsp.window.cycle_next({ next = false }))
    hl.dispatch(hl.dsp.window.bring_to_top())
end)

-- -- Window groups --
bind(mainMod .. " + G",               "Toggle group",      hl.dsp.group.toggle())
bind(mainMod .. " + ALT + G",         "Move out of group", hl.dsp.window.move({ out_of_group = true }))
bind(mainMod .. " + ALT + TAB",       "Next in group",     hl.dsp.group.next())
bind(mainMod .. " + ALT + SHIFT + TAB", "Previous in group", hl.dsp.group.prev())

-- -- Workspaces --
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    bind(mainMod .. " + " .. key,         "Workspace " .. i,         hl.dsp.focus({ workspace = i }))
    bind(mainMod .. " + SHIFT + " .. key, "Move to workspace " .. i, hl.dsp.window.move({ workspace = i }))
end

-- Cycle workspaces
bind(mainMod .. " + TAB",         "Next workspace",     hl.dsp.focus({ workspace = "e+1" }))
bind(mainMod .. " + SHIFT + TAB", "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))
bind(mainMod .. " + CTRL + TAB",  "Last workspace",     hl.dsp.focus({ workspace = "previous" }))

-- Scroll through workspaces
bind(mainMod .. " + mouse_down", "Scroll workspace forward",  hl.dsp.focus({ workspace = "e+1" }))
bind(mainMod .. " + mouse_up",   "Scroll workspace backward", hl.dsp.focus({ workspace = "e-1" }))

-- -- Scratchpad --
bind(mainMod .. " + S",       "Toggle scratchpad",  hl.dsp.workspace.toggle_special("magic"))
bind(mainMod .. " + ALT + S", "Move to scratchpad", hl.dsp.window.move({ workspace = "special:magic", follow = false }))

-- -- Mouse move/resize --
bind(mainMod .. " + mouse:272", "Move window",   hl.dsp.window.drag(),   { mouse = true })
bind(mainMod .. " + mouse:273", "Resize window", hl.dsp.window.resize(), { mouse = true })

-- -- Screenshot --
bind(mainMod .. " + SHIFT + S", "Screenshot region", hl.dsp.exec_cmd("hyprshot --mode region"))

-- -- Dictation --
-- Alt + Space toggles, like Superwhisper's Option + Space. Holding Right Alt
-- records until it is released (push-to-talk). Right Alt chords also start
-- recording, so use Left Alt for chords such as Alt + Tab.
bind("ALT + SPACE", "Toggle dictation", hl.dsp.exec_cmd("voxtype record toggle"))

bind_hold("ALT + Alt_R", "Push-to-talk dictation", "voxtype record start", "voxtype record stop")
