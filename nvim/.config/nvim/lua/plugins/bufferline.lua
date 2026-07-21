local map = vim.keymap.set

require("bufferline").setup({
	options = {
		separator_style = "slant",
		diagnostics = "nvim_lsp",
		diagnostics_indicator = function(count, level)
			local icon = level:match("error") and " " or " "
			return " " .. icon .. count
		end,
		show_close_icon = false,
		show_buffer_close_icons = true,
		indicator = { style = "icon", icon = "▎" },
		offsets = {
			{ filetype = "neo-tree", text = "Explorer", highlight = "Directory", text_align = "left", side = "right" },
		},
	},
})

map("n", "<leader>bd", function()
	local cur = vim.api.nvim_get_current_buf()
	local bufs = vim.tbl_filter(function(b)
		return vim.bo[b].buflisted
	end, vim.api.nvim_list_bufs())
	if #bufs > 1 then
		vim.cmd("BufferLineCyclePrev")
	else
		vim.cmd("enew")
	end
	vim.api.nvim_buf_delete(cur, { force = false })
end, { desc = "Delete buffer" })
map("n", "<S-h>", "<cmd>BufferLineCyclePrev<CR>", { desc = "Prev buffer" })
map("n", "<S-l>", "<cmd>BufferLineCycleNext<CR>", { desc = "Next buffer" })
map("n", "<leader>bp", "<cmd>BufferLineTogglePin<CR>", { desc = "Pin buffer" })
map("n", "<leader>bP", "<cmd>BufferLinePick<CR>", { desc = "Pick buffer" })
map("n", "<leader>bo", "<cmd>BufferLineCloseOthers<CR>", { desc = "Close other buffers" })
map("n", "<leader>bl", "<cmd>BufferLineCloseLeft<CR>", { desc = "Close buffers left" })
map("n", "<leader>br", "<cmd>BufferLineCloseRight<CR>", { desc = "Close buffers right" })
map("n", "<A-h>", "<cmd>BufferLineMovePrev<CR>", { desc = "Move buffer left" })
map("n", "<A-l>", "<cmd>BufferLineMoveNext<CR>", { desc = "Move buffer right" })
