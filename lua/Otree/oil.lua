local state = require("Otree.state")
local float = require("Otree.float")
local oil = require("oil")
local M = {}

local function format_path_for_title(path)
	local cwd = state.cwd
	path = vim.fn.expand(path):gsub("//+", "/")

	if vim.startswith(path, cwd) then
		local cwd_name = vim.fn.fnamemodify(cwd, ":t")
		local relative_path = path:sub(#cwd + 2)
		return relative_path == "" and cwd_name or (cwd_name .. "/" .. relative_path)
	else
		return path:sub(2)
	end
end

local function set_title(path)
	local formatted_path = format_path_for_title(path)
	local title = state.icons.title .. " " .. formatted_path
	float.set_title(title)
end

local function setup_oil_keymaps(buf)
	local close_keys = { "q", "<Esc>" }

	for _, key in ipairs(close_keys) do
		vim.keymap.set("n", key, function()
			float.close_float()
			require("Otree.actions").refresh()
		end, {
			buffer = buf,
			noremap = true,
		})
	end

	vim.keymap.set("n", "<CR>", function()
		oil.save()
	end, {
		buffer = buf,
		noremap = true,
	})
end

local function handle_buffer_leave(args)
	local buff = args.buf
	if vim.bo[buff].filetype ~= "oil" then
		return
	end

	vim.schedule(function()
		local curr = vim.api.nvim_get_current_buf()
		local curr_filetype = vim.bo[curr].filetype

		if curr_filetype == "oil_preview" or curr_filetype == "oil" then
			return
		end

		if vim.api.nvim_buf_is_valid(buff) then
			float.close_float()
			require("Otree.actions").refresh()
		end
	end)
end

local function setup_oil_autocmds(buf)
	vim.api.nvim_create_autocmd("BufLeave", {
		group = state.augroup,
		buffer = buf,
		callback = handle_buffer_leave,
	})
end

function M.open_oil(path)
	if float.open_float() ~= true then
		return
	end
	oil.open(path)
	set_title(path)
	local buf = vim.api.nvim_get_current_buf()
	setup_oil_keymaps(buf)
	setup_oil_autocmds(buf)
	vim.api.nvim_win_set_option(float.inner_win_id, "cursorline", state.float.cursorline)
end

return M
