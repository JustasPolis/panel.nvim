local active_tab_text_hl = "BottomPanelActiveTabText"
local inactive_tab_text_hl = "BottomPanelInactiveTabText"
local padding_hl = "BottomPanelPadding"
local notification_bubble_hl = "BottomPanelNotificationBubble"

vim.api.nvim_set_hl(0, active_tab_text_hl, { fg = "#e0def4", bg = "none" })
vim.api.nvim_set_hl(0, inactive_tab_text_hl, { fg = "#908caa", bg = "none" })
vim.api.nvim_set_hl(0, padding_hl, { fg = "none", bg = "none" })
vim.api.nvim_set_hl(0, notification_bubble_hl, { fg = "#eb6f92", bg = "none" })

local M = {}

---@param win_id integer
---@param tabs Tab[]
---@param active_tab Tab
function M.render(win_id, tabs, active_tab)
  local whitespace = " "
  local winbar = "%#" .. padding_hl .. "#" .. whitespace
  for _, tab in ipairs(tabs) do
    if active_tab.name == tab.name then
      winbar = winbar .. "%#" .. active_tab_text_hl .. "#" .. tab.name .. whitespace
    else
      winbar = winbar .. "%#" .. inactive_tab_text_hl .. "#" .. tab.name .. whitespace
    end
  end
  vim.api.nvim_set_option_value("winbar", winbar, { win = win_id })
end

return M
