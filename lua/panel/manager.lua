local M = {}

---@class View
---@field winid integer
---@field mount fun(): nil

---@type Tab?
local active_tab = nil

---@type View?
local split = nil

function M.setup()
  if lazy.config.opts.open_on_launch then
    M.navigate(lazy.config.opts.initial_tab)
  end
end

---@param tab Tab
---@param position integer?
---@return nil
function M.add(tab, position)
  table.insert(lazy.config.opts.tabs, position or 0, tab)
  assert(split, "split should not be nil")
  assert(active_tab, "active_tab should not be nil")
  assert(lazy.config.opts.tabs, "config.opts.tabs should not be nil")
  assert(lazy.config.opts.tabs > 0, "config.opts.tabs should be higher than 0")
  lazy.winbar.render(split.winid, lazy.config.opts.tabs, active_tab)
end

---@param tab Tab
---@return nil
function M.remove(tab)
  for index, value in ipairs(lazy.config.opts.tabs) do
    if value.name == tab then
      table.remove(lazy.config.opts.tabs, index)
    end
  end

  assert(active_tab, "active_tab should not be nil")
  -- we want to change to other module if the tab deleted was active
  if tab == active_tab.name then
    active_tab = nil
    assert(lazy.config.opts.tabs, "config.opts.tabs should not be nil")
    assert(lazy.config.opts.tabs > 0, "config.opts.tabs should be higher than 0")
    M.navigate(lazy.config.opts.tabs[1])
  end

  assert(split, "split should not be nil")
  assert(lazy.config.opts.tabs, "config.opts.tabs should not be nil")
  assert(lazy.config.opts.tabs > 0, "config.opts.tabs should be higher than 0")
  lazy.winbar.render(split.winid, lazy.config.opts.tabs, active_tab)
end

---@param tab string
function M.navigate(tab)
  -- clean up current active tab
  if active_tab ~= nil then
    assert(split, "split should not be nil")
    active_tab.module.on_leave(split.winid)
  end

  -- we can safely nil out current active_tab
  active_tab = nil

  -- find user selected tab from config opts
  for _, value in ipairs(lazy.config.opts.tabs) do
    if value.name == tab then
      if type(value.module) == "string" then
        local ok, module = pcall(require, "panel." .. value.module)
        if ok then
          active_tab = module
        end
      end
    elseif type(value.module) == "table" then
      active_tab = value.module
    else
      error("tab module should be either string or table")
    end
  end

  -- assert that we found tab
  assert(active_tab, "Selected tab does not exist")

  if split == nil then
    local ok, nui_split = pcall(require, "nui.split")
    assert(ok, "nui.split is required for this plugin to work")
    split = nui_split({
      relative = "editor",
      position = "bottom",
      size = "12%",
      enter = false,
    })
  end

  if split.winid == nil then
    split:mount()
  end

  -- finally render active_tab
  active_tab.on_enter(split.winid)
  lazy.winbar.setup(split.winid, lazy.config.opts.tabs, active_tab)
end

return M