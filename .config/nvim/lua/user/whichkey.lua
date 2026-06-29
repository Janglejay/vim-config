local status_ok, which_key = pcall(require, "which-key")
if not status_ok then
  return
end

which_key.setup({
  plugins = {
    marks = true,
    registers = true,
    spelling = { enabled = true, suggestions = 20 },
    presets = {
      operators = false, motions = true, text_objects = true,
      windows = true, nav = true, z = true, g = true,
    },
  },
  icons = { breadcrumb = "»", separator = "➜", group = "+" },
  win  = { border = "rounded" },
  layout = {
    height = { min = 4, max = 25 },
    width  = { min = 20, max = 50 },
    spacing = 3, align = "left",
  },
  show_help = true,
})

which_key.add({
  -- 基础操作
  { "<leader>a", "<cmd>Alpha<cr>",                          desc = "Alpha 起始页" },
  { "<leader>b", "<cmd>lua require('fzf-lua').buffers()<cr>", desc = "Buffers 列表" },
  { "<leader>e", "<cmd>NvimTreeToggle<CR>",                 desc = "文件树 (Explorer)" },
  { "<leader>p", "<cmd>NvimTreeFindFile<CR>",               desc = "定位当前文件" },
  { "<leader>P", "<cmd>NvimTreeFindFile<CR>",               desc = "SelectIn (定位当前文件)" },
  { "<leader>w", "<cmd>only<CR>",                           desc = "关闭其他窗口 (HideAllWindows)" },
  { "<leader>q", "<cmd>q!<CR>",                             desc = "Quit" },
  { "<leader>c", "<cmd>Bdelete<CR>",                        desc = "关闭当前 Buffer" },
  { "<leader>C", "<cmd>%bd|e#|bd#<CR>",                    desc = "关闭其他所有 Buffer" },
  { "<leader>n", "<cmd>nohlsearch<CR>",                     desc = "取消搜索高亮" },

  -- 搜索（fzf-lua，对应 IdeaVim）
  { "<leader>f", "<cmd>lua require('fzf-lua').files()<cr>",           desc = "SearchEverywhere (文件)" },
  { "<leader>F", "<cmd>lua require('fzf-lua').live_grep()<cr>",       desc = "FindInPath (全局搜索)" },
  { "<leader>e", "<cmd>lua require('fzf-lua').oldfiles()<cr>",        desc = "RecentFiles (最近文件)" },
  { "<leader>s", "<cmd>AerialToggle!<CR>",                            desc = "FileStructurePopup (代码大纲)" },
  { "<leader>h",  group = "HTTP/Spring" },
  { "<leader>ha", desc = "Spring 接口搜索 (Cool Request)" },

  -- Git
  { "<leader>g",  group = "Git" },
  { "<leader>gl", "<cmd>lua require 'gitsigns'.blame_line()<cr>",      desc = "Blame" },
  { "<leader>gR", "<cmd>lua require 'gitsigns'.reset_buffer()<cr>",    desc = "Reset Buffer" },
  { "<leader>gs", "<cmd>lua require 'gitsigns'.stage_hunk()<cr>",      desc = "Stage Hunk" },
  { "<leader>gu", "<cmd>lua require 'gitsigns'.undo_stage_hunk()<cr>", desc = "Undo Stage Hunk" },
  { "<leader>go", "<cmd>lua require('fzf-lua').git_status()<cr>",      desc = "Git Status" },
  { "<leader>gb", "<cmd>lua require('fzf-lua').git_branches()<cr>",    desc = "Git Branches" },
  { "<leader>gc", "<cmd>lua require('fzf-lua').git_commits()<cr>",     desc = "Git Commits" },
  { "<leader>gd", "<cmd>Gitsigns diffthis HEAD<cr>",                   desc = "Diff HEAD" },

  -- LSP
  { "<leader>l",  group = "LSP" },
  { "<leader>la", "<cmd>lua vim.lsp.buf.code_action()<cr>",                         desc = "Code Action" },
  { "<leader>ld", "<cmd>lua require('fzf-lua').diagnostics_document()<cr>",         desc = "Document Diagnostics" },
  { "<leader>lw", "<cmd>lua require('fzf-lua').diagnostics_workspace()<cr>",        desc = "Workspace Diagnostics" },
  { "<leader>lf", "<cmd>lua vim.lsp.buf.format({ async = true })<cr>",              desc = "Format" },
  { "<leader>li", "<cmd>LspInfo<cr>",                                               desc = "LSP Info" },
  { "<leader>lj", "<cmd>lua vim.diagnostic.goto_next()<CR>",                        desc = "Next Diagnostic" },
  { "<leader>lk", "<cmd>lua vim.diagnostic.goto_prev()<cr>",                        desc = "Prev Diagnostic" },
  { "<leader>ll", "<cmd>lua vim.lsp.codelens.run()<cr>",                            desc = "CodeLens Action" },
  { "<leader>lq", "<cmd>lua vim.diagnostic.setloclist()<cr>",                       desc = "Quickfix" },
  { "<leader>lr", "<cmd>lua vim.lsp.buf.rename()<cr>",                              desc = "Rename" },
  { "<leader>ls", "<cmd>lua require('fzf-lua').lsp_document_symbols()<cr>",         desc = "Document Symbols" },
  { "<leader>lS", "<cmd>lua require('fzf-lua').lsp_live_workspace_symbols()<cr>",   desc = "Workspace Symbols" },

  -- 搜索杂项
  { "<leader>S",  group = "Search" },
  { "<leader>Sb", "<cmd>lua require('fzf-lua').git_branches()<cr>",  desc = "Git Branches" },
  { "<leader>Sc", "<cmd>lua require('fzf-lua').colorschemes()<cr>",  desc = "Colorscheme" },
  { "<leader>Sh", "<cmd>lua require('fzf-lua').help_tags()<cr>",     desc = "Help Tags" },
  { "<leader>SM", "<cmd>lua require('fzf-lua').man_pages()<cr>",     desc = "Man Pages" },
  { "<leader>Sr", "<cmd>lua require('fzf-lua').oldfiles()<cr>",      desc = "Recent Files" },
  { "<leader>SR", "<cmd>lua require('fzf-lua').registers()<cr>",     desc = "Registers" },
  { "<leader>Sk", "<cmd>lua require('fzf-lua').keymaps()<cr>",       desc = "Keymaps" },
  { "<leader>SC", "<cmd>lua require('fzf-lua').commands()<cr>",      desc = "Commands" },
})
