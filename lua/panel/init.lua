_G.lazy = setmetatable({}, {
  __index = function(_, key)
    local ok, module = pcall(require, "panel." .. key)
    assert(ok, "module does not exist")
    return module
  end,
})

local plugin_loaded = false

local M = {}

---@param opts? PanelConfig
---@return nil
function M.setup(opts)
  opts = opts or {}
  lazy.config:setup(opts)
  lazy.manager.setup()
  lazy.commands.setup()
  plugin_loaded = true
end

---@param tab string
---@return nil
function M.navigate(tab)
  assert(plugin_loaded, "Please call setup() first before navigating")
  lazy.manager.navigate(tab)
end

---@param tab Tab
---@return nil
function M.add(tab)
  assert(plugin_loaded, "Please call setup() first before adding new tabs")
  lazy.manager.add(tab)
end

---@param tab Tab
---@return nil
function M.remove(tab)
  assert(plugin_loaded, "Please call setup() first before removing tabs")
  lazy.manager.remove(tab)
end

return M
