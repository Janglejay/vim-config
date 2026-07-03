return {
  -- Treesitter 核心（新版 API：只管解析器安装，高亮由 Neovim 原生处理）
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("nvim-treesitter").setup()

      -- 新版 nvim-treesitter 不再自动为 buffer 启动 treesitter 解析树。
      -- 必须手动调用 vim.treesitter.start()，否则 J/K textobjects 查询无解析树可用。
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          pcall(vim.treesitter.start, args.buf)
        end,
      })

      -- 确保常用解析器已安装（异步）
      vim.defer_fn(function()
        pcall(function()
          require("nvim-treesitter.install").install({
            "java", "lua", "python", "rust", "go",
            "json", "yaml", "toml", "xml", "markdown", "bash",
            "typescript", "javascript", "tsx", "vue", "css", "html",
          })
        end)
      end, 100)
    end,
  },

  -- nvim-treesitter-textobjects（新版 API）
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      -- 全局选项
      require("nvim-treesitter-textobjects").setup({
        move   = { set_jumps = true },
        select = { lookahead = true },
      })

      local move = require("nvim-treesitter-textobjects.move")
      local o    = { noremap = true, silent = true }

      -- 跳转后定位到方法名/类名的 identifier 节点
      local function land_on_name()
        vim.schedule(function()
          local row, col = unpack(vim.api.nvim_win_get_cursor(0))
          local node = vim.treesitter.get_node({ pos = { row - 1, col } })
          while node do
            local t = node:type()
            if vim.tbl_contains({
              -- Java
              "method_declaration", "constructor_declaration",
              "class_declaration", "interface_declaration", "enum_declaration",
              -- JS/TS/Vue
              "function_declaration", "method_definition",
              "arrow_function", "function_expression",
              "class_declaration",
            }, t) then
              -- 找第一个 identifier 子节点（方法名/类名）
              for i = 0, node:named_child_count() - 1 do
                local child = node:named_child(i)
                if child and child:type() == "identifier" then
                  local r, c = child:start()
                  vim.api.nvim_win_set_cursor(0, { r + 1, c })
                  return
                end
              end
            end
            node = node:parent()
          end
        end)
      end

      -- 对每个 query 试跳一次，只接受方向正确的目标，返回其中最近的
      local function best_target(direction, queries)
        local before = vim.api.nvim_win_get_cursor(0)
        local best   = nil

        local function in_direction(pos)
          if direction == "next" then
            return pos[1] > before[1] or (pos[1] == before[1] and pos[2] > before[2])
          else
            return pos[1] < before[1] or (pos[1] == before[1] and pos[2] < before[2])
          end
        end

        local function closer(pos, cur)
          if direction == "next" then
            return pos[1] < cur[1] or (pos[1] == cur[1] and pos[2] < cur[2])
          else
            return pos[1] > cur[1] or (pos[1] == cur[1] and pos[2] > cur[2])
          end
        end

        for _, q in ipairs(queries) do
          vim.api.nvim_win_set_cursor(0, before)
          pcall(function()
            if direction == "next" then move.goto_next_start(q)
            else                       move.goto_previous_start(q) end
          end)
          local pos = vim.api.nvim_win_get_cursor(0)
          if in_direction(pos) and (best == nil or closer(pos, best)) then
            best = pos
          end
        end

        vim.api.nvim_win_set_cursor(0, before)
        return best
      end

      -- 返回光标所在的最近一层方法/类的开头（如果光标已经在开头则返回 nil）
      -- K 用这个来"跳出"当前方法，避免原地跳自己
      local node_types = {
        "method_declaration", "constructor_declaration",
        "class_declaration", "interface_declaration", "enum_declaration",
        "function_declaration", "method_definition", "arrow_function", "function_expression",
      }
      local function containing_start()
        local row, col = unpack(vim.api.nvim_win_get_cursor(0))
        local node = vim.treesitter.get_node({ pos = { row - 1, col } })
        while node do
          if vim.tbl_contains(node_types, node:type()) then
            local sr, sc = node:start()
            -- 只有光标不在该节点开头时才返回（在开头说明已经是目标，不需要排除）
            if sr + 1 ~= row or sc ~= col then
              return { sr + 1, sc }
            end
          end
          node = node:parent()
        end
        return nil
      end

      -- J/K: 按文档顺序访问类声明 + 方法/构造方法，光标落在名字上
      local function jump(direction)
        local saved = vim.api.nvim_win_get_cursor(0)
        local from  = saved

        if direction == "prev" then
          -- K: 如果光标在方法/类内部（非开头），先移到该方法开头再找上一个
          -- 否则 goto_previous_start 会把自己当"上一个"，感觉上没动
          local cs = containing_start()
          if cs then from = cs end
        end

        vim.api.nvim_win_set_cursor(0, from)
        local target = best_target(direction, { "@function.outer", "@class.outer" })
        vim.api.nvim_win_set_cursor(0, saved)   -- 先还原，再跳到 target

        if target then
          vim.api.nvim_win_set_cursor(0, target)
          land_on_name()
        end
      end

      -- J: MethodDown
      vim.keymap.set("n", "J", function() jump("next") end,
        vim.tbl_extend("force", o, { desc = "MethodDown" }))

      -- K: MethodUp（全局映射；buffer-local 覆盖由 autocommands.lua LspAttach 保证）
      vim.keymap.set("n", "K", function() jump("prev") end,
        vim.tbl_extend("force", o, { desc = "MethodUp" }))

      -- 暴露给 autocommands.lua 在 LspAttach 时重设 buffer-local K
      _G._nvim_method_jump = jump

      -- 文本对象（select 模式）
      local select = require("nvim-treesitter-textobjects.select")
      local sel_o  = { noremap = true, silent = true }

      local textobjects = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
        ["aa"] = "@parameter.outer",
        ["ia"] = "@parameter.inner",
      }
      for key, query in pairs(textobjects) do
        vim.keymap.set({ "x", "o" }, key, function()
          select.select_textobject(query, "textobjects")
        end, sel_o)
      end
    end,
  },

  -- flash.nvim: AceJump 替代（f/F）
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
      modes = {
        char = { enabled = false },
      },
    },
    keys = {
      { "f", mode = { "n", "x", "o" }, function() require("flash").jump() end,       desc = "AceAction (Flash Jump)" },
      { "F", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "AceTargetAction (Flash Treesitter)" },
    },
  },

  -- nvim-ts-context-commentstring（注释上下文感知）
  {
    "JoosepAlviste/nvim-ts-context-commentstring",
    lazy = true,
  },

  {
    "windwp/nvim-ts-autotag",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("nvim-ts-autotag").setup({
        opts = {
          enable_close = true,
          enable_rename = true,
          enable_close_on_slash = true,
        },
      })
    end,
  },
}
