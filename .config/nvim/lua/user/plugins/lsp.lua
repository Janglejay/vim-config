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
      require("mason-lspconfig").setup({ ensure_installed = { "pyright" }, automatic_installation = true })
      vim.lsp.config("pyright", {
        settings = { python = { analysis = { autoSearchPaths = true, diagnosticMode = "openFilesOnly", typeCheckingMode = "basic" } } },
      })
      vim.lsp.enable("pyright")
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
