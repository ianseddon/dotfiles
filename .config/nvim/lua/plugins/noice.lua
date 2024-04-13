return {
  "folke/noice.nvim",
  opts = {
    views = { mini = { timeout = 10000, lang = "markdown" } },
    routes = {
      {
        filter = {
          event = "msg_show",
          kind = "",
          find = "written",
        },
        opts = { skip = true },
      },
      {
        filter = {
          event = "lsp",
          kind = "progress",
          find = "null-l",
        },
        opts = { skip = true, stop = true },
      },
      {
        view = "notify",
        filter = { event = "msg_showmode" },
      },
    },
    lsp = {
      override = {
        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
        ["vim.lsp.util.stylize_markdown"] = true,
        ["cmp.entry.get_documentation"] = true,
      },
    },
    presets = {
      bottom_search = true,
      command_palette = true,
      long_message_to_split = true,
      inc_rename = true,
      lsp_doc_border = true,
    },
  },
  dependencies = { "MunifTanjim/nui.nvim" },
  event = "VeryLazy",
}
