return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "theHamsta/nvim-dap-virtual-text",
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      -- DAP UI 设置
      dapui.setup({
        icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
        mappings = { expand = { "<CR>", "<2-LeftMouse>" }, open = "o", remove = "d" },
        layouts = {
          {
            elements = {
              { id = "scopes",      size = 0.25 },
              { id = "breakpoints", size = 0.25 },
              { id = "stacks",      size = 0.25 },
              { id = "watches",     size = 0.25 },
            },
            position = "left",
            size = 40,
          },
          {
            elements = {
              { id = "repl",    size = 0.5 },
              { id = "console", size = 0.5 },
            },
            position = "bottom",
            size = 10,
          },
        },
      })

      -- 行内虚拟文本（显示变量值）
      require("nvim-dap-virtual-text").setup({ commented = true, virt_text_pos = "eol" })

      -- 自动开关 DAP UI
      dap.listeners.after.event_initialized["dapui_config"]  = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui_config"]  = function() dapui.close() end
      dap.listeners.before.event_exited["dapui_config"]      = function() dapui.close() end

      -- 断点样式
      vim.fn.sign_define("DapBreakpoint",          { text = "●",  texthl = "DiagnosticError" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "◐",  texthl = "DiagnosticWarn" })
      vim.fn.sign_define("DapStopped",             { text = "▶",  texthl = "DiagnosticInfo", linehl = "DiffAdd" })

      local o = { noremap = true, silent = true }

      -- bb: ToggleLineBreakpoint
      vim.keymap.set("n", "bb", dap.toggle_breakpoint,
        vim.tbl_extend("force", o, { desc = "ToggleBreakpoint" }))

      -- br: Resume（Continue）
      vim.keymap.set("n", "br", dap.continue,
        vim.tbl_extend("force", o, { desc = "Resume" }))

      -- bp: PopFrame（StepOut）
      vim.keymap.set("n", "bp", dap.step_out,
        vim.tbl_extend("force", o, { desc = "PopFrame/StepOut" }))

      -- bv: ViewBreakpoints（打开左侧面板）
      vim.keymap.set("n", "bv", function() dapui.open({ layout = 1 }) end,
        vim.tbl_extend("force", o, { desc = "ViewBreakpoints" }))

      -- bf: RunToCursor
      vim.keymap.set("n", "bf", dap.run_to_cursor,
        vim.tbl_extend("force", o, { desc = "RunToCursor" }))

      -- bi: StepInto
      vim.keymap.set("n", "bi", dap.step_into,
        vim.tbl_extend("force", o, { desc = "StepInto" }))

      -- bn: StepOver
      vim.keymap.set("n", "bn", dap.step_over,
        vim.tbl_extend("force", o, { desc = "StepOver" }))

      -- be: Evaluate Expression
      vim.keymap.set("n", "be", function() dapui.eval(nil, { enter = true }) end,
        vim.tbl_extend("force", o, { desc = "EvaluateExpression" }))

      -- sd: Toggle DAP UI（ActivateDebugToolWindow）
      vim.keymap.set("n", "sd", dapui.toggle,
        vim.tbl_extend("force", o, { desc = "ToggleDebugUI" }))

      -- bc: 条件断点（额外扩展）
      vim.keymap.set("n", "bc", function()
        dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
      end, vim.tbl_extend("force", o, { desc = "ConditionalBreakpoint" }))

      -- 远程 attach 配置（Spring Boot 远程调试）
      dap.configurations.java = dap.configurations.java or {}
      table.insert(dap.configurations.java, {
        type     = "java",
        request  = "attach",
        name     = "Remote Debug (Attach)",
        hostName = function() return vim.fn.input("Host [127.0.0.1]: ", "127.0.0.1") end,
        port     = function() return tonumber(vim.fn.input("Port [5005]: ", "5005")) or 5005 end,
      })
    end,
  },
}
