# oh-my-mac

A comprehensive macOS development environment configuration featuring modern terminal, editor, and productivity tools. Built for efficiency with a focus on keyboard-centric workflows, seamless multi-device synchronization via Git, and automated deployment through symlinks.

## Overview

This dotfiles repository manages configurations across multiple software dimensions:

| Dimension | Primary Tool | Philosophy |
|-----------|-------------|------------|
| **Shell** | Zsh + Zap + Starship | Fast, minimal, informative prompt |
| **Terminal** | Ghostty | GPU-accelerated, modern terminal emulator |
| **Editor** | Neovim (primary) / Vim (legacy) | Modal editing, LSP-powered IDE experience |
| **Multiplexer** | Tmux | Persistent terminal sessions |
| **File Manager** | Yazi (terminal) / Nvim-tree (sidebar) | Keyboard-driven navigation |
| **Keyboard** | Karabiner-Elements | Vim-style navigation everywhere |
| **Launcher** | Raycast | Keyboard-first app launching |

## Repository Structure

```
~/.vim/                                    # Git repository root
├── .config/                               # XDG-compliant configurations
│   ├── nvim/                              # Neovim (Lua-based, 25+ modules)
│   ├── ghostty/                           # Terminal emulator config
│   ├── karabiner/                         # Keyboard remapping rules
│   ├── raycast/                           # Launcher extensions
│   ├── starship.toml                      # Shell prompt theme
│   └── cmux/                              # Local-only configs (excluded)
├── .zshrc                                 # Shell configuration (manual sync)
├── .tmux.conf                             # Terminal multiplexer
├── .ideavimrc                             # JetBrains IDE Vim emulation
├── plugged/                               # Vim plugins (vim-plug)
├── autoload/                              # Vim autoload scripts
├── lua/                                   # Neovim Lua modules
├── one-step-install.sh                    # **推荐: 一键安装脚本**
├── deploy.sh                              # 仅部署配置（符号链接）
├── mac-setup.sh                           # 仅安装软件
├── references/                            # Migration guides & docs
├── SYMLINK_SETUP.md                       # Sync management guide
└── CHANGELOG.md                           # Version history
```

## Configuration Architecture

### 1. Shell & Terminal Stack

#### Zsh Configuration (`.zshrc`)
Modern Zsh setup migrated from Oh-My-Zsh to lightweight alternatives:

```bash
# Plugin Manager: Zap (faster than Oh-My-Zsh)
# Plugins:
#   - zsh-autosuggestions      # Fish-like suggestions
#   - zsh-syntax-highlighting  # Command highlighting
#   - zap-zsh/supercharge      # Enhanced defaults

# Prompt: Starship (cross-shell, async rendering)
# Features:
#   - Directory navigation aliases: cc, cm, cdd, cn, cs, ct, cg, cr, cj, cll
#   - IDE shortcuts: idea, fleet, py
#   - Yazi integration: cd on quit
#   - Z command: smart directory jumping
```

#### Starship Prompt (`.config/starship.toml`)
Cross-shell prompt with rich context:
- **User/Host**: Shows when in SSH or different user
- **Directory**: Truncated with git repo awareness
- **Git**: Branch, status, ahead/behind indicators
- **Languages**: Java, Node.js, Python versions
- **Timing**: Commands >500ms show execution time
- **Style**: Nerd Font icons with custom colors

#### Ghostty Terminal (`.config/ghostty/config`)
Native macOS terminal with modern features:
```
Theme:        Catppuccin Mocha
Font:         Hack + Noto Sans SC (16pt)
Opacity:      0.85 (transparency)
Cursor:       Block with blinking
Navigation:   Alt+hjkl for pane switching
GPU:          Metal acceleration
Scrollback:   10000 lines
```

#### Tmux (`.tmux.conf`)
Terminal session management:
- **Prefix**: `Ctrl+t` (instead of default Ctrl+b)
- **Navigation**: Vim-style `hjkl` for panes
- **Mouse**: Full mouse support enabled
- **Windows**: Numbered from 1 (not 0)
- **Resizing**: `Ctrl+t` + `H/J/K/L`

### 2. Editor Stack

#### Neovim (Primary Editor)
**Architecture**: Modular Lua configuration

```lua
-- Entry Point Chain:
~/.config/nvim/init.vim      →  Sets runtimepath to ~/.vim
~/.config/nvim/lua/init.lua  →  Loads 23 user modules
```

**Module Organization** (`lua/user/`):

| Category | Modules | Purpose |
|----------|---------|---------|
| **Core** | `options.lua`, `keymaps.lua`, `colorscheme.lua` | Editor fundamentals |
| **Plugin Management** | `plugins.lua` | Packer plugin declarations |
| **LSP** | `lsp/handlers.lua`, `lsp/lsp-installer.lua`, `lsp/settings/*` | Language servers |
| **Completion** | `cmp.lua` | nvim-cmp with multiple sources |
| **UI** | `lualine.lua`, `bufferline.lua`, `alpha.lua`, `whichkey.lua` | Visual interface |
| **Navigation** | `telescope.lua`, `nvim-tree.lua`, `project.lua` | File/project navigation |
| **Terminal** | `toggleterm.lua` | Integrated terminal |
| **Git** | `gitsigns.lua` | Inline git status/diff |
| **Editing** | `autopairs.lua`, `comment.lua`, `todo-comments.lua` | Text enhancement |
| **Performance** | `impatient.lua`, `transparency.lua` | Optimization |

**Key Bindings** (Leader = `,`):

| Mode | Key | Action |
|------|-----|--------|
| Normal | `<leader>e` | Toggle nvim-tree (left sidebar) |
| Normal | `<leader>p` | Find current file in tree |
| Normal | `<leader>f` | Telescope find files |
| Normal | `<leader>F` | Telescope live grep |
| Normal | `<leader>b` | Buffer list |
| Normal | `<leader>g` | Git operations (which-key submenu) |
| Normal | `<leader>l` | LSP operations (which-key submenu) |
| Normal | `gd` | Go to definition |
| Normal | `gr` | Find references |
| Normal | `<C-\>` | Toggle terminal |

**LSP Configuration**:
- Servers: jsonls, lua_ls, rust_analyzer, pyright
- Diagnostics: Virtual text disabled, signs enabled
- Formatting: Conform.nvim (replaces null-ls)
- Completion: nvim-cmp with LSP, buffer, path, luasnip sources

#### Traditional Vim (Legacy Support)
Maintained for environments without Neovim:
- **Plugin Manager**: vim-plug
- **Plugins**: NERDTree, vim-surround, vim-table-mode, vim-devicons
- **Configuration**: `.vimrc` with vimscript
- **Note**: Neovim reuses `.vim` runtime but loads Lua modules on top

#### JetBrains IDEs (`.ideavimrc`)
Extensive Vim emulation for IntelliJ IDEA, PyCharm, Fleet:
- 800+ lines of IDE-specific keybindings
- Custom leader commands for refactoring
- Integration with IDE actions (rename, extract, etc.)

### 3. File Management

#### Yazi Integration (`lua/user/yazi.lua`)
Terminal file manager with Vim-style navigation:
```lua
-- Configurable via globals:
vim.g.yazi_direction = "vertical"  -- "vertical" | "horizontal" | "float"
vim.g.yazi_win_size = 35           -- Width/height
vim.g.yazi_win_pos = "left"        -- "left" | "right"
vim.g.yazi_chdir = true            -- Update nvim cwd on quit
```

**Key Features**:
- Image previews
- Multi-select with batch operations
- Fuzzy search
- NERDTree compatibility commands (`:NERDTreeToggle`, `:NERDTreeFind`)

#### Nvim-tree
Native Neovim file explorer (currently active):
- Sidebar on left, 35 columns wide
- Git status indicators
- File type icons
- Mouse support for resizing

### 4. macOS System Integration

#### Karabiner-Elements (`.config/karabiner/karabiner.json`)
System-wide keyboard modifications:
```
Caps Lock → Left Control
Ctrl+hjkl → Arrow Keys (Vim navigation everywhere)
Backslash ↔ Delete (swap)
```

#### Raycast (`.config/raycast/`)
Application launcher and workflow automation:
- Custom extensions in `raycast/ai/`
- Replaces Spotlight with richer features

### 5. Deployment & Synchronization

#### Symlink-Based Management
Configurations are symlinked from `~/.vim/.config/` to `~/.config/`:

```bash
~/.config/nvim        → ~/.vim/.config/nvim
~/.config/ghostty     → ~/.vim/.config/ghostty
~/.config/karabiner   → ~/.vim/.config/karabiner
~/.config/raycast     → ~/.vim/.config/raycast
~/.config/starship.toml → ~/.vim/.config/starship.toml
```

**Notable Exception**: `.zshrc` is NOT symlinked (manual sync) due to machine-specific customizations.

#### Quick Deployment

```bash
# New machine setup
git clone git@github.com:Janglejay/vim-config.git ~/.vim
cd ~/.vim && ./deploy.sh

# The deploy script:
# 1. Creates timestamped backups of existing configs
# 2. Creates symlinks for all managed configs
# 3. Preserves local-only configurations
```

## Installation Scripts

This repository provides three installation scripts for different use cases:

| Script | Purpose | Use When |
|--------|---------|----------|
| `one-step-install.sh` | **完整安装** (软件 + 配置) | 新机器首次设置 |
| `mac-setup.sh` | 仅安装软件 | 只需安装应用，不部署配置 |
| `deploy.sh` | 仅部署配置 | 软件已安装，只需同步配置 |

### Script Details

#### `one-step-install.sh` (Recommended)
The all-in-one installer for new machines:
```bash
./one-step-install.sh
```
**Does:**
- Installs Homebrew
- Installs all CLI tools (Git, Neovim, Tmux, Starship, Zap, Yazi, etc.)
- Installs GUI apps (Ghostty, Karabiner, Raycast)
- Clones the repository
- Creates symbolic links
- Configures Zsh
- Installs Neovim/Tmux plugins

#### `mac-setup.sh`
Software-only installer:
```bash
./mac-setup.sh
```
**Does:** Installs applications and tools
**Does NOT:** Clone repo, create symlinks, or configure shell

#### `deploy.sh`
Configuration-only deployer:
```bash
./deploy.sh
```
**Does:** Creates symbolic links from `~/.vim/.config/` to `~/.config/`
**Does NOT:** Install any software (assumes they're already installed)

## Software Dimension Details

### Shell Dimension
| Component | Tool | Config Location | Purpose |
|-----------|------|-----------------|---------|
| Shell | Zsh | `.zshrc` | Command interpreter |
| Plugin Manager | Zap | `.zshrc` | Zsh plugin management |
| Prompt | Starship | `.config/starship.toml` | Rich context prompt |
| Directory Jump | Z | `.zshrc` | Frecency-based cd |
| File Manager | Yazi | Shell integration | TUI file operations |

### Terminal Dimension
| Component | Tool | Config Location | Purpose |
|-----------|------|-----------------|---------|
| Emulator | Ghostty | `.config/ghostty/config` | Modern GPU terminal |
| Multiplexer | Tmux | `.tmux.conf` | Session management |
| Font | Hack + Noto Sans SC | System | Monospace + CJK support |

### Editor Dimension
| Component | Tool | Config Location | Purpose |
|-----------|------|-----------------|---------|
| Primary | Neovim | `.config/nvim/` | Modern modal editor |
| Fallback | Vim | `.vimrc`, `plugin/` | Legacy environments |
| IDE | JetBrains + IdeaVim | `.ideavimrc` | GUI IDE with Vim |
| Notes | Obsidian | `.obsidian.vimrc` | Knowledge base |

### macOS Dimension
| Component | Tool | Config Location | Purpose |
|-----------|------|-----------------|---------|
| Keyboard | Karabiner-Elements | `.config/karabiner/` | Key remapping |
| Launcher | Raycast | `.config/raycast/` | App launching |

## Getting Started

### Prerequisites
- macOS (primary target)
- Git
- Internet connection

### One-Step Installation (Recommended)

The fastest way to set up the entire environment:

```bash
# Option 1: Clone and run installer
git clone git@github.com:Janglejay/vim-config.git ~/.vim
cd ~/.vim && ./one-step-install.sh

# Option 2: Direct install via curl (if repo is public)
curl -fsSL https://raw.githubusercontent.com/Janglejay/vim-config/main/one-step-install.sh | bash
```

This script will:
1. Install Homebrew (if not present)
2. Install all CLI tools: Git, Neovim, Tmux, Starship, Zap, Yazi, Zoxide, etc.
3. Install GUI apps: Ghostty, Karabiner-Elements, Raycast
4. Clone the dotfiles repository
5. Create symbolic links for all configurations
6. Install Neovim and Tmux plugins
7. Configure Zsh with required settings

### Manual Installation (Alternative)

If you prefer step-by-step control:

```bash
# 1. Clone repository
git clone git@github.com:Janglejay/vim-config.git ~/.vim

# 2. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 3. Install CLI tools
brew install git nvim tmux starship ripgrep fd fzf lazygit yazi zoxide

# 4. Install GUI apps
brew install --cask ghostty karabiner-elements raycast

# 5. Deploy symlinks
cd ~/.vim && ./deploy.sh

# 6. Install Neovim plugins
nvim +PackerSync
```

### Post-Installation

1. **Restart terminal** or run `source ~/.zshrc` to apply changes
2. **Karabiner-Elements**: Open and grant system permissions
3. **Raycast**: Set shortcut to `Cmd+Space` to replace Spotlight
4. **Ghostty**: Configuration auto-loaded from `.config/ghostty/`
5. **Tmux plugins**: Start tmux, press `Ctrl+t` then `I` (capital i) to install plugins

## Key Workflows

### Daily Development
```bash
# Open project
cd ~/projects/my-project
nvim .

# Inside Neovim:
# <leader>e  - Open file tree
# <leader>f  - Find file
# <leader>F  - Search in files
# gd         - Go to definition
# <C-\>      - Open terminal
```

### Terminal Session Management
```bash
# Start new session
tmux new -s project

# Detach: Ctrl+t d
# Reattach: tmux attach -t project

# Window navigation: Ctrl+t 1/2/3...
# Pane navigation: Ctrl+t hjkl
```

### File Operations
```bash
# Quick file manager in terminal
yazi

# Or in Neovim:
# <leader>e  - Toggle sidebar tree
# <leader>p  - Find current file
```

## Configuration Philosophy

1. **Keyboard-First**: Minimize mouse usage with Vim-style bindings everywhere
2. **Git-Tracked**: All configs version controlled for rollback and sync
3. **Modular**: Each tool has isolated, focused configuration
4. **Progressive Enhancement**: Works without plugins, enhanced with them
5. **Cross-Tool Consistency**: Similar keybindings across editors, terminal, system

## Troubleshooting

### Neovim
- **Plugins not loading**: Run `:PackerSync`
- **LSP not working**: Run `:Mason` to install servers
- **Config errors**: Check `:messages` and `:checkhealth`

### Symlinks
- **Broken links**: Re-run `./deploy.sh`
- **Conflicts**: Check `~/.config/backups-*/` for originals

### Terminal
- **Fonts not showing**: Install Nerd Font (Hack Nerd Font)
- **Colors wrong**: Ensure `$TERM` supports truecolor

## References

- [SYMLINK_SETUP.md](./SYMLINK_SETUP.md) - Detailed sync management
- [references/ohmyzsh-to-starship-zap-migration.md](./references/ohmyzsh-to-starship-zap-migration.md) - Shell migration guide
- [references/symlink-config-guide.md](./references/symlink-config-guide.md) - Symlink configuration patterns
- [CHANGELOG.md](./CHANGELOG.md) - Version history

## License

Personal configuration - feel free to reference and adapt for your own use.
