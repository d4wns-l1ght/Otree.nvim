local state = require("treeoil.state")

local ok, oil = pcall(require, "oil")
if not ok then
	vim.api.nvim_buf_set_lines(vim.fn.expand("%:p:h"), 0, -1, false, {
		"Error: oil.nvim not installed",
	})
	return
end

local okc, config = pcall(require, "oil.config")
if not okc then
	vim.api.nvim_buf_set_lines(vim.fn.expand("%:p:h"), 0, -1, false, {
		"Error: oil.nvim not installed",
	})
	return
end
local M = {}

M.outer_win_id = nil
M.inner_win_id = nil

function M._close()
	if M.inner_win_id and vim.api.nvim_win_is_valid(M.inner_win_id) then
		vim.api.nvim_win_close(M.inner_win_id, true)
	end
	if M.outer_win_id and vim.api.nvim_win_is_valid(M.outer_win_id) then
		vim.api.nvim_win_close(M.outer_win_id, true)
	end

	M.inner_win_id = nil
	M.outer_win_id = nil
	require("treeoil.actions").refresh()
end

function M.open_float(path)
	M._create_windows()
	if vim.api.nvim_win_is_valid(M.inner_win_id) then
		vim.api.nvim_set_current_win(M.inner_win_id)

		config.view_options.show_hidden = state.show_hidden
		oil.open(path)
		M._update_title(path)
		local buf = vim.api.nvim_get_current_buf()
		M.setup_autocmds(buf)
		M.setup_keymaps(buf)
		vim.api.nvim_win_set_option(M.inner_win_id, "cursorline", true)
	end
end

function M._create_windows()
	if M.outer_win_id and vim.api.nvim_win_is_valid(M.outer_win_id) then
		return
	end
	local width = vim.o.columns
	local height = vim.o.lines
	local outer_width = math.floor(width * 0.4)
	local outer_height = math.floor(height * 0.7)
	local padding = 2
	local col = math.floor((width - outer_width) / 2)
	local row = math.floor((height - outer_height) / 2)

	local outer_buf = vim.api.nvim_create_buf(false, true)
	M.outer_win_id = vim.api.nvim_open_win(outer_buf, false, {
		relative = "editor",
		width = outer_width,
		height = outer_height,
		col = col,
		row = row,
		style = "minimal",
		border = "rounded",
		noautocmd = true,
		focusable = false,
	})
	vim.api.nvim_win_set_option(M.outer_win_id, "winhl", "Normal:TelescopeNormal,FloatBorder:TelescopeBorder")
	local inner_buf = vim.api.nvim_create_buf(false, true)
	M.inner_win_id = vim.api.nvim_open_win(inner_buf, true, {
		relative = "win",
		win = M.outer_win_id,
		width = outer_width - padding * 2,
		height = outer_height - padding * 2,
		col = padding,
		row = padding,
		style = "minimal",
		border = "none",
		noautocmd = true,
	})
	vim.api.nvim_win_set_option(M.inner_win_id, "winhl", "Normal:Normal")
end

function M._update_title(path)
	if not M.outer_win_id or not vim.api.nvim_win_is_valid(M.outer_win_id) then
		return
	end
	local cwd = vim.fn.getcwd()
	path = vim.fn.expand(path):gsub("//+", "/")
	local title = vim.startswith(path, cwd) and (vim.fn.fnamemodify(cwd, ":t") .. "/" .. path:sub(#cwd + 2))
		or path:sub(2)
	local buf = vim.api.nvim_win_get_buf(M.outer_win_id)
	vim.api.nvim_buf_clear_namespace(buf, state.ns, 0, 1)
	vim.api.nvim_buf_set_extmark(buf, state.ns, 0, 0, {
		virt_text = { { title, "TelescopeTitle" } },
	})
end

function M.setup_keymaps(buf)
	for _, key in ipairs({ "q", "<Esc>" }) do
		vim.keymap.set("n", key, function()
			M._close()
		end, { buffer = buf, noremap = true })
	end
end

function M.setup_autocmds(buf)
	local augroup_id = vim.api.nvim_create_augroup("OFloatingWindow", { clear = true })

	vim.api.nvim_create_autocmd({ "BufLeave" }, {
		group = augroup_id,
		buffer = buf,
		callback = function(args)
			local buff = args.buf
			if vim.bo[buff].filetype ~= "oil" then
				return
			end
			vim.schedule(function()
				local curr = vim.api.nvim_get_current_buf()
				if vim.bo[curr].filetype == "oil_preview" or vim.bo[curr].filetype == "oil" then
					return
				end

				if vim.api.nvim_buf_is_valid(buff) then
					M._close()
				end
			end)
		end,
	})
end

return M
