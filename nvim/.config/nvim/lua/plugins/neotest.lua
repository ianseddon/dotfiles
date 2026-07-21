local map = vim.keymap.set

require("neotest").setup({
	adapters = {
		require("neotest-vitest")({
			vitestCommand = "npx vitest",
		}),
	},
})

map("n", "<leader>tt", function() require("neotest").run.run() end, { desc = "Run nearest test" })
map("n", "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end, { desc = "Run file tests" })
map("n", "<leader>ts", function() require("neotest").summary.toggle() end, { desc = "Test summary" })
map("n", "<leader>to", function() require("neotest").output.open({ enter = true }) end, { desc = "Test output" })
map("n", "<leader>tp", function() require("neotest").output_panel.toggle() end, { desc = "Test output panel" })
map("n", "<leader>tS", function() require("neotest").run.stop() end, { desc = "Stop tests" })
map("n", "[t", function() require("neotest").jump.prev({ status = "failed" }) end, { desc = "Prev failed test" })
map("n", "]t", function() require("neotest").jump.next({ status = "failed" }) end, { desc = "Next failed test" })
