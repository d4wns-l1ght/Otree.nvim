local M = {}

M.buf = nil
M.win = nil
M.win_size = nil
M.prev_cur_pos = nil
M.cwd = nil
M.pwd = nil
M.ns = vim.api.nvim_create_namespace("TreeOil")

M.nodes = {}
M.show_hidden = false
M.show_ignore = false
M.ignore_patterns = {}

return M
