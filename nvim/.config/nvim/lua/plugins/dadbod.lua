return {
  "kristijanhusak/vim-dadbod-ui",
  -- using dbee instead
  enabled = false,
  dependencies = {
    { "tpope/vim-dotenv", lazy = true },
    { "tpope/vim-dadbod", lazy = true },
    { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
  },
  cmd = {
    "DBUI",
    "DBUIToggle",
    "DBUIAddConnection",
    "DBUIFindBuffer",
  },
  init = function()
    vim.g.db_ui_use_nerd_fonts = 1
  end,
  keys = {
    ["<leader>D"] = {
      name = "󰆼 Db Tools",
      u = { "<cmd>DBUIToggle<cr>", " DB UI Toggle" },
      f = { "<cmd>DBUIFindBuffer<cr>", " DB UI Find Buffer" },
      r = { "<cmd>DBUIRenameBuffer<cr>", " DB UI Rename Buffer" },
      l = { "<cmd>DBUILastQueryInfo<cr>", " DB UI Last Query Info" },
    },
  },
}
