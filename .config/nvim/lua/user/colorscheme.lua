-- 配色方案自动加载（由 colorschemes/init.lua 管理）
-- 使用 :Colorscheme <name> 切换
-- 或使用 ~/.config/nvim/switch-colorscheme.sh <name>

local ok, manager = pcall(require, "user.colorschemes")
if ok then
  local current = manager.apply()
  vim.g.current_colorscheme = current
else
  -- 兜底方案
  vim.cmd [[
    try
      colorscheme catppuccin
    catch /^Vim\%((\a\+)\)\=:E185/
      colorscheme default
      set background=dark
    endtry
  ]]
end
