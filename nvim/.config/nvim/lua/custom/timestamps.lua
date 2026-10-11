local picker = require 'picker'

local M = {}

function M.open()
  picker.open {
    title = ' Timestamp ',
    items = {
      { label = 'Date (YYYY-MM-DD)', text = function() return os.date '%Y-%m-%d' end },
      { label = 'Time (24h HH:MM)', text = function() return os.date '%H:%M' end },
      { label = 'Date + time', text = function() return os.date '%Y-%m-%d %H:%M' end },
      { label = 'Long (weekday + 12h)', text = function() return os.date '%Y-%m-%d %a %I:%M %p' end },
    },
  }
end

return M
