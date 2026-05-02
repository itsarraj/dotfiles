local picker = require 'picker'

local M = {}

local function config_path(path)
  return vim.fn.stdpath('config') .. '/' .. path
end

function M.open()
  picker.open {
    title = ' Nvim tools ',
    items = {
      { label = 'Edit init.lua', action = function() vim.cmd.edit(config_path 'init.lua') end },
      { label = 'Edit keymaps.lua', action = function() vim.cmd.edit(config_path 'lua/keymaps.lua') end },
      { label = 'Edit options.lua', action = function() vim.cmd.edit(config_path 'lua/options.lua') end },
      { label = 'Open Lazy', action = function() vim.cmd.Lazy() end },
      { label = 'Check health', action = function() vim.cmd.checkhealth() end },
      { label = 'Reload current file', action = function() vim.cmd.edit { bang = true } end },
      { label = 'Check external file changes', action = function() vim.cmd.checktime() end },
    },
  }
end

return M
