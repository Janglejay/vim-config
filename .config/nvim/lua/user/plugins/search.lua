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

      -- <Leader>f: SearchEverywhere（直接搜索，无需选择类型）
      -- lsp_live_workspace_symbols 同时覆盖：类名、方法名、字段名
      -- 结果中显示的文件名列也可在 fzf 里直接输入搜索（如 "OrderService.java"）
      -- jdtls 未就绪时自动退化为文件搜索
      vim.keymap.set("n", "<Leader>f", function()
        -- 全局查找 jdtls（不限制 bufnr，在 pom.xml/.json/.xml 等文件中也能找到）
        local jdtls_client = nil
        for _, c in ipairs(vim.lsp.get_clients()) do
          if c.name == "jdtls"
             and c.server_capabilities.workspaceSymbolProvider ~= nil
             and c.server_capabilities.workspaceSymbolProvider ~= false then
            jdtls_client = c
            break
          end
        end

        if jdtls_client then
          -- 一次性拉取所有项目符号，过滤 Maven，用 fzf 本地模糊搜索
          local m2_path = vim.fn.expand("~") .. "/.m2/"
          local kind_icons = {
            [1]="󰙐 Text", [2]="󰆧 Method", [3]="󰊕 Function",
            [4]=" Constructor", [5]="󰜢 Field", [6]="󰀫 Variable",
            [7]="󰠱 Class", [8]="󰜰 Interface", [9]="󰏗 Module",
            [10]="󰜢 Property", [13]="󰋺 Enum", [14]="󰌋 Keyword",
            [21]=" Constant", [22]="󰙅 Struct", [25]="󰅲 TypeParam",
          }

          -- jdtls attach 后还需要 10-30s 加载缓存到内存才能响应符号查询
          -- 用 30s 超时，失败时提示用户等待并退化为文件搜索
          vim.notify("搜索符号中...", vim.log.levels.INFO)
          local ok, result = jdtls_client.request_sync(
            "workspace/symbol", { query = "" }, 30000, 0)

          if not ok or not result or not result.result then
            -- 查询失败原因：jdtls 还在加载缓存（即使 attach 了也需要 10-30s 就绪）
            -- 状态栏显示 "󰔟 jdtls: 索引中" 时说明还没就绪
            vim.notify(
              "jdtls 尚未完全就绪（正在加载索引缓存），已退化为文件搜索\n"
              .. "提示：等状态栏显示 ✓ jdtls 后重试 <Leader>f",
              vim.log.levels.WARN
            )
            fzf.files()
            return
          end

          local entries   = {}
          local entry_map = {}

          for _, sym in ipairs(result.result) do
            local uri  = (sym.location or {}).uri or ""
            local path = vim.uri_to_fname(uri)
            -- 跳过 Maven 依赖（.m2 目录）
            if not path:find(m2_path, 1, true) then
              local lnum  = ((sym.location.range or {}).start or {}).line or 0
              local fname = vim.fn.fnamemodify(path, ":~:.")
              local icon  = kind_icons[sym.kind] or "  Symbol"
              local display = string.format("%-45s %-16s %s:%d",
                sym.name, icon, fname, lnum + 1)
              table.insert(entries, display)
              entry_map[display] = { file = path, lnum = lnum + 1 }
            end
          end

          if #entries == 0 then
            vim.notify("项目中没有找到符号（索引可能未完成）", vim.log.levels.WARN)
            return
          end

          fzf.fzf_exec(entries, {
            prompt  = "SearchEverywhere❯ ",
            winopts = {
              title  = string.format(" 项目符号 (%d 个，已过滤 Maven) ", #entries),
              height = 0.85, width = 0.92,
              preview = { layout = "vertical", vertical = "down:45%" },
            },
            fzf_opts = { ["--tiebreak"] = "begin" },
            previewer = "builtin",
            actions = {
              ["default"] = function(selected)
                if not selected or not selected[1] then return end
                local info = entry_map[selected[1]]
                if info then
                  vim.cmd("edit " .. vim.fn.fnameescape(info.file))
                  pcall(vim.api.nvim_win_set_cursor, 0, { info.lnum, 0 })
                  vim.cmd("normal! zz")
                end
              end,
            },
          })
        else
          -- jdtls 未就绪：检测是否是 Java 项目，如果是则尝试启动
          local triggered = _G.start_jdtls_for_project and _G.start_jdtls_for_project()
          if triggered then
            vim.notify(
              "jdtls 正在启动，当前显示文件搜索，索引完成（状态栏变 ✓）后按 <Leader>f 即可搜符号",
              vim.log.levels.INFO
            )
          end
          -- 退化为文件名搜索（jdtls 在后台启动）
          fzf.files({
            winopts = { title = " Files (jdtls 启动中，完成后可搜类·方法) " }
          })
        end
      end, vim.tbl_extend("force", opts, { desc = "SearchEverywhere" }))

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
