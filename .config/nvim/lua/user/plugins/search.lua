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
        -- 查找支持 workspace/symbol 的客户端（jdtls，不限 bufnr）
        local sym_client = nil
        for _, c in ipairs(vim.lsp.get_clients()) do
          local wp = c.server_capabilities.workspaceSymbolProvider
          if wp ~= nil and wp ~= false then
            sym_client = c; break
          end
        end

        if sym_client then
          -- jdtls 就绪：一次性拉取所有符号，过滤 jdt:// 和 .m2（只显示项目源码）
          -- 使用 vim.lsp.buf_request_sync（client.request_sync 在 Neovim 0.12 废弃）
          local bufnr = vim.api.nvim_get_current_buf()
          local was_attached = vim.lsp.buf_is_attached(bufnr, sym_client.id)
          if not was_attached then
            pcall(vim.lsp.buf_attach_client, bufnr, sym_client.id)
          end

          local raw = vim.lsp.buf_request_sync(bufnr, "workspace/symbol", { query = "" }, 8000)

          if not was_attached then
            pcall(vim.lsp.buf_detach_client, bufnr, sym_client.id)
          end

          -- buf_request_sync 返回 { [client_id] = { result = {...} } }
          local all_symbols = {}
          if raw then
            for _, res in pairs(raw) do
              if res.result then vim.list_extend(all_symbols, res.result) end
            end
          end

          if #all_symbols == 0 then fzf.files(); return end

          local entries, entry_map = {}, {}
          local icons = {
            [2]="󰆧 Mthd",[3]="󰊕 Func",[4]=" Ctor",
            [5]="󰜢 Field",[6]="󰀫 Var",[7]="󰠱 Class",
            [8]="󰜰 Intf",[13]="󰋺 Enum",
          }
          local m2 = vim.fn.expand("~") .. "/.m2/"

          for _, sym in ipairs(all_symbols) do
            local uri = (sym.location or {}).uri or ""
            -- 跳过 jdt://（JAR 包内的类）和 .m2（Maven 本地仓库）
            if not uri:match("^jdt://") and not uri:find(m2, 1, true) then
              local path  = vim.uri_to_fname(uri)
              local lnum  = ((sym.location.range or {}).start or {}).line or 0
              local fname = vim.fn.fnamemodify(path, ":~:.")
              local icon  = icons[sym.kind] or "󰙐 Sym "
              local disp  = string.format("%-50s %-10s %s:%d",
                sym.name, icon, fname, lnum + 1)
              table.insert(entries, disp)
              entry_map[disp] = { file = path, lnum = lnum + 1 }
            end
          end

          if #entries == 0 then fzf.files(); return end

          fzf.fzf_exec(entries, {
            prompt  = "SearchEverywhere❯ ",
            winopts = {
              title   = string.format(" 项目符号 %d 个（已过滤 JAR/Maven）", #entries),
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
        else
          -- jdtls 未就绪：用 ripgrep 直接搜索 Java 类/方法定义（秒级响应，无需 LSP）
          if _G.start_jdtls_for_project then _G.start_jdtls_for_project() end

          local root = vim.fs.root(0, { "pom.xml", "build.gradle", ".git" }) or vim.fn.getcwd()
          -- rg 搜索 Java 类/接口/枚举/方法声明行
          -- 模式匹配：class Foo | interface Bar | enum Baz | public/private void method(
          local rg_cmd = string.format(
            "rg --type java -n --no-heading --color never "
            .. [[-e '^\s*(public|protected|private)?\s*(static\s+)?(final\s+)?(class|interface|enum|@interface)\s+\w+' ]]
            .. [[-e '^\s+(public|protected|private)\s+(static\s+)?(final\s+)?[\w<>\[\]]+\s+\w+\s*\(' ]]
            .. "--glob '!*/target/*' --glob '!*/.git/*' %s",
            vim.fn.shellescape(root)
          )

          local entries, entry_map = {}, {}
          local handle = io.popen(rg_cmd .. " 2>/dev/null")
          if handle then
            for line in handle:lines() do
              local file, lnum, content = line:match("^(.+):(%d+):(.*)")
              if file and lnum and content then
                local fname = vim.fn.fnamemodify(file, ":~:.")
                -- 提取符号名（class/interface/method 名）
                local sym = content:match("[Cc]lass%s+(%w+)")
                  or content:match("[Ii]nterface%s+(%w+)")
                  or content:match("[Ee]num%s+(%w+)")
                  or content:match("(@interface%s+)(%w+)")
                  or content:match("%s(%w+)%s*%(")
                  or "?"
                local kind = content:match("class") and "Class"
                  or content:match("interface") and "Interface"
                  or content:match("enum") and "Enum"
                  or "Method"
                local disp = string.format("%-40s %-9s %s:%s", sym, kind, fname, lnum)
                table.insert(entries, disp)
                entry_map[disp] = { file = file, lnum = tonumber(lnum) }
              end
            end
            handle:close()
          end

          if #entries > 0 then
            fzf.fzf_exec(entries, {
              prompt  = "SearchEverywhere (rg)❯ ",
              winopts = {
                title   = string.format(" rg 模式 %d 个符号（jdtls 未就绪时的备用）", #entries),
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
          else
            fzf.files({ winopts = { title = " Files (等 ✓ jdtls 后可搜符号) " } })
          end
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
