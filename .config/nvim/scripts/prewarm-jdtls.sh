#!/usr/bin/env bash
# prewarm-jdtls.sh — 为 ~/Company/JavaProjects 下所有 Java 项目预热 jdtls 索引
#
# 使用方法：
#   手动运行: bash ~/.config/nvim/scripts/prewarm-jdtls.sh
#   （每次运行自动清空上次日志）

# 日志文件：每次运行前自动清空（不使用 >> 追加，避免无限增长）
LOG_FILE="$HOME/prewarm-jdtls.log"
: > "$LOG_FILE"             # 清空旧日志
exec > >(tee -a "$LOG_FILE") 2>&1   # 同时输出到终端和日志文件
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
WAIT_PER_PROJECT=1200  # 每个项目最多等 20 分钟（大型项目首次索引约需 10-15 分钟）
                       # 超时不等于失败：jdtls 增量缓存保留，下次继续
MAX_JOBS=4             # 最多同时跑几个 jdtls（内存限制，建议不超过 2）
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

# 原子计数器（临时文件，支持并行子进程写入）
TMPDIR_CNT=$(mktemp -d)
echo 0 > "$TMPDIR_CNT/total"
echo 0 > "$TMPDIR_CNT/warmed"
echo 0 > "$TMPDIR_CNT/skipped"
echo 0 > "$TMPDIR_CNT/failed"
TOTAL_PROJECTS=0  # 预计总项目数（main 里赋值后各 subprocess 读取）
cnt_inc() { echo $(( $(cat "$TMPDIR_CNT/$1") + 1 )) > "$TMPDIR_CNT/$1"; }
cnt_get() { cat "$TMPDIR_CNT/$1"; }

# ASCII 进度条：draw_bar <done> <total> [width=25]
# 用 # 和 . 替代 Unicode 方块字符，所有终端均可渲染
draw_bar() {
  local done=$1 total=$2 width=${3:-25}
  [ "$total" -le 0 ] && printf "[%s] 0/?" "$(printf '.%.0s' $(seq 1 $width))" && return
  local filled=$(( done * width / total ))
  local empty=$(( width - filled ))
  local bar=""
  [ "$filled" -gt 0 ] && bar="${bar}$(printf '#%.0s' $(seq 1 $filled))"
  [ "$empty"  -gt 0 ] && bar="${bar}$(printf '.%.0s' $(seq 1 $empty))"
  local pct=$(( done * 100 / total ))
  printf "[%s] %d/%d (%d%%)" "$bar" "$done" "$total" "$pct"
}

# 每个项目的状态文件：$TMPDIR_CNT/running_<safe_name> 存储当前耗时(秒)
# 完成后删除，monitor 通过文件列表感知哪些项目仍在运行
_safe_name() { echo "$1" | tr -cd 'a-zA-Z0-9-_'; }
set_running() { echo "$2" > "$TMPDIR_CNT/running_$(_safe_name "$1")"; }
del_running() { rm -f "$TMPDIR_CNT/running_$(_safe_name "$1")"; }

# ── Monitor 进程（独立运行，每 30s 打印一次快照）──────────────
run_monitor() {
  local total=$1
  while true; do
    sleep 5
    local done=$(( $(cnt_get warmed) + $(cnt_get skipped) ))
    local ts; ts=$(date '+%H:%M:%S')
    echo ""
    printf "  -- %s 进度快照 " "$ts"
    printf '%60s\n' '' | tr ' ' '-'

    # 每个正在运行的项目单独一行：项目名 + 时间进度条
    local running=0
    for f in "$TMPDIR_CNT"/running_*; do
      [ -f "$f" ] || continue
      local raw; raw=$(basename "$f")
      local name="${raw#running_}"    # 去掉前缀
      local elapsed; elapsed=$(cat "$f" 2>/dev/null || echo 0)
      local proj_bar; proj_bar=$(draw_bar "$elapsed" "$WAIT_PER_PROJECT" 18)
      # 读取 jdtls 真实进度消息（由 nvim Lua 写入）
      local real_prog="等待 jdtls..."
      local prog_file="$TMPDIR_CNT/progress_$name"
      [ -f "$prog_file" ] && real_prog=$(cat "$prog_file" 2>/dev/null || echo "等待 jdtls...")
      # 截断长名称避免 printf 格式溢出
      local short_name="${name:0:28}"
      printf "  %-28.28s %s %4ds  %s\n" "$short_name" "$proj_bar" "$elapsed" "$real_prog"
      running=$((running + 1))
    done

    [ $running -eq 0 ] && echo "  (无项目运行中)"

    # 整体完成进度
    local overall; overall=$(draw_bar "$done" "$total" 20)
    printf "  整体: %s  完成%d 运行%d 待处理%d\n" \
      "$overall" "$done" "$running" "$(( total - done - running ))"
    printf '%60s\n' '' | tr ' ' '-'
  done
}

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

  # Lua 脚本：
  #   1. 监听 jdtls 的 LspProgress 事件，把实时进度写到共享文件
  #   2. 索引完成（kind="end"）时标记，超时后 qa!
  local lua_file="$TMPDIR_CNT/auto_quit_$$.lua"
  local progress_file="$TMPDIR_CNT/progress_$(_safe_name "$project_name")"
  local timeout_ms=$(( WAIT_PER_PROJECT * 1000 ))

  cat > "$lua_file" << LUAEOF
-- jdtls 实时进度跟踪：把 LspProgress 消息写到文件，供 monitor 进程读取
local progress_file = "${progress_file}"

vim.api.nvim_create_autocmd("LspProgress", {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client or client.name ~= "jdtls" then return end
    local val = (ev.data.params or {}).value or {}
    local line = ""
    if val.kind == "begin" then
      line = "开始: " .. (val.title or "Building workspace")
    elseif val.kind == "report" then
      local pct = val.percentage and (val.percentage .. "%") or ""
      local msg = val.message or val.title or ""
      line = msg .. (pct ~= "" and (" [" .. pct .. "]") or "")
    elseif val.kind == "end" then
      line = "DONE"
      -- 索引完成后 3s 退出 nvim
      vim.defer_fn(function() pcall(vim.cmd, "qa!") end, 3000)
    end
    if line ~= "" then
      local f = io.open(progress_file, "w")
      if f then f:write(line); f:close() end
    end
  end
})

-- 兜底：超时后强制退出（jdtls 未完成时也不卡死）
vim.defer_fn(function()
  pcall(vim.cmd, "qa!")
end, ${timeout_ms})
LUAEOF
  local nvim_cmd="cd '$project_dir' && nvim -S '$lua_file' '$java_file'"
  local nvim_pid=""

  if [ "${USE_TMUX:-true}" = true ] && command -v tmux &>/dev/null; then
    # ── 方案 A：tmux（默认，cron 环境最稳定）──────────────────────
    local session_name="jdtls-${project_name:0:30}"
    tmux kill-session -t "$session_name" 2>/dev/null || true
    tmux new-session -d -s "$session_name" "bash -c \"$nvim_cmd\"" 2>/dev/null || true
    set_running "$project_name" "0"   # 立即注册，让 monitor 5s 内就能看到

    local elapsed=0
    while tmux has-session -t "$session_name" 2>/dev/null; do
      sleep 5; elapsed=$((elapsed + 5))
      # 有超时：超时后强制关闭
      if [ "${WAIT_PER_PROJECT:-0}" -gt 0 ] && [ $elapsed -ge "$WAIT_PER_PROJECT" ]; then
        warn "$project_name 超时 ${WAIT_PER_PROJECT}s，强制关闭（增量缓存已保留）"
        tmux kill-session -t "$session_name" 2>/dev/null || true
        break
      fi
      # 更新状态文件（供 monitor 进程读取）
      set_running "$project_name" "$elapsed"
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
      # 更新状态文件（供 monitor 进程读取）
      set_running "$project_name" "$elapsed"
    done
    wait "$nvim_pid" 2>/dev/null || true
  fi

  # 完成：删除状态文件和进度文件（monitor 据此感知项目结束）
  del_running "$project_name"
  rm -f "$TMPDIR_CNT/progress_$(_safe_name "$project_name")"

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

# 预统计 Java 项目总数（供进度条使用）
for _d in "$PROJECTS_DIR"/*/; do
  { [ -f "$_d/pom.xml" ] || [ -f "$_d/build.gradle" ]; } && \
    TOTAL_PROJECTS=$((TOTAL_PROJECTS + 1))
done
echo "  共检测到 ${TOTAL_PROJECTS} 个 Java 项目"

notify "jdtls 索引构建开始 🔨" "并行预热 ${TOTAL_PROJECTS} 个项目（${MAX_JOBS} 并发，${START_TIME}）"

# 启动 monitor 进程（每 30s 打印一次快照，汇总所有项目状态）
run_monitor "$TOTAL_PROJECTS" &
MONITOR_PID=$!

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

# 停止 monitor 进程
kill "$MONITOR_PID" 2>/dev/null || true

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
