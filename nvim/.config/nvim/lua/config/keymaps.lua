local map = vim.keymap.set

map("n", "<Esc>", "<cmd>nohlsearch<CR>")
map("n", "<C-Up>", "<cmd>resize +2<CR>")
map("n", "<C-Down>", "<cmd>resize -2<CR>")
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>")
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>")
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })
map("v", "<", "<gv")
map("v", ">", ">gv")
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Prev diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Diagnostic loclist" })
map("n", "<leader>xq", vim.diagnostic.setqflist, { desc = "Diagnostic quickfix" })

-- Quickfix navigation
map("n", "]q", "<cmd>cnext<CR>zz", { desc = "Next quickfix" })
map("n", "[q", "<cmd>cprev<CR>zz", { desc = "Prev quickfix" })
map("n", "]Q", "<cmd>clast<CR>zz", { desc = "Last quickfix" })
map("n", "[Q", "<cmd>cfirst<CR>zz", { desc = "First quickfix" })
map("n", "<leader>u", "<cmd>Undotree<CR>", { desc = "Undo tree" })

-- Remap default C-a/C-x since opencode took them
map("n", "+", "<C-a>", { desc = "Increment", noremap = true })
map("n", "-", "<C-x>", { desc = "Decrement", noremap = true })

-- Lazygit
map("n", "<leader>gg", function()
	local buf = vim.api.nvim_create_buf(false, true)
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = math.floor(vim.o.columns * 0.9),
		height = math.floor(vim.o.lines * 0.9),
		col = math.floor(vim.o.columns * 0.05),
		row = math.floor(vim.o.lines * 0.05),
		style = "minimal",
		border = "single",
	})
	vim.fn.termopen("lazygit", {
		on_exit = function()
			pcall(vim.api.nvim_win_close, win, true)
		end,
	})
	vim.cmd("startinsert")
end, { desc = "Lazygit" })
