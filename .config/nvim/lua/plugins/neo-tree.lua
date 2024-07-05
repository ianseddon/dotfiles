return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      filtered_items = {
        visible = true,
        show_hidden_count = true,
        hide_dotfiles = false,
        hide_gitignored = false,
        never_show = {
          ".benchmarks",
          ".git",
          ".gitlab",
          ".idea",
          ".ipynb_checkpoints",
          ".mypy_cache",
          ".pytest_cache",
          ".ruff_cache",
          ".venv",
          ".vscode",
          "__pycache__",
        },
      },
    },
  },
}
