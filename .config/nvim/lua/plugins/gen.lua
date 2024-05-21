return {
  "David-Kunz/gen.nvim",
  opts = {
    model = "llama3",
  },
  keys = {
    {
      "<leader>cg",
      "<cmd>Gen<cr>",
      mode = "n",
      noremap = true,
      silent = true,
      desc = "LLM tools",
    },
    {
      "<leader>cg",
      ":'<,'>Gen<cr>",
      mode = "v",
      noremap = true,
      silent = true,
      desc = "LLM tools",
    },
  },
}
