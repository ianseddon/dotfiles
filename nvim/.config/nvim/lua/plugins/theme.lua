-- The colour scheme of the current theme (`theme set <name>`, desktop only): each
-- theme's nvim.lua loads a native port, or builds one from the palette with
-- mini.base16. The theme hook re-runs the file in running instances, so it must be
-- safe to run again. Without a theme (the M75q, or before the first `theme set`),
-- Kanagawa as configured in plugins/kanagawa.lua.
local state = vim.env.XDG_STATE_HOME or (vim.env.HOME .. "/.local/state")
local theme = state .. "/theme/current/nvim.lua"

if vim.uv.fs_stat(theme) then
	dofile(theme)
else
	dofile(vim.api.nvim_get_runtime_file("lua/plugins/kanagawa.lua", false)[1])
end
