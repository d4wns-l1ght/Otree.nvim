local state = require("Otree.state")
local M = {}

local function resolve_action(action_str, actions)
	if action_str:match("^actions%.") then
		local func_name = action_str:gsub("^actions%.", "")
		return actions[func_name]
	end
	return actions[action_str]
end

local function should_redirect_buffer(args)
	local curr_win = vim.api.nvim_get_current_win()
	return curr_win == state.win and args.buf ~= state.buf and vim.bo[args.buf].filetype ~= state.buf_filetype
end

local function handle_buffer_redirection(args)
	if not should_redirect_buffer(args) then
		return
	end

	if state.oil ~= "float" and args.file:match("^oil") then
		vim.schedule(function()
			if args.file:match("^oil://") then
				require("Otree.oil").set_title(args.file:gsub("^oil://", ""), state.icons.oil)
				return
			end
			if args.file:match("^oil%-trash://") then
				require("Otree.oil").set_title(args.file:gsub("^oil%-trash://", ""), state.icons.trash)
				return
			end
		end)
		return
	end

	local target_win = nil
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local config = vim.api.nvim_win_get_config(win)
		if config.relative == "" and win ~= state.win then
			target_win = win
			break
		end
	end

	if not target_win then
		vim.api.nvim_win_set_buf(state.win, args.buf)
		state.win = nil
		return
	end

	vim.api.nvim_set_current_win(target_win)
	vim.api.nvim_win_set_buf(target_win, args.buf)

	if vim.api.nvim_buf_is_valid(state.buf) then
		vim.api.nvim_win_set_buf(state.win, state.buf)
	end
end

local function check_last_window()
	if not (state.win and vim.api.nvim_win_is_valid(state.win)) then
		return false
	end

	local wins = vim.api.nvim_tabpage_list_wins(0)
	local non_floating_wins = {}

	for _, win in ipairs(wins) do
		local config = vim.api.nvim_win_get_config(win)
		if config.relative == "" then
			table.insert(non_floating_wins, win)
		end
	end
	return #non_floating_wins == 1 and non_floating_wins[1] == state.win
end

local function handle_window_cleanup()
	local curr_win = vim.api.nvim_get_current_win()
	local config = vim.api.nvim_win_get_config(curr_win)

	if curr_win ~= state.win and config.relative == "" then
		vim.api.nvim_win_close(curr_win, false)
	end
end

local function check_modified_buffers()
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(bufnr) and vim.api.nvim_buf_get_option(bufnr, "modified") then
			return true
		end
	end
	return false
end

local function handle_window_enter()
	if check_last_window() then
		if check_modified_buffers() then
			vim.api.nvim_buf_delete(state.buf, { force = true })
			state.win = nil
		else
			vim.cmd("silent! quit!")
		end
	else
		handle_window_cleanup()
	end
end

local function is_float(win)
	return vim.api.nvim_win_get_config(win).relative ~= ""
end

function M.setup_keymaps(buf)
	local actions = require("Otree.actions")

	for _, key in ipairs({ "i", "I", "a", "A", "o", "O", "c", "C", "s", "S", "r", "R" }) do
		vim.keymap.set("n", key, "<Nop>", { buffer = buf })
	end

	for key, action_str in pairs(state.keymaps) do
		local action_func = resolve_action(action_str, actions)
		if action_func then
			vim.keymap.set("n", key, action_func, { buffer = buf, nowait = true })
		else
			vim.notify("Otree: unknown action '" .. action_str .. "' for key '" .. key .. "'", vim.log.levels.WARN)
		end
	end

	local close_keys = { "q", "<Esc>" }
	for _, key in ipairs(close_keys) do
		vim.keymap.set("n", key, function()
			local curr_win = vim.api.nvim_get_current_win()

			if is_float(curr_win) then
				require("Otree.float").close_float()
			elseif state.oil ~= "float" and curr_win == state.win then
				vim.api.nvim_win_set_buf(state.win, state.buf)
			end
			actions.refresh()
		end, { noremap = true, silent = true })
	end
end

function M.setup_autocmds(buf)
	local augroup = state.augroup

	vim.api.nvim_create_autocmd("BufEnter", {
		group = augroup,
		callback = handle_buffer_redirection,
	})

	vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
		group = augroup,
		buffer = buf,
		callback = handle_window_enter,
	})

	vim.api.nvim_create_autocmd("WinResized", {
		group = augroup,
		callback = function()
			if check_last_window() then
				vim.schedule(function()
					state.win = nil
				end)
			end
		end,
	})
end

return M
