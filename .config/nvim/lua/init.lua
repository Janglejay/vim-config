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
    reset_packpath = true,  -- 确保 packpath 正确重置
    rtp = {
      disabled_plugins = {
        "gzip", "matchit", "matchparen", "netrwPlugin",
        "tarPlugin", "tohtml", "tutor", "zipPlugin",
      },
    },
  },
})

-- Neovim 0.10+ native loader 缓存重置
-- 让新加入 runtimepath 的插件模块可以被正确找到
if vim.loader then
  vim.loader.reset()
end
