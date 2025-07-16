return {
    {
        'tpope/vim-fugitive',
        config = function()
            -- Open :Git status
            vim.keymap.set("n", "<leader>gs", vim.cmd.Git)

            -- Git push
            vim.keymap.set("n", "<leader>gp", function()
                vim.cmd("Git push")
            end)

            -- Git pull with rebase
            vim.keymap.set("n", "<leader>gP", function()
                vim.cmd("Git pull --rebase")
            end)

            -- Git add current file
            vim.keymap.set("n", "<leader>ga", function()
                vim.cmd("Git add %")
            end)

            -- Git commit
            vim.keymap.set("n", "<leader>gc", function()
                vim.cmd("Git commit")
            end)

            -- Git log
            vim.keymap.set("n", "<leader>gl", function()
                vim.cmd("Git log --oneline --graph --decorate")
            end)

            -- Git blame
            vim.keymap.set("n", "<leader>gb", function()
                vim.cmd("Git blame")
            end)

            -- Git diff
            vim.keymap.set("n", "<leader>gd", function()
                vim.cmd("Gdiffsplit")
            end)

            -- Accept left (our) changes in diff mode
            vim.keymap.set("n", "gh", "<cmd>diffget //2<CR>")

            -- Accept right (their) changes in diff mode
            vim.keymap.set("n", "gl", "<cmd>diffget //3<CR>")
        end
    }
}

