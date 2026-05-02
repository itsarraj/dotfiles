local picker = require 'picker'

local M = {}

local function telescope(name, opts)
  return function()
    local ok, builtin = pcall(require, 'telescope.builtin')
    if not ok then
      vim.notify('telescope.nvim is not available', vim.log.levels.WARN)
      return
    end
    builtin[name](opts or {})
  end
end

function M.open()
  picker.open {
    title = ' Search ',
    items = {
      { label = 'Files', action = telescope 'find_files' },
      { label = 'Grep text', action = telescope 'live_grep' },
      { label = 'Current word', action = telescope 'grep_string' },
      { label = 'Open buffers', action = telescope 'buffers' },
      { label = 'Recent files', action = telescope 'oldfiles' },
      { label = 'Commands', action = telescope 'commands' },
      { label = 'Help tags', action = telescope 'help_tags' },
      { label = 'Keymaps', action = telescope 'keymaps' },
      { label = 'Diagnostics', action = telescope 'diagnostics' },
      {
        label = 'Neovim config files',
        action = telescope('find_files', { cwd = vim.fn.stdpath 'config' }),
      },
    },
  }
end

return M
