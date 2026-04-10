-- Dark+ inspired scheme: https://github.com/LunarVim/darkplus.nvim
return {
  {
    'lunarvim/darkplus.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme 'darkplus'
    end,
  },
}
