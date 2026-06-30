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

-- 打开目录时自动启动 nvim-tree（netrw 已被禁用，由 nvim-tree 接管）
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function(data)
    if vim.fn.isdirectory(data.file) == 1 then
      vim.cmd.cd(data.file)
      require("nvim-tree.api").tree.open()
    end
  end,
})

-- Java 项目自动启动 jdtls（不需要先打开 .java 文件）
-- 在 pom.xml / build.gradle 项目中打开任意文件时，主动加载 jdtls
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    vim.defer_fn(function()
      -- 已经有 jdtls 在跑，跳过
      if #vim.lsp.get_clients({ name = "jdtls" }) > 0 then return end

      -- 检测是否是 Java 项目
      local root = vim.fs.root(0, { "pom.xml", "build.gradle", "mvnw", "gradlew" })
      if not root then return end
      local is_java_project = vim.fn.filereadable(root .. "/pom.xml") == 1
                           or vim.fn.filereadable(root .. "/build.gradle") == 1
      if not is_java_project then return end

      -- 用 lazy.nvim 强制加载 nvim-jdtls（等同于打开 .java 文件时的触发）
      -- 配置函数里的 start_or_attach 会用当前 cwd 检测项目根目录
      local ok, lazy = pcall(require, "lazy")
      if ok then
        lazy.load({ plugins = { "nvim-jdtls" } })
        vim.notify(
          "Java 项目检测到，jdtls 正在启动（" .. vim.fn.fnamemodify(root, ":t") .. "）",
          vim.log.levels.INFO
        )
      end
    end, 800)  -- 等待 800ms 让 lazy.nvim 和其他插件先初始化
  end,
})
