return {
  {
    "mfussenegger/nvim-jdtls",
    ft = "java",
    config = function()
      local mason_path = vim.fn.stdpath("data") .. "/mason"
      local lombok_path = mason_path .. "/packages/jdtls/lombok.jar"
      local jdtls_bin = mason_path .. "/bin/jdtls"

      -- workspace 用项目名隔离
      local project_root = vim.fs.root(0, { "pom.xml", "build.gradle", ".git", "mvnw", "gradlew" }) or vim.fn.getcwd()
      local project_name = vim.fn.fnamemodify(project_root, ":t")
      local workspace_dir = vim.fn.stdpath("data") .. "/jdtls-workspace/" .. project_name

      -- 向上找最顶层聚合 pom.xml（多模块 Maven 支持）
      local function find_root()
        local path = project_root
        local parent = vim.fn.fnamemodify(path, ":h")
        while vim.fn.filereadable(parent .. "/pom.xml") == 1 do
          path = parent
          parent = vim.fn.fnamemodify(path, ":h")
          if parent == path then break end
        end
        return path
      end

      local java21 = vim.fn.trim(vim.fn.system("/usr/libexec/java_home -v 21 2>/dev/null"))
      if java21 == "" then java21 = "/Library/Java/JavaVirtualMachines/zulu-21.jdk/Contents/Home" end

      -- Mason 的 jdtls wrapper（Python 脚本）通过 JAVA_HOME 找 Java
      local config = {
        cmd = { jdtls_bin },
        cmd_env = { JAVA_HOME = java21 },
        root_dir = find_root(),
        settings = {
          java = {
            home = java21,
            eclipse = { downloadSources = true },
            configuration = { updateBuildConfiguration = "interactive" },
            maven = { downloadSources = true },
            implementationsCodeLens = { enabled = true },
            referencesCodeLens = { enabled = true },
            references = { includeDecompiledSources = true },
            format = { enabled = true },
            signatureHelp = { enabled = true },
            completion = {
              favoriteStaticMembers = {
                "org.junit.Assert.*", "org.junit.jupiter.api.Assertions.*", "org.mockito.Mockito.*",
              },
              importOrder = { "java", "javax", "com", "org" },
            },
            sources = { organizeImports = { starThreshold = 9999, staticStarThreshold = 9999 } },
            codeGeneration = { useBlocks = true },
          },
        },
        init_options = {
          bundles = {},
        },
        on_attach = function(client, bufnr)
          -- 调用原有 handlers 的 on_attach
          local ok, handlers = pcall(require, "user.lsp.handlers")
          if ok then handlers.on_attach(client, bufnr) end

          -- Java 专属快捷键
          local opts = { noremap = true, silent = true, buffer = bufnr }
          vim.keymap.set("n", "gu", function() require("jdtls").super_implementation() end,
            vim.tbl_extend("force", opts, { desc = "GotoSuperMethod" }))
          vim.keymap.set("n", "<Leader>T", function()
            vim.lsp.buf.code_action({ context = { only = { "refactor" } } })
          end, vim.tbl_extend("force", opts, { desc = "RefactoringGroup" }))
          vim.keymap.set("n", "<Leader>oi", function() require("jdtls").organize_imports() end,
            vim.tbl_extend("force", opts, { desc = "Organize Imports" }))

          -- DAP 集成（如果 nvim-dap 已加载）
          local dap_ok, _ = pcall(require, "dap")
          if dap_ok then
            require("jdtls").setup_dap({ hotcodereplace = "auto" })
          end

          -- 索引刷新快捷键（Java buffer 内有效）
          local o = { noremap = true, silent = true, buffer = bufnr }

          -- <Leader>jr: 软刷新（pom.xml 变更后同步，不删 workspace）
          vim.keymap.set("n", "<Leader>jr", function()
            require("jdtls").update_project_config()
            vim.notify("jdtls: 正在同步项目配置...", vim.log.levels.INFO)
          end, vim.tbl_extend("force", o, { desc = "jdtls: Reload project config" }))

          -- <Leader>jR: 全量重建索引（删除 workspace，重启 jdtls）
          vim.keymap.set("n", "<Leader>jR", function()
            local project_root = vim.fs.root(0, { "pom.xml", "build.gradle", ".git" })
                              or vim.fn.getcwd()
            local project_name = vim.fn.fnamemodify(project_root, ":t")
            local workspace    = vim.fn.stdpath("data") .. "/jdtls-workspace/" .. project_name

            vim.notify("jdtls: 正在清理 workspace，重建索引...", vim.log.levels.WARN)
            -- 停止当前 jdtls 客户端
            for _, client in ipairs(vim.lsp.get_clients({ name = "jdtls" })) do
              client.stop()
            end
            -- 删除 workspace
            vim.fn.delete(workspace, "rf")
            -- 延迟重新 attach（等 jdtls 完全停止）
            vim.defer_fn(function()
              vim.cmd("edit")
              vim.notify("jdtls: workspace 已清理，正在重新索引（需 1-3 分钟）", vim.log.levels.INFO)
            end, 1500)
          end, vim.tbl_extend("force", o, { desc = "jdtls: Full reindex (delete workspace)" }))
        end,
        capabilities = (function()
          local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
          if ok then return cmp_lsp.default_capabilities() end
          return vim.lsp.protocol.make_client_capabilities()
        end)(),
      }

      require("jdtls").start_or_attach(config)
    end,
  },
}
