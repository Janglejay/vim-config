local status_ok, nvim_tree = pcall(require, "nvim-tree")
if not status_ok then
  return
end

nvim_tree.setup({
  -- 禁用 netrw（vim 默认文件浏览器）
  disable_netrw = true,
  hijack_netrw = true,

  -- 自动重载
  auto_reload_on_write = true,

  -- 更新当前文件位置
  update_focused_file = {
    enable = true,
    update_cwd = false,
  },

  -- Git 集成
  git = {
    enable = true,
    ignore = false,
    timeout = 500,
  },

  -- 文件系统过滤器
  filters = {
    dotfiles = false,      -- 显示隐藏文件
    custom = { ".git", "node_modules", ".cache" },
  },

  -- 视图设置
  view = {
    width = 35,
    side = "left",
    number = false,
    relativenumber = false,
    signcolumn = "yes",
  },

  -- 渲染设置
  renderer = {
    indent_markers = {
      enable = true,
    },
    icons = {
      show = {
        git = true,
        folder = true,
        file = true,
        folder_arrow = true,
      },
      glyphs = {
        default = "",
        symlink = "",
        git = {
          unstaged = "",
          staged = "S",
          unmerged = "",
          renamed = "➜",
          deleted = "",
          untracked = "U",
          ignored = "◌",
        },
        folder = {
          default = "",
          open = "",
          empty = "",
          empty_open = "",
          symlink = "",
        },
      },
    },
  },

  -- 操作行为
  actions = {
    open_file = {
      quit_on_open = false,     -- 打开文件时不关闭 tree
      resize_window = true,
      window_picker = {
        enable = false,
      },
    },
  },

  -- 诊断信息
  diagnostics = {
    enable = true,
    show_on_dirs = true,
    icons = {
      hint = "",
      info = "",
      warning = "",
      error = "",
    },
  },

  -- 文件修改监控
  filesystem_watchers = {
    enable = true,
  },
})

-- 快捷键
vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', { noremap = true, silent = true, desc = 'Toggle file tree' })
-- <leader>P → NvimTreeFindFile（SelectIn，对应 IdeaVim）
-- <leader>f 已被 fzf-lua SearchEverywhere 使用
