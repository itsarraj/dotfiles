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
-- Plugin specs live in `lua/plugins/<name>.lua`. List basenames below (no `.lua`).
-- Add or remove names here instead of repeating `require 'plugins.<name>'`.

local specs = {
  { 'NMAC427/guess-indent.nvim', opts = {} },
}

-- Basename matches lua/plugins/<name>.lua — uncomment a line to load that plugin.
local plugins = {
  'darkplus', -- Colorscheme (Dark+ / VS-style)
  'telescope', -- Fuzzy finder (files, grep, buffers, LSP pickers)
  'harpoon', -- Pin files and jump with few keys (Harpoon 2)
  'blink-cmp', -- Completion (LSP, path, snippets)
  'mini', -- mini.nvim: textobjects, surround, statusline, …
}

for _, name in ipairs(plugins) do
  specs[#specs + 1] = require('plugins.' .. name)
end

require('lazy').setup(specs)

-- vim: ts=2 sts=2 sw=2 et
