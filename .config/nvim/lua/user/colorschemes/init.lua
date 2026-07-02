-- 配色方案管理器
-- 支持: catppuccin, tokyonight, nightfox

local M = {}

-- 可用的配色方案
M.schemes = {
  catppuccin = require("user.colorschemes.catppuccin"),
  tokyonight = require("user.colorschemes.tokyonight"),
  nightfox = require("user.colorschemes.nightfox"),
}

-- 配置文件路径
local config_file = vim.fn.stdpath("config") .. "/.colorscheme"

-- 获取当前配色
function M.get_current()
  local f = io.open(config_file, "r")
  if f then
    local name = f:read("*l")
    f:close()
    if name and M.schemes[name] then
      return name
    end
  end
  return "catppuccin" -- 默认
end

-- 设置配色
function M.set(name)
  if not M.schemes[name] then
    vim.notify("未知的配色方案: " .. name, vim.log.levels.ERROR)
    return false
  end

  -- 保存配置
  local f = io.open(config_file, "w")
  if f then
    f:write(name)
    f:close()
  end

  -- 重新加载配置
  vim.cmd("colorscheme " .. name)
  vim.notify("配色方案已切换为: " .. name, vim.log.levels.INFO)
  return true
end

-- 应用配色配置（在 lazy 的 config 中使用）
function M.apply()
  local name = M.get_current()
  local scheme = M.schemes[name]
  if scheme then
    scheme.setup()
    vim.cmd("colorscheme " .. name)
  end
  return name
end

-- 获取所有可用配色名称
function M.list()
  local names = {}
  for name, _ in pairs(M.schemes) do
    table.insert(names, name)
  end
  table.sort(names)
  return names
end

-- 创建切换命令
vim.api.nvim_create_user_command("Colorscheme", function(opts)
  if opts.args == "" then
    local current = M.get_current()
    local list = table.concat(M.list(), ", ")
    print("当前配色: " .. current)
    print("可用配色: " .. list)
    print("使用方法: :Colorscheme <name>")
  else
    M.set(opts.args)
  end
end, {
  nargs = "?",
  complete = function()
    return M.list()
  end,
  desc = "切换配色方案 (catppuccin/tokyonight/nightfox)",
})

return M
