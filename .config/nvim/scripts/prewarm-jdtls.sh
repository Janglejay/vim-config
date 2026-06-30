#!/usr/bin/env bash
# prewarm-jdtls.sh — 为 ~/Company/JavaProjects 下所有 Java 项目预热 jdtls 索引
#
# 使用方法：
#   手动运行: bash ~/.config/nvim/scripts/prewarm-jdtls.sh
#   定时任务: crontab -e 添加 "0 22 * * 0 bash ~/.config/nvim/scripts/prewarm-jdtls.sh"
#             (每周日 22:00 自动运行)
#
# 原理：
#   用 tmux 在后台为每个项目打开 Neovim（找一个 .java 文件触发 jdtls）
#   jdtls 会建立本地 workspace 缓存，下次在 Neovim 中打开项目时直接从缓存加载（几秒内就绪）
#   一次预热后，workspace 缓存持久保存，只有项目大改动才需要重新预热

set -euo pipefail

PROJECTS_DIR="$HOME/Company/JavaProjects"
WORKSPACE_DIR="$HOME/.local/share/nvim/jdtls-workspace"
WAIT_PER_PROJECT=180   # 每个项目最多等 3 分钟（大项目首次可能需要更长）
FORCE_REBUILD=false    # 设为 true 则重建所有已有 workspace

# 颜色输出
GREEN='\033[0;32m' YELLOW='\033[1;33m' RED='\033[0;31m' NC='\033[0m'
log()  { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[⟳]${NC} $*"; }
err()  { echo -e "${RED}[✗]${NC} $*"; }

# 确保 tmux 可用
if ! command -v tmux &>/dev/null; then
  err "需要 tmux，请先 brew install tmux"
  exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  jdtls 预热脚本 — Java 项目索引构建"
echo "  项目目录: $PROJECTS_DIR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

total=0; skipped=0; warmed=0; failed=0

for project_dir in "$PROJECTS_DIR"/*/; do
  [ -d "$project_dir" ] || continue
  project_name=$(basename "$project_dir")
  workspace="$WORKSPACE_DIR/$project_name"

  # 检查是否是 Java 项目
  is_java=false
  [ -f "$project_dir/pom.xml" ]       && is_java=true
  [ -f "$project_dir/build.gradle" ]   && is_java=true
  $is_java || continue

  total=$((total + 1))

  # 检查 workspace 缓存是否存在且不太旧（7天内）
  if [ "$FORCE_REBUILD" = false ] && [ -d "$workspace/.metadata" ]; then
    cache_age=$(( ($(date +%s) - $(stat -f %m "$workspace/.metadata")) / 86400 ))
    if [ "$cache_age" -lt 7 ]; then
      log "$project_name (缓存有效，${cache_age}天前构建，跳过)"
      skipped=$((skipped + 1))
      continue
    fi
  fi

  # 找一个 Java 文件（触发 jdtls 需要）
  java_file=$(fd --type f -e java --max-results 1 "$project_dir" 2>/dev/null | head -1)
  if [ -z "$java_file" ]; then
    warn "$project_name (无 .java 文件，跳过)"
    skipped=$((skipped + 1))
    continue
  fi

  warn "$project_name → 构建索引中（最多等 ${WAIT_PER_PROJECT}s）..."

  session_name="jdtls-warm-$(echo "$project_name" | tr '.' '-')"

  # 清理可能残留的旧 session
  tmux kill-session -t "$session_name" 2>/dev/null || true

  # 在后台 tmux session 中打开 nvim
  # nvim 会触发 jdtls 通过 ft=java 自动加载，jdtls 开始索引
  # 等待 WAIT_PER_PROJECT 秒后自动退出（通过 timer 发送 :qa!）
  tmux new-session -d -s "$session_name" \
    "cd '$project_dir' && nvim -c 'lua vim.defer_fn(function() vim.cmd(\"qa!\") end, $((WAIT_PER_PROJECT * 1000)))' '$java_file'" \
    2>/dev/null

  # 等待 session 结束（nvim 关闭）
  elapsed=0
  while tmux has-session -t "$session_name" 2>/dev/null; do
    sleep 5
    elapsed=$((elapsed + 5))
    if [ $elapsed -ge $WAIT_PER_PROJECT ]; then
      tmux kill-session -t "$session_name" 2>/dev/null || true
      break
    fi
    # 每 30 秒打印一次进度
    [ $((elapsed % 30)) -eq 0 ] && echo "    $project_name: ${elapsed}s / ${WAIT_PER_PROJECT}s ..."
  done

  # 检查 workspace 是否建立成功
  if [ -d "$workspace/.metadata" ]; then
    log "$project_name (索引完成)"
    warmed=$((warmed + 1))
  else
    err "$project_name (索引可能未完成，可能需要更多时间)"
    failed=$((failed + 1))
  fi

  # 项目间休息 5 秒，避免同时多个 jdtls 进程抢资源
  sleep 5
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  完成！共 $total 个 Java 项目"
echo "  ✓ 新建/更新: $warmed  ⟳ 已跳过: $skipped  ✗ 失败: $failed"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
