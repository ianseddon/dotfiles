local map = vim.keymap.set

require("flash").setup()

map("n", "s", function()
	require("flash").jump()
end, { desc = "Flash" })
map("n", "S", function()
	require("flash").treesitter()
end, { desc = "Flash Treesitter" })
