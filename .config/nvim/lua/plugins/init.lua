-- This is where plugins that require no/minimal configuration are placed.
-- More extensive configurations should be placed in their own files.
return {
  "folke/neodev.nvim",
  {
    "williamboman/mason.nvim",
    opts = {
      -- Prefer mason-lspconfig over this if possible.
      ensure_installed = {
        -- Python
        "debugpy",
        "mypy",
        -- Lua
        "stylua",
        -- Shell
        "shellcheck",
        "shfmt",
        -- TOML
        "taplo",
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    -- This must be setup after mason-lspconfig
    dependencies = { "williamboman/mason-lspconfig.nvim" },
  },
}
