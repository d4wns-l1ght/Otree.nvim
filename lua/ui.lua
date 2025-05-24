local state = require("treeoil.state")
local keymap = require("treeoil.keymap")

local M = {}

local function render_nodes(filtered, lines, highlights)
	for i, node in ipairs(filtered) do
		local display = node.filename
		table.insert(lines, display)
		table.insert(highlights, {
			line = i - 1,
			col = 0,
			len = #node.filename + 2,
			hl = node.type == "Directory" and "Directory" or "Normal",
		})
	end
end

function M.render()
	local lines = {}
	local highlights = {}

	local nodes = state.nodes
	render_nodes(nodes, lines, highlights)

	vim.api.nvim_buf_set_option(state.buf, "modifiable", true)
	vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
	vim.api.nvim_buf_clear_namespace(state.buf, state.ns, 0, -1)

	for _, h in ipairs(highlights) do
		vim.api.nvim_buf_add_highlight(state.buf, state.ns, h.hl, h.line, h.col, h.col + h.len)
	end

	for i, node in ipairs(nodes) do
		local line = i - 1
		local chunks = {}
		local npadding = node.level * 3

		for _ = 1, node.level do
			table.insert(chunks, { "│  ", "Comment" })
			npadding = npadding - 3
		end

		local is_last = true
		for j = i + 1, #nodes do
			local next_node = nodes[j]
			if next_node.level == node.level then
				is_last = false
				break
			elseif next_node.level < node.level then
				break
			end
		end
		local connector = is_last and "└─" or "├─"
		local padding = string.rep(" ", npadding)
		table.insert(chunks, { padding .. connector .. " ", "Comment" })
		if node.icon then
			table.insert(chunks, { node.icon .. " ", node.icon_hl or "Normal" })
		end
		vim.api.nvim_buf_set_extmark(state.buf, state.ns, line, 0, {
			virt_text = chunks,
			virt_text_pos = "inline",
		})
	end

	vim.api.nvim_buf_set_option(state.buf, "modifiable", false)
	local cwd_name = vim.fn.fnamemodify(state.cwd, ":t")
	vim.wo[state.win].winbar = "%#TelescopeTitle#" .. " " .. cwd_name
end

function M.create_buffer()
	state.buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(state.buf, "treeoil://" .. state.cwd)

	local bo = vim.bo[state.buf]
	bo.buftype = "nofile"
	bo.bufhidden = "hide"
	bo.filetype = "treeoil"
	bo.modifiable = false
	bo.swapfile = false
	keymap.setup_keymaps(state.buf)
	keymap.setup_buffer_autocmds(state.buf)
end

function M.create_window()
	vim.cmd("topleft " .. tostring(state.win_size) .. "vsplit")
	state.win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(state.win, state.buf)
	vim.api.nvim_set_option_value("number", false, { scope = "local", win = state.win })
	vim.api.nvim_set_option_value("signcolumn", "no", { scope = "local", win = state.win })
	vim.api.nvim_set_option_value("relativenumber", false, { scope = "local", win = state.win })
	vim.api.nvim_set_option_value("sidescrolloff", 20, { scope = "local", win = state.win })
	vim.api.nvim_set_option_value("cursorline", true, { scope = "local", win = state.win })
	vim.api.nvim_set_option_value("winfixwidth", true, { scope = "local", win = state.win })
	vim.api.nvim_set_option_value("winfixheight", true, { scope = "local", win = state.win })

	M.render()
end

return M
