local state = require("treeoil.state")
local fs = require("treeoil.fs")
local ui = require("treeoil.ui")

local M = {}

local function close_dir(node)
	for i, item in ipairs(state.nodes) do
		if node.full_path == item.full_path then
			local prefix = item.full_path
			while state.nodes[i + 1] and state.nodes[i + 1].full_path:sub(1, #prefix + 1) == prefix .. "/" do
				table.remove(state.nodes, i + 1)
			end
			break
		end
	end
	node.is_open = false
end

local function open_dir(node)
	local new_nodes = fs.scan_dir(node.full_path)
	if not new_nodes or next(new_nodes) == nil then
		return
	end
	for i, item in ipairs(state.nodes) do
		if item.full_path == new_nodes[1].parent_path then
			for j, new_node in ipairs(new_nodes) do
				new_node.level = item.level + 1
				table.insert(state.nodes, i + j, new_node)
			end
		end
	end
	node.is_open = true
end

function M.open_dirs()
	local cursor = vim.api.nvim_win_get_cursor(state.win)
	local line = cursor[1]
	local item = state.nodes[line]
	for _, node in ipairs(state.nodes) do
		if node.parent_path == item.parent_path and node.type == "directory" and not node.is_open then
			open_dir(node)
		end
	end
	ui.render()
end

function M.close_dirs()
	local cursor = vim.api.nvim_win_get_cursor(state.win)
	local line = cursor[1]
	local item = state.nodes[line]
	for _, node in ipairs(state.nodes) do
		if node.parent_path == item.parent_path and node.type == "directory" and node.is_open then
			close_dir(node)
		end
	end
	ui.render()
end

function M.on_enter()
	local cursor = vim.api.nvim_win_get_cursor(state.win)
	local line = cursor[1]
	local node = state.nodes[line]
	if not node then
		return
	end
	if node.type == "directory" then
		if not node.is_open then
			open_dir(node)
			local total_line = vim.api.nvim_buf_line_count(state.buf)
			vim.api.nvim_win_set_cursor(state.win, { math.min(line + 1, total_line), 0 })
		else
			close_dir(node)
		end
		ui.render()
	elseif node.type == "file" then
		local target_win = vim.fn.win_getid(vim.fn.winnr("l"))
		if vim.api.nvim_win_is_valid(target_win) then
			vim.api.nvim_set_current_win(target_win)
			vim.cmd("drop " .. node.path)
		end
	end
end

function M.on_close_dir()
	local cursor = vim.api.nvim_win_get_cursor(state.win)
	local line = cursor[1]
	local node = state.nodes[line]
	if not node then
		return
	end

	if node.type == "directory" and node.is_open then
		close_dir(node)
		ui.render()
		vim.api.nvim_win_set_cursor(state.win, { line, 0 })
		return
	end

	if node.level ~= 0 then
		for _, item in ipairs(state.nodes) do
			if item.full_path == node.parent_path and item.type == "directory" then
				close_dir(item)
				ui.render()
				vim.api.nvim_win_set_cursor(state.win, { _, 0 })
				return
			end
		end
	end
	vim.api.nvim_win_set_cursor(state.win, { math.max(line - 1, 1), 0 })
end

function M.toggle()
	if M.close_win() then
	else
		if not (state.buf and vim.api.nvim_buf_is_valid(state.buf)) then
			state.cwd = vim.fn.getcwd()
			state.pwd = vim.fn.getcwd()
			state.nodes = fs.scan_dir(state.cwd)
			ui.create_buffer()
			state.prev_cur_pos = nil
		end

		ui.create_window()
		if state.prev_cur_pos then
			vim.api.nvim_win_set_cursor(0, state.prev_cur_pos)
		else
			vim.api.nvim_win_set_cursor(0, { 1, 0 })
		end
	end
end

function M.close_win()
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		state.prev_cur_pos = vim.api.nvim_win_get_cursor(state.win)
		vim.api.nvim_win_close(state.win, true)
		state.win = nil
		return true
	end
	return false
end

function M.refresh()
	local open_dirs = {}
	if state.nodes then
		for _, node in ipairs(state.nodes) do
			if node.type == "directory" and node.is_open then
				open_dirs[node.full_path] = true
			end
		end
	end
	state.nodes = fs.scan_dir(state.cwd)
	for _, node in ipairs(state.nodes) do
		if node.type == "directory" and open_dirs[node.full_path] then
			open_dir(node)
		end
	end

	ui.render()
end

function M.change_pwd()
	vim.cmd("cd " .. state.cwd)
	state.pwd = state.cwd
	fs.update_paths(state.nodes)
	vim.notify("PWD: " .. state.cwd, vim.log.levels.INFO)
end

function M.goto_pwd()
	state.prev_cur_pos = nil
	state.pwd = vim.fn.getcwd()
	state.cwd = state.pwd
	state.nodes = fs.scan_dir(state.cwd)
	ui.render()
end

function M.goto_parent()
	local parent_dir = vim.fn.fnamemodify(state.cwd, ":h")
	if parent_dir ~= state.cwd then
		state.prev_cur_pos = nil
		local last_cwd = state.cwd
		local last_nodes = state.nodes
		state.cwd = parent_dir
		state.nodes = fs.scan_dir(state.cwd)
		for i, node in ipairs(state.nodes) do
			if node.full_path == last_cwd and last_nodes then
				node.is_open = true
				for j, curr in ipairs(last_nodes) do
					curr.level = curr.level + 1
					table.insert(state.nodes, i + j, curr)
				end
			end
		end
		ui.render()
	end
end

function M.goto_dir()
	local cursor = vim.api.nvim_win_get_cursor(state.win)
	local line = cursor[1]
	local node = state.nodes[line]
	if node.type == "directory" then
		state.cwd = node.full_path
	else
		state.cwd = node.parent_path
	end
	state.prev_cur_pos = nil
	M.refresh()
end

function M.edit_dir()
	local cursor = vim.api.nvim_win_get_cursor(state.win)
	local line = cursor[1]
	local node = state.nodes[line]
	require("treeoil.float").open_float(node.parent_path)
end

function M.toggle_hidden()
	state.prev_cur_pos = nil
	state.show_hidden = not state.show_hidden
	M.refresh()
end

function M.toggle_ignore()
	state.prev_cur_pos = nil
	state.show_ignore = not state.show_ignore
	M.refresh()
end

return M
