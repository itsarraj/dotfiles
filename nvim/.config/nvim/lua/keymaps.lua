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
vim.keymap.set('n', '<Leader>a', ':wa!<CR>', { noremap = true, silent = true, desc = '[W]rite [A]ll buffers' })
vim.keymap.set('n', '<Leader>q', ':q<CR>', { noremap = true, silent = true, desc = '[Q]uit the current buffer' })
vim.keymap.set('n', '<Leader>x', ':x!<CR>', { noremap = true, silent = true, desc = '[W]rite and [Q]uit the current buffer' })


-- Insert current date and time
vim.keymap.set('n', '<F3>', 'i<C-R>=strftime("%Y-%m-%d %a %I:%M %p")<CR><Esc>', { noremap = true, silent = true })
vim.keymap.set('i', '<F3>', '<C-R>=strftime("%Y-%m-%d %a %I:%M %p")<CR>', { noremap = true, silent = true })

-- Date/time insertion shortcuts
vim.keymap.set('n', '<leader>dd', function() vim.api.nvim_put({ os.date '%Y-%m-%d' }, 'c', true, true) end, { desc = 'Insert current date' })
vim.keymap.set('n', '<leader>tt', function() vim.api.nvim_put({ os.date '%H:%M' }, 'c', true, true) end, { desc = 'Insert current time' })
vim.keymap.set('n', '<leader>dtt', function() vim.api.nvim_put({ os.date '%Y-%m-%d %H:%M' }, 'c', true, true) end, { desc = 'Insert date+time' })

-- File creation shortcuts
local function create_file(filename)
  local current_directory = vim.fn.expand '%:p:h'
  vim.cmd('silent !touch ' .. current_directory .. '/' .. filename)
  vim.cmd 'redraw'
end

vim.keymap.set('n', '<leader>df', function()
  create_file(os.date '%Y%m%d.md')
end, { desc = 'Create dated file (YYYYMMDD)' })

vim.keymap.set('n', '<leader>dtf', function()
  local filename = os.date '%Y%m%d%H%M%S.md'
  create_file(filename)
  print('Created file: ' .. filename)
end, { desc = 'Create timestamped file' })

--

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

-- vim: ts=2 sts=2 sw=2 et
