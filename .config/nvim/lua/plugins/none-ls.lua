-- We only use this for the diagnostics, formatting is handled by conform.
return {
  "nvimtools/none-ls.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "williamboman/mason.nvim",
  },
  event = { "BufReadPre", "BufNewFile" },
  cmd = { "NullLsInfo", "NullLsLog" },
  opts = function()
    local null_ls = require "null-ls"

    return {
      sources = {
        null_ls.builtins.diagnostics.mypy,
        null_ls.builtins.diagnostics.phpcs,
      },
    }
  end,
  config = function(opts)
    error(opts)
  end,
}
