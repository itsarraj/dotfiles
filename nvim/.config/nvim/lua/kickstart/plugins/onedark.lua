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
                -- toggle_style_key = '<leader>ts',
                -- toggle_style_list = {'dark', 'darker', 'cool', 'deep', 'warm', 'warmer', 'light'},
                -- code_style = {
                --     comments = 'italic',
                --     keywords = 'bold',
                --     functions = 'italic',
                --     strings = 'none',
                --     variables = 'none'
                -- }
                -- diagnostics = {
                --   darker = true,
                --   undercurl = true,
                --   background = true,
                -- },
                -- -- Optional: tweak colors
                -- colors = {
                --     green = '#A0FF70',
                -- },
                -- highlights = {
                --     ["@function"] = { fg = '$green', fmt = 'italic' },
                --     ["@keyword"] = { fg = '$cyan', fmt = 'bold' },
                -- },
            }
            -- Load the theme
            require('onedark').load()
        end,
    },
}
