-- 已迁移到 user.plugins.lsp，此文件保留仅作备份
-- Mason、mason-lspconfig、pyright 和 jdtls 的配置均已移至 plugins/lsp.lua 和 plugins/java.lua
do return end

-- Mason + Mason-LSPConfig for Neovim 0.11+
-- LSP servers installed by mason, configured via vim.lsp.config (native API)
local mason_ok, mason = pcall(require, "mason")
if not mason_ok then
  vim.notify("mason.nvim not found, please run :PackerSync", vim.log.levels.ERROR)
  return
end

local mason_lspconfig_ok, mason_lspconfig = pcall(require, "mason-lspconfig")
if not mason_lspconfig_ok then
  vim.notify("mason-lspconfig.nvim not found, please run :PackerSync", vim.log.levels.ERROR)
  return
end

-- Mason: install LSP servers, linters, formatters
mason.setup({
  ui = {
    border = "rounded",
    icons = {
      package_installed = "✓",
      package_pending = "➜",
      package_uninstalled = "✗",
    },
  },
  log_level = vim.log.levels.INFO,
  max_concurrent_installers = 4,
})

-- Mason-LSPConfig: auto-register servers with vim.lsp.config
-- local lsp_servers = { "pyright", "jdtls" }  -- jdtls 已迁移到 plugins/java.lua
local lsp_servers = { "pyright" }
mason_lspconfig.setup({
  ensure_installed = lsp_servers,
  automatic_installation = true,
})

-- vim.lsp.config (Neovim 0.11+ native LSP config API)
vim.lsp.config("pyright", {
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,
        diagnosticMode = "openFilesOnly",
        typeCheckingMode = "basic",
      },
    },
  },
})

-- vim.lsp.config("jdtls", {  -- 已迁移到 plugins/java.lua（nvim-jdtls 方式）
--   cmd = { "jdtls" },
--   root_dir = function()
--     return vim.fs.root(0, { "pom.xml", "build.gradle", ".git", "mvnw", "gradlew" }) or vim.fn.getcwd()
--   end,
-- })

-- vim.lsp.enable starts registered servers
vim.lsp.enable("pyright")
-- vim.lsp.enable("jdtls")  -- 已迁移到 plugins/java.lua
