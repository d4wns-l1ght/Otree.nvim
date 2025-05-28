local state = require("Otree.state")
local devicons = require("nvim-web-devicons")
local M = {}

local uv = vim.uv or vim.loop
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

local function get_icon(type, fullpath, filename)
	local icon, icon_hl
	if type == "directory" then
		if is_dir_empty(fullpath) then
			icon = state.icons.empty_dir
		else
			icon = state.icons.directory
		end
		icon_hl = state.highlights.directory
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
		if a.type == "directory" and b.type ~= "directory" then
			return true
		elseif a.type ~= "directory" and b.type == "directory" then
			return false
		end
		return a.full_path < b.full_path
	end
	local result = {}
	for _, node in ipairs(nodes) do
		table.insert(result, node)
	end
	table.sort(result, compare_nodes)
	return result
end

function M.scan_dir(dir)
	dir = dir or vim.fn.getcwd()
	local cmd = { state.fd, "--max-depth", "1", "--absolute-path", "-t", "f", "-t", "d" }
	if state.show_hidden then
		table.insert(cmd, "--hidden")
	end
	if state.show_ignore then
		table.insert(cmd, "--no-ignore")
	else
		for _, pattern in ipairs(state.ignore_patterns) do
			table.insert(cmd, "--exclude")
			table.insert(cmd, pattern)
		end
	end
	table.insert(cmd, ".")
	table.insert(cmd, dir)
	local paths = vim.system(cmd, { cwd = dir, text = true }):wait()
	if paths.code ~= 0 then
		vim.notify("Otree: fd failed to run in " .. dir, vim.log.levels.ERROR)
		return {}
	end
	paths = vim.split(paths.stdout or "", "\n", { trimempty = true })
	local nodes = {}
	for _, path in ipairs(paths) do
		if path ~= dir then
			path = path:gsub("/$", "")
			local stat = cached_stat(path)
			if stat then
				local node = make_node(path, dir, stat.type)
				table.insert(nodes, node)
			end
		end
	end

	return sort_nodes(nodes)
end

return M
