local picker = require 'picker'

local M = {}

local virtual_text_enabled = true

local function set_virtual_text(enabled)
  virtual_text_enabled = enabled
  vim.diagnostic.config { virtual_text = enabled }
  print('Diagnostic virtual text: ' .. (enabled and 'on' or 'off'))
end

function M.open()
  picker.open {
    title = ' Diagnostics ',
    items = {
      { label = 'Show line diagnostic', action = vim.diagnostic.open_float },
      { label = 'Next diagnostic', action = vim.diagnostic.goto_next },
      { label = 'Previous diagnostic', action = vim.diagnostic.goto_prev },
      { label = 'Send buffer diagnostics to loclist', action = vim.diagnostic.setloclist },
      { label = 'Send workspace diagnostics to quickfix', action = vim.diagnostic.setqflist },
      { label = 'Toggle virtual text', action = function() set_virtual_text(not virtual_text_enabled) end },
    },
  }
end

return M
