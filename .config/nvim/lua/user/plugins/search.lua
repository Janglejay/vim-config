return {
  {
    "ibhagwan/fzf-lua",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local fzf = require("fzf-lua")
      fzf.setup({
        winopts = {
          height = 0.85, width = 0.90,
          preview = { layout = "vertical", vertical = "down:50%" },
        },
        fzf_opts = { ["--layout"] = "reverse" },
        files = {
          fd_opts = "--color=never --type f --follow --exclude .git --exclude target --exclude node_modules",
        },
        grep = {
          rg_opts = "--column --line-number --no-heading --color=always --smart-case --max-columns=512",
        },
      })

      local opts = { noremap = true, silent = true }

      -- <Leader>f: SearchEverywhere
      vim.keymap.set("n", "<Leader>f", function() fzf.files() end,
        vim.tbl_extend("force", opts, { desc = "SearchEverywhere" }))

      -- <Leader>F: FindInPath
      vim.keymap.set("n", "<Leader>F", function() fzf.live_grep() end,
        vim.tbl_extend("force", opts, { desc = "FindInPath" }))

      -- <Leader>e: RecentFiles
      vim.keymap.set("n", "<Leader>e", function() fzf.oldfiles() end,
        vim.tbl_extend("force", opts, { desc = "RecentFiles" }))

      -- gr: FindUsages
      vim.keymap.set("n", "gr", function() fzf.lsp_references() end,
        vim.tbl_extend("force", opts, { desc = "FindUsages" }))

      -- gi: GotoImplementation
      vim.keymap.set("n", "gi", function() fzf.lsp_implementations() end,
        vim.tbl_extend("force", opts, { desc = "GotoImplementation" }))

      -- gR: CallHierarchy
      vim.keymap.set("n", "gR", function() fzf.lsp_incoming_calls() end,
        vim.tbl_extend("force", opts, { desc = "CallHierarchy" }))

      -- qi: QuickImplementations
      vim.keymap.set("n", "qi", function() fzf.lsp_implementations() end,
        vim.tbl_extend("force", opts, { desc = "QuickImplementations" }))

      -- ma: ShowBookmarks
      vim.keymap.set("n", "ma", "<cmd>BookmarkShowAll<CR>",
        vim.tbl_extend("force", opts, { desc = "ShowBookmarks" }))
    end,
  },

  -- aerial: FileStructurePopup 替代
  {
    "stevearc/aerial.nvim",
    cmd  = { "AerialToggle", "AerialOpen", "AerialNext", "AerialPrev" },
    keys = { { "<Leader>s", "<cmd>AerialToggle!<CR>", desc = "FileStructurePopup" } },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    config = function()
      require("aerial").setup({
        backends = { "lsp", "treesitter", "markdown", "man" },
        layout = { max_width = { 40, 0.2 }, width = nil, min_width = 20, default_direction = "right" },
        show_guides = true,
        filter_kind = false,
      })
    end,
  },

  -- vim-bookmarks（供 ma 使用）
  { "MattesGroeger/vim-bookmarks", event = "BufReadPost" },
}
