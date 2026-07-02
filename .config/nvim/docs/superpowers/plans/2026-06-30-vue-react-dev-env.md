# Vue/React 开发环境 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在现有 Neovim 0.12 配置基础上，添加 Vue 3 + React/TypeScript 完整开发支持（LSP、Treesitter、自动闭合标签、格式化）。

**Architecture:** 复用现有的 `vim.lsp.config` 原生 API（Neovim 0.11+ 风格），在 `plugins/lsp.lua` 里追加 LSP 配置；在 `plugins/editing.lua` 里追加 treesitter parsers 和 nvim-ts-autotag；在 `lsp/conform.lua` 里追加 prettier。不引入 `nvim-lspconfig` 包，保持与现有 pyright 配置完全一致的风格。

**Tech Stack:** Neovim 0.12.3, lazy.nvim, mason.nvim, vim.lsp.config（native），nvim-treesitter，conform.nvim，prettier，ts_ls，volar，eslint，cssls，html，emmet_ls，nvim-ts-autotag

## Global Constraints

- Neovim 版本：0.12.3，使用 `vim.lsp.config` / `vim.lsp.enable` 原生 API，禁止使用 `require("lspconfig")`
- 现有 mason_bin 路径：`vim.fn.stdpath("data") .. "/mason/bin"`
- 格式化统一由 conform.nvim 管理，LSP 服务器的 documentFormattingProvider 需关闭（ts_ls、eslint）
- on_attach 定义在 `lua/user/lsp/handlers.lua` 的 `M.on_attach`，LSP 配置里引用它
- 所有插件 spec 通过 `lua/user/plugins/` 模块聚合，不修改 init.lua

---

## Task 1: Treesitter 解析器 + nvim-ts-autotag

**Files:**
- Modify: `~/.config/nvim/lua/user/plugins/editing.lua`

**Interfaces:**
- Produces: Vue/TS/TSX/JS/JSX/CSS/HTML treesitter 语法高亮和文本对象；HTML/JSX/Vue 标签自动关闭

- [ ] **Step 1: 在 editing.lua 的 treesitter install 列表里追加前端语言解析器**

找到 `editing.lua` 中的 `install({ ... })` 调用，把原来的列表：
```lua
"java", "lua", "python", "rust", "go",
"json", "yaml", "toml", "xml", "markdown", "bash",
```
替换为：
```lua
"java", "lua", "python", "rust", "go",
"json", "yaml", "toml", "xml", "markdown", "bash",
"typescript", "javascript", "tsx", "vue", "css", "html",
```

- [ ] **Step 2: 在 editing.lua 末尾的 return 列表里追加 nvim-ts-autotag**

在 `return {` 的最后一个插件（nvim-ts-context-commentstring）之后、`}` 之前，追加：
```lua
-- nvim-ts-autotag: Vue/JSX/HTML 标签自动关闭和重命名
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
```

- [ ] **Step 3: 打开 Neovim 验证安装**

```bash
nvim --headless -c "TSUpdate" -c "sleep 5" -c "qa" 2>&1 | tail -5
```
预期：无报错；打开 `test.tsx` 文件后 `:TSBufInfo` 可见 typescript / tsx parser。

- [ ] **Step 4: 提交**

```bash
cd ~/.config/nvim
git add lua/user/plugins/editing.lua
git commit -m "feat(treesitter): add vue/ts/tsx/js/css/html parsers + nvim-ts-autotag"
```

---

## Task 2: LSP 服务器配置（ts_ls + volar + eslint + cssls + html + emmet_ls）

**Files:**
- Modify: `~/.config/nvim/lua/user/plugins/lsp.lua`

**Interfaces:**
- Consumes: `M.on_attach` from `user.lsp.handlers`，`M.capabilities` from `user.lsp.handlers`
- Produces: 在 `.vue` / `.ts` / `.tsx` / `.js` / `.jsx` / `.css` / `.html` 文件中提供 LSP 智能补全、跳转、诊断

- [ ] **Step 1: 在 lsp.lua 的 mason-lspconfig config 函数里更新 ensure_installed，并添加所有前端 LSP 配置**

把 `mason-lspconfig.nvim` 的 `config` 函数完整替换为以下内容：

```lua
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
```

- [ ] **Step 2: 打开 Neovim 让 Mason 自动安装服务器**

```bash
nvim --headless -c "MasonUpdate" -c "sleep 3" -c "qa" 2>&1
# 然后手动启动 nvim，执行 :MasonInstall ts_ls volar eslint cssls html emmet_ls
```

实际验证：打开一个 `.ts` 文件，执行 `:LspInfo`，确认 `ts_ls` 已附加。

- [ ] **Step 3: 提交**

```bash
cd ~/.config/nvim
git add lua/user/plugins/lsp.lua
git commit -m "feat(lsp): add ts_ls, volar, eslint, cssls, html, emmet_ls for vue/react"
```

---

## Task 3: 修复 handlers.lua 的 on_attach（兼容 ts_ls 新名称）

**Files:**
- Modify: `~/.config/nvim/lua/user/lsp/handlers.lua`

**Interfaces:**
- Consumes: `client.name` from LSP attach event
- Produces: `M.on_attach` 正确处理 ts_ls（不再检查已废弃的 `tsserver` 名称）

- [ ] **Step 1: 更新 on_attach 里的 client.name 判断**

找到 `handlers.lua` 中的：
```lua
M.on_attach = function(client, bufnr)
  if client.name == "tsserver" then
    client.server_capabilities.documentFormattingProvider = false
  end
  lsp_keymaps(bufnr)
  lsp_highlight_document(client)
end
```

替换为（ts_ls 的格式化已在 Task 2 的 on_attach wrapper 里关闭，这里直接去掉冗余判断）：
```lua
M.on_attach = function(client, bufnr)
  lsp_keymaps(bufnr)
  lsp_highlight_document(client)
end
```

- [ ] **Step 2: 验证**

打开任意 `.ts` 文件，执行 `:lua vim.print(vim.lsp.get_clients({bufnr=0}))` 确认 ts_ls 已附加，且无 Lua error。

- [ ] **Step 3: 提交**

```bash
cd ~/.config/nvim
git add lua/user/lsp/handlers.lua
git commit -m "fix(lsp): remove obsolete tsserver name check from on_attach"
```

---

## Task 4: conform.nvim 添加 Prettier 格式化

**Files:**
- Modify: `~/.config/nvim/lua/user/lsp/conform.lua`

**Interfaces:**
- Produces: 保存 `.vue` / `.ts` / `.tsx` / `.js` / `.jsx` / `.css` / `.html` 文件时自动用 prettier 格式化

- [ ] **Step 1: 在 conform.lua 的 formatters_by_ft 里追加前端格式化**

找到：
```lua
formatters_by_ft = {
  python = { "black", "isort", "ruff_format" },
  java = { "google-java-format" },
  lua = { "stylua" },
  json = { "jq" },
  yaml = { "yamlfmt" },
},
```

替换为：
```lua
formatters_by_ft = {
  python = { "black", "isort", "ruff_format" },
  java = { "google-java-format" },
  lua = { "stylua" },
  json = { "jq" },
  yaml = { "yamlfmt" },
  -- 前端：统一用 prettier
  javascript      = { "prettier" },
  javascriptreact = { "prettier" },
  typescript      = { "prettier" },
  typescriptreact = { "prettier" },
  vue             = { "prettier" },
  css             = { "prettier" },
  scss            = { "prettier" },
  html            = { "prettier" },
},
```

- [ ] **Step 2: 确保 prettier 已安装（Mason 或全局 npm）**

```bash
# 优先用 Mason 安装
nvim --headless -c "MasonInstall prettier" -c "sleep 5" -c "qa" 2>&1
# 或全局安装（二选一）
npm install -g prettier
```

验证：在 Neovim 中打开 `.ts` 文件，执行 `<leader>f` 或 `:lua require("conform").format()`，文件应按 prettier 规范格式化。

- [ ] **Step 3: 提交**

```bash
cd ~/.config/nvim
git add lua/user/lsp/conform.lua
git commit -m "feat(format): add prettier for vue/ts/tsx/js/jsx/css/html in conform.nvim"
```

---

## 验收清单

完成所有任务后，按以下步骤整体验证：

```
□ 打开 test.vue 文件 → :LspInfo 显示 volar + eslint + emmet_ls 已附加
□ 打开 test.tsx 文件 → :LspInfo 显示 ts_ls + eslint + emmet_ls 已附加
□ 打开 test.css 文件 → :LspInfo 显示 cssls 已附加
□ 在 .vue 文件里输入 <div，回车后自动补全 </div>（nvim-ts-autotag）
□ 在 .tsx 文件里输入 <div，回车后自动补全 </div>
□ 保存 .ts 文件后 prettier 自动格式化（conform.nvim）
□ 保存 .vue 文件后 prettier 自动格式化
□ gd 跳转到 TS 类型定义
□ gr 查找引用（fzf-lua + ts_ls）
□ ga 查看 code action（ESLint quick fix 出现）
```
