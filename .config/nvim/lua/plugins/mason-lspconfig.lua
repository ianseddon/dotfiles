return {
  "williamboman/mason-lspconfig.nvim",
  dependencies = { "williamboman/mason.nvim" },
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    -- These should be valid lspconfig server names
    ensure_installed = {
      "dockerls",
      "docker_compose_language_service",
      "html",
      "jsonls",
      "pyright",
      "ruff",
      "lua_ls",
      "phpactor",
      "pyright",
      "rust_analyzer",
      "tsserver",
      "yamlls",
    },
    handlers = {
      function(server_name) -- default handler
        require("lspconfig")[server_name].setup {}
      end,
      -- custom handlers can be added here
      -- ["custom_server_name"] = function () ... end,
    },
  },
}
