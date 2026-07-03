local options = {
  backup = false, -- creates a backup file
  autoread = true, -- 外部程序（如 mtcc/Claude Code）修改文件后自动重载
  clipboard = "unnamedplus", -- allows neovim to access the system clipboard
  cmdheight = 2, -- more space in the neovim command line for displaying messages
  completeopt = { "menuone", "noselect" }, -- mostly just for cmp
  conceallevel = 0, -- so that `` is visible in markdown files
  fileencoding = "utf-8", -- the encoding written to a file
  hlsearch = true, -- highlight all matches on previous search pattern
  ignorecase = true, -- ignore case in search patterns
  mouse = "a", -- enable mouse for resizing windows
  pumheight = 10, -- pop up menu height
  showmode = false, -- we don't need to see things like -- INSERT -- anymore
  showtabline = 2, -- always show tabs
  laststatus  = 3, -- 全局状态栏（始终可见，Neovim 0.7+）
  smartcase = true, -- smart case
  smartindent = true, -- make indenting smarter again
  splitbelow = true, -- force all horizontal splits to go below current window
  splitright = true, -- force all vertical splits to go to the right of current window
  swapfile = false, -- creates a swapfile
  -- termguicolors = true,                    -- set term gui colors (most terminals support this)
  -- timeoutlen = 100,                        -- time to wait for a mapped sequence to complete (in milliseconds)
  timeoutlen = 500, -- time to wait for a mapped sequence to complete (in milliseconds)
  undofile = true, -- enable persistent undo
  updatetime = 300, -- faster completion (4000ms default)
  writebackup = false, -- if a file is being edited by another program (or was written to file while editing with another program), it is not allowed to be edited
  autowriteall = true, -- automatically write buffer when leaving (matching .vimrc: set autowriteall)
  expandtab = true, -- convert tabs to spaces
  shiftwidth = 4, -- the number of spaces inserted for each indentation (matching .vimrc)
  tabstop = 4, -- insert 4 spaces for a tab (matching .vimrc)
  softtabstop = 4, -- (matching .vimrc)
  cursorline = true, -- highlight the current line
  number = true, -- set numbered lines
  relativenumber = false, -- set relative numbered lines
  numberwidth = 4, -- set number column width to 2 {default 4}
  signcolumn = "yes", -- always show the sign column, otherwise it would shift the text each time
  -- wrap = false,                            -- display lines as one long line
  wrap = true, -- display lines as one long line
  scrolloff = 8, -- is one of my fav
  sidescrolloff = 8,
  guifont = "monospace:h17", -- the font used in graphical neovim applications
  foldmethod  = "expr",
  foldexpr    = "v:lua.vim.treesitter.foldexpr()",  -- Neovim 0.10+ 原生 treesitter fold
  foldenable  = true,   -- 启用折叠（zz/zZ 才能生效）
  foldlevel   = 99,     -- 默认全展开（需要时手动折叠）
  foldlevelstart = 99   -- 打开文件时全展开
}

vim.opt.shortmess:append "c"

for k, v in pairs(options) do
  vim.opt[k] = v
end

vim.cmd "set whichwrap+=<,>,[,],h,l"
vim.cmd [[set iskeyword+=-]]
-- vim.cmd [[set formatoptions-=cro]] -- TODO: this doesn't seem to work

-- vim.api.nvim_create_autocmd({ "InsertLeave" }, {
--   callback = function()
--     -- vim.fn.execute("silent! write")
--     vim.fn.execute("silent! write")
--     -- vim.notify("Autosaved!", vim.log.levels.INFO, {})
--   end,
-- })
