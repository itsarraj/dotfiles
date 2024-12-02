return {
  {
    'nvim-telescope/telescope-file-browser.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim', 'nvim-lua/plenary.nvim' },
    opts = {
      extensions = {
        file_browser = {
          hidden = { file_browser = true, folder_browser = true },
        },
      },
    },
    config = function()
      vim.keymap.set('n', '<space>fb', ':Telescope file_browser<CR>', { noremap = true, silent = true, desc = 'Open Telescope [F]ile [Browser]' })

      -- open file_browser with the path of the current buffer
      vim.keymap.set(
        'n',
        '<space>fbb',
        ':Telescope file_browser path=%:p:h select_buffer=true<CR>',
        { noremap = true, silent = true, desc = 'Open Telescope [F]ile [Browser] in current [B]uffer' }
      )

      -- -- Alternatively, using lua API
      -- vim.keymap.set("n", "<space>fb", function()
      -- 	require("telescope").extensions.file_browser.file_browser()
      -- end)
    end,
  },
}
