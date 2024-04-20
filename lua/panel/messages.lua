local Line = require("nui.line")
local Text = require("nui.text")
local Utils = require("panel.utils")

local time_text_hl = "BottomPanelTimeText"
local error_text_hl = "BottomPanelErrorText"
local warn_text_hl = "BottomPanelWarnText"
local info_text_hl = "BottomPanelInfoText"
local trace_text_hl = "BottomPanelTraceText"
local off_text_hl = "BottomPanelOffText"
local debug_text_hl = "BottomPanelDebugText"

vim.api.nvim_set_hl(0, time_text_hl, { fg = "#908caa", bg = "none" })
vim.api.nvim_set_hl(0, error_text_hl, { fg = "#eb6f92", bg = "none" })
vim.api.nvim_set_hl(0, warn_text_hl, { fg = "#ebc7ba", bg = "none" })
vim.api.nvim_set_hl(0, info_text_hl, { fg = "#e0def4", bg = "none" })
vim.api.nvim_set_hl(0, trace_text_hl, { fg = "#c7aee6", bg = "none" })
vim.api.nvim_set_hl(0, off_text_hl, { fg = "#e0def4", bg = "none" })
vim.api.nvim_set_hl(0, debug_text_hl, { fg = "#f6c177", bg = "none" })

---@class Message
---@field text string
---@field level integer
---@field date string|osdate

---@class State
---@field bufnr integer|nil
---@field winid integer|nil

---@type State
local state = {
  bufnr = vim.api.nvim_create_buf(false, true),
  winid = nil,
}

vim.bo[state.bufnr].filetype = "PanelMessages"
vim.bo[state.bufnr].modifiable = false

---@type Message[]
local messages = {}

---@param message Message
local function append(message)
  if state.winid ~= nil then
    if vim.api.nvim_buf_is_valid(state.bufnr) and vim.api.nvim_win_is_valid(state.winid) then
      local line = Line()

      line:append(Text(message.date .. " ", time_text_hl))

      if message.level == vim.log.levels.ERROR then
        line:append(Text(message.text, error_text_hl))
      elseif message.level == vim.log.levels.INFO then
        line:append(Text(message.text, info_text_hl))
      elseif message.level == vim.log.levels.TRACE then
        line:append(Text(message.text, trace_text_hl))
      elseif message.level == vim.log.levels.DEBUG then
        line:append(Text(message.text, debug_text_hl))
      elseif message.level == vim.log.levels.WARN then
        line:append(Text(message.text, warn_text_hl))
      elseif message.level == vim.log.levels.OFF then
        line:append(Text(message.text, off_text_hl))
      else
        line:append(Text(message.text, info_text_hl))
      end

      vim.bo[state.bufnr].modifiable = true
      vim.api.nvim_buf_set_lines(
        state.bufnr,
        Utils.buffer_empty(state.bufnr) and 0 or vim.api.nvim_buf_line_count(state.bufnr),
        Utils.buffer_empty(state.bufnr) and -1 or vim.api.nvim_buf_line_count(state.bufnr) + 1,
        false,
        { line:content() }
      )
      line:highlight(state.bufnr, -1, vim.api.nvim_buf_line_count(state.bufnr))

      vim.wo[state.winid].winfixbuf = true
      vim.bo[state.bufnr].modifiable = false
      -- set cursor to last line only if we are not currently focused to that window
      if vim.api.nvim_get_current_win() ~= state.winid then
        vim.api.nvim_win_set_cursor(state.winid, { vim.api.nvim_buf_line_count(state.bufnr), 0 })
      end
    end
  end
end

---@param message Message
local function add(message)
  for text in message.text:gmatch("[^\n]+") do
    message = { text = text, level = message.level, date = message.date }
    table.insert(messages, message)
    append(message)
  end
end

local function on_message(_, result, _)
  ---@type integer
  local level

  if result.type == 1 then
    level = vim.log.levels.ERROR
  elseif result.type == 2 then
    level = vim.log.levels.WARN
  elseif result.type == 3 then
    level = vim.log.levels.INFO
  elseif result.type == 4 then
    level = vim.log.levels.DEBUG
  else
    level = vim.log.levels.OFF
  end

  add({ text = result.message, level = level, date = os.date("%H:%M:%S") })
end

vim.lsp.handlers["window/showMessage"] = on_message

_G.print = function(...)
  local print_safe_args = {}
  local _ = { ... }
  for i = 1, #_ do
    table.insert(print_safe_args, tostring(_[i]))
  end
  add({
    text = table.concat(print_safe_args),
    level = vim.log.levels.INFO,
    date = os.date("%H:%M:%S"),
  })
end

_G.error = function(...)
  local print_safe_args = {}
  local _ = { ... }
  for i = 1, #_ do
    table.insert(print_safe_args, tostring(_[i]))
  end
  table.insert(print_safe_args, debug.traceback("", 1))
  add({
    text = table.concat(print_safe_args),
    level = vim.log.levels.ERROR,
    date = os.date("%H:%M:%S"),
  })
end

local function notify(msg, level, opts)
  if vim.in_fast_event() then
    vim.schedule(function()
      notify(msg, level, opts)
    end)
    return
  end

  add({ text = msg, level = level, date = os.date("%H:%M:%S") })
end

if vim.notify ~= notify then
  vim.notify = notify
end

local function render()
  if state.winid ~= nil then
    if
      vim.api.nvim_buf_is_valid(state.bufnr)
      and vim.api.nvim_win_is_valid(state.winid)
      and #messages > 0
    then
      vim.wo[state.winid].winfixbuf = true
      vim.bo[state.bufnr].modifiable = false
      vim.api.nvim_win_set_cursor(state.winid, { vim.api.nvim_buf_line_count(state.bufnr), 0 })
    end
  end
end

local M = {}

---@return nil
function M.on_enter(winid)
  state.winid = winid
  vim.api.nvim_win_set_buf(winid, state.bufnr)
  Utils.set_win_option(state.winid, "relativenumber", false)
  Utils.set_win_option(state.winid, "number", false)
  Utils.set_win_option(state.winid, "signcolumn", "no")

  if vim.api.nvim_get_current_win() == state.winid and not Utils.buffer_empty(state.bufnr) then
    Utils.set_win_option(state.winid, "cursorline", true)
  else
    Utils.set_win_option(state.winid, "cursorline", false)
  end

  render()

  vim.api.nvim_create_autocmd("WinEnter", {
    group = Utils.create_augroup("panel_messages_win_enter"),
    callback = function(_)
      if vim.api.nvim_get_current_win() == state.winid and not Utils.buffer_empty(state.bufnr) then
        Utils.set_win_option(state.winid, "cursorline", true)
      else
        Utils.set_win_option(state.winid, "cursorline", false)
      end
    end,
  })
end

---@return nil
function M.on_leave(_)
  vim.api.nvim_del_augroup_by_name("panel_messages_win_enter")
  vim.wo[state.winid].winfixbuf = false
  Utils.set_win_option(state.winid, "relativenumber", true)
  Utils.set_win_option(state.winid, "number", true)
  Utils.set_win_option(state.winid, "signcolumn", "yes")
  state.winid = nil
end

vim.api.nvim_create_autocmd("LspProgress", {
  group = Utils.create_augroup("panel_messages"),
  callback = function(event)
    local client_id = event.data.client_id
    local value = event.data.result.value
    local client = vim.lsp.get_client_by_id(client_id).name or " "
    local title = value.title or ""
    local message = value.message or ""

    local computed_text

    if value.kind == "end" then
      computed_text = client .. ": " .. "Finished" .. " " .. title
    else
      computed_text = client .. ": " .. title .. " " .. message
    end

    add({ text = computed_text, date = os.date("%H:%M:%S"), level = vim.log.levels.INFO })
  end,
})

return M
