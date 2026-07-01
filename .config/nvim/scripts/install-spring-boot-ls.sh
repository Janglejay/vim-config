#!/usr/bin/env bash
# 安装 Spring Boot Language Server（standalone）
# 提供 Spring Bean 导航、@RequestMapping 补全、YAML/Properties 智能提示等
# 运行方式：bash ~/.config/nvim/scripts/install-spring-boot-ls.sh

set -euo pipefail

INSTALL_DIR="$HOME/.local/share/nvim/spring-boot-ls"
JAR_PATH="$INSTALL_DIR/spring-boot-language-server.jar"

# 获取最新版本（STS4 GitHub releases）
echo "正在获取最新版本..."
LATEST_TAG=$(curl -fsSL \
  "https://api.github.com/repos/spring-projects/sts4/releases/latest" \
  | grep '"tag_name"' | sed 's/.*"V\([^"]*\)".*/\1/')

if [ -z "$LATEST_TAG" ]; then
  # fallback 到已知稳定版
  LATEST_TAG="1.58.0.RELEASE"
  echo "  使用 fallback 版本: $LATEST_TAG"
else
  echo "  最新版本: $LATEST_TAG"
fi

DOWNLOAD_URL="https://github.com/spring-projects/sts4/releases/download/V${LATEST_TAG}/spring-boot-language-server-${LATEST_TAG}.jar"

mkdir -p "$INSTALL_DIR"

echo "正在下载: $DOWNLOAD_URL"
if curl -fL --progress-bar -o "$JAR_PATH" "$DOWNLOAD_URL"; then
  echo "✓ 安装完成: $JAR_PATH"
  echo ""
  echo "重启 Neovim 后打开 .java 文件，Spring Boot LSP 自动生效。"
  echo "功能："
  echo "  · @Autowired 字段 → gd 跳转到 Bean 定义"
  echo "  · application.properties/yaml 智能补全"
  echo "  · @RequestMapping 路径提示"
  echo "  · Spring Security 配置辅助"
else
  echo "✗ 下载失败，请手动下载："
  echo "  $DOWNLOAD_URL"
  echo "保存到: $JAR_PATH"
  exit 1
fi
