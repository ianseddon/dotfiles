local gh = function(x)
	return "https://github.com/" .. x
end

vim.pack.add({
	-- Colour schemes: the theme's nvim.lua picks one (lua/plugins/theme.lua).
	gh("rebelot/kanagawa.nvim"),
	gh("folke/tokyonight.nvim"),
	gh("sainnhe/gruvbox-material"),
	gh("nyoom-engineering/oxocarbon.nvim"),
	gh("echasnovski/mini.base16"),
	gh("nvim-lua/plenary.nvim"),
	gh("ibhagwan/fzf-lua"),
	gh("nvim-treesitter/nvim-treesitter-textobjects"),
	gh("lewis6991/gitsigns.nvim"),
	gh("nvim-neo-tree/neo-tree.nvim"),
	gh("MunifTanjim/nui.nvim"),
	gh("nvim-lualine/lualine.nvim"),
	gh("echasnovski/mini.icons"),
	gh("akinsho/bufferline.nvim"),
	gh("echasnovski/mini.surround"),
	gh("echasnovski/mini.pairs"),

	gh("folke/flash.nvim"),
	gh("folke/which-key.nvim"),
	gh("stevearc/conform.nvim"),
	gh("wakatime/vim-wakatime"),
	gh("paulbkim-dev/vim-herdr-navigation"),
	{ src = gh("saghen/blink.cmp"), version = vim.version.range("1.*") },
	gh("rafamadriz/friendly-snippets"),
	gh("b0o/SchemaStore.nvim"),
	gh("nvim-neotest/neotest"),
	gh("nvim-neotest/nvim-nio"),
	gh("marilari88/neotest-vitest"),
}, { load = true })

-- config
require("config.options")
require("config.keymaps")
require("config.autocmds")

-- plugins
require("plugins.theme")
require("plugins.treesitter")
require("plugins.gitsigns")
require("plugins.neo-tree")
require("plugins.lualine")
require("plugins.mini")
require("plugins.bufferline")
require("plugins.flash")
require("plugins.which-key")
require("plugins.conform")
require("plugins.fzf-lua")
require("plugins.blink")
require("plugins.neotest")
require("plugins.herdr-navigation")
require("plugins.lsp")
