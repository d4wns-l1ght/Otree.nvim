local state = require("Otree.state")
local M = {}

function M.setup_keymaps(buf)
	local actions = require("Otree.actions")
	for _, key in ipairs({ "i", "I", "a", "A", "o", "O", "c", "C", "s", "S", "r", "R" }) do
		vim.keymap.set("n", key, "<Nop>", { buffer = buf })
	end
	vim.keymap.set("n", "<CR>", actions.on_enter, { buffer = buf, nowait = true })
	vim.keymap.set("n", "q", actions.close_win, { buffer = buf, nowait = true })
	vim.keymap.set("n", "r", actions.refresh, { buffer = buf, nowait = true })
	vim.keymap.set("n", "h", actions.on_close_dir, { buffer = buf, nowait = true })
	vim.keymap.set("n", "l", actions.on_enter, { buffer = buf, nowait = true })
	vim.keymap.set("n", "cd", actions.change_pwd, { buffer = buf, nowait = true })
	vim.keymap.set("n", "L", actions.open_dirs, { buffer = buf, nowait = true })
	vim.keymap.set("n", "H", actions.close_dirs, { buffer = buf, nowait = true })
	vim.keymap.set("n", "<C-h>", actions.goto_parent, { buffer = buf, nowait = true })
	vim.keymap.set("n", "<C-l>", actions.goto_dir, { buffer = buf, nowait = true })
	vim.keymap.set("n", "<M-H>", actions.goto_pwd, { buffer = buf, nowait = true })
	vim.keymap.set("n", "o", actions.edit_dir, { buffer = buf, nowait = true })
	vim.keymap.set("n", "s.", actions.toggle_hidden, { buffer = buf, nowait = true })
	vim.keymap.set("n", "si", actions.toggle_ignore, { buffer = buf, nowait = true })
end

function M.setup_buffer_autocmds(buf)
	local augroup = vim.api.nvim_create_augroup("OtreeGroup", { clear = true })

	vim.api.nvim_create_autocmd("BufEnter", {
		group = augroup,
		callback = function(args)
			local curr_win = vim.api.nvim_get_current_win()
			if curr_win == state.win and args.buf ~= state.buf and vim.bo[args.buf].filetype ~= "Otree" then
				local target_win = vim.fn.win_getid(vim.fn.winnr("l"))
				if vim.api.nvim_win_is_valid(target_win) then
					vim.api.nvim_set_current_win(target_win)
					vim.api.nvim_win_set_buf(target_win, args.buf)
					if vim.api.nvim_buf_is_valid(state.buf) then
						vim.api.nvim_win_set_buf(state.win, state.buf)
					end
				end
			end
		end,
	})

	vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
		group = augroup,
		buffer = buf,
		callback = function(args)
			if state.win and vim.api.nvim_win_is_valid(state.win) then
				local wins = vim.api.nvim_tabpage_list_wins(0)
				if #wins == 1 and wins[1] == state.win then
					vim.cmd("silent! quit!")
				end
			end
			local curr_win = vim.api.nvim_get_current_win()
			if curr_win ~= state.win and args.buf == state.buf then
				vim.api.nvim_win_close(curr_win, true)
			end
		end,
	})
end

return M
