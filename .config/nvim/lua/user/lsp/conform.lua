-- Conform.nvim — formatting for Neovim 0.12+
-- Replaces null-ls.nvim (unmaintained / incompatible with Neovim 0.12)
local conform_ok, conform = pcall(require, "conform")
if not conform_ok then
  return
end

conform.setup({
  formatters_by_ft = {
    python = { "black", "isort", "ruff_format" },
    java = { "google-java-format" },
    lua = { "stylua" },
    json = { "jq" },
    yaml = { "yamlfmt" },
  },
  format_on_save = {
    timeout_ms = 5000,
    lsp_fallback = true,
  },
})

-- 格式化已由 keymaps.lua 中的 = 绑定处理，此处不重复绑定
