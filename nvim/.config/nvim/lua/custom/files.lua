local picker = require 'picker'

local M = {}

local function current_dir()
  return vim.fn.expand '%:p:h'
end

local function create_file(name)
  local path = vim.fs.joinpath(current_dir(), name)
  vim.fn.writefile({}, path, 'a')
  vim.cmd 'redraw'
  return path
end

function M.new_file()
  picker.open {
    title = ' New file ',
    items = {
      {
        label = 'Timestamped - YYYYMMDDHHMMSS.md',
        action = function()
          local name = os.date '%Y%m%d%H%M%S.md'
          create_file(name)
          print('Created file: ' .. name)
        end,
      },
      {
        label = 'Dated - YYYYMMDD.md',
        action = function()
          create_file(os.date '%Y%m%d.md')
        end,
      },
      {
        label = 'Prompt for filename',
        action = function()
          vim.ui.input({ prompt = 'New file: ' }, function(name)
            if not name or name == '' then
              return
            end
            create_file(name)
            print('Created file: ' .. name)
          end)
        end,
      },
    },
  }
end

return M
