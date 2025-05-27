local actions = require("Otree.actions")
local state = require("Otree.state")
local M = {}

local default_config = {
	win_size = 27,
	open_on_startup = false,
	hijack_netrw = true,
	show_hidden = false,
	show_ignore = false,
	ignore_patterns = {},
	cursorline = true,
	keymaps = {
		["<CR>"] = "actions.on_enter",
		["l"] = "actions.on_enter",
		["h"] = "actions.on_close_dir",
		["q"] = "actions.close_win",
		["<C-h>"] = "actions.goto_parent",
		["<C-l>"] = "actions.goto_dir",
		["<M-H>"] = "actions.goto_pwd",
		["cd"] = "actions.change_pwd",
		["L"] = "actions.open_dirs",
		["H"] = "actions.close_dirs",
		["o"] = "actions.edit_dir",
		["O"] = "actions.edit_into_dir",
		["st"] = "actions.open_tab",
		["sv"] = "actions.open_vsplit",
		["ss"] = "actions.open_split",
		["s."] = "actions.toggle_hidden",
		["si"] = "actions.toggle_ignore",
		["r"] = "actions.refresh",
		["sf"] = "actions.focus_file",
	},
	tree = {
		connector_last = "└─",
		connector_middle = "├─",
		vertical_line = "│",
		spacing = "  ",
	},
	icons = {
		title = " ",
		directory = "",
		empty_dir = "",
	},
	highlights = {
		directory = "Directory",
		file = "Normal",
		title = "TelescopeTitle",
		tree = "Comment",
		normal = "Normal",
		float_normal = "TelescopeNormal",
		float_border = "TelescopeBorder",
	},
	float = {
		width_ratio = 0.4,
		height_ratio = 0.7,
		padding = 2,
		cursorline = true,
	},
}

local function hijack_netrw(opts)
	vim.g.loaded_netrw = 1
	vim.g.loaded_netrwPlugin = 1

	vim.api.nvim_create_autocmd("VimEnter", {
		nested = true,
		callback = function()
			local args = vim.fn.argv()
			if #args == 0 then
				if opts.open_on_startup then
					actions.open_win(state.pwd)
				end
				return
			end
			local file_flag = false
			local path = nil
			for i = 1, #args do
				if vim.fn.isdirectory(args[i]) == 1 then
					if vim.fn.bufexists(args[i]) == 1 then
						vim.cmd("bwipeout " .. vim.fn.bufnr(args[i]))
					end
					path = args[i]
				else
					file_flag = true
				end
			end
			if not file_flag then
				vim.cmd("enew")
			end
			if path == "." then
				actions.open_win(state.pwd)
			elseif path == ".." then
				actions.open_win(state.pwd:match("^(.+)/[^/]+$"))
			else
				actions.open_win(state.pwd .. "/" .. path)
			end
		end,
	})
end

local function setup_oil(oil)
	oil.setup({
		use_default_keymaps = false,
		skip_confirm_for_simple_edits = true,
		delete_to_trash = true,
		cleanup_delay_ms = false,
		default_file_explorer = false,
		keymaps = {
			["st"] = { "actions.toggle_trash", mode = "n" },
		},
		view_options = {
			show_hidden = state.show_hidden,
		},
		confirmation = {
			max_width = 0.9,
			min_width = { 30 },
		},
	})
end

function M.setup(opts)
	opts = vim.tbl_deep_extend("force", default_config, opts or {})

	local ok_devicons, _ = pcall(require, "nvim-web-devicons")
	if not ok_devicons then
		vim.notify("Otree: nvim-web-devicons is required but not installed", vim.log.levels.ERROR)
		return
	end

	local ok_oil, oil = pcall(require, "oil")
	if not ok_oil then
		vim.notify("Otree: oil.nvim is required but not installed", vim.log.levels.ERROR)
		return
	end

	state.fd = vim.fn.executable("fd") == 1 and "fd" or (vim.fn.executable("fdfind") == 1 and "fdfind")
	if not state.fd then
		vim.notify("Otree : neither 'fd' nor 'fdfind' is installed!", vim.log.levels.ERROR)
		return
	end

	state.pwd = vim.fn.getcwd()
	local config_keys = {
		"show_hidden",
		"show_ignore",
		"cursorline",
		"ignore_patterns",
		"keymaps",
		"win_size",
		"highlights",
		"tree",
		"icons",
		"float",
	}
	for _, key in ipairs(config_keys) do
		state[key] = opts[key]
	end

	vim.api.nvim_create_user_command("Otree", actions.toggle_tree, {})
	vim.api.nvim_create_user_command("OtreeFocus", actions.focus_tree, {})

	setup_oil(oil)
	if opts.hijack_netrw then
		hijack_netrw(opts)
	end

	return M
end

return M
