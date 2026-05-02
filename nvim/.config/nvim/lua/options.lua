-- [[ Setting options ]]
-- See `:help vim.opt` and `:help option-list` for the full option list.

-- Cursor & indentation
-- Cursor shape per mode and how Tab / indent behaves when you edit.
vim.opt.guicursor = 'n-v-i-c:block-Cursor' -- Block cursor in normal, visual, insert, command-line
vim.opt.tabstop = 4 -- Columns one Tab counts as
vim.opt.softtabstop = 4 -- Spaces inserted when Tab in insert mode (often matches tabstop)
vim.opt.shiftwidth = 4 -- Columns reindent operations use (>>, <<, =)
vim.opt.expandtab = true -- Insert spaces instead of a tab character
vim.opt.smartindent = true -- Auto-indent new lines in C-like and some other syntax

-- UI
-- How the window looks: line numbers, cursor line, margins, and the sign column.
vim.opt.termguicolors = true -- 24-bit color in the terminal
vim.opt.number = true -- Absolute line number of the cursor line
vim.opt.relativenumber = true -- Line numbers relative to the cursor
vim.opt.cursorline = true -- Highlight the line the cursor is on
vim.opt.scrolloff = 10 -- Minimum lines to keep above/below the cursor
vim.opt.signcolumn = 'yes' -- Always reserve space for signs (e.g. git, diagnostics)
vim.opt.colorcolumn = '80' -- Draw a column at this width (ruler / line-length guide)

-- Search
-- Case rules: with ignorecase+smartcase, search is case-insensitive unless the pattern has an uppercase letter.
vim.opt.ignorecase = true -- Case-insensitive patterns (unless overridden)
vim.opt.smartcase = true -- If pattern has upper case, search becomes case-sensitive
vim.opt.hlsearch = false -- Do not keep the last search pattern highlighted
vim.opt.incsearch = true -- Show where the pattern matches while typing the command

-- Files & undo
-- Swap/backup files on disk and persistent undo between sessions.
vim.opt.swapfile = false -- No swap file (.swp)
vim.opt.backup = false -- No backup file (~ backup)
vim.opt.undofile = true -- Undo history saved and restored when you reopen the file
vim.opt.autoread = true -- Reload buffer from disk when it changed outside Neovim

-- Performance
-- How often Neovim waits after typed keys before triggering CursorHold and similar events.
vim.opt.updatetime = 50 -- Milliseconds (lower = snappier plugins; default is often 4000)

-- Whitespace visibility & wrapping
-- Optional visible tabs/trailing space; wrap controls line continuation at window edge.
vim.opt.list = true -- Show listchars for whitespace
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' } -- Characters used when list is on
vim.opt.wrap = true -- Wrap long lines at the window edge

-- Input & filenames
vim.keymap.set('i', '<C-c>', '<Esc>') -- Treat Ctrl-C like Escape in insert mode
vim.opt.isfname:append('@-@') -- Allow `@` in filenames for gf / path logic

-- Mouse & mode line
vim.opt.mouse = 'a' -- Mouse in all modes (resize splits, scroll, etc.)
vim.opt.showmode = false -- Hide -- INSERT -- etc.; statusline can show mode instead

-- Clipboard
-- unnamedplus uses the system clipboard (+ register); needs xclip, xsel, or wl-clipboard on Linux.
vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus' -- Defer so startup is not slowed (:help clipboard)
end)

-- Indent continuation for wrapped lines
vim.opt.breakindent = true -- Wrapped lines keep the same indent as the start of the line

-- Keymap timing
-- How long Neovim waits for the next key in a mapping sequence.
vim.opt.timeoutlen = 300 -- Milliseconds; lower can make which-key and leader feel snappier

-- Splits
-- Where new windows open when you split.
vim.opt.splitright = true -- :vsplit puts new window on the right
vim.opt.splitbelow = true -- :split puts new window below

-- Command line
-- Live feedback when using :s and similar.
vim.opt.inccommand = 'split' -- Show preview of :substitute in a split (Neovim)

-- Quit / unsaved
-- If a command would fail with unsaved changes, ask whether to save instead of erroring.
vim.opt.confirm = true -- e.g. on :q with modified buffer, prompt to save
