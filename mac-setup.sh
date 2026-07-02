#!/bin/bash

# =============================================================================
# Mac 开发环境一键安装脚本（并行版）
# =============================================================================
# 安装内容:
#   - Homebrew (包管理器)
#   - Raycast (快捷启动)
#   - Google Chrome (浏览器)
#   - Microsoft Edge (浏览器)
#   - Snipaste (截图/贴图工具)
#   - Karabiner-Elements (键盘映射)
#   - Git (版本控制)
#   - Ghostty (终端)
#   - Neovim + 配置 (编辑器)
#
# 特性:
#   - 并行安装：可同时下载多个软件，大幅提升速度
#   - 自动重试：下载失败时自动重试3次
#   - 错误隔离：单个软件失败不影响其他软件安装
#   - 详细日志：每个任务独立日志，失败时可查看详情
# =============================================================================

# 设置错误处理：允许子进程失败，主脚本根据返回码处理
set -o pipefail

# 并行任务结果存储目录
RESULTS_DIR=""

# 带重试的 brew install 函数
brew_install_with_retry() {
    local max_retries=3
    local retry_delay=5
    local attempt=1
    local cmd="$1"
    shift
    local args="$@"

    while [[ $attempt -le $max_retries ]]; do
        log_info "尝试 $attempt/$max_retries: brew install $args"
        if eval "$cmd $args" 2>&1; then
            return 0
        fi

        if [[ $attempt -lt $max_retries ]]; then
            log_warn "安装失败，${retry_delay}秒后重试..."
            sleep $retry_delay
        fi
        ((attempt++))
    done

    log_error "安装失败，已达到最大重试次数: $args"
    return 1
}

# 初始化并行任务环境
init_parallel() {
    RESULTS_DIR=$(mktemp -d)
    export RESULTS_DIR
}

# 带前缀输出的函数
prefix_output() {
    local prefix="$1"
    local color="$2"
    while IFS= read -r line; do
        echo -e "${color}[$prefix]${NC} $line"
    done
}

# 运行并行任务（带实时进度显示）
run_parallel() {
    local name="$1"
    shift
    local cmd="$@"
    local result_file="$RESULTS_DIR/$name.result"
    local log_file="$RESULTS_DIR/$name.log"
    local color="${BLUE}"

    # 为不同任务分配不同颜色
    case "$name" in
        raycast) color="${BLUE}" ;;
        chrome) color="${GREEN}" ;;
        edge) color="${BLUE}" ;;
        snipaste) color="${YELLOW}" ;;
        karabiner) color="${RED}" ;;
        ghostty) color="${GREEN}" ;;
        nvim) color="${YELLOW}" ;;
        *) color="${BLUE}" ;;
    esac

    {
        echo "=== $name 开始安装 ===" | prefix_output "$name" "$color"
        if eval "$cmd" 2>&1 | tee -a "$log_file" | prefix_output "$name" "$color"; then
            echo "SUCCESS" > "$result_file"
            echo "=== $name 安装成功 ===" | prefix_output "$name" "$color"
        else
            echo "FAILED" > "$result_file"
            echo "=== $name 安装失败 ===" | prefix_output "$name" "$color"
        fi
    } &

    echo $!
}

# 等待所有并行任务完成并报告结果
wait_parallel() {
    local pids="$@"
    local failed_tasks=()

    log_info "等待所有安装任务完成..."
    wait

    echo ""
    log_info "=========================================="
    log_info "安装结果汇总"
    log_info "=========================================="

    for result_file in "$RESULTS_DIR"/*.result; do
        [[ -f "$result_file" ]] || continue
        local name=$(basename "$result_file" .result)
        local result=$(cat "$result_file")
        local log_file="$RESULTS_DIR/$name.log"

        if [[ "$result" == "SUCCESS" ]]; then
            log_success "$name: 成功"
        else
            log_error "$name: 失败"
            failed_tasks+=("$name")
            echo ""
            echo "--- $name 错误日志 (最后20行) ---"
            tail -20 "$log_file" 2>/dev/null || echo "无日志"
            echo "---"
        fi
    done

    echo ""
    if [[ ${#failed_tasks[@]} -eq 0 ]]; then
        log_success "所有任务安装成功！"
        rm -rf "$RESULTS_DIR"
        return 0
    else
        log_error "以下任务安装失败: ${failed_tasks[*]}"
        log_info "完整日志保存在: $RESULTS_DIR"
        return 1
    fi
}

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查命令是否存在
check_command() {
    command -v "$1" &> /dev/null
}

# 检查文件中是否已包含某行
file_contains() {
    local file="$1"
    local pattern="$2"
    [[ -f "$file" ]] && grep -q "$pattern" "$file" 2>/dev/null
}

# 安全追加配置（避免重复）
safe_append_config() {
    local file="$1"
    local content="$2"
    local pattern="${3:-$content}"

    if [[ ! -f "$file" ]]; then
        touch "$file"
    fi

    if ! file_contains "$file" "$pattern"; then
        # 确保文件以换行符结尾
        [[ -s "$file" && "$(tail -c1 "$file" | wc -l)" -eq 0 ]] && echo "" >> "$file"
        echo "$content" >> "$file"
        return 0
    fi
    return 1
}

# =============================================================================
# 1. 安装 Homebrew
# =============================================================================
install_homebrew() {
    log_info "检查 Homebrew..."
    if check_command brew; then
        log_success "Homebrew 已安装: $(brew --version | head -n1)"
        return 0
    fi

    log_info "正在安装 Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # 配置环境变量
    if [[ $(uname -m) == "arm64" ]]; then
        # Apple Silicon Mac
        safe_append_config ~/.zprofile 'eval "$(/opt/homebrew/bin/brew shellenv)"' "brew shellenv"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        # Intel Mac
        safe_append_config ~/.zprofile 'eval "$(/usr/local/bin/brew shellenv)"' "brew shellenv"
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    log_success "Homebrew 安装完成"
}

# =============================================================================
# 2. 安装 Raycast
# =============================================================================
install_raycast() {
    log_info "[Raycast] 检查 Raycast..."
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local config_file="${script_dir}/raycast_config.rayconfig"
    local config_imported_marker="$HOME/.raycast_config_imported"

    # 1. 软件安装检查
    if [[ -d "/Applications/Raycast.app" ]]; then
        log_success "[Raycast] 软件已安装，跳过安装"
    else
        log_info "[Raycast] 正在安装..."
        if brew_install_with_retry "brew install --cask" "raycast"; then
            log_success "[Raycast] 安装完成"
        else
            log_error "[Raycast] 安装失败"
            return 1
        fi
    fi

    # 2. 配置导入检查（避免重复导入）
    if [[ -f "$config_imported_marker" ]]; then
        log_info "[Raycast] 配置已导入过（标记文件存在），跳过配置导入"
        return 0
    fi

    if [[ -f "$config_file" ]]; then
        log_info "[Raycast] 发现配置文件，准备导入..."
        log_info "[Raycast] 配置文件: $config_file"
        log_info "[Raycast] 配置密码: fufangjie"

        # Raycast 配置导入命令
        if open -a Raycast "$config_file" 2>/dev/null; then
            log_success "[Raycast] 配置导入已启动"
            log_info "[Raycast] 请在弹出的窗口中输入密码: fufangjie"
            # 创建标记文件，表示已尝试导入
            touch "$config_imported_marker"
            log_info "[Raycast] 已创建导入标记: $config_imported_marker"
        else
            log_warn "[Raycast] 无法自动导入配置"
            log_info "[Raycast] 请手动导入: 打开 Raycast → 设置 → 导入配置"
            log_info "[Raycast] 配置文件路径: $config_file"
            log_info "[Raycast] 配置密码: fufangjie"
        fi
    else
        log_warn "[Raycast] 未找到配置文件: $config_file"
    fi
}

# =============================================================================
# 3. 安装 Chrome
# =============================================================================
install_chrome() {
    log_info "[Chrome] 检查 Google Chrome..."
    if [[ -d "/Applications/Google Chrome.app" ]]; then
        log_success "[Chrome] 已安装，跳过"
        return 0
    fi

    log_info "[Chrome] 正在安装..."
    if brew_install_with_retry "brew install --cask" "google-chrome"; then
        log_success "[Chrome] 安装完成"
    else
        log_error "[Chrome] 安装失败"
        return 1
    fi
}

# =============================================================================
# 4. 安装 Edge
# =============================================================================
install_edge() {
    log_info "[Edge] 检查 Microsoft Edge..."
    if [[ -d "/Applications/Microsoft Edge.app" ]]; then
        log_success "[Edge] 已安装，跳过"
        return 0
    fi

    log_info "[Edge] 正在安装..."
    if brew_install_with_retry "brew install --cask" "microsoft-edge"; then
        log_success "[Edge] 安装完成"
    else
        log_error "[Edge] 安装失败"
        return 1
    fi
}

# =============================================================================
# 5. 安装 Snipaste
# =============================================================================
install_snipaste() {
    log_info "[Snipaste] 检查 Snipaste..."
    if [[ -d "/Applications/Snipaste.app" ]]; then
        log_success "[Snipaste] 已安装，跳过"
        return 0
    fi

    log_info "[Snipaste] 正在安装..."
    if brew_install_with_retry "brew install --cask" "snipaste"; then
        log_success "[Snipaste] 安装完成"
        log_info "[Snipaste] 快捷键: F1 截图, F3 贴图"
    else
        log_error "[Snipaste] 安装失败"
        return 1
    fi
}

# =============================================================================
# 6. 安装 Karabiner-Elements
# =============================================================================
install_karabiner() {
    log_info "[Karabiner] 检查 Karabiner-Elements..."
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local config_file="${script_dir}/karabiner_config.json"
    local karabiner_config_dir="$HOME/.config/karabiner"
    local karabiner_config_dest="$karabiner_config_dir/karabiner.json"
    local need_restart=false

    # 1. 软件安装检查
    if [[ -d "/Applications/Karabiner-Elements.app" ]]; then
        log_success "[Karabiner] 软件已安装，跳过安装"
    else
        log_info "[Karabiner] 正在安装..."
        if brew_install_with_retry "brew install --cask" "karabiner-elements"; then
            log_success "[Karabiner] 安装完成"
            need_restart=true
        else
            log_error "[Karabiner] 安装失败"
            return 1
        fi
    fi

    # 2. 配置导入检查
    if [[ -f "$karabiner_config_dest" ]]; then
        log_info "[Karabiner] 配置文件已存在，跳过配置导入"
        log_info "[Karabiner] 现有配置: $karabiner_config_dest"
        log_info "[Karabiner] 如需重新导入，请手动删除该文件后重新运行脚本"
    elif [[ -f "$config_file" ]]; then
        log_info "[Karabiner] 发现配置文件，准备导入..."
        mkdir -p "$karabiner_config_dir"
        if cp "$config_file" "$karabiner_config_dest"; then
            log_success "[Karabiner] 配置已导入: $karabiner_config_dest"
            need_restart=true
        else
            log_error "[Karabiner] 配置复制失败"
        fi
    else
        log_warn "[Karabiner] 未找到配置文件: $config_file"
    fi

    if $need_restart; then
        log_warn "[Karabiner] 请手动打开 Karabiner-Elements 并授予必要权限"
        log_info "[Karabiner] 配置导入后可能需要重启软件生效"
    fi
}

# =============================================================================
# 7. 安装 Git
# =============================================================================
install_git() {
    log_info "[Git] 检查 Git..."
    if check_command git; then
        log_success "[Git] 已安装: $(git --version)"
    else
        log_info "[Git] 正在安装..."
        brew_install_with_retry "brew install" "git"
        log_success "[Git] 安装完成"
    fi

    # 配置 Git 默认设置（无论是否新安装都执行）
    log_info "[Git] 配置默认设置..."
    git config --global init.defaultBranch main
    git config --global core.editor nvim
    log_success "[Git] 配置完成"
}

# =============================================================================
# 8. 安装 Ghostty
# =============================================================================
install_ghostty() {
    log_info "[Ghostty] 检查 Ghostty..."
    if check_command ghostty; then
        log_success "[Ghostty] 已安装，跳过"
        return 0
    fi

    log_info "[Ghostty] 正在安装..."
    if brew_install_with_retry "brew install --cask" "ghostty"; then
        log_success "[Ghostty] 安装完成"
    else
        log_error "[Ghostty] 安装失败"
        return 1
    fi
}

# =============================================================================
# 9. 配置 Neovim 环境
# =============================================================================
setup_nvim() {
    log_info "[Neovim] 开始配置 Neovim..."

    # 1. 安装 Neovim
    if ! check_command nvim; then
        log_info "[Neovim] 正在安装 Neovim..."
        if brew_install_with_retry "brew install" "neovim"; then
            log_success "[Neovim] 安装完成"
        else
            log_error "[Neovim] 安装失败"
            return 1
        fi
    else
        log_success "[Neovim] 已安装: $(nvim --version | head -n1)"
    fi

    # 2. 检查配置是否已存在
    local config_exists=false
    if [[ -d "$HOME/.config/nvim" ]] && ([[ -f "$HOME/.config/nvim/init.lua" ]] || [[ -f "$HOME/.config/nvim/init.vim" ]]); then
        config_exists=true
        log_info "[Neovim] 配置已存在: ~/.config/nvim"
        log_info "[Neovim] 跳过仓库克隆，将直接刷新插件..."
    fi

    # 3. 安装依赖工具（使用重试）
    log_info "[Neovim] 安装依赖工具 (ripgrep, fd, fzf, lazygit, node, jq, python)..."
    if brew_install_with_retry "brew install" "ripgrep fd fzf lazygit node jq python"; then
        log_success "[Neovim] 依赖工具安装完成"
    else
        log_warn "[Neovim] 部分依赖工具安装失败"
    fi

    # Java 21（jdtls 运行时必须）
    log_info "[Neovim] 安装 Java 21 (jdtls 依赖)..."
    if [[ -d "/Library/Java/JavaVirtualMachines/zulu-21.jdk" ]]; then
        log_success "[Neovim] Java 21 已安装，跳过"
    elif brew_install_with_retry "brew install --cask" "zulu@21"; then
        log_success "[Neovim] Java 21 安装完成"
    else
        log_warn "[Neovim] Java 21 安装失败，jdtls 将无法启动"
    fi

    # 4. 安装 pynvim（检查 pip3 是否存在）
    log_info "[Neovim] 检查并安装 pynvim..."
    if ! check_command pip3; then
        log_warn "[Neovim] pip3 未找到，尝试安装..."
        if ! python3 -m ensurepip --user 2>/dev/null; then
            log_error "[Neovim] 无法安装 pip3，请手动安装 Python 和 pip"
            return 1
        fi
        log_success "[Neovim] pip3 安装完成"
    fi

    log_info "[Neovim] 安装 pynvim..."
    if pip3 install --user pynvim; then
        log_success "[Neovim] pynvim 安装完成"
    else
        log_warn "[Neovim] pynvim 安装失败"
    fi

    # 5-7. 克隆配置仓库（如果配置不存在）
    if ! $config_exists; then
        # 如果目录存在但没有有效配置，删除它
        if [[ -d "$HOME/.config/nvim" ]]; then
            log_warn "[Neovim] 发现无效配置目录，删除中..."
            rm -rf "$HOME/.config/nvim"
        fi

        # 克隆配置仓库
        log_info "[Neovim] 克隆 vim-config 配置仓库到 ~/.config/nvim ..."
        if git clone https://github.com/Janglejay/vim-config.git "$HOME/.config/nvim"; then
            log_success "[Neovim] 配置仓库克隆完成"
        else
            log_error "[Neovim] 配置仓库克隆失败"
            return 1
        fi

        # 验证配置
        if [[ -f "$HOME/.config/nvim/init.lua" ]] || [[ -f "$HOME/.config/nvim/init.vim" ]]; then
            log_success "[Neovim] 配置文件已就位"
        else
            log_warn "[Neovim] 未找到 init.lua/init.vim，配置可能不完整"
        fi
    fi

    # 8. 安装 lazy.nvim 插件管理器
    log_info "[Neovim] 安装 lazy.nvim 插件管理器..."
    local lazy_dir="$HOME/.local/share/nvim/lazy/lazy.nvim"
    if [[ -d "$lazy_dir" ]]; then
        log_info "[Neovim] lazy.nvim 已存在，更新中..."
        (cd "$lazy_dir" && git pull) || log_warn "[Neovim] lazy.nvim 更新失败，继续使用现有版本"
    else
        if git clone --filter=blob:none --branch=stable \
                https://github.com/folke/lazy.nvim.git "$lazy_dir"; then
            log_success "[Neovim] lazy.nvim 安装完成"
        else
            log_error "[Neovim] lazy.nvim 安装失败"
        fi
    fi

    # 9. 安装/同步所有插件（headless 模式）
    log_info "[Neovim] 正在同步所有插件（可能需要几分钟）..."
    log_info "[Neovim] 运行 lazy sync 中，请耐心等待..."
    if timeout 300 nvim --headless "+Lazy! sync" +qa 2>&1; then
        log_success "[Neovim] 所有插件安装/同步完成"
    else
        local exit_code=$?
        if [[ $exit_code -eq 124 ]]; then
            log_warn "[Neovim] 插件安装超时（5分钟），首次启动 nvim 时会继续"
        else
            log_warn "[Neovim] 插件安装可能有错误（退出码: $exit_code），首次启动会继续"
        fi
    fi
    log_info "[Neovim] 提示：首次启动后运行 :MasonUpdate 安装 jdtls 等 LSP 工具"

    log_success "[Neovim] 配置完成"
    log_info "[Neovim] 提示: 首次启动后建议运行 :checkhealth 检查状态"
}

# =============================================================================
# 10. 配置 Ghostty
# =============================================================================
setup_ghostty_config() {
    log_info "[Ghostty] 开始配置 Ghostty..."

    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local config_source="${script_dir}/ghostty_config"
    local config_dest_dir="$HOME/.config/ghostty"
    local config_dest="$config_dest_dir/config"

    # 1. 检查配置文件是否已存在
    if [[ -f "$config_dest" ]]; then
        log_info "[Ghostty] 配置文件已存在，跳过复制"
        log_info "[Ghostty] 现有配置: $config_dest"
        log_info "[Ghostty] 如需重新配置，请手动删除该文件后重新运行脚本"
        return 0
    fi

    # 2. 检查源配置文件是否存在
    if [[ ! -f "$config_source" ]]; then
        log_warn "[Ghostty] 未找到配置文件: $config_source"
        log_info "[Ghostty] 将使用 Ghostty 默认配置"
        return 0
    fi

    # 3. 创建配置目录
    log_info "[Ghostty] 创建配置目录: $config_dest_dir"
    mkdir -p "$config_dest_dir"

    # 4. 复制配置文件
    log_info "[Ghostty] 复制配置: $config_source → $config_dest"
    if cp "$config_source" "$config_dest"; then
        log_success "[Ghostty] 配置已复制"
    else
        log_error "[Ghostty] 配置复制失败"
        return 1
    fi

    # 5. 验证配置
    if [[ -f "$config_dest" ]]; then
        log_success "[Ghostty] 配置文件已就位: $config_dest"
    else
        log_error "[Ghostty] 配置验证失败"
        return 1
    fi

    log_success "[Ghostty] 配置完成"
}

# =============================================================================
# 11. 配置 Zsh (可选)
# =============================================================================
setup_zsh() {
    log_info "[Zsh] 开始配置 Zsh..."

    # 安装 oh-my-zsh (如果未安装)
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        log_info "[Zsh] 安装 Oh My Zsh..."
        if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
            log_success "[Zsh] Oh My Zsh 安装完成"
        else
            log_error "[Zsh] Oh My Zsh 安装失败"
        fi
    else
        log_info "[Zsh] Oh My Zsh 已安装"
    fi

    # 添加常用别名到 .zshrc
    log_info "[Zsh] 检查 .zshrc 配置..."

    # 确保 .zshrc 存在
    if [[ ! -f ~/.zshrc ]]; then
        log_info "[Zsh] 创建 ~/.zshrc 文件"
        touch ~/.zshrc
    fi

    # 检查是否已添加过配置
    if grep -q "由 mac-setup.sh 添加" ~/.zshrc 2>/dev/null; then
        log_warn "[Zsh] 配置已存在，跳过添加"
    else
        log_info "[Zsh] 添加自定义配置到 ~/.zshrc ..."

        # 确保文件以换行符结尾
        if [[ -s ~/.zshrc ]] && [[ "$(tail -c1 ~/.zshrc | wc -l)" -eq 0 ]]; then
            echo "" >> ~/.zshrc
        fi

        # 追加配置块
        cat >> ~/.zshrc << 'EOF'

# ============================================
# 自定义配置（由 mac-setup.sh 添加）
# ============================================

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

# 快速编辑配置
alias zshrc='${EDITOR} ~/.zshrc'
alias vimrc='${EDITOR} ~/.config/nvim/init.lua'

# Homebrew 路径 (Apple Silicon)
if [[ -f "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi
EOF

        log_success "[Zsh] 配置已添加到 ~/.zshrc"
    fi

    # 验证配置
    if grep -q "由 mac-setup.sh 添加" ~/.zshrc 2>/dev/null; then
        log_success "[Zsh] 配置验证通过"
    else
        log_error "[Zsh] 配置验证失败，请检查 ~/.zshrc"
    fi

    log_success "[Zsh] 配置完成"
}

# =============================================================================
# 主函数
# =============================================================================
main() {
    echo "=========================================="
    echo "   Mac 开发环境一键安装脚本"
    echo "=========================================="
    echo ""

    # 检查系统
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "此脚本仅适用于 macOS"
        exit 1
    fi

    # 管理员权限检查
    log_info "检查管理员权限..."
    if ! sudo -n true 2>/dev/null; then
        log_warn "某些安装步骤需要管理员权限，可能会提示输入密码"
        log_warn "如需提前授权，请执行: sudo -v"
        echo ""
    fi

    # 安全警告
    log_warn "安全提示: 本脚本会从网络下载并执行 Homebrew 和 Oh My Zsh 安装脚本"
    log_warn "请确保您信任这些来源:"
    log_warn "  - https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
    log_warn "  - https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
    echo ""
    read -p "是否继续? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "已取消安装"
        exit 0
    fi
    echo ""

    log_info "开始安装，这可能需要一些时间..."
    log_info "启用并行安装模式，可同时安装多个软件"
    echo ""

    # 步骤1: 必须先安装 Homebrew（其他所有软件都依赖它）
    install_homebrew
    echo ""

    # 步骤2: 并行安装独立的应用程序（浏览器、工具等）
    log_info "=========================================="
    log_info "并行安装应用程序（5个任务同时运行）"
    log_info "任务: Raycast | Chrome | Edge | Snipaste | Karabiner"
    log_info "=========================================="
    init_parallel

    # 启动并行任务
    pids=()
    pids+=("$(run_parallel "raycast" "install_raycast")")
    pids+=("$(run_parallel "chrome" "install_chrome")")
    pids+=("$(run_parallel "edge" "install_edge")")
    pids+=("$(run_parallel "snipaste" "install_snipaste")")
    pids+=("$(run_parallel "karabiner" "install_karabiner")")

    echo ""
    log_info "所有任务已启动，正在并行下载安装中..."
    log_info ""

    # 等待并行任务完成
    if ! wait_parallel "${pids[@]}"; then
        log_warn "部分应用安装失败，继续执行后续步骤..."
    fi
    echo ""

    # 步骤3: 安装开发工具（Git、终端、编辑器）
    log_info "=========================================="
    log_info "安装开发工具"
    log_info "=========================================="

    # Git 需要先安装
    install_git
    echo ""

    # Ghostty 安装（并行）
    log_info "安装 Ghostty 终端..."
    install_ghostty
    echo ""

    # Neovim 配置（串行，步骤复杂，需要看到详细输出）
    log_info "=========================================="
    log_info "配置 Neovim 环境"
    log_info "=========================================="
    setup_nvim
    echo ""

    # 步骤4: 配置 Ghostty（依赖 Neovim 配置仓库）
    log_info "=========================================="
    log_info "配置 Ghostty"
    log_info "=========================================="
    setup_ghostty_config
    echo ""

    # 步骤5: 配置 Zsh（依赖前面的所有工具）
    log_info "=========================================="
    log_info "配置 Zsh"
    log_info "=========================================="
    setup_zsh
    echo ""

    # 完成提示
    echo "=========================================="
    log_success "所有安装完成！"
    echo "=========================================="
    echo ""
    echo "请执行以下操作:"
    echo ""
    echo "1. 重启终端或执行: source ~/.zshrc"
    echo "2. 启动 nvim，等待插件自动安装完成"
    echo "3. 打开 Karabiner-Elements 并授予权限"
    echo "4. 配置 Raycast 替换 Spotlight (Cmd+Space)"
    echo ""
    echo "配置文件导入提示:"
    echo "  - Raycast 配置密码: fufangjie"
    echo "  - 如未自动导入，可手动导入脚本目录中的:"
    echo "    - raycast_config.rayconfig"
    echo "    - karabiner_config.json"
    echo ""
    echo "常用命令:"
    echo "  nvim    - 启动编辑器"
    echo "  ghostty - 启动终端"
    echo "  snipaste - 截图工具 (如已在后台运行)"
    echo ""
    echo "安装特性:"
    echo "  ✓ 并行安装：多个软件同时下载"
    echo "  ✓ 自动重试：失败时自动重试3次"
    echo "  ✓ 错误隔离：单个失败不影响整体"
    echo ""
}

# 运行主函数
main
