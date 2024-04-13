return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    { "nvim-telescope/telescope-fzf-native.nvim", build = 'make' },
    { "jvgrootveld/telescope-zoxide" },
  },
  opts = function ()
    local opt = require "nvchad.configs.telescope"

    opt.extensions_list = { "fzf", "themes", "terms", "zoxide" }

    return opt
  end,
}
