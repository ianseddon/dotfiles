-- <C-h/j/k/l> move between nvim splits and, at an edge, into the neighbouring
-- herdr pane. The herdr half is the same repo installed as a herdr plugin and
-- bound in herdr/.config/herdr/config.toml; outside herdr it falls back to wincmd.
local plugin = vim.pack.get({ "vim-herdr-navigation" })[1]
dofile(plugin.path .. "/editor/nvim.lua")

-- herdr-app sets HC_TERMINAL_ID rather than HERDR_PANE_ID, so the plugin above
-- doesn't see it. There the app's pane-nav mod sends <C-h/j/k/l> here
-- (herdr-app/.config/herdr-app/mods/pane-nav), and at a split edge we ask the
-- app to move focus. Remote terminals have no herdr-app, so they stay in nvim.
if (vim.env.HERDR_PANE_ID or "") == "" and (vim.env.HC_TERMINAL_ID or "") ~= "" and vim.fn.executable("herdr-app") == 1 then
	local function nav(wincmd, dir)
		local prev = vim.api.nvim_get_current_win()
		vim.cmd("wincmd " .. wincmd)
		if vim.api.nvim_get_current_win() == prev then
			vim.system({ "herdr-app", "do", "pane.go", "--direction", dir })
		end
	end
	for lhs, args in pairs({
		["<C-h>"] = { "h", "left" },
		["<C-j>"] = { "j", "down" },
		["<C-k>"] = { "k", "up" },
		["<C-l>"] = { "l", "right" },
	}) do
		vim.keymap.set("n", lhs, function()
			nav(args[1], args[2])
		end, { silent = true, desc = "Navigate " .. args[2] .. " (nvim/herdr-app)" })
	end
end
