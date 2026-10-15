-- <C-h/j/k/l> move between nvim splits and, at an edge, into the neighbouring
-- herdr pane. The herdr half is the same repo installed as a herdr plugin and
-- bound in herdr/.config/herdr/config.toml; outside herdr it falls back to wincmd.
local plugin = vim.pack.get({ "vim-herdr-navigation" })[1]
dofile(plugin.path .. "/editor/nvim.lua")
