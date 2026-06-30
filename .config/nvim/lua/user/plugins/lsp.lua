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
          "volar",
          "eslint",
          "cssls",
          "html",
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

      -- ── Vue 3（Volar）────────────────────────────────────────────────────
      vim.lsp.config("volar", {
        cmd = { mason_bin .. "/vue-language-server", "--stdio" },
        filetypes = { "vue" },
        root_markers = { "vue.config.js", "vue.config.ts", "vite.config.js", "vite.config.ts", "nuxt.config.ts", "package.json", ".git" },
        init_options = {
          vue = { hybridMode = false },
          typescript = {
            -- 优先使用项目本地 typescript，找不到则用 mason 安装的
            tsdk = (function()
              local local_ts = vim.fn.getcwd() .. "/node_modules/typescript/lib"
              if vim.fn.isdirectory(local_ts) == 1 then
                return local_ts
              end
              return vim.fn.stdpath("data") .. "/mason/packages/typescript-language-server/node_modules/typescript/lib"
            end)(),
          },
        },
        on_attach = function(client, bufnr)
          client.server_capabilities.documentFormattingProvider = false
          handlers.on_attach(client, bufnr)
        end,
        capabilities = handlers.capabilities,
      })
      vim.lsp.enable("volar")

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
          -- eslint 不提供格式化，只做诊断
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
        on_attach = handlers.on_attach,
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
