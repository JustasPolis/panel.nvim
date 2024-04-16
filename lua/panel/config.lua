local M = {}

---@class Tab
---@field name string
---@field module table<string, fun(win_id: integer): nil>|string

---@class PanelConfig
---@field open_on_launch boolean
---@field tabs Tab[]
---@field initial_tab Tab
M.opts = {
  open_on_launch = false,
  tabs = {},
}

---@param opts PanelConfig
function M:setup(opts)
  self.opts = vim.tbl_deep_extend("force", self.opts, opts)
  assert(#self.opts.tabs > 0, "Please add at least one tab")

  -- if user forgets to set initial tab, we set the first one in the tab table
  if self.opts.initial_tab == nil then
    self.opts.initial_tab = self.opts.tabs[1]
  end
end

return M
