return {
  "kndndrj/nvim-dbee",
  enabled = false,
  dependencies = {
    "MunifTanjim/nui.nvim",
  },
  build = function()
    -- Install tries to automatically detect the install method.
    -- if it fails, try calling it with one of these parameters:
    --    "curl", "wget", "bitsadmin", "go"
    require("dbee").install()
  end,
  config = function()
    require("dbee").setup({
      mappings = {
        -- edit a connection
        { key = "e", mode = "n", action = "action_2" },
      },
    })
  end,
  keys = {
    {
      "<leader>D",
      "<cmd>Dbee<cr>",
      desc = "󰆼 Db Tools",
    },
  },
}
