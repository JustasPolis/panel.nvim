local Line = require("nui.line")
local Text = require("nui.text")
local Utils = require("panel.utils")

---@class ProcessedDiagnosticItem
---@field bufnr integer
---@field filename string
---@field lnum integer
---@field col integer
---@field severity integer
---@field message string

---@class FullDiagnosticItem
---@field bufnr integer
---@field lnum integer
---@field col integer
---@field severity integer
---@field message string

---@param item FullDiagnosticItem
---@return ProcessedDiagnosticItem
local function process(item)
  return {
    bufnr = item.bufnr,
    filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(item.bufnr), ":p:."),
    lnum = item.lnum + 1,
    col = item.col,
    severity = item.severity,
    message = item.message,
  }
end

---@enum diagnostic_name
local DIAGNOSTIC_NAME = {
  [0] = "Other",
  [1] = "DiagnosticSignError",
  [2] = "DiagnosticSignWarn",
  [3] = "DiagnosticSignInfo",
  [4] = "DiagnosticSignHint",
}

local diagnostic_text_hl = "BottomPanelDiagnosticText"
local diagnostic_client_name_hl = "BottomPanelDiagnosticClientName"
local diagnostic_filename_hl = "BottomPanelDiagnosticLocation"

vim.api.nvim_set_hl(0, diagnostic_text_hl, { fg = "#908caa", bg = "none" })
vim.api.nvim_set_hl(0, diagnostic_client_name_hl, { fg = "#524f67", bg = "none" })
vim.api.nvim_set_hl(0, diagnostic_filename_hl, { fg = "#524f67", bg = "none" })

local buffer = {
  content = {},
  lines = {},
}

local bufnr = vim.api.nvim_create_buf(false, true)
vim.bo[bufnr].filetype = "PanelDiagnostics"
vim.bo[bufnr].modifiable = false

local M = {}

---@class DiagnosticSign
---@field text string
---@field texthl string

---@param severity integer
---@return DiagnosticSign[] | nil
local function get_sign(severity)
  return vim.fn.sign_getdefined(DIAGNOSTIC_NAME[severity])
end

---@param a ProcessedDiagnosticItem
---@param b ProcessedDiagnosticItem
---@return boolean
local function sort_severity(a, b)
  return a.severity < b.severity -- Reverse comparison for sorting in descending order
end

local function process_diagnostics(diagnostics)
  local items = {} ---@type (ProcessedDiagnosticItem)[]

  for _, item in ipairs(diagnostics) do
    table.insert(items, process(item))
  end

  table.sort(items, sort_severity)
  return items
end

---@param diagnostics ProcessedDiagnosticItem[]
---@param winid integer
local function render(diagnostics, winid)
  if not vim.api.nvim_win_is_valid(winid) then
    return
  end

  buffer = {
    content = {},
    lines = {},
  }

  for _, item in ipairs(diagnostics) do
    local index = 0

    for message in item.message:gmatch("[^\n]+") do
      local text_line = Line()
      index = index + 1

      if index == 1 then
        local sign = get_sign(item.severity)
        if sign ~= nil and sign[1] ~= nil then
          text_line:append(Text((" " .. sign[1].text .. " "), sign[1].texthl))
        end
        text_line:append(Text(message .. " ", diagnostic_text_hl))
        text_line:append(Text(item.filename, diagnostic_filename_hl))
      else
        text_line:append(Text("    " .. message, diagnostic_text_hl))
      end
      table.insert(buffer.content, text_line:content())
      table.insert(buffer.lines, { diagnostics = item, text = text_line })
    end
  end

  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, buffer.content)
  Utils.clear_hl(bufnr)

  for index, line in ipairs(buffer.lines) do
    line.text:highlight(bufnr, -1, index)
  end

  vim.bo[bufnr].modifiable = false
  vim.wo[winid].winfixbuf = true
  if not Utils.buffer_empty(bufnr) then
    vim.api.nvim_set_option_value("cursorline", true, { win = winid, scope = "local" })
  else
    vim.api.nvim_set_option_value("cursorline", false, { win = winid, scope = "local" })
  end
end

---@type ProcessedDiagnosticItem[]
local diagnostics = nil

---@param winid integer
function M.on_enter(winid)
  vim.api.nvim_win_set_buf(winid, bufnr)
  Utils.set_win_option(winid, "relativenumber", false)
  Utils.set_win_option(winid, "number", false)
  Utils.set_win_option(winid, "signcolumn", "no")
  Utils.set_win_option(winid, "winfixbuf", false)
  Utils.set_win_option(winid, "winfixbuf", true)

  diagnostics = process_diagnostics(vim.diagnostic.get())
  assert(diagnostics, "expect diagnostics to be not nil")
  render(diagnostics, winid)
  -- set to top for now
  vim.api.nvim_win_set_cursor(winid, { 1, 0 })

  vim.keymap.set("n", "<CR>", function()
    local cursor = vim.api.nvim_win_get_cursor(winid)
    if cursor == nil or #cursor == 0 then
      return
    end

    local row = cursor[1]
    local line = buffer.lines[row]

    if line == nil then
      return
    end

    local line_diagnostics = line.diagnostics ---@type ProcessedDiagnosticItem
    local line_bufnr = line_diagnostics.bufnr

    if not vim.bo[line_bufnr].buflisted then
      vim.bo[line_bufnr].buflisted = true
    end

    if not vim.api.nvim_buf_is_loaded(line_bufnr) then
      vim.fn.bufload(line_bufnr)
    end

    local parent = vim.fn.win_getid(vim.fn.winnr("#"))
    vim.api.nvim_win_set_buf(parent, line_bufnr)
    vim.api.nvim_set_current_win(parent)
    vim.api.nvim_win_set_cursor(parent, { line_diagnostics.lnum, line_diagnostics.col })
  end, { noremap = true, silent = true, buffer = bufnr })

  vim.api.nvim_create_autocmd("DiagnosticChanged", {
    group = Utils.create_augroup("diagnostics_changed"),
    callback = function()
      diagnostics = process_diagnostics(vim.diagnostic.get())
      render(diagnostics, winid)
    end,
  })
end

---@param winid integer
function M.on_leave(winid)
  Utils.set_win_option(winid, "relativenumber", true)
  Utils.set_win_option(winid, "number", true)
  Utils.set_win_option(winid, "signcolumn", "yes")
  Utils.set_win_option(winid, "winfixbuf", false)
  vim.api.nvim_clear_autocmds({ group = "diagnostics_changed" })
end

return M
