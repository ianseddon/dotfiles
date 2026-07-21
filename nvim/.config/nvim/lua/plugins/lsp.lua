local map = vim.keymap.set

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("lsp-attach", {}),
	callback = function(ev)
		local client = vim.lsp.get_client_by_id(ev.data.client_id)
		if not client then
			return
		end
		local bmap = function(mode, l, r, desc)
			map(mode, l, r, { buffer = ev.buf, desc = "LSP: " .. desc })
		end

		-- Navigation (fzf-lua pickers)
		bmap("n", "gd", "<cmd>FzfLua lsp_definitions<CR>", "Definition")
		bmap("n", "gD", vim.lsp.buf.declaration, "Declaration")
		bmap("n", "grr", "<cmd>FzfLua lsp_references<CR>", "References")
		bmap("n", "gri", "<cmd>FzfLua lsp_implementations<CR>", "Implementations")
		bmap("n", "gy", "<cmd>FzfLua lsp_typedefs<CR>", "Type definition")
		bmap("n", "<leader>ds", "<cmd>FzfLua lsp_document_symbols<CR>", "Document symbols")
		bmap("n", "<leader>ws", "<cmd>FzfLua lsp_workspace_symbols<CR>", "Workspace symbols")

		-- Actions (Neovim defaults + aliases)
		bmap("n", "grn", vim.lsp.buf.rename, "Rename")
		bmap("n", "gra", vim.lsp.buf.code_action, "Code action")
		bmap("n", "<leader>cr", vim.lsp.buf.rename, "Rename")
		bmap("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")
		bmap("n", "K", function() vim.lsp.buf.hover { silent = true } end, "Hover")
		bmap("n", "<C-k>", function() vim.lsp.buf.signature_help { silent = true, focusable = false } end, "Signature help")
		bmap("i", "<C-k>", function() vim.lsp.buf.signature_help { silent = true, focusable = false } end, "Signature help")

		if client:supports_method("textDocument/foldingRange") then
			vim.wo[vim.api.nvim_get_current_win()][0].foldexpr = "v:lua.vim.lsp.foldexpr()"
		end
		if client:supports_method("textDocument/documentHighlight") then
			local g = vim.api.nvim_create_augroup("lsp-hl-" .. ev.buf, {})
			vim.api.nvim_create_autocmd(
				{ "CursorHold", "CursorHoldI" },
				{ buffer = ev.buf, group = g, callback = vim.lsp.buf.document_highlight }
			)
			vim.api.nvim_create_autocmd(
				{ "CursorMoved", "CursorMovedI" },
				{ buffer = ev.buf, group = g, callback = vim.lsp.buf.clear_references }
			)
		end
		if client:supports_method("textDocument/inlayHint") then
			vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
		end
	end,
})

vim.diagnostic.config({
	virtual_text = { spacing = 4, prefix = "~" },
	underline = true,
	update_in_insert = false,
	severity_sort = true,
	float = { source = true },
})

vim.lsp.config("*", {
	root_markers = { ".git" },
	capabilities = require("blink.cmp").get_lsp_capabilities(),
})
vim.lsp.enable({
	"lua_ls",
	"basedpyright",
	"ruff",
	"vtsls",
	"biome",
	"gopls",
	"rust_analyzer",
	"jsonls",
	"yamlls",
	"dockerls",
	"tailwindcss",
})
