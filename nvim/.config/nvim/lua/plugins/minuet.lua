-- ~/.config/nvim/lua/plugins/minuet.lua
return {
  {
    "milanglacier/minuet-ai.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },

    config = function()
      require("minuet").setup({
        -- Use Ollama's OpenAI-compatible Fill-in-the-Middle endpoint
        provider = "openai_fim_compatible",

        -- Generate one completion only (best for local models)
        n_completions = 1,

        -- Good starting point for your ThinkPad T495
        context_window = 512,

        -- Timeout in seconds
        request_timeout = 3,

        -- Show warnings and errors
        notify = "warn",

        provider_options = {
          openai_fim_compatible = {
            -- Ollama doesn't need a real API key.
            -- Minuet just needs some non-empty value.
            api_key = function()
              return "ollama"
            end,

            name = "Ollama",
            end_point = "http://127.0.0.1:11434/v1/completions",

            -- Must exist in `ollama list`
            model = "qwen2.5-coder:7b-instruct-q4_K_M",
            optional = {
              max_tokens = 64,
              top_p = 0.9,
              temperature = 0.2,
            },
          },
        },
      })
    end,
  },
  {
    "saghen/blink.cmp",
    optional = true,
    opts = function(_, opts)
      opts.sources = opts.sources or {}
      opts.sources.default = opts.sources.default or {}
      opts.sources.providers = opts.sources.providers or {}

      if not vim.tbl_contains(opts.sources.default, "minuet") then
        table.insert(opts.sources.default, "minuet")
      end

      opts.sources.providers.minuet = vim.tbl_extend("force", opts.sources.providers.minuet or {}, {
        name = "minuet",
        module = "minuet.blink",
        async = true,
        timeout_ms = 1500,
        score_offset = 20,
      })
    end,
    keys = {
      {
        "<F4>",
        function()
          require("blink.cmp").show({ providers = { "minuet" } })
        end,
        mode = "i",
        desc = "AI Complete (Minuet)",
      },
    },
  },
}
