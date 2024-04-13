return {
  "nvim-treesitter/nvim-treesitter",
  opts = function ()
    local opt = require "nvchad.configs.treesitter"

    opt.auto_install = true
    opt.ensure_installed = {
        "bash",
        "css",
        "csv",
        "dockerfile",
        "git_config",
        "graphql",
        "html",
        "http",
        "javascript",
        "json",
        "lua",
        "markdown",
        "php",
        "python",
        "rust",
        "sql",
        "toml",
        "typescript",
    }

    return opt
  end,
}
