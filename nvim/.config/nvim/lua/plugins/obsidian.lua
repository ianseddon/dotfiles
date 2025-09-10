local vault_work = vim.env.VAULT_WORK or ""
local vault_personal = vim.env.VAULT_WORK or ""

return {
  "obsidian-nvim/obsidian.nvim",
  version = "*", -- latest release instead of latest commit
  cmd = "Obsidian",
  ft = "markdown",
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {
    workspaces = {
      {
        name = "work",
        path = vault_work,
      },
      {
        name = "personal",
        path = vault_personal,
      },
    },

    notes_subdir = "Inbox",
    new_notes_location = "notes_subdir",

    daily_notes = {
      -- Optional, if you keep daily notes in a separate directory.
      folder = "Flows/Daily Notes",
      -- Optional, if you want to change the date format for the ID of daily notes.
      date_format = "%Y-%m-%d",
      -- Optional, if you want to change the date format of the default alias of daily notes.
      alias_format = "%B %-d, %Y",
      -- Optional, default tags to add to each new daily note created.
      default_tags = { "daily-notes" },
      -- Optional, if you want to automatically insert a template from your template directory like 'daily.md'
      template = "+ Daily Note.md",
    },

    templates = {
      folder = "templates",
      date_format = "%Y-%m-%d",
      time_format = "%H:%M",
      -- A map for custom variables, the key should be the variable and the value a function
      substitutions = {},
    },
  },
}
