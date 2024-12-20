return {
  {
    'cloudhead/neovim-fuzzy',
    config = function()
      -- Set the keymap for FuzzyOpen
      vim.keymap.set('n', '<Leader>f', '<cmd>:FuzzyOpen<CR>')
    end
  }
}
