local map = vim.keymap.set

vim.g.opencode_opts = {}

map({ "n", "x" }, "<C-a>", function() require("opencode").ask("@this: ", { submit = true }) end, { desc = "Ask opencode" })
map({ "n", "x" }, "<C-x>", function() require("opencode").select() end, { desc = "Opencode actions" })
map({ "n", "t" }, "<C-.>", function() require("opencode").toggle() end, { desc = "Toggle opencode" })
map({ "n", "x" }, "go", function() return require("opencode").operator("@this ") end, { desc = "Send range to opencode", expr = true })
map("n", "goo", function() return require("opencode").operator("@this ") .. "_" end, { desc = "Send line to opencode", expr = true })
