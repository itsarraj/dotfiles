-- [[ Setting options ]]
-- See `:help vim.opt`
-- NOTE: You can change these options as you wish!
--  For more options, you can see `:help option-list`

-- Cursor and editing
-- Set the cursor style to a block for normal (n), visual (v), insert (i), and command (c) modes.
vim.opt.guicursor = 'n-v-i-c:block-Cursor'
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true

-- UI
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true -- Show which line your cursor is on
vim.opt.scrolloff = 10 
vim.opt.signcolumn = 'yes' -- Keep signcolumn on by default
vim.opt.colorcolumn = '80'  -- Visual line-length guide

-- Search
-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = false  -- Disable highlight
vim.opt.incsearch = true  -- Incremental search

-- File handling
vim.opt.swapfile = false    -- Disable swap files
vim.opt.backup = false      -- Disable backups
vim.opt.undofile = true

-- Performance
vim.opt.updatetime = 50  -- Faster (default 4000ms)

-- Formatting
-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.opt.wrap = true -- No line wrapping

vim.keymap.set("i", "<C-c>", "<Esc>")  -- Use Ctrl-C like Escape
vim.opt.isfname:append("@-@")          -- Consider @-@ as part of filenames

-- Enable mouse mode, can be useful for resizing splits for example!
vim.opt.mouse = 'a'

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false

-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)

-- Enable break indent
vim.opt.breakindent = true

-- File handling
vim.opt.swapfile = false    -- Disable swap files
vim.opt.backup = false      -- Disable backups
vim.opt.undofile = true     -- Save undo history

-- Decrease mapped sequence wait time
-- Displays which-key popup sooner
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Preview substitutions live, as you type!
vim.opt.inccommand = 'split'
