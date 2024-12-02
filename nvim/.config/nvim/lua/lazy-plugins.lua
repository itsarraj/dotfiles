-- [[ Configure and install plugins ]]
--
--  To check the current status of your plugins, run
--    :Lazy
--
--  You can press `?` in this menu for help. Use `:q` to close the window
--
--  To update plugins you can run
--    :Lazy update
--
-- NOTE: Here is where you install your plugins.
local is_vscode = vim.g.vscode ~= nil

local plugins = {
  -- NOTE: Plugins can be added with a link (or for a github repo: 'owner/repo' link).
  'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically

  -- NOTE: Plugins can also be added by using a table,
  -- with the first argument being the link and the following
  -- keys can be used to configure plugin behavior/loading/etc.
  --
  -- Use `opts = {}` to force a plugin to be loaded.
  --

  -- modular approach: using `require 'path/name'` will
  -- include a plugin definition from file lua/path/name.lua
}

if is_vscode then
  -- Plugins for VS Code Neovim
  -- table.insert(plugins, require 'kickstart/plugins/gitsigns')
  -- table.insert(plugins, require 'kickstart/plugins/which-key')
  -- table.insert(plugins, require 'kickstart/plugins/telescope')
  -- table.insert(plugins, require 'kickstart/plugins/telescope-file-browser')
  -- table.insert(plugins, require 'kickstart/plugins/lspconfig')
  -- table.insert(plugins, require 'kickstart/plugins/conform')
  -- table.insert(plugins, require 'kickstart/plugins/cmp')
  -- table.insert(plugins, require 'kickstart/plugins/onedark')
  -- table.insert(plugins, require 'kickstart/plugins/tokyonight')
  -- table.insert(plugins, require 'kickstart/plugins/onedarkpro')
  -- table.insert(plugins, require 'kickstart/plugins/todo-comments')
  -- table.insert(plugins, require 'kickstart/plugins/mini')
  -- table.insert(plugins, require 'kickstart/plugins/treesitter')
  -- table.insert(plugins, require 'kickstart/plugins/vim-tmux-navigator')
  -- table.insert(plugins, require 'kickstart/plugins/deoplete')
  -- table.insert(plugins, require 'kickstart/plugins/markdown-preview')
else
  -- Plugins for VS Code and regular Neovim
  -- table.insert(plugins, require 'kickstart/plugins/gitsigns')
  -- table.insert(plugins, require 'kickstart/plugins/which-key')
  -- table.insert(plugins, require 'kickstart/plugins/telescope')
  -- table.insert(plugins, require 'kickstart/plugins/telescope-file-browser')
  -- table.insert(plugins, require 'kickstart/plugins/lspconfig')
  -- table.insert(plugins, require 'kickstart/plugins/conform')
  -- table.insert(plugins, require 'kickstart/plugins/cmp')
  table.insert(plugins, require 'kickstart/plugins/onedark')
  -- table.insert(plugins, require 'kickstart/plugins/tokyonight')
  -- table.insert(plugins, require 'kickstart/plugins/onedarkpro')
  -- table.insert(plugins, require 'kickstart/plugins/todo-comments')
  -- table.insert(plugins, require 'kickstart/plugins/mini')
  -- table.insert(plugins, require 'kickstart/plugins/treesitter')
  -- table.insert(plugins, require 'kickstart/plugins/vim-tmux-navigator')
  -- table.insert(plugins, require 'kickstart/plugins/deoplete')
  -- table.insert(plugins, require 'kickstart/plugins/markdown-preview')
end

require('lazy').setup(plugins, {
  ui = {
    -- If you are using a Nerd Font: set icons to an empty table which will use the
    -- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})

-- vim: ts=2 sts=2 sw=2 et
