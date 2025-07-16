-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Set highlight on search, but clear on pressing <Esc> in normal mode
-- or {both line are same}
-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch
vim.opt.hlsearch = true
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Custom keymaps

-- Key mappings
-- vim.keymap.set('n', '<Leader>fe', ':Explore<CR>', { noremap = true, silent = true, desc = 'Open [E]xplore - NetRW file explorer' })
vim.keymap.set('n', '<Leader>fe', vim.cmd.Ex, { noremap = true, silent = true, desc = 'Open [E]xplore - NetRW file explorer' })
vim.keymap.set('n', '<Leader>w', ':w!<CR>', { noremap = true, silent = true, desc = '[W]rite the current buffer' })
vim.keymap.set('n', '<Leader>a', ':wa!<CR>', { noremap = true, silent = true, desc = '[W]rite [A]ll buffers' })
-- vim.keymap.set('n', '<Leader>q!', ':q!<CR>', { noremap = true, silent = true, desc = 'Force [Q]uit and discard changes to the buffer' })
vim.keymap.set('n', '<Leader>q', ':q<CR>', { noremap = true, silent = true, desc = '[Q]uit the current buffer' })
vim.keymap.set('n', '<Leader>x', ':x!<CR>', { noremap = true, silent = true, desc = '[W]rite and [Q]uit the current buffer' })
-- vim.keymap.set('n', '<Leader>xa', ':xa!<CR>', { noremap = true, silent = true, desc = '[X] quit and save all buffers' })

-- Insert current date and time in normal mode with F3
vim.keymap.set('n', '<F3>', 'i<C-R>=strftime("%Y-%m-%d %a %I:%M %p")<CR><Esc>', { noremap = true, silent = true, desc = 'Insert current date and time' })

-- Insert current date and time in insert mode with F3
vim.keymap.set('i', '<F3>', '<C-R>=strftime("%Y-%m-%d %a %I:%M %p")<CR>', { noremap = true, silent = true, desc = 'Insert current date and time' })

-- Function to insert current date in the specified format at cursor position
vim.keymap.set('n', '<leader>dd', function()
  vim.api.nvim_put({ os.date '%Y-%m-%d' }, 'c', true, true)
end, { desc = 'Insert current [D]ate' })

-- Function to insert current time in the specified format at cursor position
vim.keymap.set('n', '<leader>tt', function()
  vim.api.nvim_put({ os.date '%H:%M' }, 'c', true, true)
end, { desc = 'Insert current [T]ime' })

-- Function to insert current date and time in the specified format at cursor position
vim.keymap.set('n', '<leader>dtt', function()
  vim.api.nvim_put({ os.date '%Y-%m-%d %H:%M' }, 'c', true, true)
end, { desc = 'Insert current [D]ate and [T]ime' })

-- Function to create a file in the current netrw directory
local function create_file(filename)
  local current_directory = vim.fn.expand '%:p:h' -- Get the current directory
  vim.cmd('silent !touch ' .. current_directory .. '/' .. filename)
  vim.cmd 'redraw' -- Refresh the view
end

-- Keymap to create a file with the name YYYYMMDD.md
vim.keymap.set('n', '<leader>df', function()
  local date = os.date '%Y%m%d'
  local filename = date .. '.md'
  create_file(filename)
end, { desc = 'Create file with current [D]ate in YYYYMMDD format' })

-- Keymap to create a file with the name YYYYMMDDHHMMSS.md
vim.keymap.set('n', '<leader>dtf', function()
  local date_time = os.date '%Y%m%d%H%M%S'
  local filename = date_time .. '.md'
  create_file(filename)
  print('Created file: ' .. filename)
end, { desc = 'Create file with current [D]ate and [T]ime in YYYYMMDDHHMMSS format' })

--
--
--

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous [D]iagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next [D]iagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror messages' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- TIP: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

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
