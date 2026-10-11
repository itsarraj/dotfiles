local picker = require 'picker'

local M = {}

local function with_harpoon(fn)
  return function()
    local ok, harpoon = pcall(require, 'harpoon')
    if not ok then
      vim.notify('harpoon is not available', vim.log.levels.WARN)
      return
    end
    fn(harpoon)
  end
end

function M.open()
  picker.open {
    title = ' Harpoon ',
    items = {
      { label = 'Add current file', action = with_harpoon(function(h) h:list():add() end) },
      { label = 'Open quick menu', action = with_harpoon(function(h) h.ui:toggle_quick_menu(h:list()) end) },
      { label = 'Jump to file 1', action = with_harpoon(function(h) h:list():select(1) end) },
      { label = 'Jump to file 2', action = with_harpoon(function(h) h:list():select(2) end) },
      { label = 'Jump to file 3', action = with_harpoon(function(h) h:list():select(3) end) },
      { label = 'Jump to file 4', action = with_harpoon(function(h) h:list():select(4) end) },
      { label = 'Previous harpoon file', action = with_harpoon(function(h) h:list():prev() end) },
      { label = 'Next harpoon file', action = with_harpoon(function(h) h:list():next() end) },
    },
  }
end

return M
