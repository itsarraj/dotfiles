local picker = require 'picker'

local M = {}

local function run_git(args)
  return function()
    vim.cmd 'botright split'
    vim.cmd 'resize 14'
    vim.fn.termopen(vim.list_extend({ 'git' }, args))
    vim.cmd.startinsert()
  end
end

function M.open()
  picker.open {
    title = ' Git ',
    items = {
      { label = 'Status short', action = run_git { 'status', '--short' } },
      { label = 'Status full', action = run_git { 'status' } },
      { label = 'Diff', action = run_git { 'diff' } },
      { label = 'Diff staged', action = run_git { 'diff', '--staged' } },
      { label = 'Log compact', action = run_git { 'log', '--oneline', '--decorate', '-20' } },
      { label = 'Current branch', action = run_git { 'branch', '--show-current' } },
    },
  }
end

return M
