local picker = require 'picker'

local M = {}

local function delete_current()
  local ok, err = pcall(vim.cmd.bdelete)
  if not ok then
    vim.notify(err, vim.log.levels.WARN)
  end
end

function M.open()
  picker.open {
    title = ' Buffer ',
    items = {
      { label = 'Write current buffer', action = function() vim.cmd.write() end },
      { label = 'Write all buffers', action = function() vim.cmd.wall() end },
      { label = 'New empty buffer', action = function() vim.cmd.enew() end },
      { label = 'Delete current buffer', action = delete_current },
      { label = 'Next buffer', action = function() vim.cmd.bnext() end },
      { label = 'Previous buffer', action = function() vim.cmd.bprevious() end },
      { label = 'List buffers', action = function() vim.cmd.ls() end },
    },
  }
end

return M
