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
      })

      local opts = { noremap = true, silent = true }

      -- <Leader>f: SearchEverywhere
      vim.keymap.set("n", "<Leader>f", function() fzf.files() end,
        vim.tbl_extend("force", opts, { desc = "SearchEverywhere" }))

      -- <Leader>F: FindInPath
      vim.keymap.set("n", "<Leader>F", function() fzf.live_grep() end,
        vim.tbl_extend("force", opts, { desc = "FindInPath" }))

      -- <Leader>e: RecentFiles
      vim.keymap.set("n", "<Leader>e", function() fzf.oldfiles() end,
        vim.tbl_extend("force", opts, { desc = "RecentFiles" }))

      -- gr: FindUsages（默认过滤 Maven .m2 依赖，在 fzf 里删掉 "!.m2" 可看全部）
      vim.keymap.set("n", "gr", function()
        fzf.lsp_references({
          fzf_opts = { ["--query"] = "!.m2" },
          winopts   = { title = " FindUsages (! to show Maven) " },
        })
      end, vim.tbl_extend("force", opts, { desc = "FindUsages" }))

      -- gi: GotoImplementation
      vim.keymap.set("n", "gi", function() fzf.lsp_implementations() end,
        vim.tbl_extend("force", opts, { desc = "GotoImplementation" }))

      -- gR: CallHierarchy（递归调用链，最多 4 层）
      vim.keymap.set("n", "gR", function()
        -- Step1: 获取光标处的 CallHierarchyItem
        local params = vim.lsp.util.make_position_params()
        local prepare = vim.lsp.buf_request_sync(
          0, "textDocument/prepareCallHierarchy", params, 3000)

        if not prepare then
          vim.notify("jdtls 未响应，请等待索引完成后重试", vim.log.levels.WARN)
          return
        end

        local root_items = {}
        for _, res in pairs(prepare) do
          if res.result then vim.list_extend(root_items, res.result) end
        end
        if #root_items == 0 then
          vim.notify("光标处找不到可调用的符号（需在方法声明行上）", vim.log.levels.WARN)
          return
        end

        -- Step2: 递归找调用者
        local entries   = {}
        local entry_map = {}
        local visited   = {}

        local function find_callers(item, depth)
          if depth > 4 then return end
          local key = item.uri .. ":" .. tostring(item.range.start.line)
          if visited[key] then return end
          visited[key] = true

          local res = vim.lsp.buf_request_sync(
            0, "callHierarchy/incomingCalls", { item = item }, 3000)
          if not res then return end

          for _, r in pairs(res) do
            for _, call in ipairs(r.result or {}) do
              local caller = call.from
              local path   = vim.uri_to_fname(caller.uri)
              local lnum   = caller.selectionRange.start.line + 1
              local is_m2  = path:find("/.m2/", 1, true) ~= nil
              local indent = string.rep("  ", depth)
              local tag    = is_m2 and " [Maven]" or ""
              local display = string.format("%s← %s  %s:%d%s",
                indent, caller.name, vim.fn.fnamemodify(path, ":t"), lnum, tag)

              table.insert(entries, display)
              entry_map[display] = { file = path, lnum = lnum }
              find_callers(caller, depth + 1)
            end
          end
        end

        find_callers(root_items[1], 0)

        if #entries == 0 then
          vim.notify("没有找到调用者（项目可能还在索引中）", vim.log.levels.INFO)
          return
        end

        fzf.fzf_exec(entries, {
          prompt  = "Call Hierarchy❯ ",
          winopts = {
            title  = " gR Call Hierarchy (↑ = caller, indent = depth) ",
            height = 0.7, width = 0.85,
          },
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
      end, vim.tbl_extend("force", opts, { desc = "CallHierarchy (recursive)" }))

      -- qi: QuickImplementations
      vim.keymap.set("n", "qi", function() fzf.lsp_implementations() end,
        vim.tbl_extend("force", opts, { desc = "QuickImplementations" }))

      -- ma: ShowBookmarks
      vim.keymap.set("n", "ma", "<cmd>BookmarkShowAll<CR>",
        vim.tbl_extend("force", opts, { desc = "ShowBookmarks" }))
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

  -- vim-bookmarks（供 ma 使用）
  { "MattesGroeger/vim-bookmarks", event = "BufReadPost" },
}
