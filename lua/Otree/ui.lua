local state = require("Otree.state")
local keymap = require("Otree.keymap")
local M = {}

local function get_node_highlight(node)
	return node.type == "directory" and state.highlights.directory or state.highlights.file
end

local function render_basic_lines(nodes, lines, highlights)
	for i, node in ipairs(nodes) do
		local display = node.filename
		table.insert(lines, display)
		table.insert(highlights, {
			line = i - 1,
			col = 0,
			len = #node.filename + 2,
			hl = get_node_highlight(node),
		})
	end
end

local function is_last_at_level(node, node_index, nodes)
	for j = node_index + 1, #nodes do
		local next_node = nodes[j]
		if next_node.level == node.level then
			return false
		elseif next_node.level < node.level then
			break
		end
	end
	return true
end

local function create_tree_chunks(node, node_index, nodes)
	local chunks = {}
	local npadding = node.level

	for _ = 1, node.level do
		table.insert(chunks, {
			state.tree.vertical_line .. state.tree.spacing,
			state.highlights.tree,
		})
		npadding = npadding - 1
	end

	local is_last = is_last_at_level(node, node_index, nodes)
	local connector = is_last and state.tree.connector_last or state.tree.connector_middle
	local padding = string.rep(" ", npadding)

	table.insert(chunks, {
		padding .. connector .. " ",
		state.highlights.tree,
	})

	local icon = node.icon
	if icon then
		table.insert(chunks, {
			icon .. " ",
			node.icon_hl or state.highlights.normal,
		})
	end

	return chunks
end

local function set_buffer_content(lines, highlights)
	vim.api.nvim_buf_set_option(state.buf, "modifiable", true)
	vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
	vim.api.nvim_buf_clear_namespace(state.buf, state.ns, 0, -1)

	for _, h in ipairs(highlights) do
		vim.api.nvim_buf_add_highlight(state.buf, state.ns, h.hl, h.line, h.col, h.col + h.len)
	end
end

local function add_tree_structure(nodes)
	for i, node in ipairs(nodes) do
		local line = i - 1
		local chunks = create_tree_chunks(node, i, nodes)

		vim.api.nvim_buf_set_extmark(state.buf, state.ns, line, 0, {
			virt_text = chunks,
			virt_text_pos = "inline",
		})
	end
end

local function set_window_title()
	local cwd_name = vim.fn.fnamemodify(state.cwd, ":t")
	vim.wo[state.win].winbar = "%#" .. state.highlights.title .. "#" .. state.icons.title .. cwd_name
end

function M.render()
	local lines = {}
	local highlights = {}
	local nodes = state.nodes

	render_basic_lines(nodes, lines, highlights)
	set_buffer_content(lines, highlights)
	add_tree_structure(nodes)
	set_window_title()
	vim.api.nvim_buf_set_option(state.buf, "modifiable", false)
end

local function configure_buffer_options()
	local bo = vim.bo[state.buf]
	bo.buftype = "nofile"
	bo.bufhidden = "hide"
	bo.filetype = state.buf_filetype
	bo.modifiable = false
	bo.swapfile = false
end

local function setup_buffer_behavior()
	keymap.setup_keymaps(state.buf)
	keymap.setup_buffer_autocmds(state.buf)
end

function M.create_buffer()
	state.buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(state.buf, state.buf_prefix .. state.cwd)

	configure_buffer_options()
	setup_buffer_behavior()
end

local function configure_window_options()
	local win_opts = {
		number = false,
		signcolumn = "no",
		relativenumber = false,
		sidescrolloff = 20,
		cursorline = state.cursorline,
		winfixwidth = true,
		winfixheight = true,
		winhl = "Search:None,CurSearch:None,IncSearch:None",
	}

	for opt, value in pairs(win_opts) do
		vim.api.nvim_set_option_value(opt, value, { scope = "local", win = state.win })
	end
end

function M.create_window()
	vim.cmd("topleft " .. tostring(state.win_size) .. "vsplit")
	state.win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(state.win, state.buf)

	configure_window_options()
	M.render()
end

return M
