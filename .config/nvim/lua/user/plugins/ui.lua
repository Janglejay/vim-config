-- UI 相关插件

return {
  -- Icons（被多个插件依赖）
  {
    "nvim-tree/nvim-web-devicons",
    lazy = true,
  },

  -- File explorer
  {
    "nvim-tree/nvim-tree.lua",
    cmd = { "NvimTreeToggle", "NvimTreeOpen", "NvimTreeFocus", "NvimTreeFindFileToggle" },
    config = function()
      require "user.nvim-tree"
    end,
  },

  -- Bufferline（tab 栏）
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    config = function()
      require "user.bufferline"
    end,
  },

  -- Buffer 删除命令（:Bdelete / :Bwipeout）
  {
    "moll/vim-bbye",
    cmd = { "Bdelete", "Bwipeout" },
  },

  -- 状态栏
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    config = function()
      require "user.lualine"
    end,
  },

  -- 终端
  {
    "akinsho/toggleterm.nvim",
    cmd  = { "ToggleTerm", "TermExec", "ToggleTermToggleAll" },
    config = function()
      require "user.toggleterm"
    end,
  },

  -- 启动页
  {
    "goolord/alpha-nvim",
    event = "VimEnter",
    config = function()
      require "user.alpha"
    end,
  },

  -- 快捷键提示
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      require "user.whichkey"
    end,
  },

  -- ==================== 配色方案 ====================
  -- Catppuccin - 柔和奶油风
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
  },
  -- Tokyo Night - 高对比度现代风
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
  },
  -- Nightfox - 温暖舒适风
  {
    "EdenEast/nightfox.nvim",
    lazy = false,
    priority = 1000,
  },
  -- 旧配色，改为懒加载
  {
    "morhetz/gruvbox",
    lazy = true,
  },
  {
    "lunarvim/darkplus.nvim",
    lazy = true,
  },
  {
    "tanvirtin/monokai.nvim",
    lazy = true,
  },
  -- 配色管理器（最后加载，应用选中的配色）
  {
    dir = vim.fn.stdpath("config") .. "/lua/user/colorschemes",
    lazy = false,
    priority = 999,
    config = function()
      require("user.colorschemes").apply()
    end,
  },

  -- Git 状态标记
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require "user.gitsigns"
    end,
  },

  -- 自动括号配对
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require "user.autopairs"
    end,
  },

  -- 注释
  {
    "numToStr/Comment.nvim",
    keys = { { "gc", mode = { "n", "v" } }, { "gb", mode = { "n", "v" } } },
    config = function()
      require "user.comment"
    end,
  },

  -- TODO 注释高亮
  {
    "folke/todo-comments.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require "user.todo-comments"
    end,
  },

  -- 项目管理
  {
    "ahmedkhalf/project.nvim",
    event = "VeryLazy",
    config = function()
      require "user.project"
    end,
  },

  -- 透明背景
  {
    "xiyaowong/transparent.nvim",
    event = "VeryLazy",
    config = function()
      require "user.transparency"
    end,
  },

  -- 工具库（被多个插件依赖）
  {
    "nvim-lua/plenary.nvim",
    lazy = true,
  },
  {
    "nvim-lua/popup.nvim",
    lazy = true,
  },
}
