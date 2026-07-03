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
          async_or_timeout = 30000,   -- 30 秒（大型项目 jdtls 响应慢）
          jump_to_single_result = true,
        },
      })

      local opts = { noremap = true, silent = true }

      -- 向上遍历找最顶层聚合 pom.xml（多模块 Maven 项目支持）
      local function find_project_root()
        local path = vim.fs.root(0, { "pom.xml", "build.gradle", "mvnw", "gradlew" })
                  or vim.fn.getcwd()
        local parent = vim.fn.fnamemodify(path, ":h")
        while vim.fn.filereadable(parent .. "/pom.xml") == 1 do
          path   = parent
          parent = vim.fn.fnamemodify(path, ":h")
          if parent == path then break end
        end
        return path
      end

      -- <Leader>f: SearchEverywhere — ripgrep 搜 Java 类/接口/枚举/方法声明（即时，无 LSP 依赖）
      -- fzf 框里直接输入类名/方法名过滤；右侧预览定位到对应行
      vim.keymap.set("n", "<Leader>f", function()
        local root = find_project_root()
        local pat_type   = "-e '(class|interface|enum|@interface)\\s+\\w+'"
        local pat_method = "-e '\\s+(public|protected|private)\\s+\\S+\\s+\\w+\\s*\\('"
        local rg_cmd = string.format(
          "rg -tjava -n --no-heading --color never %s %s"
          .. " --glob '!*/target/*' --glob '!*/.git/*' %s",
          pat_type, pat_method, vim.fn.shellescape(root)
        )

        local entries, entry_map = {}, {}
        local handle = io.popen(rg_cmd .. " 2>/dev/null")
        if handle then
          for line in handle:lines() do
            local file, lnum, content = line:match("^(.+):(%d+):(.*)")
            if file and lnum and content then
              local fname = vim.fn.fnamemodify(file, ":~:.")
              local sym = content:match("[Cc]lass%s+(%w+)")
                or content:match("[Ii]nterface%s+(%w+)")
                or content:match("[Ee]num%s+(%w+)")
                or content:match("@interface%s+(%w+)")
                or content:match("%s(%w+)%s*%(")
                or "?"
              local kind = content:match("class") and "Class    "
                or content:match("interface") and "Interface"
                or content:match("enum") and "Enum     "
                or "Method   "
              local disp = string.format("%-40s %s  %s:%s", sym, kind, fname, lnum)
              table.insert(entries, disp)
              entry_map[disp] = { file = file, lnum = tonumber(lnum) }
            end
          end
          handle:close()
        end

        if #entries == 0 then
          fzf.files({ winopts = { title = " 未找到符号，退化为文件搜索 " } })
          return
        end

        fzf.fzf_exec(entries, {
          prompt  = "Symbol❯ ",
          winopts = {
            title   = string.format(" %d 个符号（类/接口/枚举/方法）", #entries),
            height  = 0.85, width = 0.92,
            preview = { layout = "vertical", vertical = "down:45%" },
          },
          previewer = "builtin",
          actions   = {
            ["default"] = function(sel)
              if not sel or not sel[1] then return end
              local info = entry_map[sel[1]]
              if info then
                vim.cmd("edit " .. vim.fn.fnameescape(info.file))
                pcall(vim.api.nvim_win_set_cursor, 0, { info.lnum, 0 })
                vim.cmd("normal! zz")
              end
            end,
          },
        })
      end, vim.tbl_extend("force", opts, { desc = "SearchEverywhere" }))

      -- <Leader>F: FindInPath（从项目根目录全文搜索）
      vim.keymap.set("n", "<Leader>F", function()
        fzf.live_grep({ cwd = find_project_root() })
      end, vim.tbl_extend("force", opts, { desc = "FindInPath" }))

      -- <Leader>e: RecentFiles
      vim.keymap.set("n", "<Leader>e", function() fzf.oldfiles({ cwd_only = true }) end,
        vim.tbl_extend("force", opts, { desc = "RecentFiles（当前项目）" }))

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

      -- gR: Call Hierarchy（lspsaga GUI 风格，可展开/折叠，彩色图标）
      vim.keymap.set("n", "gR", "<cmd>Lspsaga incoming_calls<CR>",
        vim.tbl_extend("force", opts, { desc = "CallHierarchy (lspsaga)" }))

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

  -- lspsaga: GUI 风格 LSP UI（主要用于 gR Call Hierarchy）
  {
    "nvimdev/lspsaga.nvim",
    event = "LspAttach",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("lspsaga").setup({
        -- 只配置 call hierarchy，其他功能不干扰已有快捷键
        callhierarchy = {
          layout = "float",       -- 浮窗形式，不侵占编辑区
          left_width = 0.3,       -- 调用链树占浮窗 30%，预览占 70%
          keys = {
            edit         = "<CR>",  -- 跳转到调用处
            vsplit       = "v",
            split        = "s",
            tabe         = "t",
            quit         = "q",
            close        = "q",
            toggle_or_req = "u",   -- u 展开/折叠节点
          },
        },
        -- 禁用会覆盖已有快捷键的功能
        ui = {
          border        = "rounded",
          devicon       = true,
          title         = true,
          expand        = "⊞",
          collapse      = "⊟",
          code_action   = "💡",
          diagnostic    = "🐛",
          incoming      = "󰏷 ",   -- 调用者图标
          outgoing      = "󰏻 ",   -- 被调用者图标
          hover         = "▣",
        },
        -- 关闭所有非 call hierarchy 的后台功能
        -- symbol_in_winbar 会后台轮询 buffer 符号，buffer 删除后崩溃
        symbol_in_winbar = { enable = false },
        lightbulb        = { enable = false },
        diagnostic       = { show_code_action = false },
        rename           = { in_select = false },
        outline          = { auto_preview = false },
        finder           = { default = "ref" },
        -- beacon 是导航高亮动画，关掉节省资源
        beacon           = { enable = false },
      })
    end,
  },

}
