local M = {}

---@param buf_nr integer
---@param ns_id integer?
---@param line_start integer?
---@param line_end integer?
---@return nil
function M.clear_hl(buf_nr, ns_id, line_start, line_end)
  ns_id = ns_id or -1
  line_start = line_start or 0
  line_end = line_end or -1
  if vim.api.nvim_buf_is_valid(buf_nr) then
    vim.api.nvim_buf_clear_namespace(buf_nr, ns_id, line_start, line_end)
  end
end

---@param name string
---@return integer
function M.create_augroup(name)
  return vim.api.nvim_create_augroup(name, { clear = true })
end

---@param buf_nr integer
---@return boolean
function M.buffer_empty(buf_nr)
  local lines = vim.api.nvim_buf_get_lines(buf_nr, 0, -1, false)
  return #lines == 1 and lines[1] == ""
end

---@param mod string
---@return boolean
function M.module_exists(mod)
  return pcall(_G.require, mod) == true
end

---@param winid integer
---@param name string
---@param value any
---@return nil
function M.set_win_option(winid, name, value)
  vim.api.nvim_set_option_value(name, value, { win = winid, scope = "local" })
end

return M
