-- local status_ok, gitsigns = pcall(require, "gitsigns")
-- if not status_ok then
--   return
-- end
--
-- gitsigns.setup {
--   signs = {
--     add = { hl = "GitSignsAdd", text = "▎", numhl = "GitSignsAddNr", linehl = "GitSignsAddLn" },
--     change = { hl = "GitSignsChange", text = "▎", numhl = "GitSignsChangeNr", linehl = "GitSignsChangeLn" },
--     delete = { hl = "GitSignsDelete", text = "契", numhl = "GitSignsDeleteNr", linehl = "GitSignsDeleteLn" },
--     topdelete = { hl = "GitSignsDelete", text = "契", numhl = "GitSignsDeleteNr", linehl = "GitSignsDeleteLn" },
--     changedelete = { hl = "GitSignsChange", text = "▎", numhl = "GitSignsChangeNr", linehl = "GitSignsChangeLn" },
--   },
--   signcolumn = true, -- Toggle with `:Gitsigns toggle_signs`
--   numhl = false, -- Toggle with `:Gitsigns toggle_numhl`
--   linehl = false, -- Toggle with `:Gitsigns toggle_linehl`
--   word_diff = false, -- Toggle with `:Gitsigns toggle_word_diff`
--   watch_gitdir = {
--     interval = 1000,
--     follow_files = true,
--   },
--   attach_to_untracked = true,
--   current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
--   current_line_blame_opts = {
--     virt_text = true,
--     virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
--     delay = 1000,
--     ignore_whitespace = false,
--   },
--   current_line_blame_formatter_opts = {
--     relative_time = false,
--   },
--   sign_priority = 6,
--   update_debounce = 100,
--   status_formatter = nil, -- Use default
--   max_file_length = 40000,
--   preview_config = {
--     -- Options passed to nvim_open_win
--     border = "single",
--     style = "minimal",
--     relative = "cursor",
--     row = 0,
--     col = 1,
--   }
--   -- yadm = {
--   --   enable = false,
--   -- },
-- }
for name, url in pairs {
  gitsigns = 'https://github.com/lewis6991/gitsigns.nvim',
  -- ADD OTHER PLUGINS _NECESSARY_ TO REPRODUCE THE ISSUE
} do
  local install_path = vim.fn.fnamemodify('gitsigns_issue/' .. name, ':p')
  if vim.fn.isdirectory(install_path) == 0 then
    vim.fn.system { 'git', 'clone', '--depth=1', url, install_path }
  end
  vim.opt.runtimepath:append(install_path)
end

require('gitsigns').setup {
  debug_mode          = true, -- You must add this to enable debug messages
  signs               = {

    -- add = { hl = "GitSignsAdd", text = "▎", numhl = "GitSignsAddNr", linehl = "GitSignsAddLn" },
    -- change = { hl = "GitSignsChange", text = "▎", numhl = "GitSignsChangeNr", linehl = "GitSignsChangeLn" },
    -- delete = { hl = "GitSignsDelete", text = "契", numhl = "GitSignsDeleteNr", linehl = "GitSignsDeleteLn" },
    -- topdelete = { hl = "GitSignsDelete", text = "契", numhl = "GitSignsDeleteNr", linehl = "GitSignsDeleteLn" },
    -- changedelete = { hl = "GitSignsChange", text = "▎", numhl = "GitSignsChangeNr", linehl = "GitSignsChangeLn" },
    -- Colors may be changed via the according highlight groupd, check :h gitsigns-highlight-groups
    -- add          = { text = '+' },
    -- change       = { text = '~' },
    -- delete       = { text = '-' },
    -- topdelete    = { text = '-' },
    -- changedelete = { text = '~' },
    -- untracked    = { text = '┆' },
  },
  signcolumn          = true,  -- Toggle with `:Gitsigns toggle_signs`
  -- different highlight options
  numhl               = false, -- Toggle with `:Gitsigns toggle_numhl`
  linehl              = false, -- Toggle with `:Gitsigns toggle_linehl`
  word_diff           = false, -- Toggle with `:Gitsigns toggle_word_diff`
  -- Watch changes
  watch_gitdir        = {
    enable = true,
    interval = 1000,
    follow_files = true
  },
  attach_to_untracked = true,
  -- Virtual text with information about the commit where it originates
  -- current_line_blame = true, -- Toggle with `:Gitsigns toggle_current_line_blame`
  -- current_line_blame_opts = {
  --   virt_text = true,
  --   virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
  --   delay = 1000,
  --   ignore_whitespace = false,
  -- },
  -- current_line_blame_formatter = '<author>, <author_time:%Y-%m-%d> - <summary>',
  sign_priority       = 6,     -- should be below LSP signs
  update_debounce     = 100,
  status_formatter    = nil,   -- Use default
  max_file_length     = 40000, -- Disable if file is longer than this (in lines)
  preview_config      = {
    -- Options passed to nvim_open_win
    border = 'single',
    style = 'minimal',
    relative = 'cursor',
    row = 0,
    col = 1
  }
  -- yadm                = {
  --   enable = false
  -- },
}
