-- Kanagawa (wave) with this nvim config's overrides. They live in
-- nvim/.config/nvim/lua/plugins/kanagawa.lua, which is also nvim's fallback where no
-- theme is set (the M75q). dofile, not require: the theme hook re-runs this file.
dofile(vim.api.nvim_get_runtime_file("lua/plugins/kanagawa.lua", false)[1])
