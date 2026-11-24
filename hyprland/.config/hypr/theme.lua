---------------
---- THEME ----
---------------

-- Border colours from the current theme. `theme set <name>` writes this file and
-- reloads Hyprland; see theme/ in the dotfiles. Before the first `theme set` the
-- file does not exist, and Hyprland keeps its default colours.

local state = os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")
local path  = state .. "/theme/current/hyprland.lua"

local file = io.open(path, "r")
if file then
    file:close()
    dofile(path)
end
