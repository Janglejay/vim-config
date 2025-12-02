# Vim / Neovim 配置说明

此目录包含两套联动的配置：传统 Vim 通过 `~/.vimrc` + `~/.vim/plugin` 等目录加载，Neovim 通过 `~/.config/nvim/init.vim` 先复用 `~/.vimrc`，再加载 `lua/user` 下的 Lua 配置（packer 插件、LSP 等）。

## 目录结构
- `.vimrc`：基础按键映射、编辑行为、vim-plug 插件声明。
- `plugin/`：针对插件的 vimscript 配置与快捷键（NERDTree、vim-surround、table-mode、instant-markdown）。
- `autoload/plug.vim`：vim-plug 自身。
- `plugged/`：vim-plug 下载的 Vim 插件。
- `.config/nvim/init.vim`：设置 runtimepath，复用 `.vimrc`，再 `lua require('init')`。
- `.config/nvim/lua/init.lua`：加载 `lua/user` 下的模块（选项、按键、packer 插件、LSP、UI 等）。
- `.config/nvim/lua/user/plugins.lua`：packer 插件清单。
- `.config/nvim/plugin/packer_compiled.lua`：packer 生成文件（不要手改）。
- `gitsigns_issue/` 与 `.config/nvim/lua/user/gitsigns_issue/`：本地调试用的 gitsigns 源码副本，Lua 里会将它加入 runtimepath。

## 基础选项
- Vim（`.vimrc`）：`mapleader` 设为 `,`，禁用 `q` 为宏寄存器，`ttimeoutlen=0`/`timeoutlen=500`，`clipboard=unnamed`，拆分方向下/右，显示行号+相对行号，缩进 4 空格（`shiftwidth=4`、`softtabstop=4`、`expandtab`），关闭鼠标，`hlsearch`/`incsearch`/`ignorecase`/`smartcase`。
- Neovim（`lua/user/options.lua`）：`clipboard=unnamedplus`，`cmdheight=2`，`completeopt=menuone,noselect`，`pumheight=10`，`showtabline=2`，`smartindent`，`timeoutlen=500`，`undofile`，`signcolumn=yes`，`wrap=true`，`scrolloff=8`，`foldmethod=expr` + `foldexpr=nvim_treesitter#foldexpr()`（但默认 `foldenable=false`），缩进 2 空格。颜色主题默认 `gruvbox`（`lua/user/colorscheme.lua`）。

## 快捷键（Vim）
- 领导键：`,`；禁用 `q`，`\` 触发原 `q`。
- 移动/跳转：`J/K` 跳段（`}`/`{`），`L` 到行尾，`H` 到行首，`gn` 跳配对 `%`，`vv` 进入行选，`jk` 退出插入。
- 段落/块模板：`{` 在行末补出 `{}` 并回到上一行。
- 查找：`<Leader>j/#` 当前词向前/后搜索；`<Leader>n` 清除高亮。
- 窗口：`gh/gj/gk/gl` 在窗口间移动；`sV` 横向分屏，`sv` 纵向分屏。
- 复制粘贴：`Y` 复制全缓冲；`<Leader>v` 全选；`x/c/s` 与 `<Leader>d` 走黑洞寄存器；可视模式 `p` 不污染寄存器；`<Leader>r` 用黑洞寄存器替换当前词。
- 缩进：普通模式 `<Tab>`/`<BS>` 右/左缩进，视觉模式同理。
- Markdown：`<Leader>tm` 切换表格模式（vim-table-mode）；`<Leader>=` 预览 Markdown（instant-markdown），`<Leader>+` 停止。
- NERDTree（`plugin/nerdTree.vim`）：显示隐藏文件、启用 git 状态、文件图标；`g:NERDTreeMapJumpParent='h'`；当 NERDTree 是唯一窗口时自动退出 Vim。
- vim-surround：`<Leader>i`（给单词加环绕）、`<Leader>I`（整行）、`<Leader>a`（当前词，包括空格）。

## 快捷键（Neovim 专属）
- 基础（`lua/user/keymaps.lua`）：`R/E` 下/上一个 buffer；`=` 触发 `vim.lsp.buf.formatting()`；gitsigns：`<C-u>` 重置 hunk，`gp` 预览，`<C-f>/<C-d>` 上/下个 hunk；`ma` 打开 Telescope 书签；`<C-n>` 跳转 jumplist 前向；`st` 打开水平终端。
- LSP buffer 映射（`lua/user/lsp/handlers.lua`）：`gD/gd` 跳转定义，`gi` Telescope 实现，`<c-p>` hover，`gr` Telescope 引用，`ga` code action，`<Leader>R` rename，`se` 浮动诊断，`F2` 下一条诊断。
- WhichKey `<Leader>` 菜单（`lua/user/whichkey.lua`）：`<Leader>a` Alpha 启动界面，`b` buffer 列表，`p` `NERDTreeFind`，`w` 保存并关闭 NERDTree，`q` 退出，`c` 关当前 buffer (`Bdelete!`)，`C` 关其他 buffer，`n` 清除高亮，`f` 查文件，`F` live grep，`e` 项目列表（project.nvim），`g` Git 子菜单（blame/stage/branch/commit/diff），`l` LSP 子菜单（code action/diagnostic/format/rename/symbols），`S` 常用 Telescope（分支/主题/help/man/oldfiles/registers/keymaps/commands）。
- 终端（`lua/user/toggleterm.lua`）：`<C-\\>` 切换终端，终端内 `jk`/`<esc>` 回普通模式，`<C-h/j/k/l>` 在窗口间导航。
- Telescope（`lua/user/telescope.lua`）：`fd` 为默认文件查找器，界面快捷键见配置；WhichKey 已暴露常用入口。
- Alpha 仪表盘：预置「打开文件/新建/项目/历史/搜索/配置」按钮。

## 插件清单与说明
### Vim（vim-plug，见 `.vimrc`）
- `preservim/nerdtree`：文件树。
- `Xuyuanp/nerdtree-git-plugin`：NERDTree Git 状态。
- `instant-markdown/vim-instant-markdown`：Markdown 实时预览（端口 10010，默认不自动启动）。
- `tpope/vim-surround`：包围符操作。
- `dhruvasagar/vim-table-mode`：Markdown/表格编辑。
- `tiagofumo/vim-nerdtree-syntax-highlight`：NERDTree 高亮。
- `ryanoasis/vim-devicons`：图标支持。

### Neovim（packer，见 `lua/user/plugins.lua`）
- 管理/基础：`wbthomason/packer.nvim`，`nvim-lua/popup.nvim`，`nvim-lua/plenary.nvim`。
- UI：`akinsho/bufferline.nvim`，`moll/vim-bbye`，`nvim-lualine/lualine.nvim`，`akinsho/toggleterm.nvim`，`lewis6991/impatient.nvim`，`lukas-reineke/indent-blankline.nvim`（模块暂未启用），`goolord/alpha-nvim`，`kyazdani42/nvim-web-devicons`，`ahmedkhalf/project.nvim`，`folke/which-key.nvim`，`antoinemadec/FixCursorHold.nvim`。
- 主题：`lunarvim/darkplus.nvim`，`tanvirtin/monokai.nvim`，`morhetz/gruvbox`（启用）。
- 补全：`hrsh7th/nvim-cmp` + `cmp-buffer`/`cmp-path`/`cmp-cmdline`/`cmp-nvim-lsp`，`saadparwaiz1/cmp_luasnip`，`L3MON4D3/LuaSnip`，`rafamadriz/friendly-snippets`。
- LSP/格式化：`neovim/nvim-lspconfig`，`williamboman/nvim-lsp-installer`，`tamago324/nlsp-settings.nvim`，`jose-elias-alvarez/null-ls.nvim`，`ray-x/lsp_signature.nvim`。`lua/user/lsp/settings/*` 提供 `jsonls`、`sumneko_lua`、`rust_ls` 的特定设置。
- 文件/搜索：`kyazdani42/nvim-tree.lua`（仍保留，但默认通过 WhichKey 调用 NERDTree），`nvim-telescope/telescope.nvim` + `telescope-ui-select.nvim`/`telescope-live-grep-raw.nvim`，`MattesGroeger/vim-bookmarks` + `telescope-vim-bookmarks`。
- Treesitter：`nvim-treesitter/nvim-treesitter`，`JoosepAlviste/nvim-ts-context-commentstring`（`lua/user/init.lua` 中 Treesitter 模块当前被注释，如需启用取消注释）。
- Git：`lewis6991/gitsigns.nvim`（使用 `lua/user/gitsigns.lua`，会把本地 `gitsigns_issue/gitsigns` 添加到 runtimepath；`debug_mode=true`）。
- 注释/标记：`numToStr/Comment.nvim`（结合 ts-context-commentstring），`folke/todo-comments.nvim`。
- 其它：`windwp/nvim-autopairs`（`Alt+e` 快速包裹），`ahmedkhalf/project.nvim`，`folke/todo-comments.nvim`。

## LSP / 补全 / 格式化
- 自动补全：`nvim-cmp`，`<Tab>/<S-Tab>` 选项跳转，`<CR>` 确认；`<C-e>/<C-u>` 浏览候选。
- 自动成对：`nvim-autopairs` 启用 Treesitter 检测、`Alt-e` 快速包裹。
- LSP：通过 `nvim-lsp-installer` 自动加载已安装的 server；`jsonls`、`sumneko_lua`、`rust_ls` 有额外配置；诊断符号自定义，虚拟文本关闭，悬浮/签名浮窗带圆角。
- null-ls：当前只启用拼写补全源（`completion.spell`），格式化/诊断源默认注释，可按需打开。

## Markdown / 其他
- Markdown 预览：`vim-instant-markdown`（端口 10010，MathJax 开启）；表格辅助 `vim-table-mode`。
- TODO 标记：`folke/todo-comments.nvim` 关键字与配色已定义（FIX/TODO/HACK/WARN/PERF/NOTE）。
- 项目切换：`project.nvim` 使用 pattern 方式寻找根目录（`.git` 等），`Telescope projects` 为入口。

## 使用建议
- Vim 插件：`vim +PlugInstall` 安装；Neovim 插件：`nvim +PackerSync`（或在 `plugins.lua` 保存时自动触发）。
- 如需启用 Treesitter/indent-blankline，在 `lua/init.lua` 取消对应 `require` 注释。
- gitsigns 使用本地源码调试路径，如不需要可改回官方插件或移除 `lua/user/gitsigns.lua` 中的 runtimepath 追加逻辑。
