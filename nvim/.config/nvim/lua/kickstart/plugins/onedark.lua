return {
  {
    'navarasu/onedark.nvim',
    -- style = 'deep',
    -- init = function()
    --   vim.cmd.colorscheme 'onedark'
    -- end,
    config = function()
      require('onedark').setup {
        style = 'darker', -- change theme style to darker
        -- transparent = true, -- do not make background transparent
        -- term_colors = true, -- apply theme colors to terminal
        -- ending_tildes = false, -- disable end-of-buffer tildes
        -- toggle_style_key = '<leader>ts', -- set toggle key for changing theme style
        -- code_style = {
        --   comments = 'italic', -- make comments italic
        --   keywords = 'bold', -- bold for keywords
        -- },
        -- diagnostics = {
        --   darker = true,
        --   undercurl = true,
        --   background = true,
        -- },
      }
      -- Load the theme
      require('onedark').load()
    end,
  },
}
