local function find_biome_bin(bufnr)
	local fname = vim.api.nvim_buf_get_name(bufnr)
	local dir = fname ~= "" and vim.fs.dirname(fname) or vim.uv.cwd()
	local found = vim.fs.find("node_modules/.bin/biome", { path = dir, upward = true, type = "file" })[1]
	return found
end

return {
	cmd = function(dispatchers, config)
		local bufnr = vim.api.nvim_get_current_buf()
		local bin = find_biome_bin(bufnr) or "biome"
		return vim.lsp.rpc.start({ bin, "lsp-proxy" }, dispatchers, { cwd = config.cwd })
	end,
	filetypes = {
		"astro",
		"css",
		"graphql",
		"javascript",
		"javascriptreact",
		"json",
		"jsonc",
		"svelte",
		"typescript",
		"typescriptreact",
		"vue",
	},
	root_markers = {
		"biome.json",
		"biome.jsonc",
	},
	-- Only attach when a biome config exists in the project
	workspace_required = true,
}
