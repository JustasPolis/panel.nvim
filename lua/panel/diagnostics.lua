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

local buffer = vim.api.nvim_create_buf(false, true)
vim.bo[buffer].filetype = "PanelDiagnostics"

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

---@param winid integer
function M.on_enter(winid)
  print("hello world")
end

---@param winid integer
function M.on_leave(winid) end
