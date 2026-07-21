require("kanagawa").setup({
	overrides = function(colors)
		local theme = colors.theme
		return {
		Pmenu = { fg = theme.ui.shade0, bg = theme.ui.bg_p1 },
		PmenuSel = { fg = "NONE", bg = theme.ui.bg_p2 },
		PmenuSbar = { bg = theme.ui.bg_m1 },
		PmenuThumb = { bg = theme.ui.bg_p2 },

		NormalFloat = { bg = theme.ui.bg_m3 },
		FloatBorder = { fg = theme.ui.bg_p2, bg = theme.ui.bg_m3 },
		FloatTitle = { fg = theme.syn.special1, bg = theme.ui.bg_m3, bold = true },
		}
	end,
})
vim.cmd.colorscheme("kanagawa")
