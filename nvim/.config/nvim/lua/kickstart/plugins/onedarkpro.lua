return {
  {
    'olimorris/onedarkpro.nvim',
    priority = 1000, -- Ensure it loads first

    init = function()
      vim.cmd.colorscheme 'onedark_vivid'
    end,
  },
}
