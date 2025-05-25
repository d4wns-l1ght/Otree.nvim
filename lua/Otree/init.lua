local actions = require("Otree.actions")
local state = require("Otree.state")
local M = {}

function M.setup(opts)
	opts = opts or {}

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

	oil.setup({
		use_default_keymaps = false,
		skip_confirm_for_simple_edits = true,
		delete_to_trash = true,
		cleanup_delay_ms = 100,
		default_file_explorer = false,
		keymaps = {
			["st"] = { "actions.toggle_trash", mode = "n" },
		},
		confirmation = {
			max_width = 0.9,
			min_width = { 30 },
		},
	})

	state.show_hidden = opts.show_hidden or false
	state.show_ignore = opts.show_ignore or false
	state.ignore_patterns = opts.ignore_patterns or {}
	state.win_size = opts.win_size or 27

	vim.api.nvim_create_user_command("Otree", actions.toggle, {})

	vim.g.loaded_netrw = 1
	vim.g.loaded_netrwPlugin = 1

	vim.api.nvim_create_autocmd("VimEnter", {
		callback = function()
			local arg = vim.fn.argv(0)
			if arg == "" or vim.fn.isdirectory(arg) == 1 then
				if arg ~= "" then
					vim.cmd("cd " .. arg)
				end
			end
		end,
	})

	return M
end

return M
