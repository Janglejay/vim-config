#!/usr/bin/env bash
# prewarm-jdtls.sh — 为 ~/Company/JavaProjects 下所有 Java 项目预热 jdtls 索引
#
# 使用方法：
#   手动运行: bash ~/.config/nvim/scripts/prewarm-jdtls.sh
#   定时任务: crontab -e → 0 12 * * 1,3,5 bash ~/.config/nvim/scripts/prewarm-jdtls.sh >> ~/prewarm-jdtls.log 2>&1

set -euo pipefail

# ──────────────────────────────────────────────────────────────
# 全局资源跟踪（用于 cleanup）
# ──────────────────────────────────────────────────────────────
declare -a pids=()          # 后台子进程 PID
TMPDIR_CNT=""               # 原子计数临时目录（后面赋值）
CLEANUP_DONE=false          # 防止重复清理
INTERRUPTED=false           # 是否被中断

# 资源清理函数：无论正常退出/中断/错误都会执行
cleanup() {
  [ "$CLEANUP_DONE" = true ] && return
  CLEANUP_DONE=true

  echo ""
  warn "释放资源..."

  # 1. 发送 SIGTERM 给所有后台子进程（含进程组）
  for pid in "${pids[@]+"${pids[@]}"}"; do
    # 尝试终止整个进程组（避免孤儿进程）
    kill -- -"$pid" 2>/dev/null || kill -TERM "$pid" 2>/dev/null || true
  done

  # 等待子进程退出（最多 8 秒），超时则 SIGKILL
  local deadline=$(( $(date +%s) + 8 ))
  for pid in "${pids[@]+"${pids[@]}"}"; do
    while kill -0 "$pid" 2>/dev/null && [ "$(date +%s)" -lt "$deadline" ]; do
      sleep 1
    done
    kill -KILL "$pid" 2>/dev/null || true
  done

  # 2. 关闭所有本脚本创建的 tmux sessions（命名约定：jdtls- 前缀）
  if command -v tmux &>/dev/null; then
    tmux list-sessions -F '#{session_name}' 2>/dev/null \
      | grep '^jdtls-' \
      | while read -r s; do tmux kill-session -t "$s" 2>/dev/null || true; done
  fi

  # 3. 清理临时目录（原子计数器）
  [ -n "${TMPDIR_CNT:-}" ] && [ -d "$TMPDIR_CNT" ] && rm -rf "$TMPDIR_CNT"

  log "资源释放完成"
}

# 中断处理（Ctrl+C / kill）：先清理再通知
on_interrupt() {
  INTERRUPTED=true
  echo ""
  err "收到中断信号，正在清理所有资源..."
  cleanup
  local uid; uid=$(id -u)
  { launchctl asuser "$uid" /opt/homebrew/bin/terminal-notifier \
      -title "jdtls 索引被中断 ⚠️" \
      -message "脚本被手动中断，已清理所有 tmux sessions 和后台进程" \
      -sound Sosumi; } >/dev/null 2>&1 || true
  exit 130
}

# 注册信号处理：
#   EXIT  = 正常退出（cleanup 做最后收尾）
#   INT   = Ctrl+C
#   TERM  = kill 命令
trap cleanup EXIT
trap on_interrupt INT TERM

PROJECTS_DIR="$HOME/Company/JavaProjects"
JDTLS_CACHE="$HOME/Library/Caches/jdtls"   # jdtls（Mason wrapper）实际的 workspace 目录
WAIT_PER_PROJECT=0     # 0 = 不限时，等 jdtls 自然完成（推荐，脚本在凌晨/中午跑）
                       # 改为正整数（秒）可设超时，超时后 jdtls 增量缓存仍保留
MAX_JOBS=2             # 最多同时跑几个 jdtls（内存限制，建议不超过 2）
FORCE_REBUILD=false
# 提供 PTY 的方式：tmux（默认）或 script（macOS 内置，不需要额外安装）
# 改为 script 时设为 false
USE_TMUX=true

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
# 注意：cleanup 和 trap 已在脚本顶部定义，此处不重复注册

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

  local wait_desc; wait_desc=$( [ "${WAIT_PER_PROJECT:-0}" -eq 0 ] && echo "无时间限制" || echo "最多 ${WAIT_PER_PROJECT}s" )
  warn "$project_name → 构建索引中（${wait_desc}）..."

  local ws_before; ws_before=$(ls "$JDTLS_CACHE" 2>/dev/null | wc -l | tr -d ' ')

  # nvim 自动退出命令：有超时则用 defer_fn 定时 qa!，无超时则不注入（jdtls 完成后手动退出）
  # 注：jdtls 完成索引后不会自动关闭 nvim，无超时模式下 nvim 会一直等
  # 解决方案：用 LspProgress "end" 事件检测索引完成，自动退出
  local auto_quit_lua=""
  if [ "${WAIT_PER_PROJECT:-0}" -gt 0 ]; then
    auto_quit_lua="-c 'lua vim.defer_fn(function() vim.cmd(\"qa!\") end, $((WAIT_PER_PROJECT * 1000)))'"
  else
    # 无限等待模式：监听 jdtls 索引完成事件，完成后自动退出
    auto_quit_lua="-c 'lua vim.api.nvim_create_autocmd(\"LspProgress\", { callback = function(ev) local v = (ev.data.params or {}).value or {}; if v.kind == \"end\" then vim.defer_fn(function() vim.cmd(\"qa!\") end, 3000) end end })'"
  fi
  local nvim_cmd="cd '$project_dir' && nvim $auto_quit_lua '$java_file'"
  local nvim_pid=""

  if [ "${USE_TMUX:-true}" = true ] && command -v tmux &>/dev/null; then
    # ── 方案 A：tmux（默认，cron 环境最稳定）──────────────────────
    local session_name="jdtls-${project_name:0:30}"
    tmux kill-session -t "$session_name" 2>/dev/null || true
    tmux new-session -d -s "$session_name" "bash -c \"$nvim_cmd\"" 2>/dev/null || true

    local elapsed=0
    while tmux has-session -t "$session_name" 2>/dev/null; do
      sleep 10; elapsed=$((elapsed + 10))
      # 有超时：超时后强制关闭
      if [ "${WAIT_PER_PROJECT:-0}" -gt 0 ] && [ $elapsed -ge "$WAIT_PER_PROJECT" ]; then
        warn "$project_name 超时 ${WAIT_PER_PROJECT}s，强制关闭（增量缓存已保留）"
        tmux kill-session -t "$session_name" 2>/dev/null || true
        break
      fi
      [ $((elapsed % 60)) -eq 0 ] && echo "    [$project_name] ${elapsed}s ..."
    done

  else
    # ── 方案 B：script（macOS 内置 PTY，不需要 tmux）──────────────
    (
      cd "$project_dir"
      if [ "${WAIT_PER_PROJECT:-0}" -gt 0 ]; then
        script -q /dev/null timeout "$WAIT_PER_PROJECT" bash -c "$nvim_cmd"
      else
        script -q /dev/null bash -c "$nvim_cmd"
      fi
    ) >/dev/null 2>&1 &
    nvim_pid=$!

    local elapsed=0
    while kill -0 "$nvim_pid" 2>/dev/null; do
      sleep 10; elapsed=$((elapsed + 10))
      [ $((elapsed % 60)) -eq 0 ] && echo "    [$project_name] ${elapsed}s ..."
    done
    wait "$nvim_pid" 2>/dev/null || true
  fi

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
if [ "${USE_TMUX:-true}" = true ] && ! command -v tmux &>/dev/null; then
  warn "未找到 tmux，自动切换为 script 模式（macOS 内置，无需安装）"
  USE_TMUX=false
fi

START_TIME=$(date '+%H:%M')
PTY_MODE=$( [ "${USE_TMUX:-true}" = true ] && echo "tmux" || echo "script" )
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  jdtls 预热脚本 — 并行 ${MAX_JOBS} 个项目  [PTY: $PTY_MODE]"
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
