-- 添加 lazy.nvim 到 rtp
vim.opt.rtp:prepend(vim.fn.stdpath("data") .. "/lazy/lazy.nvim")

local ok, lazy = pcall(require, "lazy")
if not ok then
  vim.notify("lazy.nvim not found. Run the install step first.", vim.log.levels.ERROR)
  return
end

-- 基础配置（不依赖任何插件）
require "user.options"
require "user.keymaps"
require "user.vim-compat"
require "user.autocommands"

-- 插件加载
lazy.setup(require("user.plugins"), {
  install = { colorscheme = { "gruvbox", "habamax" } },
  ui = { border = "rounded" },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip", "matchit", "matchparen", "netrwPlugin",
        "tarPlugin", "tohtml", "tutor", "zipPlugin",
      },
    },
  },
})
