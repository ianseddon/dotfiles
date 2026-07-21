local map = vim.keymap.set

require("fzf-lua").setup({
	"default-title",
	actions = {
		files = {
			["enter"] = require("fzf-lua.actions").file_edit_or_qf,
			["ctrl-q"] = {
				fn = require("fzf-lua.actions").file_sel_to_qf,
				prefix = "select-all+",
			},
		},
	},
	winopts = {
		width = 0.87,
		height = 0.80,
		border = "rounded",
		preview = {
			default = "bat",
			horizontal = "right:45%",
		},
	},
	files = {
		fd_opts = "--hidden --type f --exclude .git --exclude node_modules --exclude __pycache__ --exclude .venv",
	},
	grep = {
		rg_opts = "--hidden --column --line-number --no-heading --color=always --smart-case "
			.. "--glob '!.git/' --glob '!node_modules/' --glob '!__pycache__/' --glob '!.venv/'",
	},
	buffers = {
		previewer = false,
		winopts = { width = 0.6, height = 0.5 },
		sort_lastused = true,
		ignore_current_buffer = true,
	},
	oldfiles = {
		previewer = false,
		winopts = { width = 0.6, height = 0.5 },
	},
})

local fzf = require("fzf-lua")
fzf.register_ui_select({
	winopts = {
		relative = "cursor",
		row = 1,
		col = 0,
		width = 0.4,
		height = 0.3,
		border = "rounded",
		preview = { hidden = "hidden" },
	},
})

map("n", "<leader>ff", fzf.files, { desc = "Find files" })
map("n", "<leader>fg", fzf.live_grep, { desc = "Live grep" })
map("n", "<leader>fb", fzf.buffers, { desc = "Buffers" })
map("n", "<leader>fh", fzf.help_tags, { desc = "Help tags" })
map("n", "<leader>fr", fzf.oldfiles, { desc = "Recent files" })
map("n", "<leader>fd", fzf.diagnostics_workspace, { desc = "Diagnostics" })
map("n", "<leader>/", fzf.lgrep_curbuf, { desc = "Buffer search" })
map("n", "<leader><leader>", fzf.buffers, { desc = "Buffers" })
