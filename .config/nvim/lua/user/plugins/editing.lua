return {
  -- Treesitter 核心 + textobjects（J/K 方法跳转）
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
      "JoosepAlviste/nvim-ts-context-commentstring",
    },
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "java", "lua", "python", "rust", "go",
          "json", "yaml", "toml", "xml", "markdown",
          "bash", "regex",
        },
        auto_install = true,
        highlight = { enable = true },
        indent    = { enable = true },
        textobjects = {
          move = {
            enable = true,
            set_jumps = true,
            goto_next_start     = { ["J"] = { query = "@function.outer", desc = "MethodDown" } },
            goto_previous_start = { ["K"] = { query = "@function.outer", desc = "MethodUp" } },
          },
          select = {
            enable   = true,
            lookahead = true,
            keymaps  = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
              ["aa"] = "@parameter.outer",
              ["ia"] = "@parameter.inner",
            },
          },
        },
      })
    end,
  },

  -- flash.nvim: AceJump 替代
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
      modes = {
        char = { enabled = false },  -- 禁用 f/t 原生行为覆盖，保留 flash 自身的 jump
      },
    },
    keys = {
      { "f", mode = { "n", "x", "o" }, function() require("flash").jump() end,       desc = "AceAction (Flash Jump)" },
      { "F", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "AceTargetAction (Flash Treesitter)" },
    },
  },
}
