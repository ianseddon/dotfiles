local map = vim.keymap.set

vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("highlight-yank", {}),
	callback = function()
		vim.hl.on_yank({ timeout = 200 })
	end,
})

vim.api.nvim_create_autocmd("VimResized", {
	group = vim.api.nvim_create_augroup("resize-splits", {}),
	callback = function()
		vim.cmd("tabdo wincmd =")
	end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
	group = vim.api.nvim_create_augroup("last-position", {}),
	callback = function()
		local mark = vim.api.nvim_buf_get_mark(0, '"')
		if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(0) then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
	group = vim.api.nvim_create_augroup("checktime", {}),
	callback = function()
		if vim.o.buftype ~= "nofile" then
			vim.cmd("checktime")
		end
	end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
	group = vim.api.nvim_create_augroup("auto-create-dir", {}),
	callback = function(args)
		local dir = vim.fn.fnamemodify(args.match, ":p:h")
		if not dir:match("^%w+://") then
			vim.fn.mkdir(dir, "p")
		end
	end,
})

vim.api.nvim_create_autocmd("BufWinEnter", {
	group = vim.api.nvim_create_augroup("q-close-windows", {}),
	callback = function(args)
		if vim.tbl_contains({ "help", "nofile", "quickfix" }, vim.bo[args.buf].buftype) then
			map("n", "q", "<cmd>close<cr>", { buffer = args.buf, silent = true, nowait = true })
		end
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("quickfix-tweaks", {}),
	pattern = "qf",
	callback = function()
		vim.opt_local.buflisted = false

		-- dd to delete quickfix entries
		map("n", "dd", function()
			local idx = vim.fn.line(".")
			local items = vim.fn.getqflist()
			table.remove(items, idx)
			vim.fn.setqflist(items, "r")
			vim.fn.cursor(math.min(idx, #items), 1)
		end, { buffer = true, desc = "Delete quickfix entry" })
	end,
})

vim.api.nvim_create_autocmd("QuickFixCmdPost", {
	group = vim.api.nvim_create_augroup("quickfix-auto-open", {}),
	pattern = { "[^l]*" },
	callback = function()
		vim.cmd("cwindow")
	end,
})
