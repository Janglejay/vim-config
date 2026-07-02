return {
  -- diffview：文件变更列表 + 侧边 diff（类 JetBrains Local Changes / Diff 面板）
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewToggleFiles" },
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<Leader>gd", "<cmd>DiffviewOpen<CR>",            noremap = true, silent = true, desc = "Git Diff（所有改动）" },
      { "<Leader>gh", "<cmd>DiffviewFileHistory %<CR>",   noremap = true, silent = true, desc = "Git 当前文件历史" },
      { "<Leader>gH", "<cmd>DiffviewFileHistory<CR>",     noremap = true, silent = true, desc = "Git 全项目历史" },
      { "<Leader>gc", "<cmd>DiffviewClose<CR>",           noremap = true, silent = true, desc = "关闭 Diffview" },
    },
    config = function()
      require("diffview").setup({
        enhanced_diff_hl = true,
        view = {
          default      = { layout = "diff2_horizontal" },
          file_history = { layout = "diff2_horizontal" },
        },
        file_panel = {
          listing_style = "tree",
          tree_options  = { flatten_dirs = true, folder_statuses = "only_folded" },
          win_config    = { position = "left", width = 35 },
        },
      })

      -- 在 diffview 内按 q 关闭
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "DiffviewFiles", "DiffviewFileHistory" },
        callback = function(args)
          vim.keymap.set("n", "q", "<cmd>DiffviewClose<CR>",
            { buffer = args.buf, noremap = true, silent = true })
        end,
      })
    end,
  },
}
