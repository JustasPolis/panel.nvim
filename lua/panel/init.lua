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
  local function load()
    lazy.config:setup(opts)
    lazy.manager.setup()
    lazy.commands.setup()
    plugin_loaded = true
  end

  if vim.v.vim_did_enter == 0 then
    vim.api.nvim_create_autocmd("VimEnter", {
      once = true,
      callback = load,
    })
  else
    vim.schedule(load)
  end
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
  lazy.manager.add(tab)
end

---@param tab Tab
---@return nil
function M.remove(tab)
  lazy.manager.remove(tab)
end

return M
