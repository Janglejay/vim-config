return {
  {
    "mfussenegger/nvim-jdtls",
    ft = "java",
    config = function()
      local mason_path = vim.fn.stdpath("data") .. "/mason"
      local lombok_path = mason_path .. "/packages/jdtls/lombok.jar"
      local jdtls_bin   = mason_path .. "/bin/jdtls"

      -- 向上找最顶层聚合 pom.xml（多模块 Maven 支持）
      -- 只用 pom.xml/build.gradle 作为根标记，.git 可能跨多个子项目导致误判
      local function find_root()
        local start = vim.fn.getcwd()
        local path  = vim.fs.root(0, { "pom.xml", "build.gradle", "mvnw", "gradlew" }) or start
        local parent = vim.fn.fnamemodify(path, ":h")
        while vim.fn.filereadable(parent .. "/pom.xml") == 1 do
          path   = parent
          parent = vim.fn.fnamemodify(path, ":h")
          if parent == path then break end
        end
        return path
      end

      local project_root = find_root()
      local project_name = vim.fn.fnamemodify(project_root, ":t")

      local java21 = vim.fn.trim(vim.fn.system("/usr/libexec/java_home -v 21 2>/dev/null"))
      if java21 == "" then java21 = "/Library/Java/JavaVirtualMachines/zulu-21.jdk/Contents/Home" end

      -- Lombok: -javaagent 让注解处理器运行，识别 @Data/@Getter/@Setter
      -- Java 21 已废弃 -Xbootclasspath/a，只需 -javaagent
      local cmd = { jdtls_bin }
      if vim.fn.filereadable(lombok_path) == 1 then
        table.insert(cmd, "--jvm-arg=-javaagent:" .. lombok_path)
      end

      -- capabilities 复用 handlers.lua 里已配置好的，避免重复
      local handlers_ok, handlers = pcall(require, "user.lsp.handlers")
      local caps = handlers_ok and handlers.capabilities
               or vim.lsp.protocol.make_client_capabilities()

      local config = {
        cmd     = cmd,
        cmd_env = { JAVA_HOME = java21 },
        root_dir = project_root,

        settings = {
          java = {
            home          = java21,
            maven         = { downloadSources = true },   -- eclipse.downloadSources 与此重复，移除
            configuration = { updateBuildConfiguration = "interactive" },
            references    = { includeDecompiledSources = true },
            format        = { enabled = true },
            signatureHelp = { enabled = true },
            -- CodeLens 在大项目性能开销明显，建议按需开启
            implementationsCodeLens = { enabled = false },
            referencesCodeLens      = { enabled = false },
            completion = {
              favoriteStaticMembers = {
                "org.junit.Assert.*",
                "org.junit.jupiter.api.Assertions.*",
                "org.mockito.Mockito.*",
              },
              importOrder = { "java", "javax", "com", "org" },
            },
            sources      = { organizeImports = { starThreshold = 9999, staticStarThreshold = 9999 } },
            codeGeneration = { useBlocks = true },
          },
        },

        init_options = { bundles = {} },
        capabilities = caps,

        on_attach = function(client, bufnr)
          if handlers_ok then handlers.on_attach(client, bufnr) end

          -- Java 专属快捷键（统一用 o，不重复定义）
          local o = { noremap = true, silent = true, buffer = bufnr }

          vim.keymap.set("n", "gu", function()
            require("jdtls").super_implementation()
          end, vim.tbl_extend("force", o, { desc = "GotoSuperMethod" }))

          vim.keymap.set("n", "<Leader>T", function()
            vim.lsp.buf.code_action({ context = { only = { "refactor" } } })
          end, vim.tbl_extend("force", o, { desc = "RefactoringGroup" }))

          vim.keymap.set("n", "<Leader>oi", function()
            require("jdtls").organize_imports()
          end, vim.tbl_extend("force", o, { desc = "Organize Imports" }))

          -- DAP 集成
          if pcall(require, "dap") then
            require("jdtls").setup_dap({ hotcodereplace = "auto" })
          end

          -- ── 索引管理 ────────────────────────────────────────────
          -- 软刷新（pom.xml 依赖变更后同步，不删 workspace）
          vim.keymap.set("n", "<Leader>jr", function()
            require("jdtls").update_project_config()
            vim.notify("jdtls: 正在同步项目配置...", vim.log.levels.INFO)
          end, vim.tbl_extend("force", o, { desc = "jdtls: Reload project config" }))

          -- 全量重建（删 workspace 重启，首次约 1-3 分钟）
          vim.keymap.set("n", "<Leader>jR", function()
            local root      = vim.fs.root(0, { "pom.xml", "build.gradle", ".git" }) or vim.fn.getcwd()
            local name      = vim.fn.fnamemodify(root, ":t")
            local workspace = vim.fn.stdpath("data") .. "/jdtls-workspace/" .. name

            -- 安全检查：只删含 jdtls-workspace 的路径，防止路径拼接错误
            if not workspace:match("jdtls%-workspace") then
              vim.notify("jdtls: 路径异常，拒绝删除: " .. workspace, vim.log.levels.ERROR)
              return
            end

            vim.notify("jdtls: 清理 workspace，重建索引...", vim.log.levels.WARN)
            for _, c in ipairs(vim.lsp.get_clients({ name = "jdtls" })) do c.stop() end
            vim.fn.delete(workspace, "rf")
            -- 在 defer_fn 里重新计算 config，避免 Lua GC 在 jdtls stop 后
            -- 回收 closure 里的 config 变量（jdtls stop 会释放对 config 的引用，
            -- 触发 GC，导致 "config is required" 错误）
            vim.defer_fn(function()
              local mp   = vim.fn.stdpath("data") .. "/mason"
              local bin  = mp .. "/bin/jdtls"
              local lok  = mp .. "/packages/jdtls/lombok.jar"
              local j21  = vim.fn.trim(vim.fn.system("/usr/libexec/java_home -v 21 2>/dev/null"))
              if j21 == "" then j21 = "/Library/Java/JavaVirtualMachines/zulu-21.jdk/Contents/Home" end
              local rc = { bin }
              if vim.fn.filereadable(lok) == 1 then
                table.insert(rc, "--jvm-arg=-javaagent:" .. lok)
              end
              require("jdtls").start_or_attach({
                cmd      = rc,
                cmd_env  = { JAVA_HOME = j21 },
                root_dir = root,
              })
              vim.notify("jdtls: 重建中（等状态栏变 ✓）", vim.log.levels.INFO)
            end, 1500)
          end, vim.tbl_extend("force", o, { desc = "jdtls: Full reindex" }))
        end,
      }

      require("jdtls").start_or_attach(config)
    end,
  },
}
