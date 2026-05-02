-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Set highlight on search, but clear on pressing <Esc> in normal mode
-- vim.opt.hlsearch = true
-- vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
 
vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")

-- Custom keymap remaps
-- Move selected lines up/down while keeping selection
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = 'Move selection down' })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = 'Move selection up' })

-- Center cursor after common navigation commands
-- vim.keymap.set("n", "J", "mzJ`z", { desc = 'Join lines centered' })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = 'Half-page down centered' })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = 'Half-page up centered' })
vim.keymap.set("n", "n", "nzzzv", { desc = 'Next search result centered' })
vim.keymap.set("n", "N", "Nzzzv", { desc = 'Previous search result centered' })

-- Quickfix list navigation (centered)
vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz", { desc = 'Next quickfix item centered' })
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz", { desc = 'Previous quickfix item centered' })
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz", { desc = 'Next location list item centered' })
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz", { desc = 'Previous location list item centered' })

-- System utilities
-- vim.keymap.set("n", "<leader><leader>", function() vim.cmd("so") end, { desc = 'Source current file' })

-- Key mappings
-- Custom keymaps
vim.keymap.set('n', '<Leader>fe', vim.cmd.Ex, { noremap = true, silent = true, desc = 'Open [E]xplore - NetRW file explorer' })
vim.keymap.set('n', '<Leader>w', ':w!<CR>', { noremap = true, silent = true, desc = '[W]rite the current buffer' })
-- vim.keymap.set('n', '<Leader>a', ':wa!<CR>', { noremap = true, silent = true, desc = '[W]rite [A]ll buffers' })
vim.keymap.set('n', '<Leader>q', ':q<CR>', { noremap = true, silent = true, desc = '[Q]uit the current buffer' })
-- vim.keymap.set('n', '<Leader>x', ':x!<CR>', { noremap = true, silent = true, desc = '[W]rite and [Q]uit the current buffer' })

-- File refresh keymaps
-- vim.keymap.set('n', '<Leader>r', ':e!<CR>', { noremap = true, silent = true, desc = '[R]eload current buffer (discard changes)' })
-- vim.keymap.set('n', '<Leader>R', ':bufdo e!<CR>', { noremap = true, silent = true, desc = '[R]eload all buffers (discard changes)' })
-- vim.keymap.set('n', '<Leader>cr', ':checktime<CR>', { noremap = true, silent = true, desc = '[C]heck for external file changes' })

-- local timestamps = require 'custom.timestamps'
-- local files = require 'custom.files'
-- local tools = require 'custom.tools'
-- local search = require 'custom.search'
-- local scratch = require 'custom.scratch'
-- local buffers = require 'custom.buffers'
-- local harpoon_menu = require 'custom.harpoon'
-- local git = require 'custom.git'
-- local diagnostics = require 'custom.diagnostics'

-- vim.keymap.set('n', '<leader>dd', timestamps.open, { desc = 'Insert date/time' })
-- vim.keymap.set('n', '<leader>df', files.new_file, { desc = 'Create empty file here' })
-- vim.keymap.set('n', '<leader>nn', tools.open, { desc = 'Nvim tools menu' })
-- vim.keymap.set('n', '<leader>sm', search.open, { desc = 'Search menu' })
-- vim.keymap.set('n', '<leader>bs', scratch.open, { desc = 'Scratch buffer menu' })
-- vim.keymap.set('n', '<leader>bb', buffers.open, { desc = 'Buffer menu' })
-- vim.keymap.set('n', '<leader>hh', harpoon_menu.open, { desc = 'Harpoon menu' })
-- vim.keymap.set('n', '<leader>gg', git.open, { desc = 'Git menu' })
-- vim.keymap.set('n', '<leader>dm', diagnostics.open, { desc = 'Diagnostics menu' })


-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous [D]iagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next [D]iagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror messages' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Disable arrow keys in normal mode
vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`

-- vim.api.nvim_create_autocmd('TextYankPost', {
--   desc = 'Highlight when yanking (copying) text',
--   group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
--   callback = function()
--     vim.highlight.on_yank()
--   end,
-- })
