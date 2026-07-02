#!/bin/bash
# =============================================================================
# oh-my-mac 一键安装脚本
# =============================================================================
# 功能:
#   1. 安装所有必需软件 (Homebrew, Starship, Zap, Tmux, Neovim 等)
#   2. 克隆 dotfiles 仓库 (如果尚未克隆)
#   3. 创建符号链接部署配置
#   4. 安装 Neovim 插件
#
# 用法:
#   curl -fsSL https://raw.githubusercontent.com/Janglejay/oh-my-mac/main/one-step-install.sh | bash
#   或本地运行: ./one-step-install.sh
# =============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 配置
REPO_URL="git@github.com:Janglejay/vim-config.git"
REPO_DIR="${HOME}/.vim"
CONFIG_DIR="${HOME}/.config"
BACKUP_DIR="${CONFIG_DIR}/backups-$(date +%Y%m%d-%H%M%S)"

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# 检查命令是否存在
check_command() {
    command -v "$1" &> /dev/null
}

# 带重试的 brew install
brew_install_with_retry() {
    local max_retries=3
    local retry_delay=5
    local attempt=1
    local package="$1"

    while [[ $attempt -le $max_retries ]]; do
        log_info "尝试 $attempt/$max_retries: brew install $package"
        if brew install "$package" 2>&1; then
            return 0
        fi

        if [[ $attempt -lt $max_retries ]]; then
            log_warn "安装失败，${retry_delay}秒后重试..."
            sleep $retry_delay
        fi
        ((attempt++))
    done

    log_error "安装失败，已达到最大重试次数: $package"
    return 1
}

# 带重试的 brew install --cask
brew_cask_install_with_retry() {
    local max_retries=3
    local retry_delay=5
    local attempt=1
    local package="$1"

    while [[ $attempt -le $max_retries ]]; do
        log_info "尝试 $attempt/$max_retries: brew install --cask $package"
        if brew install --cask "$package" 2>&1; then
            return 0
        fi

        if [[ $attempt -lt $max_retries ]]; then
            log_warn "安装失败，${retry_delay}秒后重试..."
            sleep $retry_delay
        fi
        ((attempt++))
    done

    log_error "安装失败，已达到最大重试次数: $package"
    return 1
}

# =============================================================================
# Step 1: 检查系统
# =============================================================================
step_check_system() {
    log_step "检查系统环境..."

    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "此脚本仅适用于 macOS"
        exit 1
    fi

    log_success "系统检查通过: macOS"
}

# =============================================================================
# Step 2: 安装 Homebrew
# =============================================================================
step_install_homebrew() {
    log_step "安装 Homebrew..."

    if check_command brew; then
        log_success "Homebrew 已安装: $(brew --version | head -n1)"
        return 0
    fi

    log_info "正在安装 Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # 配置环境变量
    if [[ $(uname -m) == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    else
        eval "$(/usr/local/bin/brew shellenv)"
        echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
    fi

    log_success "Homebrew 安装完成"
}

# =============================================================================
# Step 3: 安装命令行工具
# =============================================================================
step_install_cli_tools() {
    log_step "安装命令行工具..."

    local tools=("git" "nvim" "tmux" "starship" "zap" "ripgrep" "fd" "fzf" "lazygit" "yazi" "zoxide" "jq" "node")

    for tool in "${tools[@]}"; do
        if check_command "$tool"; then
            log_success "$tool 已安装"
        else
            log_info "安装 $tool..."
            case "$tool" in
                "zap")
                    # Zap 是 Zsh 插件管理器
                    if [[ ! -d "$HOME/.local/share/zap" ]]; then
                        zsh <(curl -s https://raw.githubusercontent.com/zap-zsh/zap/master/install.zsh) --branch release-v1
                    fi
                    ;;
                "yazi")
                    brew_cask_install_with_retry "yazi" || true
                    ;;
                *)
                    brew_install_with_retry "$tool" || true
                    ;;
            esac
        fi
    done

    log_success "命令行工具安装完成"
}

# =============================================================================
# Step 4: 安装 GUI 应用
# =============================================================================
step_install_gui_apps() {
    log_step "安装 GUI 应用程序..."

    local apps=("ghostty" "karabiner-elements" "raycast" "zulu@21")

    for app in "${apps[@]}"; do
        local app_name=$(echo "$app" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1')
        log_info "安装 $app_name..."
        brew_cask_install_with_retry "$app" || log_warn "$app_name 安装失败，可手动安装"
    done

    log_success "GUI 应用程序安装完成"
}

# =============================================================================
# Step 5: 克隆仓库
# =============================================================================
step_clone_repo() {
    log_step "克隆 dotfiles 仓库..."

    if [[ -d "$REPO_DIR/.git" ]]; then
        log_info "仓库已存在，拉取最新更新..."
        cd "$REPO_DIR"
        git pull
        log_success "仓库已更新"
    else
        log_info "克隆仓库到 $REPO_DIR..."
        if [[ -d "$REPO_DIR" ]]; then
            log_warn "目录已存在但不是 git 仓库，备份到 $REPO_DIR.backup"
            mv "$REPO_DIR" "$REPO_DIR.backup.$(date +%s)"
        fi
        git clone "$REPO_URL" "$REPO_DIR"
        log_success "仓库克隆完成"
    fi
}

# =============================================================================
# Step 6: 创建符号链接
# =============================================================================
step_create_symlinks() {
    log_step "创建配置文件符号链接..."

    mkdir -p "$BACKUP_DIR"

    # 定义链接映射: "源文件:目标文件:名称"
    local links=(
        "$REPO_DIR/.config/nvim:$CONFIG_DIR/nvim:Neovim"
        "$REPO_DIR/.config/ghostty:$CONFIG_DIR/ghostty:Ghostty"
        "$REPO_DIR/.config/karabiner:$CONFIG_DIR/karabiner:Karabiner"
        "$REPO_DIR/.config/raycast:$CONFIG_DIR/raycast:Raycast"
        "$REPO_DIR/.config/starship.toml:$CONFIG_DIR/starship.toml:Starship"
        "$REPO_DIR/.tmux.conf:$HOME/.tmux.conf:Tmux"
    )

    for link in "${links[@]}"; do
        IFS=':' read -r src dst name <<< "$link"

        # 备份现有配置
        if [[ -e "$dst" ]] && [[ ! -L "$dst" ]]; then
            log_warn "备份 $name: $dst -> $BACKUP_DIR/"
            cp -r "$dst" "$BACKUP_DIR/" 2>/dev/null || true
            rm -rf "$dst"
        fi

        # 创建或更新符号链接
        if [[ -L "$dst" ]]; then
            local current_target=$(readlink "$dst")
            if [[ "$current_target" == "$src" ]]; then
                log_success "$name 已正确链接"
            else
                log_warn "$name 指向其他位置，更新链接"
                rm "$dst"
                ln -sf "$src" "$dst"
                log_success "$name 链接已更新"
            fi
        else
            ln -sf "$src" "$dst"
            log_success "$name -> $src"
        fi
    done

    log_info "备份位置: $BACKUP_DIR"
}

# =============================================================================
# Step 7: 配置 Zsh
# =============================================================================
step_configure_zsh() {
    log_step "配置 Zsh..."

    # 确保 .zshrc 存在
    if [[ ! -f ~/.zshrc ]]; then
        touch ~/.zshrc
    fi

    # 检查是否已配置
    if grep -q "oh-my-mac" ~/.zshrc 2>/dev/null; then
        log_warn ".zshrc 已配置，跳过"
        return 0
    fi

    log_info "添加配置到 ~/.zshrc..."

    cat >> ~/.zshrc << 'EOF'

# ============================================
# oh-my-mac 配置 (由 one-step-install.sh 添加)
# ============================================

# Homebrew (Apple Silicon)
if [[ -f "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# 编辑器设置
export EDITOR='nvim'
alias vi='nvim'
alias vim='nvim'

# 常用别名
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'

# Git 别名
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'

# Tmux 别名
alias tm='tmux'
alias tma='tmux attach'
alias tml='tmux ls'

# 快速编辑配置
alias zshrc='${EDITOR} ~/.zshrc'
alias vimrc='${EDITOR} ~/.config/nvim'

# Starship 提示符
eval "$(starship init zsh)"

# Zoxide (智能 cd)
eval "$(zoxide init zsh)"
EOF

    log_success ".zshrc 配置完成"
}

# =============================================================================
# Step 8: 安装 Neovim 插件（lazy.nvim）
# =============================================================================
step_install_nvim_plugins() {
    log_step "安装 Neovim 插件（lazy.nvim）..."

    # 引导安装 lazy.nvim（插件管理器本体）
    local lazy_dir="$HOME/.local/share/nvim/lazy/lazy.nvim"
    if [[ ! -d "$lazy_dir" ]]; then
        log_info "安装 lazy.nvim..."
        git clone --filter=blob:none --branch=stable \
            https://github.com/folke/lazy.nvim.git "$lazy_dir"
        log_success "lazy.nvim 安装完成"
    else
        log_success "lazy.nvim 已存在"
    fi

    # 同步所有插件（headless 模式）
    log_info "运行 lazy sync（首次安装可能需要几分钟）..."
    if timeout 300 nvim --headless "+Lazy! sync" +qa 2>&1; then
        log_success "Neovim 插件安装完成"
    else
        local exit_code=$?
        if [[ $exit_code -eq 124 ]]; then
            log_warn "插件安装超时（5分钟），首次启动 nvim 时会继续完成"
        else
            log_warn "插件安装可能有错误（退出码: $exit_code），首次启动 nvim 时会继续"
        fi
    fi

    # Mason 工具安装（LSP、格式化器等）
    log_info "安装 Mason 工具（jdtls、google-java-format 等）..."
    log_info "提示：首次启动 nvim 后运行 :MasonUpdate 安装所有工具"
}

# =============================================================================
# Step 9: 安装 Tmux 插件
# =============================================================================
step_install_tmux_plugins() {
    log_step "安装 Tmux 插件..."

    local tpm_dir="$HOME/.tmux/plugins/tpm"
    if [[ ! -d "$tpm_dir" ]]; then
        log_info "安装 Tmux Plugin Manager (TPM)..."
        git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
    fi

    log_success "Tmux 插件管理器已安装"
    log_info "首次启动 tmux 后按 prefix + I 安装插件"
}

# =============================================================================
# Step 10: 验证安装
# =============================================================================
step_verify() {
    log_step "验证安装..."

    echo ""
    echo "========================================"
    echo "         安装验证报告"
    echo "========================================"
    echo ""

    local tools=("brew" "git" "nvim" "tmux" "starship" "zoxide")
    for tool in "${tools[@]}"; do
        if check_command "$tool"; then
            local version=$($tool --version 2>&1 | head -n1 || echo "已安装")
            printf "${GREEN}✓${NC} %-15s %s\n" "$tool" "${version:0:40}"
        else
            printf "${RED}✗${NC} %-15s %s\n" "$tool" "未安装"
        fi
    done

    echo ""
    echo "符号链接状态:"
    local links=("nvim" "ghostty" "karabiner" "raycast" "starship.toml")
    for link in "${links[@]}"; do
        local target="$CONFIG_DIR/$link"
        if [[ -L "$target" ]]; then
            local realpath=$(readlink "$target")
            printf "${GREEN}✓${NC} %-15s -> %s\n" "$link" "$realpath"
        else
            printf "${RED}✗${NC} %-15s %s\n" "$link" "未链接"
        fi
    done

    echo ""
    log_success "验证完成"
}

# =============================================================================
# 主函数
# =============================================================================
main() {
    echo ""
    echo "========================================"
    echo "      oh-my-mac 一键安装脚本"
    echo "========================================"
    echo ""
    echo "此脚本将:"
    echo "  1. 安装 Homebrew 包管理器"
    echo "  2. 安装 Starship, Zap, Tmux, Neovim 等工具"
    echo "  3. 安装 Ghostty, Karabiner, Raycast 等应用"
    echo "  4. 克隆 dotfiles 仓库"
    echo "  5. 创建配置文件符号链接"
    echo "  6. 安装 Neovim/Tmux 插件"
    echo ""

    read -p "是否继续? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "已取消安装"
        exit 0
    fi

    echo ""
    log_info "开始安装，这可能需要 10-30 分钟..."
    echo ""

    # 执行所有步骤
    step_check_system
    step_install_homebrew
    step_install_cli_tools
    step_install_gui_apps
    step_clone_repo
    step_create_symlinks
    step_configure_zsh
    step_install_nvim_plugins
    step_install_tmux_plugins
    step_verify

    # 完成提示
    echo ""
    echo "========================================"
    echo "${GREEN}       安装完成！${NC}"
    echo "========================================"
    echo ""
    echo "后续步骤:"
    echo ""
    echo "1. 重启终端或执行: source ~/.zshrc"
    echo ""
    echo "2. 启动应用完成配置:"
    echo "   - Ghostty: 首次启动会自动加载配置"
    echo "   - Karabiner-Elements: 需授予系统权限"
    echo "   - Raycast: 建议设置为 Cmd+Space 替换 Spotlight"
    echo ""
    echo "3. 在 Tmux 中安装插件:"
    echo "   启动 tmux，然后按 Ctrl+t 再按 I (大写 i)"
    echo ""
    echo "4. 首次启动 Neovim:"
    echo "   运行 'nvim'，插件会自动完成安装"
    echo ""
    echo "常用快捷键:"
    echo "   nvim        启动编辑器"
    echo "   tmux        启动终端复用器"
    echo "   yazi        启动文件管理器"
    echo "   Ctrl+t      Tmux prefix 键"
    echo "   ,           Vim leader 键"
    echo ""
    echo "备份位置: $BACKUP_DIR"
    echo ""
}

# 运行主函数
main
