return {
  -- Treesitter 核心（新版 API：只管解析器安装，高亮由 Neovim 原生处理）
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("nvim-treesitter").setup()

      -- 新版 nvim-treesitter 不再自动为 buffer 启动 treesitter 解析树。
      -- 必须手动调用 vim.treesitter.start()，否则 J/K textobjects 查询无解析树可用。
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          pcall(vim.treesitter.start, args.buf)
        end,
      })

      -- 确保常用解析器已安装（异步）
      vim.defer_fn(function()
        pcall(function()
          require("nvim-treesitter.install").install({
            "java", "lua", "python", "rust", "go",
            "json", "yaml", "toml", "xml", "markdown", "bash",
          })
        end)
      end, 100)
    end,
  },

  -- nvim-treesitter-textobjects（新版 API）
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      -- 全局选项
      require("nvim-treesitter-textobjects").setup({
        move   = { set_jumps = true },
        select = { lookahead = true },
      })

      local move = require("nvim-treesitter-textobjects.move")
      local o    = { noremap = true, silent = true }

      -- J: MethodDown（跳到下一个函数/方法开头）
      vim.keymap.set("n", "J", function()
        move.goto_next_start("@function.outer")
      end, vim.tbl_extend("force", o, { desc = "MethodDown" }))

      -- K: MethodUp（跳到上一个函数/方法开头）
      vim.keymap.set("n", "K", function()
        move.goto_previous_start("@function.outer")
      end, vim.tbl_extend("force", o, { desc = "MethodUp" }))

      -- 文本对象（select 模式）
      local select = require("nvim-treesitter-textobjects.select")
      local sel_o  = { noremap = true, silent = true }

      local textobjects = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
        ["aa"] = "@parameter.outer",
        ["ia"] = "@parameter.inner",
      }
      for key, query in pairs(textobjects) do
        vim.keymap.set({ "x", "o" }, key, function()
          select.select_textobject(query, "textobjects")
        end, sel_o)
      end
    end,
  },

  -- flash.nvim: AceJump 替代（f/F）
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
      modes = {
        char = { enabled = false },
      },
    },
    keys = {
      { "f", mode = { "n", "x", "o" }, function() require("flash").jump() end,       desc = "AceAction (Flash Jump)" },
      { "F", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "AceTargetAction (Flash Treesitter)" },
    },
  },

  -- nvim-ts-context-commentstring（注释上下文感知）
  {
    "JoosepAlviste/nvim-ts-context-commentstring",
    lazy = true,
  },
}
