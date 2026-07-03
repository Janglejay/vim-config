vim.cmd [[
  augroup _general_settings
    autocmd!
    autocmd FileType qf,help,man,lspinfo nnoremap <silent> <buffer> q :close<CR> 
    autocmd TextYankPost * silent! lua require('vim.highlight').on_yank({higroup = 'Visual', timeout = 200}) 
    autocmd BufWinEnter * :set formatoptions-=cro
    autocmd FileType qf set nobuflisted
  augroup end

  augroup _git
    autocmd!
    autocmd FileType gitcommit setlocal wrap
    autocmd FileType gitcommit setlocal spell
  augroup end

  augroup _markdown
    autocmd!
    autocmd FileType markdown setlocal wrap
    autocmd FileType markdown setlocal spell
  augroup end

  augroup _auto_resize
    autocmd!
    autocmd VimResized * tabdo wincmd = 
  augroup end

  augroup _alpha
    autocmd!
    autocmd User AlphaReady set showtabline=0 | autocmd BufUnload <buffer> set showtabline=2
  augroup end
]]

-- Autoformat
-- augroup _lsp
--   autocmd!
--   autocmd BufWritePre * lua vim.lsp.buf.formatting()
-- augroup end

-- K=MethodUp 保护：lspsaga/Neovim 在 LspAttach 里（含 vim.schedule）设 buffer-local K→hover
-- vim.defer_fn(100ms) 明确晚于所有同步+异步 LspAttach 处理，buffer-local 最后设置的赢
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local buf = args.buf
    vim.defer_fn(function()
      if not _G._nvim_method_jump then return end
      vim.keymap.set("n", "K", function() _G._nvim_method_jump("prev") end,
        { noremap = true, silent = true, buffer = buf, desc = "MethodUp" })
    end, 100)
  end,
})

-- mtcc / Claude Code 集成：外部修改文件后，切回 Neovim 时自动重载 buffer
-- autoread 只声明意图，checktime 才真正触发检查
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  command = "silent! checktime",
})

-- 禁止 LSP 通过 willSaveWaitUntil 在保存时注入格式化 edits
-- jdtls 等服务器会响应此请求并返回格式化变更，这是自动格式化的根源
vim.lsp.handlers["textDocument/willSaveWaitUntil"] = function() end

-- 打开目录时自动启动 nvim-tree（netrw 已被禁用，由 nvim-tree 接管）
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function(data)
    if vim.fn.isdirectory(data.file) == 1 then
      vim.cmd.cd(data.file)
      require("nvim-tree.api").tree.open()
    end
  end,
})

-- Java 项目 jdtls 启动辅助函数（供 <leader>f 调用）
-- 通过打开一个 Java 文件来触发 jdtls（比直接 lazy.load 更安全）
_G.start_jdtls_for_project = function()
  if #vim.lsp.get_clients({ name = "jdtls" }) > 0 then return true end

  local root = vim.fs.root(0, { "pom.xml", "build.gradle", "mvnw", "gradlew" })
           or vim.fn.getcwd()
  if vim.fn.filereadable(root .. "/pom.xml") == 0
     and vim.fn.filereadable(root .. "/build.gradle") == 0 then
    return false
  end

  -- 找一个 Java 文件来触发 jdtls（jdtls 需要 Java 文件 context 才能正确初始化）
  local java_files = vim.fn.systemlist(
    "fd --type f -e java --max-results 1 " .. vim.fn.shellescape(root) .. " 2>/dev/null")
  if #java_files == 0 then return false end

  -- 在后台打开 Java 文件（不改变用户当前窗口）
  local cur_win = vim.api.nvim_get_current_win()
  vim.cmd("split " .. vim.fn.fnameescape(java_files[1]))
  local java_win = vim.api.nvim_get_current_win()
  -- jdtls 会通过 FileType=java 自动触发
  -- 立刻关闭窗口（jdtls 已经开始初始化了）
  vim.defer_fn(function()
    pcall(vim.api.nvim_win_close, java_win, true)
    if vim.api.nvim_win_is_valid(cur_win) then
      vim.api.nvim_set_current_win(cur_win)
    end
  end, 200)

  return true  -- 已触发启动
end
