return {
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    version = false,
    build = vim.fn.has("win32") ~= 0
        and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
      or "make",
    enabled = function()
      return vim.fn.has("nvim-0.11") == 1
    end,
    keys = {
      { "<leader>at", "<cmd>AvanteToggle<cr>", desc = "AI Toggle (Avante)" },
      { "<leader>aq", "<cmd>AvanteAsk<cr>", mode = { "n", "v" }, desc = "AI Ask (Avante)" },
      { "<leader>ae", "<cmd>AvanteEdit<cr>", mode = { "n", "v" }, desc = "AI Edit (Avante)" },
    },
    opts = {
      provider = "ollama",
      auto_suggestions_provider = "ollama",
      selector = {
        provider = "telescope",
      },
      providers = {
        ollama = {
          model = "qwen2.5-coder:7b-instruct-q4_K_M",
          is_env_set = function()
            return vim.fn.executable("curl") == 1
          end,
        },
      },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-telescope/telescope.nvim",
      "nvim-tree/nvim-web-devicons",
      {
        "MeanderingProgrammer/render-markdown.nvim",
        ft = { "markdown", "Avante", "codecompanion" },
        opts = {
          file_types = { "markdown", "Avante", "codecompanion" },
        },
      },
    },
  },
}
