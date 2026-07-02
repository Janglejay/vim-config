#!/bin/bash
# 配色方案切换脚本
# Usage: ./switch-colorscheme.sh [catppuccin|tokyonight|nightfox]

CONFIG_FILE="${HOME}/.config/nvim/.colorscheme"
NVIM_CMD="nvim"

# 确保配置目录存在
mkdir -p "$(dirname "$CONFIG_FILE")"

# 显示帮助
show_help() {
    echo "用法: $0 <配色方案>"
    echo ""
    echo "可用的配色方案:"
    echo "  catppuccin  - 柔和奶油风，语义高亮出色（默认）"
    echo "  tokyonight  - 高对比度现代风，函数方法清晰"
    echo "  nightfox    - 温暖舒适风，专为 Treesitter 设计"
    echo ""
    echo "当前配色: $(cat "$CONFIG_FILE" 2>/dev/null || echo 'catppuccin')"
}

# 如果没有参数，显示帮助
if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

SCHEME="$1"

# 验证输入
case "$SCHEME" in
    catppuccin|tokyonight|nightfox)
        echo "$SCHEME" > "$CONFIG_FILE"
        echo "配色方案已设置为: $SCHEME"
        echo "请重启 Neovim 生效，或在 Neovim 中执行 :Colorscheme $SCHEME"
        ;;
    -h|--help|help)
        show_help
        exit 0
        ;;
    *)
        echo "错误: 未知的配色方案 '$SCHEME'"
        echo ""
        show_help
        exit 1
        ;;
esac
