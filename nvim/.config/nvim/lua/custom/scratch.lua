local picker = require 'picker'

local M = {}

local function scratch(ft, lines)
  vim.cmd.enew()
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'hide'
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = ft
  vim.api.nvim_buf_set_name(buf, 'scratch://' .. ft .. '/' .. os.date '%H%M%S')

  if lines and #lines > 0 then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_win_set_cursor(0, { #lines, 0 })
  end
end

function M.open()
  picker.open {
    title = ' Scratch ',
    items = {
      { label = 'Empty text scratch', action = function() scratch('text') end },
      { label = 'Markdown scratch', action = function() scratch('markdown', { '# Scratch', '', '' }) end },
      { label = 'Lua scratch', action = function() scratch('lua', { '-- scratch', '' }) end },
      {
        label = 'Daily note scratch',
        action = function()
          scratch('markdown', {
            '# ' .. os.date '%Y-%m-%d %a',
            '',
            '- ',
          })
        end,
      },
    },
  }
end

return M
