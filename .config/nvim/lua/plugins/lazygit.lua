return {
  "kdheepak/lazygit.nvim",
  cmd = {
    "LazyGit",
    "LazyGitConfig",
    "LazyGitCurrentFile",
    "LazyGitFilter",
    "LazyGitFilterCurrentFile",
  },
  keys = {
    {
      "<leader>gg",
      "<cmd> LazyGit<cr>",
      desc = "LazyGit",
    },
    {
      "<leader>gf",
      "<cmd> LazyGitFilter<cr>",
      desc = "LazyGit filter",
    },
  },
}
