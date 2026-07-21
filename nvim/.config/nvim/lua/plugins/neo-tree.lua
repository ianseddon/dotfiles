local map = vim.keymap.set
local git_available = vim.fn.executable("git") == 1

require("neo-tree").setup({
	close_if_last_window = true,
	enable_git_status = git_available,
	auto_clean_after_session_restore = true,
	sources = vim.tbl_filter(function(v)
		return v ~= nil
	end, {
		"filesystem",
		"buffers",
		git_available and "git_status" or nil,
	}),
	source_selector = {
		winbar = true,
		content_layout = "center",
		sources = vim.tbl_filter(function(v)
			return v ~= nil
		end, {
			{ source = "filesystem", display_name = " File" },
			{ source = "buffers", display_name = "󰈙 Bufs" },
			git_available and { source = "git_status", display_name = " Git" } or nil,
		}),
	},
	default_component_configs = {
		indent = {
			padding = 0,
			expander_collapsed = "",
			expander_expanded = "",
		},
		icon = {
			folder_closed = "",
			folder_open = "",
			folder_empty = "",
			folder_empty_open = "",
			default = "󰈙",
		},
		modified = { symbol = "" },
		git_status = {
			symbols = {
				added = "",
				deleted = "",
				modified = "",
				renamed = "➜",
				untracked = "★",
				ignored = "◌",
				unstaged = "✗",
				staged = "✓",
				conflict = "",
			},
		},
	},
	commands = {
		system_open = function(state)
			vim.ui.open(state.tree:get_node():get_id())
		end,
		parent_or_close = function(state)
			local node = state.tree:get_node()
			if node:has_children() and node:is_expanded() then
				state.commands.toggle_node(state)
			else
				require("neo-tree.ui.renderer").focus_node(state, node:get_parent_id())
			end
		end,
		child_or_open = function(state)
			local node = state.tree:get_node()
			if node:has_children() then
				if not node:is_expanded() then
					state.commands.toggle_node(state)
				else
					if node.type == "file" then
						state.commands.open(state)
					else
						require("neo-tree.ui.renderer").focus_node(state, node:get_child_ids()[1])
					end
				end
			else
				state.commands.open(state)
			end
		end,
		copy_selector = function(state)
			local node = state.tree:get_node()
			local filepath = node:get_id()
			local filename = node.name
			local modify = vim.fn.fnamemodify

			local vals = {
				["BASENAME"] = modify(filename, ":r"),
				["EXTENSION"] = modify(filename, ":e"),
				["FILENAME"] = filename,
				["PATH (CWD)"] = modify(filepath, ":."),
				["PATH (HOME)"] = modify(filepath, ":~"),
				["PATH"] = filepath,
				["URI"] = vim.uri_from_fname(filepath),
			}

			local options = vim.tbl_filter(function(val)
				return vals[val] ~= ""
			end, vim.tbl_keys(vals))
			if vim.tbl_isempty(options) then
				vim.notify("No values to copy", vim.log.levels.WARN)
				return
			end
			table.sort(options)
			vim.ui.select(options, {
				prompt = "Choose to copy to clipboard:",
				format_item = function(item)
					return ("%s: %s"):format(item, vals[item])
				end,
			}, function(choice)
				local result = vals[choice]
				if result then
					vim.notify(("Copied: `%s`"):format(result))
					vim.fn.setreg("+", result)
				end
			end)
		end,
	},
	window = {
		position = "right",
		width = 30,
		mappings = {
			["<S-CR>"] = "system_open",
			["<Space>"] = false,
			["[b"] = "prev_source",
			["]b"] = "next_source",
			O = "system_open",
			Y = "copy_selector",
			h = "parent_or_close",
			l = "child_or_open",
		},
		fuzzy_finder_mappings = {
			["<C-J>"] = "move_cursor_down",
			["<C-K>"] = "move_cursor_up",
		},
	},
	filesystem = {
		follow_current_file = { enabled = true },
		filtered_items = {
			visible = true,
			hide_dotfiles = false,
			hide_gitignored = true,
			always_show = {
				".env",
				".dev.vars",
			},
			always_show_by_pattern = {
				".env.*",
			},
			never_show = {
				".git",
			},
		},
		hijack_netrw_behavior = "open_current",
		use_libuv_file_watcher = vim.fn.has("win32") ~= 1,
	},
	event_handlers = {
		{
			event = "neo_tree_buffer_enter",
			handler = function()
				vim.opt_local.signcolumn = "auto"
				vim.opt_local.foldcolumn = "0"
			end,
		},
	},
})

-- keymaps
map("n", "<leader>e", "<cmd>Neotree toggle<CR>", { desc = "Toggle Explorer" })
map("n", "<leader>o", function()
	if vim.bo.filetype == "neo-tree" then
		vim.cmd.wincmd("p")
	else
		vim.cmd.Neotree("focus")
	end
end, { desc = "Toggle Explorer Focus" })

-- open neo-tree when nvim is opened with a directory
vim.api.nvim_create_autocmd("BufEnter", {
	group = vim.api.nvim_create_augroup("neotree_start", { clear = true }),
	desc = "Open Neo-Tree on startup with directory",
	callback = function(args)
		if package.loaded["neo-tree"] then
			return true
		end
		local stats = vim.uv.fs_stat(vim.api.nvim_buf_get_name(args.buf))
		if stats and stats.type == "directory" then
			vim.cmd.Neotree({ args = { vim.api.nvim_buf_get_name(args.buf) } })
			return true
		end
	end,
})
