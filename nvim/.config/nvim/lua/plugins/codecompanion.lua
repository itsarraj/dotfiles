return {
  {
    "olimorris/codecompanion.nvim",
    version = "^19.0.0",
    event = "VeryLazy",
    enabled = function()
      return vim.fn.has("nvim-0.11") == 1
    end,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "nvim-telescope/telescope.nvim",
      { "saghen/blink.cmp", version = "1.*" },
    },
    keys = {
      { "<leader>ac", "<cmd>CodeCompanionChat<cr>", desc = "AI Chat (CodeCompanion)" },
      { "<leader>aa", "<cmd>CodeCompanionActions<cr>", desc = "AI Actions (CodeCompanion)" },
      { "<leader>ai", "<cmd>CodeCompanion<cr>", mode = { "n", "v" }, desc = "AI Inline (CodeCompanion)" },
    },
    opts = {
      adapters = {
        http = {
          ollama = function()
            return require("codecompanion.adapters").extend("ollama", {
              schema = {
                model = {
                  default = "qwen2.5-coder:7b-instruct-q4_K_M",
                },
              },
            })
          end,
        },
      },
      interactions = {
        chat = {
          adapter = {
            name = "ollama",
            model = "qwen2.5-coder:7b-instruct-q4_K_M",
          },
        },
        inline = {
          adapter = {
            name = "ollama",
            model = "qwen2.5-coder:7b-instruct-q4_K_M",
          },
        },
      },
      display = {
        action_palette = {
          provider = "telescope",
        },
      },
      opts = {
        log_level = "INFO",
      },
    },
  },
}
