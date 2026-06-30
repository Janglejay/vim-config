return {
  {
    "ibhagwan/fzf-lua",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local fzf = require("fzf-lua")
      fzf.setup({
        winopts = {
          height = 0.85, width = 0.90,
          preview = { layout = "vertical", vertical = "down:50%" },
        },
        fzf_opts = { ["--layout"] = "reverse" },
        files = {
          fd_opts = "--color=never --type f --follow --exclude .git --exclude target --exclude node_modules",
        },
        grep = {
          rg_opts = "--column --line-number --no-heading --color=always --smart-case --max-columns=512",
        },
        -- jdtls 索引中响应慢，增大 LSP 超时（默认约 5000ms 容易超时）
        lsp = {
          async_or_timeout = 15000,   -- 15 秒
          jump_to_single_result = true,
        },
      })

      local opts = { noremap = true, silent = true }

      -- <Leader>f: SearchEverywhere（IDEA 风格，选类型后搜索）
      local search_modes = {
        { label = "  Files         文件名搜索",       fn = function() fzf.files() end },
        { label = "  Symbols       类·方法·字段",     fn = function() fzf.lsp_live_workspace_symbols() end },
        { label = "  Classes       仅类和接口",        fn = function()
            fzf.lsp_workspace_symbols({ query = "", regex_filter = "Class|Interface|Enum" })
          end },
        { label = "  Live Grep     内容全文搜索",      fn = function() fzf.live_grep() end },
        { label = "  Recent Files  最近文件",          fn = function() fzf.oldfiles() end },
      }
      vim.keymap.set("n", "<Leader>f", function()
        fzf.fzf_exec(
          vim.tbl_map(function(m) return m.label end, search_modes),
          {
            prompt  = "SearchEverywhere❯ ",
            winopts = { height = 0.28, width = 0.48, title = " 搜索类型 (Enter 确认) " },
            actions = {
              ["default"] = function(sel)
                if not sel or not sel[1] then return end
                for _, m in ipairs(search_modes) do
                  if m.label == sel[1] then m.fn(); return end
                end
              end,
            },
          }
        )
      end, vim.tbl_extend("force", opts, { desc = "SearchEverywhere (IDEA style)" }))

      -- <Leader>F: FindInPath
      vim.keymap.set("n", "<Leader>F", function() fzf.live_grep() end,
        vim.tbl_extend("force", opts, { desc = "FindInPath" }))

      -- <Leader>e: RecentFiles
      vim.keymap.set("n", "<Leader>e", function() fzf.oldfiles() end,
        vim.tbl_extend("force", opts, { desc = "RecentFiles" }))

      -- gr: FindUsages（默认过滤 Maven .m2 依赖，在 fzf 里删掉 "!.m2" 可看全部）
      vim.keymap.set("n", "gr", function()
        local clients = vim.lsp.get_clients({ bufnr = 0 })
        if #clients == 0 then
          vim.notify("LSP 未连接，请等待 jdtls 索引完成", vim.log.levels.WARN)
          return
        end
        fzf.lsp_references({
          fzf_opts = { ["--query"] = "!.m2" },
          winopts   = { title = " FindUsages (! to show Maven) " },
        })
      end, vim.tbl_extend("force", opts, { desc = "FindUsages" }))

      -- gi: GotoImplementation
      vim.keymap.set("n", "gi", function() fzf.lsp_implementations() end,
        vim.tbl_extend("force", opts, { desc = "GotoImplementation" }))

      -- gR: CallHierarchy 右侧边栏（树形结构，持久显示）
      vim.keymap.set("n", "gR", function()
        require("user.call_hierarchy").open()
      end, vim.tbl_extend("force", opts, { desc = "CallHierarchy sidebar" }))

      -- qi: QuickImplementations
      vim.keymap.set("n", "qi", function() fzf.lsp_implementations() end,
        vim.tbl_extend("force", opts, { desc = "QuickImplementations" }))

      -- ma: ShowBookmarks（自定义 fzf-lua picker，选中后直接跳转）
      vim.keymap.set("n", "ma", function()
        -- 确保 vim-bookmarks 已加载
        if vim.fn.exists("*bm#all_files") == 0 then
          vim.notify("vim-bookmarks 未加载，请先打开一个文件", vim.log.levels.WARN)
          return
        end

        local all_files = vim.fn["bm#all_files"]()
        if vim.tbl_isempty(all_files) then
          vim.notify("没有书签，用 mm 打标后再试", vim.log.levels.INFO)
          return
        end

        local entries   = {}
        local entry_map = {}

        for _, file in ipairs(all_files) do
          local marks = vim.fn["bm#all_bookmarks"](file)
          for _, mark in ipairs(marks) do
            local lnum = tonumber(mark.line_nr) or 0
            local note = (mark.annotation and mark.annotation ~= "")
                         and ("  " .. mark.annotation) or ""
            local short = vim.fn.fnamemodify(file, ":~:.")
            local display = string.format("%-45s:%d%s", short, lnum, note)
            table.insert(entries, display)
            entry_map[display] = { file = file, lnum = lnum }
          end
        end

        if #entries == 0 then
          vim.notify("没有书签，用 mm 打标后再试", vim.log.levels.INFO)
          return
        end

        fzf.fzf_exec(entries, {
          prompt  = "Bookmarks❯ ",
          winopts = { title = " 书签 (mm 打标 / mm 删除) ", height = 0.5, width = 0.82 },
          actions = {
            ["default"] = function(selected)
              if not selected or not selected[1] then return end
              local info = entry_map[selected[1]]
              if info then
                vim.cmd("edit " .. vim.fn.fnameescape(info.file))
                vim.api.nvim_win_set_cursor(0, { info.lnum, 0 })
                vim.cmd("normal! zz")
              end
            end,
          },
        })
      end, vim.tbl_extend("force", opts, { desc = "ShowBookmarks" }))
    end,
  },

  -- aerial: FileStructurePopup 替代
  {
    "stevearc/aerial.nvim",
    cmd  = { "AerialToggle", "AerialOpen", "AerialNext", "AerialPrev" },
    keys = { { "<Leader>s", "<cmd>AerialToggle!<CR>", desc = "FileStructurePopup" } },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    config = function()
      require("aerial").setup({
        backends = { "lsp", "treesitter", "markdown", "man" },
        layout = { max_width = { 40, 0.2 }, width = nil, min_width = 20, default_direction = "right" },
        show_guides = true,
        filter_kind = false,
      })
    end,
  },

  -- vim-bookmarks（立即加载确保 bm# 函数始终可用）
  { "MattesGroeger/vim-bookmarks", lazy = false },
}
