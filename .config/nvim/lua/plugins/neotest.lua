return {
  "nvim-neotest/neotest",
  dependencies = {
    "marilari88/neotest-vitest",
  },
  opts = {
    adapters = {
      ["neotest-python"] = {
        args = { "-vv" },
      },
      ["neotest-vitest"] = {},
    },
  },
}
