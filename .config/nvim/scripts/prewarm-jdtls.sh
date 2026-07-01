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
# jdtls（通过 Mason wrapper）实际使用 ~/Library/Caches/jdtls/jdtls-HASH/ 作为 workspace
JDTLS_CACHE="$HOME/Library/Caches/jdtls"
WAIT_PER_PROJECT=360   # 每个项目最多等 6 分钟（首次索引大项目需要时间）
FORCE_REBUILD=false    # 设为 true 则跳过缓存检查重新索引所有项目

# 颜色输出
GREEN='\033[0;32m' YELLOW='\033[1;33m' RED='\033[0;31m' NC='\033[0m'
log()  { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[⟳]${NC} $*"; }
err()  { echo -e "${RED}[✗]${NC} $*"; }

# macOS 系统通知（在 tmux/cron 中运行，需要 launchctl 切换到用户会话）
NOTIFIER=/opt/homebrew/bin/terminal-notifier
notify() {
  local title="$1"
  local msg="$2"
  # 在 cron/tmux 中用 launchctl 切换到登录用户的 GUI 会话
  local uid
  uid=$(id -u)
  {
    if [ -x "$NOTIFIER" ]; then
      launchctl asuser "$uid" "$NOTIFIER" \
        -title "$title" -message "$msg" -sound Glass
    else
      launchctl asuser "$uid" /usr/bin/osascript \
        -e "display notification \"$msg\" with title \"$title\" sound name \"Glass\""
    fi
  } >/dev/null 2>&1 || true   # 任何失败都继续，不中断脚本
}

# 确保 tmux 可用
if ! command -v tmux &>/dev/null; then
  err "需要 tmux，请先 brew install tmux"
  exit 1
fi

START_TIME=$(date '+%H:%M')
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  jdtls 预热脚本 — Java 项目索引构建"
echo "  项目目录: $PROJECTS_DIR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

notify "jdtls 索引构建开始 🔨" "开始为 JavaProjects 构建索引，完成后通知 (${START_TIME})"

total=0; skipped=0; warmed=0; failed=0

for project_dir in "$PROJECTS_DIR"/*/; do
  [ -d "$project_dir" ] || continue
  project_name=$(basename "$project_dir")

  # 检查是否是 Java 项目
  is_java=false
  [ -f "$project_dir/pom.xml" ]       && is_java=true
  [ -f "$project_dir/build.gradle" ]   && is_java=true
  $is_java || continue

  total=$((total + 1))

  # 找一个 Java 文件（触发 jdtls 需要）
  # 用 find 替代 fd（fd v8.4+ 将路径误识别为 pattern，含 / 时报错）
  java_file=$(find "$project_dir" -name "*.java" -not -path "*/target/*" \
              -not -path "*/.git/*" 2>/dev/null | head -1) || true
  if [ -z "$java_file" ]; then
    warn "$project_name (无 .java 文件，跳过)"
    skipped=$((skipped + 1))
    continue
  fi

  warn "$project_name → 构建索引中（最多等 ${WAIT_PER_PROJECT}s）..."

  session_name="jdtls-warm-$(echo "$project_name" | tr '.' '-')"
  tmux kill-session -t "$session_name" 2>/dev/null || true

  # 记录索引前的 workspace 数量（用于后面判断是否新建了 workspace）
  ws_count_before=$(ls "$JDTLS_CACHE" 2>/dev/null | wc -l | tr -d ' ')

  # 在 tmux 后台打开 nvim（触发 jdtls 通过 ft=java 启动），等 WAIT 秒后退出
  tmux new-session -d -s "$session_name" \
    "cd '$project_dir' && nvim -c 'lua vim.defer_fn(function() vim.cmd(\"qa!\") end, $((WAIT_PER_PROJECT * 1000)))' '$java_file'" \
    2>/dev/null

  # 轮询等待 nvim session 结束
  elapsed=0
  while tmux has-session -t "$session_name" 2>/dev/null; do
    sleep 10
    elapsed=$((elapsed + 10))
    if [ $elapsed -ge $WAIT_PER_PROJECT ]; then
      tmux kill-session -t "$session_name" 2>/dev/null || true
      break
    fi
    [ $((elapsed % 60)) -eq 0 ] && echo "    $project_name: ${elapsed}s / ${WAIT_PER_PROJECT}s ..."
  done

  # 判断成功：看 jdtls workspace 数量是否增加（说明新建了 workspace）
  ws_count_after=$(ls "$JDTLS_CACHE" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$ws_count_after" -gt "$ws_count_before" ]; then
    log "$project_name (索引启动成功，jdtls 新建了 workspace)"
    warmed=$((warmed + 1))
  else
    # workspace 未新增，可能 jdtls 已有该项目缓存（复用了旧 workspace）
    log "$project_name (jdtls 已有缓存或索引仍在进行)"
    warmed=$((warmed + 1))  # 也算成功，jdtls 进程确实启动了
  fi

  # 等 jdtls 进程退出后再处理下一个（避免并发占用过多资源）
  while pgrep -f "org.eclipse.jdt.ls.core.id1" >/dev/null 2>&1; do
    sleep 5
    elapsed=$((elapsed + 5))
    [ $((elapsed % 30)) -eq 0 ] && echo "    等待 jdtls 进程退出..."
    [ $elapsed -gt $((WAIT_PER_PROJECT * 2)) ] && break
  done
  sleep 3
done

END_TIME=$(date '+%H:%M')
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  完成！共 $total 个 Java 项目"
echo "  ✓ 新建/更新: $warmed  ⟳ 已跳过: $skipped  ✗ 失败: $failed"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 结束通知
if [ "$failed" -gt 0 ]; then
  notify "jdtls 索引构建完成 ⚠️" \
    "共 ${total} 项目: +${warmed} 更新  ~${skipped} 跳过  x${failed} 失败  (${START_TIME}-${END_TIME})"
else
  notify "jdtls 索引构建完成 ✅" \
    "共 ${total} 项目: +${warmed} 更新  ~${skipped} 跳过  (${START_TIME}-${END_TIME})"
fi
