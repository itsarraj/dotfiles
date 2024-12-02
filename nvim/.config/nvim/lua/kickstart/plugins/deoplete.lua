return {
  {
    'Shougo/deoplete.nvim',
    build = ':UpdateRemotePlugins', -- Run :UpdateRemotePlugins after installation/update
    event = 'VimEnter', -- Lazy-load the plugin on VimEnter event
    config = function()
      vim.g['deoplete#enable_at_startup'] = 1 -- Enable deoplete at startup
    end,
  },
}
