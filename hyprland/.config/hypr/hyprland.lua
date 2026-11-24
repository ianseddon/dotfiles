-- Hyprland Lua config (hyprlang .conf is deprecated since 0.55).
-- https://wiki.hypr.land/Configuring/Start/
-- API stubs for editor completion: /usr/share/hypr/stubs/hl.meta.lua
--
-- Each require runs in its own scope: an error in one module does not stop the others.

require("envs")
require("monitors")
require("input")
require("bindings")
require("looknfeel")
require("theme") -- after looknfeel: the theme's colours win
require("autostart")
require("windows")
