local map = vim.keymap.set

local biome_first = { "biome", "prettier", stop_after_first = true }

local function has_oxc_config(bufnr)
	local path = vim.api.nvim_buf_get_name(bufnr)
	local start = path ~= "" and vim.fs.dirname(path) or vim.uv.cwd()
	return #vim.fs.find({ ".oxfmtrc.json", ".oxfmtrc.jsonc", ".oxlintrc.json" }, { path = start, upward = true }) > 0
end

local function web_formatter(bufnr)
	if has_oxc_config(bufnr) then
		return { "oxfmt" }
	end
	return biome_first
end

local function js_formatter(bufnr)
	if has_oxc_config(bufnr) then
		return { "oxlint", "oxfmt" }
	end
	return biome_first
end

require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
		python = { "ruff_format" },
		javascript = js_formatter,
		typescript = js_formatter,
		typescriptreact = js_formatter,
		javascriptreact = js_formatter,
		json = web_formatter,
		css = web_formatter,
		yaml = { "prettier" },
		markdown = { "prettier" },
		html = biome_first,
		svelte = biome_first,
		go = { "gofumpt", "goimports" },
		rust = { "rustfmt" },
	},
	format_on_save = { timeout_ms = 1000, lsp_format = "fallback" },
})

map("n", "<leader>cf", function()
	require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "Format" })
