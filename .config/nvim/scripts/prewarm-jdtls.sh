#!/usr/bin/env bash
# prewarm-jdtls.sh — 为 ~/Company/JavaProjects 下所有 Java 项目预热 jdtls 索引
#
# 使用方法：
#   手动运行: bash ~/.config/nvim/scripts/prewarm-jdtls.sh
#   定时任务: crontab -e → 0 12 * * 1,3,5 bash ~/.config/nvim/scripts/prewarm-jdtls.sh >> ~/prewarm-jdtls.log 2>&1

set -euo pipefail

PROJECTS_DIR="$HOME/Company/JavaProjects"
JDTLS_CACHE="$HOME/Library/Caches/jdtls"   # jdtls（Mason wrapper）实际的 workspace 目录
WAIT_PER_PROJECT=360   # 每个项目最多等 6 分钟
MAX_JOBS=2             # 最多同时跑几个 jdtls（内存限制，建议不超过 2）
FORCE_REBUILD=false

# 颜色输出
GREEN='\033[0;32m' YELLOW='\033[1;33m' RED='\033[0;31m' NC='\033[0m'
log()  { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[⟳]${NC} $*"; }
err()  { echo -e "${RED}[✗]${NC} $*"; }

# macOS 系统通知（launchctl 确保 cron/tmux 环境也能弹窗）
NOTIFIER=/opt/homebrew/bin/terminal-notifier
notify() {
  local uid; uid=$(id -u)
  { if [ -x "$NOTIFIER" ]; then
      launchctl asuser "$uid" "$NOTIFIER" -title "$1" -message "$2" -sound Glass
    else
      launchctl asuser "$uid" /usr/bin/osascript \
        -e "display notification \"$2\" with title \"$1\" sound name \"Glass\""
    fi
  } >/dev/null 2>&1 || true
}

# 原子计数器（用临时文件，支持并行子进程写入）
TMPDIR_CNT=$(mktemp -d)
echo 0 > "$TMPDIR_CNT/total"
echo 0 > "$TMPDIR_CNT/warmed"
echo 0 > "$TMPDIR_CNT/skipped"
echo 0 > "$TMPDIR_CNT/failed"
cnt_inc() { echo $(( $(cat "$TMPDIR_CNT/$1") + 1 )) > "$TMPDIR_CNT/$1"; }
cnt_get() { cat "$TMPDIR_CNT/$1"; }
cleanup() { rm -rf "$TMPDIR_CNT"; }
trap cleanup EXIT

# ──────────────────────────────────────────────────────────────
# 单项目处理函数（在后台子进程中运行）
# ──────────────────────────────────────────────────────────────
process_project() {
  local project_dir="$1"
  local project_name; project_name=$(basename "$project_dir")

  # 找一个 Java 文件触发 jdtls（用 find，fd v8.4+ 有路径识别 bug）
  local java_file
  java_file=$(find "$project_dir" -name "*.java" \
              -not -path "*/target/*" -not -path "*/.git/*" \
              2>/dev/null | head -1) || true

  if [ -z "$java_file" ]; then
    warn "$project_name (无 .java 文件，跳过)"
    cnt_inc skipped
    return
  fi

  warn "$project_name → 构建索引中（最多 ${WAIT_PER_PROJECT}s）..."

  local session_name="jdtls-${project_name:0:30}"
  tmux kill-session -t "$session_name" 2>/dev/null || true

  local ws_before; ws_before=$(ls "$JDTLS_CACHE" 2>/dev/null | wc -l | tr -d ' ')

  # 在独立 tmux session 里开 nvim，触发 jdtls 通过 FileType=java 加载
  tmux new-session -d -s "$session_name" \
    "cd '$project_dir' && nvim \
      -c 'lua vim.defer_fn(function() vim.cmd(\"qa!\") end, $((WAIT_PER_PROJECT * 1000)))' \
      '$java_file'" 2>/dev/null || true

  # 等待 nvim session 结束（或超时强制关闭）
  local elapsed=0
  while tmux has-session -t "$session_name" 2>/dev/null; do
    sleep 10; elapsed=$((elapsed + 10))
    if [ $elapsed -ge $WAIT_PER_PROJECT ]; then
      tmux kill-session -t "$session_name" 2>/dev/null || true
      break
    fi
    [ $((elapsed % 60)) -eq 0 ] && echo "    [$project_name] ${elapsed}s/${WAIT_PER_PROJECT}s ..."
  done

  # 结果判断
  local ws_after; ws_after=$(ls "$JDTLS_CACHE" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$ws_after" -gt "$ws_before" ]; then
    log "$project_name ✓ 新建 workspace（首次索引）"
  else
    log "$project_name ✓ 复用已有缓存（已索引过）"
  fi
  cnt_inc warmed
}

# ──────────────────────────────────────────────────────────────
# 主流程：并行处理，最多 MAX_JOBS 个并发
# ──────────────────────────────────────────────────────────────
if ! command -v tmux &>/dev/null; then
  err "需要 tmux，请先: brew install tmux"; exit 1
fi

START_TIME=$(date '+%H:%M')
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  jdtls 预热脚本 — 并行 ${MAX_JOBS} 个项目"
echo "  目录: $PROJECTS_DIR  |  开始: ${START_TIME}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

notify "jdtls 索引构建开始 🔨" "并行预热 JavaProjects (${MAX_JOBS} 并发，${START_TIME})"

pids=()   # 后台子进程 PID 列表

for project_dir in "$PROJECTS_DIR"/*/; do
  [ -d "$project_dir" ] || continue
  local_name=$(basename "$project_dir")

  # 快速过滤非 Java 项目（不进子进程，避免 overhead）
  if [ ! -f "$project_dir/pom.xml" ] && [ ! -f "$project_dir/build.gradle" ]; then
    continue
  fi
  cnt_inc total

  # 启动后台子进程处理项目
  process_project "$project_dir" &
  pids+=($!)

  # 限流：达到 MAX_JOBS 时等任意一个完成
  while [ ${#pids[@]} -ge $MAX_JOBS ]; do
    new_pids=()
    for pid in "${pids[@]}"; do
      if kill -0 "$pid" 2>/dev/null; then
        new_pids+=("$pid")   # 还在跑
      fi
    done
    pids=("${new_pids[@]+"${new_pids[@]}"}")
    [ ${#pids[@]} -ge $MAX_JOBS ] && sleep 5
  done
done

# 等待所有剩余子进程完成
for pid in "${pids[@]+"${pids[@]}"}"; do
  wait "$pid" 2>/dev/null || true
done

END_TIME=$(date '+%H:%M')
total=$(cnt_get total); warmed=$(cnt_get warmed)
skipped=$(cnt_get skipped); failed=$(cnt_get failed)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  完成！共 $total 个 Java 项目"
printf "  ✓ 索引: %-4s  ⟳ 跳过: %-4s  ✗ 失败: %-4s  时间: %s→%s\n" \
  "$warmed" "$skipped" "$failed" "$START_TIME" "$END_TIME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$failed" -gt 0 ]; then
  notify "jdtls 索引完成 ⚠️" \
    "共${total}项目: +${warmed}索引 ~${skipped}跳过 x${failed}失败 (${START_TIME}-${END_TIME})"
else
  notify "jdtls 索引完成 ✅" \
    "共${total}项目: +${warmed}索引 ~${skipped}跳过 (${START_TIME}-${END_TIME})"
fi
