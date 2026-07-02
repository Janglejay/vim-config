-- Conform.nvim — formatting for Neovim 0.12+
-- Replaces null-ls.nvim (unmaintained / incompatible with Neovim 0.12)
local conform_ok, conform = pcall(require, "conform")
if not conform_ok then
  return
end

conform.setup({
  -- jq 格式化 JSON 参数：2 空格缩进，tab 可用 --tab
  formatters = {
    jq = {
      prepend_args = { "--indent", "2" },
    },
  },
  formatters_by_ft = {
    python = { "black", "isort", "ruff_format" },
    java   = { "google-java-format" },
    lua    = { "stylua" },
    json   = { "jq" },
    jsonc  = { "jq" },   -- JSON with Comments（VS Code settings.json 等）
    yaml   = { "yamlfmt" },
    javascript      = { "prettier" },
    javascriptreact = { "prettier" },
    typescript      = { "prettier" },
    typescriptreact = { "prettier" },
    vue             = { "prettier" },
    css             = { "prettier" },
    scss            = { "prettier" },
    html            = { "prettier" },
  },
})

-- 格式化已由 keymaps.lua 中的 = 绑定处理，此处不重复绑定
