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

      local java18 = vim.fn.trim(vim.fn.system("/usr/libexec/java_home -v 18 2>/dev/null"))
      if java18 == "" then java18 = "/Library/Java/JavaVirtualMachines/zulu-18.jdk/Contents/Home" end

      local cmd = {
        java18 .. "/bin/java",
        "-Declipse.application=org.eclipse.jdt.ls.core.id1",
        "-Dosgi.bundles.defaultStartLevel=4",
        "-Declipse.product=org.eclipse.jdt.ls.core.product",
        "-Dlog.protocol=true", "-Dlog.level=ALL",
        "-Xmx2g",
        "--add-modules=ALL-SYSTEM",
        "--add-opens", "java.base/java.util=ALL-UNNAMED",
        "--add-opens", "java.base/java.lang=ALL-UNNAMED",
        "-data", workspace_dir,
      }

      if vim.fn.filereadable(lombok_path) == 1 then
        table.insert(cmd, 2, "-javaagent:" .. lombok_path)
        table.insert(cmd, 3, "-Xbootclasspath/a:" .. lombok_path)
      end

      -- 让 mason 的 jdtls wrapper 处理 bundle 路径（更简单）
      -- 如果直接用 java 命令有问题，改用: cmd = { jdtls_bin }
      local config = {
        cmd = { jdtls_bin },
        root_dir = find_root(),
        settings = {
          java = {
            home = java18,
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
