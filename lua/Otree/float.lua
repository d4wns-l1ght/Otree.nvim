local state = require("Otree.state")
local M = {}

M.outer_win_id = nil
M.inner_win_id = nil

local function close_window_if_valid(win_id)
	if win_id and vim.api.nvim_win_is_valid(win_id) then
		vim.api.nvim_win_close(win_id, true)
	end
end

local function calculate_window_geometry(config)
	local width = vim.o.columns
	local height = vim.o.lines
	local outer_width = math.floor(width * config.width_ratio)
	local outer_height = math.floor(height * config.height_ratio)
	local col = math.floor((width - outer_width) / 2)
	local row = math.floor((height - outer_height) / 2)

	return {
		outer_width = outer_width,
		outer_height = outer_height,
		inner_width = outer_width - config.padding * 2,
		inner_height = outer_height - config.padding * 2,
		col = col,
		row = row,
		padding = config.padding,
	}
end

local function create_outer_window(geometry)
	local outer_buf = vim.api.nvim_create_buf(false, true)

	M.outer_win_id = vim.api.nvim_open_win(outer_buf, false, {
		relative = "editor",
		width = geometry.outer_width,
		height = geometry.outer_height,
		col = geometry.col,
		row = geometry.row,
		style = "minimal",
		border = state.float.border,
		noautocmd = true,
		focusable = false,
	})

	local winhl =
		string.format("Normal:%s,FloatBorder:%s", state.highlights.float_normal, state.highlights.float_border)
	vim.api.nvim_win_set_option(M.outer_win_id, "winhl", winhl)
end

local function create_inner_window(geometry)
	local inner_buf = vim.api.nvim_create_buf(false, true)

	M.inner_win_id = vim.api.nvim_open_win(inner_buf, true, {
		relative = "win",
		win = M.outer_win_id,
		width = geometry.inner_width,
		height = geometry.inner_height,
		col = geometry.padding,
		row = geometry.padding,
		style = "minimal",
		border = "none",
		noautocmd = true,
	})
end

function M.close_float()
	close_window_if_valid(M.inner_win_id)
	close_window_if_valid(M.outer_win_id)
	M.inner_win_id = nil
	M.outer_win_id = nil
end

function M.open_float(config)
	config = vim.tbl_deep_extend("force", state.float, config or {})
	local geometry = calculate_window_geometry(config)
	create_outer_window(geometry)
	create_inner_window(geometry)
	if not vim.api.nvim_win_is_valid(M.inner_win_id) then
		return false
	end
	vim.api.nvim_set_current_win(M.inner_win_id)
	return true
end

function M.set_title(title)
	if not M.outer_win_id or not vim.api.nvim_win_is_valid(M.outer_win_id) then
		return
	end
	local buf = vim.api.nvim_win_get_buf(M.outer_win_id)
	vim.api.nvim_buf_clear_namespace(buf, state.ns, 0, 1)
	vim.api.nvim_buf_set_extmark(buf, state.ns, 0, 0, {
		virt_text = { { title, state.highlights.title } },
	})
end

return M
