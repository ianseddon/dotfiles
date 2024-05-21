return {
  {
    "catppuccin/nvim",
    lazy = false,
    name = "catppuccin",
    priority = 1000,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
  {
    "telescope.nvim",
    dependencies = {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
      config = function()
        require("telescope").load_extension("fzf")
      end,
    },
  },
  {
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
  },
  {
    "nvimtools/none-ls.nvim",
    opts = function(_, opts)
      local nls = require("null-ls")

      opts.sources = vim.list_extend(opts.sources or {}, {
        nls.builtins.diagnostics.mypy,
      })
    end,
  },
}
