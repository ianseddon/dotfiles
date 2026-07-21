local map = vim.keymap.set

local parsers = {
	"bash",
	"c",
	"css",
	"diff",
	"dockerfile",
	"fish",
	"go",
	"gomod",
	"gosum",
	"html",
	"javascript",
	"json",
	"lua",
	"luadoc",
	"luap",
	"markdown",
	"markdown_inline",
	"python",
	"query",
	"regex",
	"rust",
	"svelte",
	"toml",
	"tsx",
	"typescript",
	"vim",
	"vimdoc",
	"yaml",
}
require("nvim-treesitter").install(parsers)

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("treesitter-start", {}),
	callback = function(ev)
		pcall(vim.treesitter.start, ev.buf)
	end,
})

-- Textobjects
require("nvim-treesitter-textobjects").setup()

local ts_select = require("nvim-treesitter-textobjects.select")
local ts_move = require("nvim-treesitter-textobjects.move")

for _, m in ipairs({
	{ { "x", "o" }, "af", "@function.outer", "outer function" },
	{ { "x", "o" }, "if", "@function.inner", "inner function" },
	{ { "x", "o" }, "ac", "@class.outer", "outer class" },
	{ { "x", "o" }, "ic", "@class.inner", "inner class" },
	{ { "x", "o" }, "aa", "@parameter.outer", "outer parameter" },
	{ { "x", "o" }, "ia", "@parameter.inner", "inner parameter" },
}) do
	map(m[1], m[2], function()
		ts_select.select_textobject(m[3], "textobjects")
	end, { desc = m[4] })
end

for _, m in ipairs({
	{ "]f", "goto_next_start", "@function.outer", "Next function start" },
	{ "]c", "goto_next_start", "@class.outer", "Next class start" },
	{ "]F", "goto_next_end", "@function.outer", "Next function end" },
	{ "]C", "goto_next_end", "@class.outer", "Next class end" },
	{ "[f", "goto_previous_start", "@function.outer", "Prev function start" },
	{ "[c", "goto_previous_start", "@class.outer", "Prev class start" },
	{ "[F", "goto_previous_end", "@function.outer", "Prev function end" },
	{ "[C", "goto_previous_end", "@class.outer", "Prev class end" },
}) do
	map({ "n", "x", "o" }, m[1], function()
		ts_move[m[2]](m[3], "textobjects")
	end, { desc = m[4] })
end
