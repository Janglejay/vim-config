return {
  { "williamboman/mason.nvim",
    build = ":MasonUpdate",
    config = function()
      require("mason").setup({
        ui = { border = "rounded", icons = { package_installed = "✓", package_pending = "➜", package_uninstalled = "✗" } },
      })
    end,
  },
  { "williamboman/mason-lspconfig.nvim",
    dependencies = "williamboman/mason.nvim",
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "pyright",
          "ts_ls",
          "vue_ls",
          "cssls",
          "emmet_ls",
        },
        automatic_installation = true,
      })

      local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
      local handlers = require("user.lsp.handlers")

      -- ── Python ──────────────────────────────────────────────────────────
      vim.lsp.config("pyright", {
        cmd = { mason_bin .. "/pyright-langserver", "--stdio" },
        filetypes = { "python" },
        root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
        settings = {
          python = { analysis = { autoSearchPaths = true, diagnosticMode = "openFilesOnly", typeCheckingMode = "basic" } },
        },
        on_attach = handlers.on_attach,
        capabilities = handlers.capabilities,
      })
      vim.lsp.enable("pyright")

      -- ── TypeScript / React ───────────────────────────────────────────────
      vim.lsp.config("ts_ls", {
        cmd = { mason_bin .. "/typescript-language-server", "--stdio" },
        filetypes = {
          "javascript", "javascriptreact", "javascript.jsx",
          "typescript", "typescriptreact", "typescript.tsx",
        },
        root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
        init_options = { hostInfo = "neovim" },
        on_attach = function(client, bufnr)
          -- 格式化交给 prettier（conform.nvim），禁用 ts_ls 自带格式化
          client.server_capabilities.documentFormattingProvider = false
          client.server_capabilities.documentRangeFormattingProvider = false
          handlers.on_attach(client, bufnr)
        end,
        capabilities = handlers.capabilities,
      })
      vim.lsp.enable("ts_ls")

      -- ── Vue 3（vue_ls / Vue Language Tools 2.x）─────────────────────────
      vim.lsp.config("vue_ls", {
        cmd = { mason_bin .. "/vue-language-server", "--stdio" },
        filetypes = { "vue" },
        root_markers = { "vue.config.js", "vue.config.ts", "vite.config.js", "vite.config.ts", "nuxt.config.ts", "package.json", ".git" },
        init_options = {
          vue = { hybridMode = false },
          typescript = {
            tsdk = (function()
              local local_ts = vim.fn.getcwd() .. "/node_modules/typescript/lib"
              if vim.fn.isdirectory(local_ts) == 1 then
                return local_ts
              end
              return vim.fn.stdpath("data") .. "/mason/packages/vue-language-server/node_modules/typescript/lib"
            end)(),
          },
        },
        on_attach = function(client, bufnr)
          client.server_capabilities.documentFormattingProvider = false
          handlers.on_attach(client, bufnr)
        end,
        capabilities = handlers.capabilities,
      })
      vim.lsp.enable("vue_ls")

      -- ── ESLint ───────────────────────────────────────────────────────────
      vim.lsp.config("eslint", {
        cmd = { mason_bin .. "/vscode-eslint-language-server", "--stdio" },
        filetypes = {
          "javascript", "javascriptreact", "javascript.jsx",
          "typescript", "typescriptreact", "typescript.tsx",
          "vue",
        },
        root_markers = { ".eslintrc", ".eslintrc.js", ".eslintrc.cjs", ".eslintrc.json", "eslint.config.js", "eslint.config.ts", "package.json", ".git" },
        settings = { workingDirectory = { mode = "auto" } },
        on_attach = function(client, bufnr)
          -- 无文件路径的 buffer（unnamed/scratch）跳过，避免 -32603 path undefined 错误
          if vim.api.nvim_buf_get_name(bufnr) == "" then
            vim.lsp.buf_detach_client(bufnr, client.id)
            return
          end
          client.server_capabilities.documentFormattingProvider = false
          handlers.on_attach(client, bufnr)
        end,
        capabilities = handlers.capabilities,
      })
      vim.lsp.enable("eslint")

      -- ── CSS / SCSS / Less ────────────────────────────────────────────────
      vim.lsp.config("cssls", {
        cmd = { mason_bin .. "/vscode-css-language-server", "--stdio" },
        filetypes = { "css", "scss", "less" },
        root_markers = { "package.json", ".git" },
        settings = {
          css  = { validate = true },
          scss = { validate = true },
          less = { validate = true },
        },
        on_attach = function(client, bufnr)
          client.server_capabilities.documentFormattingProvider = false
          handlers.on_attach(client, bufnr)
        end,
        capabilities = handlers.capabilities,
      })
      vim.lsp.enable("cssls")

      -- ── HTML ─────────────────────────────────────────────────────────────
      vim.lsp.config("html", {
        cmd = { mason_bin .. "/vscode-html-language-server", "--stdio" },
        filetypes = { "html" },
        root_markers = { "package.json", ".git" },
        init_options = { configurationSection = { "html", "css", "javascript" }, embeddedLanguages = { css = true, javascript = true } },
        on_attach = function(client, bufnr)
          client.server_capabilities.documentFormattingProvider = false
          handlers.on_attach(client, bufnr)
        end,
        capabilities = handlers.capabilities,
      })
      vim.lsp.enable("html")

      -- ── Emmet ────────────────────────────────────────────────────────────
      vim.lsp.config("emmet_ls", {
        cmd = { mason_bin .. "/emmet-language-server", "--stdio" },
        filetypes = {
          "html", "css", "scss", "javascriptreact", "typescriptreact", "vue",
        },
        root_markers = { "package.json", ".git" },
        on_attach = handlers.on_attach,
        capabilities = handlers.capabilities,
      })
      vim.lsp.enable("emmet_ls")

      -- ── Spring Boot Language Server ──────────────────────────────────────
      -- 安装：bash ~/.config/nvim/scripts/install-spring-boot-ls.sh
      -- 功能：Bean 导航、@RequestMapping 补全、application.yml 智能提示
      local sb_jar = vim.fn.expand("~/.local/share/nvim/spring-boot-ls/spring-boot-language-server.jar")
      if vim.fn.filereadable(sb_jar) == 1 then
        local java21 = vim.fn.trim(vim.fn.system("/usr/libexec/java_home -v 21 2>/dev/null"))
        if java21 == "" then java21 = "java" else java21 = java21 .. "/bin/java" end

        vim.lsp.config("spring_boot_ls", {
          cmd = { java21, "-jar", sb_jar, "--stdio" },
          filetypes = { "java", "yaml", "properties" },
          root_markers = { "pom.xml", "build.gradle", "mvnw", "gradlew", ".git" },
          -- 只处理 Spring Boot 项目（有 pom.xml 或 build.gradle 的目录）
          settings = {
            spring_boot = {
              ls = {
                checkJDKCompatibility = false,  -- 避免频繁弹出 JDK 不兼容警告
                java_home = java21:gsub("/bin/java$", ""),
              }
            }
          },
          on_attach = function(client, bufnr)
            -- Spring Boot LS 只做补全和导航，不做格式化/高亮
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentHighlightProvider  = false
            handlers.on_attach(client, bufnr)
          end,
          capabilities = handlers.capabilities,
        })
        vim.lsp.enable("spring_boot_ls")
      end
    end,
  },
  { "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-buffer", "hrsh7th/cmp-path", "hrsh7th/cmp-cmdline",
      "hrsh7th/cmp-nvim-lsp", "saadparwaiz1/cmp_luasnip",
      "L3MON4D3/LuaSnip", "rafamadriz/friendly-snippets",
    },
    config = function() require "user.cmp" end,
  },
  { "stevearc/conform.nvim", event = { "BufWritePre" }, config = function() require "user.lsp.conform" end },
  { "ray-x/lsp_signature.nvim", event = "LspAttach", opts = { bind = true, border = "rounded" } },
  { "tamago324/nlsp-settings.nvim", lazy = true },
}
