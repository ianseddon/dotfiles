local map = vim.keymap.set

require("gitsigns").setup({
	signs = {
		add = { text = "+" },
		change = { text = "~" },
		delete = { text = "_" },
		topdelete = { text = "-" },
		changedelete = { text = "~" },
	},
	on_attach = function(buf)
		local gs = require("gitsigns")
		local bmap = function(mode, l, r, desc)
			map(mode, l, r, { buffer = buf, desc = desc })
		end
		bmap("n", "]h", gs.next_hunk, "Next hunk")
		bmap("n", "[h", gs.prev_hunk, "Prev hunk")
		bmap("n", "<leader>hs", gs.stage_hunk, "Stage hunk")
		bmap("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
		bmap("n", "<leader>hp", gs.preview_hunk, "Preview hunk")
		bmap("n", "<leader>hb", function()
			gs.blame_line({ full = true })
		end, "Blame line")
	end,
})
