return {
  "supermaven-inc/supermaven-nvim",
  enabled = false,
  config = function()
    require("supermaven-nvim").setup({
      keymaps = {
        accept_suggestion = "<C-l>",
      },
    })
  end,
}
