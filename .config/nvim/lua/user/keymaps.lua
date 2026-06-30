local opts = { noremap = true, silent = true }
local term_opts = { silent = true }
local keymap = vim.api.nvim_set_keymap

-- ====================
-- Leader Key
-- ====================
vim.g.mapleader = ","
vim.g.maplocalleader = ","

-- ====================
-- 基础按键映射 (来自 .vimrc)
-- ====================

-- ESC delay 设置 (timoutlen=500, ttimeoutlen=0 在 options.lua 中)
vim.opt.ttimeoutlen = 0

-- Normal 模式
keymap("n", "q", "<NOP>", opts)          -- 禁用 q
keymap("n", "\\", "q", opts)              -- \ 代替 q
keymap("n", "U", ":redo<CR>", opts)       -- U 重做
keymap("n", "<C-e>", "<C-d>", opts)       -- Ctrl+e 向下半页
keymap("n", "<C-r>", "<C-u>", opts)       -- Ctrl+r 向上半页
keymap("n", "<CR>", ";", opts)            -- 回车变为 ;
keymap("n", "vv", "<S-v>", opts)          -- vv 选中整行
keymap("n", "go", "gi", opts)             -- go 跳到上次插入位置并进入插入模式

-- 翻页 (以空行为段落)
-- keymap("n", "J", "}", opts)  -- 已替换为 treesitter method jump (editing.lua)
-- keymap("n", "K", "{", opts)  -- 已替换为 treesitter method jump (editing.lua)

-- Leader 快捷键
keymap("n", "<Leader>j", "*", opts)        -- 搜索当前词
keymap("n", "<Leader>k", "#", opts)        -- 反向搜索
keymap("n", "W", "b", opts)                -- W 跳词
keymap("n", "zc", "zz", opts)
keymap("n", "zz", "zc", opts)
keymap("n", "zZ", "zM", opts)
keymap("n", "zO", "zR", opts)

-- 移动
keymap("n", "L", "<End>", opts)           -- L 跳到行尾
keymap("n", "H", "^", opts)                -- H 跳到行首
keymap("n", "gn", "%", opts)               -- gn 跳到匹配括号

-- Edit 快捷键
keymap("n", "{", "$a {<CR>}<Esc>O", opts) -- { 补 {}

-- Buffer 操作
keymap("n", "R", ":bnext<CR>", opts)      -- R 下一个 buffer
keymap("n", "E", ":bprevious<CR>", opts)   -- E 上一个 buffer

-- Window 导航
keymap("n", "gh", "<C-w>h", opts)
keymap("n", "gj", "<C-w>j", opts)
keymap("n", "gk", "<C-w>k", opts)
keymap("n", "gl", "<C-w>l", opts)

-- 分割窗口
keymap("n", "sV", ":sp<CR>", opts)
keymap("n", "sv", ":vs<CR>", opts)

-- 窗口缩放：<Leader> + 方向键，每次 4 格
-- 比 <C-arrow> 更不易与终端快捷键冲突
vim.keymap.set("n", "<Leader><Up>",    ":resize +4<CR>",          { noremap=true, silent=true, desc="窗口增高" })
vim.keymap.set("n", "<Leader><Down>",  ":resize -4<CR>",          { noremap=true, silent=true, desc="窗口减高" })
vim.keymap.set("n", "<Leader><Right>", ":vertical resize +4<CR>", { noremap=true, silent=true, desc="窗口加宽" })
vim.keymap.set("n", "<Leader><Left>",  ":vertical resize -4<CR>", { noremap=true, silent=true, desc="窗口减宽" })

-- Tab 操作
keymap("n", "<Tab>", ">>", opts)          -- Tab 右缩进
keymap("n", "<BS>", "<<", opts)           -- Backspace 左缩进
keymap("v", "<Tab>", ">", opts)
keymap("v", "<BS>", "<", opts)

-- ====================
-- 搜索
-- ====================
keymap("n", "<Leader>n", ":nohlsearch<CR>", opts)  -- 取消高亮

-- ====================
-- 复制粘贴 (来自 .vimrc)
-- ====================
keymap("n", "Y", "gg^yG<End>", opts)      -- Y 复制整行
keymap("n", "<Leader>v", "gg^vG<End>", opts) -- 全选
keymap("n", "<Leader>d", "\"_d", opts)     -- 删除到黑洞寄存器
keymap("n", "x", "\"_x", opts)             -- x 删除字符
keymap("n", "c", "\"_c", opts)             -- c 修改
keymap("n", "cc", "\"_cc", opts)           -- cc 删除当前行进入插入
keymap("n", "s", "\"_s", opts)             -- s 删除字符进入插入
keymap("v", "p", "\"_dP", opts)            -- v 模式 p 粘贴到前面
keymap("n", "<Leader>y", "\"_y", opts)     -- y 复制到黑洞
keymap("n", "<Leader>r", 'viw"_dP', opts)  -- 替换当前词

-- ====================
-- Git / Hunk 操作
-- ====================
keymap("n", "<C-u>", "<cmd>lua require 'gitsigns'.reset_hunk()<cr>", opts)
keymap("n", "gp", "<cmd>lua require 'gitsigns'.preview_hunk()<cr>", opts)
keymap("n", "<C-f>", "<cmd>lua require 'gitsigns'.prev_hunk()<cr>", opts)
keymap("n", "<C-d>", "<cmd>lua require 'gitsigns'.next_hunk()<cr>", opts)

-- ====================
-- 跳转历史
-- ====================
keymap("n", "<C-n>", "<C-i>", opts)  -- Forward（对应 IdeaVim <C-n> Forward）

-- ====================
-- Terminal
-- ====================
keymap("n", "st", "<cmd>ToggleTerm direction=horizontal<cr>", opts)

-- ====================
-- LSP Format
-- ====================
keymap("n", "=", "<cmd>lua vim.lsp.buf.format({ async = true })<cr>", opts)

-- ====================
-- Insert 模式
-- ====================
keymap("i", "jk", "<ESC>", opts)          -- jk 退出插入模式

-- ====================
-- Visual 模式
-- ====================
keymap("v", "U", "~", opts)                -- U 大写
keymap("v", "~", "<Nop>", opts)
keymap("v", "u", "<ESC>", opts)            -- u 小写

-- ====================
-- LSP 快速查看（对照 IdeaVim）
-- ====================
keymap("n", "qt", "<cmd>lua vim.lsp.buf.type_definition()<CR>", opts)   -- QuickTypeDefinition
keymap("n", "qd", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)              -- QuickJavaDoc

-- ====================
-- 窗口操作（对照 IdeaVim）
-- ====================
keymap("n", "sl", "<C-w>w", opts)                          -- NextWindow（循环切换分割）
keymap("n", "sh", "<C-w>W", opts)                          -- PreviousWindow（反向循环）
keymap("n", "sw", "<cmd>vsplit<CR><cmd>lua vim.lsp.buf.definition()<CR>", opts)  -- EditSourceInNewWindow
keymap("n", "sq", "<cmd>close<CR>", opts)                  -- Unsplit
-- <Leader>w: 隐藏/恢复所有工具窗口（对应 IDEA Shift+F12 Hide All Windows）
-- 隐藏：关闭 nvim-tree、terminal、aerial、call hierarchy 等工具窗口
-- 恢复：把之前开着的工具窗口重新打开
local _tools_hidden = false
local _tools_state  = {
  nvim_tree      = false,
  terminal       = false,
  aerial         = false,
  call_hierarchy = false,
}

local function is_tool_win(win)
  local buf   = vim.api.nvim_win_get_buf(win)
  local bname = vim.api.nvim_buf_get_name(buf)
  local bt    = vim.bo[buf].buftype
  return bt == "terminal"
      or bname:find("NvimTree")       ~= nil
      or bname:find("aerial://")      ~= nil
      or bname:find("CallHierarchy")  ~= nil
      or bname == "[dap-repl]"
      or bname:find("DAP") ~= nil
end

vim.keymap.set("n", "<Leader>w", function()
  local ch = require("user.call_hierarchy")

  if _tools_hidden then
    -- 恢复所有工具窗口
    if _tools_state.nvim_tree      then vim.cmd("NvimTreeOpen") end
    if _tools_state.aerial         then vim.cmd("AerialOpen") end
    if _tools_state.terminal       then vim.cmd("ToggleTerm direction=horizontal") end
    if _tools_state.call_hierarchy then ch.reopen() end
    _tools_hidden = false
    vim.notify("工具窗口已恢复", vim.log.levels.INFO)
  else
    -- 扫描当前哪些工具窗口是开的
    _tools_state.nvim_tree      = false
    _tools_state.terminal       = false
    _tools_state.aerial         = false
    _tools_state.call_hierarchy = ch.is_open()

    local tool_wins = {}
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_config(win).relative ~= "" then goto continue end
      if is_tool_win(win) then
        local buf   = vim.api.nvim_win_get_buf(win)
        local bname = vim.api.nvim_buf_get_name(buf)
        local bt    = vim.bo[buf].buftype
        if bname:find("NvimTree")  then _tools_state.nvim_tree = true end
        if bt == "terminal"        then _tools_state.terminal  = true end
        if bname:find("aerial://") then _tools_state.aerial    = true end
        table.insert(tool_wins, win)
      end
      ::continue::
    end

    if #tool_wins == 0 and not _tools_state.call_hierarchy then
      vim.notify("没有工具窗口可隐藏", vim.log.levels.INFO)
      return
    end

    -- 关闭 call hierarchy（包含 preview 窗口）
    if _tools_state.call_hierarchy then ch.close_all() end
    -- 关闭其他工具窗口
    for _, win in ipairs(tool_wins) do
      pcall(vim.api.nvim_win_close, win, false)
    end
    _tools_hidden = true
    vim.notify("工具窗口已隐藏（再按 <Leader>w 恢复）", vim.log.levels.INFO)
  end
end, { noremap = true, silent = true, desc = "Hide/Restore all tool windows (IDEA Shift+F12)" })
keymap("n", "<Leader>c", "<cmd>Bdelete<CR>", opts)         -- CloseContent
keymap("n", "<Leader>C", "<cmd>%bd|e#|bd#<CR>", opts)     -- CloseAllEditorsButActive
keymap("n", "gw", "<cmd>NvimTreeFocus<CR>", opts)          -- OpenProjectWindows
keymap("n", "<Leader>P", "<cmd>NvimTreeFindFile<CR>", opts) -- SelectIn（定位当前文件）

-- ====================
-- 构建（对照 IdeaVim zb = Java.BuildMenu）
-- ====================
keymap("n", "zb", "<cmd>TermExec cmd='mvn compile'<CR>", opts)  -- Java.BuildMenu

-- ====================
-- 书签（对照 IdeaVim）
-- ====================
keymap("n", "mm", "<cmd>BookmarkToggle<CR>", opts)   -- ToggleBookmark
keymap("n", "gm", "<cmd>BookmarkNext<CR>", opts)     -- GotoNextBookmark
keymap("n", "gM", "<cmd>BookmarkPrev<CR>", opts)     -- GotoPreviousBookmark

-- ====================
-- 来自 .vimrc 的全局 buffer-local 映射
-- ====================
-- 这些通过 autocmd 在特定文件类型上设置
--[[ vim.api.nvim_create_autocmd("FileType", { ]]
--[[   pattern = { "java", "rust", "lua", "go" }, ]]
--[[   callback = function() ]]
--[[     vim.api.nvim_buf_set_keymap(0, "n", ";", "$a;<Esc>", { noremap = true, silent = true }) ]]
--[[     vim.api.nvim_buf_set_keymap(0, "n", "{", "$a {<CR>}<Esc>O", { noremap = true, silent = true }) ]]
--[[   end, ]]
--[[ }) ]]
--[[]]
--[[ -- Rust 特有 ]]
--[[ vim.api.nvim_create_autocmd("FileType", { ]]
--[[   pattern = { "rust" }, ]]
--[[   callback = function() ]]
--[[     vim.api.nvim_buf_set_keymap(0, "n", "zr", "<cmd>w<CR><cmd>TermExec cmd=\"cargo run\" dir=\".\"<CR>", { noremap = true, silent = true }) ]]
--[[     vim.api.nvim_buf_set_keymap(0, "n", "zb", "<cmd>w<CR><cmd>TermExec cmd=\"cargo build\" dir=\".\"<CR>", { noremap = true, silent = true }) ]]
--[[     vim.api.nvim_buf_set_keymap(0, "n", "zc", "<cmd>w<CR><cmd>TermExec cmd=\"cargo check\" dir=\".\"<CR>", { noremap = true, silent = true }) ]]
--[[     vim.api.nvim_buf_set_keymap(0, "n", "zR", "<cmd>w<CR><cmd>RustRun<CR>", { noremap = true, silent = true }) ]]
--[[   end, ]]
--[[ }) ]]
--[[]]
--[[ -- Lua 特有 ]]
--[[ vim.api.nvim_create_autocmd("FileType", { ]]
--[[   pattern = { "lua" }, ]]
--[[   callback = function() ]]
--[[     vim.api.nvim_buf_set_keymap(0, "n", "zr", "<cmd>w<CR><cmd>!lua %<CR>", { noremap = true, silent = true }) ]]
--[[   end, ]]
--[[ }) ]]
--[[]]
--[[ -- Markdown 特有 ]]
--[[ vim.api.nvim_create_autocmd("FileType", { ]]
--[[   pattern = { "markdown" }, ]]
--[[   callback = function() ]]
--[[     local mopts = { noremap = true, silent = true, buffer = 0 } ]]
--[[     vim.keymap.set("n", "<Leader>x", "/<++><CR>:nohl<CR>4\"-cl", mopts) ]]
--[[     vim.keymap.set("n", "<Leader>C", "i```<CR><++><CR>```<Esc>", mopts) ]]
--[[     vim.keymap.set("n", "<Leader>c", "i`<++>`<Esc>", mopts) ]]
--[[     vim.keymap.set("n", "<Leader>b", "i**<++>**<Esc>", mopts) ]]
--[[     vim.keymap.set("n", "<Leader>s", "i~~<++>~~<Esc>", mopts) ]]
--[[     vim.keymap.set("n", "<Leader>o", "i[<++>](<++>)<Esc>", mopts) ]]
--[[     vim.keymap.set("n", "<Leader>O", "i![<++>](<++>)<Esc>", mopts) ]]
--[[     vim.keymap.set("n", "<Leader>m", "i- [<Space>]<Esc>", mopts) ]]
--[[   end, ]]
--[[ }) ]]
