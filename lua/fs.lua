local state = require("treeoil.state")
local ok, devicons = pcall(require, "nvim-web-devicons")
if not ok then
	vim.api.nvim_buf_set_lines(vim.fn.expand("%:p:h"), 0, -1, false, {
		"Error: devicons not installed",
	})
	return
end
local M = {}
local uv = vim.uv or vim.loop

local fd_cache = {}
local stat_cache = {}

local function is_dir_empty(path)
	local req, _ = uv.fs_scandir(path)
	if not req then
		return false
	end
	local entry = uv.fs_scandir_next(req)
	return entry == nil
end

local function get_parent_path(path)
	return path:match("^(.+)/[^/]+$")
end

local function get_relative_path(full_path, cwd)
	local function split(str, sep)
		local result = {}
		for part in str:gmatch("[^" .. sep .. "]+") do
			table.insert(result, part)
		end
		return result
	end

	local function join(parts, sep)
		return table.concat(parts, sep or "/")
	end

	local function relative_path(from, to)
		local from_parts = split(vim.fn.resolve(from), "/")
		local to_parts = split(vim.fn.resolve(to), "/")

		local i = 1
		while i <= #from_parts and i <= #to_parts and from_parts[i] == to_parts[i] do
			i = i + 1
		end

		local up = {}
		for _ = i, #from_parts do
			table.insert(up, "..")
		end
		for j = i, #to_parts do
			table.insert(up, to_parts[j])
		end

		return join(up)
	end

	return relative_path(cwd, full_path)
end

local function cached_stat(path)
	if stat_cache[path] then
		return stat_cache[path]
	end
	local stat = uv.fs_stat(path)
	stat_cache[path] = stat
	return stat
end

function M.clear_cache()
	fd_cache = {}
	stat_cache = {}
end

local function get_icon(type, fullpath, filename)
	local icon, icon_hl
	if type == "directory" then
		if is_dir_empty(fullpath) then
			icon = ""
		else
			icon = ""
		end
		icon_hl = "Directory"
	else
		icon, icon_hl = devicons.get_icon(filename, nil, { default = true })
	end
	return icon, icon_hl
end

local function make_node(full_path, base, type)
	local rel = full_path:sub(#base + 2)
	local filename = vim.fn.fnamemodify(full_path, ":t")
	local level = select(2, rel:gsub("/", ""))
	local icon, icon_hl = get_icon(type, full_path, filename)

	return {
		filename = filename,
		path = get_relative_path(full_path, state.pwd),
		full_path = full_path,
		parent_path = get_parent_path(full_path),
		type = type,
		is_open = false,
		level = level,
		icon = icon,
		icon_hl = icon_hl,
	}
end

local function sort_nodes(nodes)
	local function compare_nodes(a, b)
		local isaDir = a.type == "directory"
		local isbDir = b.type == "directory"
		if isaDir ~= isbDir then
			return isaDir
		else
			return a.full_path < b.full_path
		end
	end
	local result = {}
	for _, node in ipairs(nodes) do
		table.insert(result, node)
	end
	table.sort(result, compare_nodes)
	return result
end

function M.update_paths(nodes)
	for _, node in ipairs(nodes) do
		node.path = get_relative_path(node.full_path, state.pwd)
	end
end

function M.scan_dir(dir)
	local show_hidden = state.show_hidden
	local show_ignore = state.show_ignore
	local ignore_patterns = state.ignore_patterns or {}
	local base = dir or vim.fn.getcwd()

	local cache_key = string.format(
		"%s:%s:%s:%s",
		base,
		tostring(show_hidden),
		tostring(show_ignore),
		table.concat(ignore_patterns, ",")
	)

	local cached = fd_cache[cache_key]
	if cached and (os.time() - cached.timestamp) < 1 then
		return cached.result
	end

	local cmd = { "fd", "--max-depth", "1", "--absolute-path", "-t", "f", "-t", "d" }

	if show_hidden then
		table.insert(cmd, "--hidden")
	end

	if show_ignore then
		table.insert(cmd, "--no-ignore")
	else
		for _, pattern in ipairs(ignore_patterns) do
			table.insert(cmd, "--exclude")
			table.insert(cmd, pattern)
		end
	end

	table.insert(cmd, ".")
	table.insert(cmd, base)

	local obj = vim.system(cmd, { cwd = base, text = true })
	local output = obj:wait()

	if output.code ~= 0 then
		vim.notify("fd failed to run in " .. base, vim.log.levels.ERROR)
		return {}
	end

	local result = vim.split(output.stdout or "", "\n", { trimempty = true })
	local nodes = {}

	for _, full_path in ipairs(result) do
		if full_path ~= base then
			full_path = full_path:gsub("/$", "")
			local stat = cached_stat(full_path)
			if stat then
				local node = make_node(full_path, base, stat.type)
				table.insert(nodes, node)
			end
		end
	end

	local sorted = sort_nodes(nodes)

	fd_cache[cache_key] = {
		result = sorted,
		timestamp = os.time(),
	}

	return sorted
end

return M
