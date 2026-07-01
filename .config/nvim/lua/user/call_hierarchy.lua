-- Call Hierarchy 右侧边栏 + 代码预览
-- 布局：右列 72 宽，上方树（按内容自适应高度），下方代码预览
-- gR 打开，<CR> 跳转，p/o 预览，q 关闭

local M = {}

local state = {
  buf         = -1,   -- 调用链树 buffer（nofile，modifiable=false）
  win         = -1,   -- 调用链树 window（上方）
  preview_win = -1,   -- 代码预览 window（下方）
  entries     = {},   -- { file, lnum } 每行对应的跳转位置
  source_win  = -1,   -- 触发 gR 时的代码窗口
}

-- 宽度用相对值：右边一半（最小 60，最大 120）
local function sidebar_width()
  return math.max(60, math.min(120, math.floor(vim.o.columns * 0.5)))
end
local HEADER_SIZE = 2
local FOOTER_SIZE = 2
-- 最大递归深度（visited 集合防止循环调用，此限制纯粹为了性能）
-- 每增加一层请求数量指数增长，默认 6 层对大型项目通常够用
-- 如需更深：require("user.call_hierarchy").set_max_depth(10)
local MAX_DEPTH = 6

-- ──────────────────────────────────────────────
-- 构建带树形连线的文本行
-- ──────────────────────────────────────────────
local function build_tree(root)
  local lines   = {}
  local entries = {}
  local visited = {}

  local root_file  = vim.uri_to_fname(root.uri)
  local root_lnum  = root.selectionRange.start.line + 1
  local root_fname = vim.fn.fnamemodify(root_file, ":t")
  table.insert(lines,   "◉ " .. root.name .. "  [" .. root_fname .. ":" .. root_lnum .. "]")
  table.insert(entries, { file = root_file, lnum = root_lnum })

  local function add_callers(item, prefix, depth)
    if depth > MAX_DEPTH then return end
    local key = item.uri .. ":" .. tostring(item.range.start.line)
    if visited[key] then return end
    visited[key] = true

    local res = vim.lsp.buf_request_sync(
      0, "callHierarchy/incomingCalls", { item = item }, 8000)
    if not res then return end

    local callers = {}
    for _, r in pairs(res) do
      for _, call in ipairs(r.result or {}) do
        table.insert(callers, call.from)
      end
    end

    for i, caller in ipairs(callers) do
      local is_last   = (i == #callers)
      local conn      = is_last and "└─ " or "├─ "
      local child_pfx = prefix .. (is_last and "   " or "│  ")
      local path      = vim.uri_to_fname(caller.uri)
      local lnum      = caller.selectionRange.start.line + 1
      local is_m2     = path:find("/.m2/", 1, true) ~= nil
      local tag       = is_m2 and "  ⬡" or ""
      local fname     = vim.fn.fnamemodify(path, ":t")

      table.insert(lines, prefix .. conn .. caller.name ..
        "  [" .. fname .. ":" .. lnum .. "]" .. tag)
      table.insert(entries, { file = path, lnum = lnum })

      if not is_m2 then
        add_callers(caller, child_pfx, depth + 1)
      end
    end
  end

  add_callers(root, "", 0)
  return lines, entries
end

-- ──────────────────────────────────────────────
-- 代码预览：切换到 preview_win 打开文件，再回到树
-- 使用直接 window 切换（避免 nvim_win_call 的 buffer 混淆问题）
-- ──────────────────────────────────────────────
local function update_preview(row)
  if not vim.api.nvim_win_is_valid(state.preview_win) then return end
  local e = state.entries[row]
  if not e or not e.file or not e.lnum then return end
  if vim.fn.filereadable(e.file) == 0 then return end

  local cur_win = vim.api.nvim_get_current_win()
  pcall(function()
    vim.api.nvim_set_current_win(state.preview_win)
    local cur_name = vim.api.nvim_buf_get_name(0)
    if cur_name ~= e.file then
      vim.cmd("edit " .. vim.fn.fnameescape(e.file))
    end
    pcall(vim.api.nvim_win_set_cursor, 0, { e.lnum, 0 })
    vim.cmd("normal! zz")
  end)
  -- 无论成功失败，焦点都回到树窗口
  if vim.api.nvim_win_is_valid(cur_win) then
    vim.api.nvim_set_current_win(cur_win)
  end
end

-- ──────────────────────────────────────────────
-- 在 source_win 里跳转到 entry
-- ──────────────────────────────────────────────
local function open_in_source(entry, back_to_sidebar)
  if not entry or not entry.file then return end
  local sw = vim.api.nvim_win_is_valid(state.source_win)
           and state.source_win or vim.fn.win_getid(1)
  vim.api.nvim_set_current_win(sw)
  vim.cmd("edit " .. vim.fn.fnameescape(entry.file))
  vim.api.nvim_win_set_cursor(sw, { entry.lnum, 0 })
  vim.cmd("normal! zz")
  if back_to_sidebar and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_set_current_win(state.win)
  end
end

-- ──────────────────────────────────────────────
-- 创建窗口：右侧栏 SIDEBAR_WIDTH 宽，树和预览各占 50%
-- ──────────────────────────────────────────────
local function create_windows(source_win)
  vim.api.nvim_set_current_win(source_win)

  -- botright vsplit：右侧占屏幕 50%（相对定位，不用固定列数）
  local w = sidebar_width()
  vim.cmd("botright " .. w .. "vsplit")
  state.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(state.win, state.buf)
  vim.wo[state.win].winfixwidth    = true
  vim.wo[state.win].number         = false
  vim.wo[state.win].relativenumber = false
  vim.wo[state.win].wrap           = false
  vim.wo[state.win].signcolumn     = "no"
  vim.wo[state.win].cursorline     = true

  -- 树占整列高度的 50%（减去状态栏 2 行）
  local total_h = vim.o.lines - 2
  local tree_h  = math.floor(total_h * 0.5)
  vim.api.nvim_win_set_height(state.win, tree_h)

  -- 预览窗口（下半部分，独立 buffer 避免 E21 modifiable 错误）
  vim.cmd("belowright split")
  state.preview_win = vim.api.nvim_get_current_win()
  vim.cmd("enew")
  vim.bo[0].bufhidden = "wipe"
  vim.wo[state.preview_win].number         = true
  vim.wo[state.preview_win].relativenumber = false
  vim.wo[state.preview_win].wrap           = false
  vim.wo[state.preview_win].signcolumn     = "no"
  vim.wo[state.preview_win].cursorline     = true

  -- 焦点回到树窗口
  vim.api.nvim_set_current_win(state.win)
end

-- ──────────────────────────────────────────────
-- 侧边栏 buffer 的快捷键（只注册一次）
-- ──────────────────────────────────────────────
local function setup_keymaps(buf)
  local o = { buffer = buf, noremap = true, silent = true }

  vim.keymap.set("n", "<CR>", function()
    local row = vim.api.nvim_win_get_cursor(0)[1]
    open_in_source(state.entries[row], false)
  end, vim.tbl_extend("force", o, { desc = "Jump to entry" }))

  for _, key in ipairs({ "p", "o" }) do
    vim.keymap.set("n", key, function()
      local row = vim.api.nvim_win_get_cursor(0)[1]
      open_in_source(state.entries[row], true)
    end, vim.tbl_extend("force", o, { desc = "Preview entry (stay in sidebar)" }))
  end

  vim.keymap.set("n", "q", function()
    M.close_all()
    if vim.api.nvim_win_is_valid(state.source_win) then
      vim.api.nvim_set_current_win(state.source_win)
    end
  end, vim.tbl_extend("force", o, { desc = "Close call hierarchy" }))

  -- CursorMoved: 自动更新代码预览
  vim.api.nvim_create_autocmd("CursorMoved", {
    buffer   = buf,
    callback = function()
      local row = vim.api.nvim_win_get_cursor(0)[1]
      update_preview(row)
    end,
  })
end

-- ──────────────────────────────────────────────
-- 主入口
-- ──────────────────────────────────────────────
function M.open()
  local source_win = vim.api.nvim_get_current_win()

  local params  = vim.lsp.util.make_position_params()
  local prepare = vim.lsp.buf_request_sync(
    0, "textDocument/prepareCallHierarchy", params, 5000)

  if not prepare then
    vim.notify("gR: jdtls 未响应，请等待索引完成后重试", vim.log.levels.WARN)
    return
  end

  local root_items = {}
  for _, res in pairs(prepare) do
    if res.result then vim.list_extend(root_items, res.result) end
  end

  if #root_items == 0 then
    vim.notify("gR: 光标需在方法声明行（方法名处）", vim.log.levels.WARN)
    return
  end

  vim.notify("gR: 正在构建调用链（最多 4 层）...", vim.log.levels.INFO)
  local lines, entries = build_tree(root_items[1])

  if #entries <= 1 then
    vim.notify("gR: 未找到调用者（索引未完成或该方法未被调用）", vim.log.levels.INFO)
    return
  end

  -- 创建或复用树 buffer
  if not vim.api.nvim_buf_is_valid(state.buf) then
    state.buf = vim.api.nvim_create_buf(false, true)
    vim.bo[state.buf].buftype   = "nofile"
    vim.bo[state.buf].bufhidden = "hide"
    vim.bo[state.buf].swapfile  = false
    pcall(vim.api.nvim_buf_set_name, state.buf, "CallHierarchy")
    setup_keymaps(state.buf)
  end

  -- 填充内容
  local all_lines = {}
  table.insert(all_lines, " Call Hierarchy: " .. root_items[1].name)
  table.insert(all_lines, string.rep("─", sidebar_width() - 2))
  for _, l in ipairs(lines) do table.insert(all_lines, l) end
  table.insert(all_lines, string.rep("─", sidebar_width() - 2))
  table.insert(all_lines, " <CR>跳转  p/o预览  q关闭  <Leader>↑↓调高度")

  local offset_entries = {}
  for _ = 1, HEADER_SIZE do table.insert(offset_entries, {}) end
  for _, e in ipairs(entries) do table.insert(offset_entries, e) end
  for _ = 1, FOOTER_SIZE do table.insert(offset_entries, {}) end

  vim.bo[state.buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, all_lines)
  vim.bo[state.buf].modifiable = false

  state.entries    = offset_entries
  state.source_win = source_win

  -- 检查侧边栏是否已打开
  local tree_win_open = vim.api.nvim_win_is_valid(state.win)
                     and vim.api.nvim_win_get_buf(state.win) == state.buf

  if tree_win_open then
    vim.api.nvim_win_set_cursor(state.win, { HEADER_SIZE + 1, 0 })
    vim.api.nvim_set_current_win(state.win)
  else
    create_windows(source_win)
  end

  update_preview(HEADER_SIZE + 1)
end

-- ──────────────────────────────────────────────
-- 供 <Leader>w 使用的接口
-- ──────────────────────────────────────────────
function M.is_open()
  return vim.api.nvim_win_is_valid(state.win)
      and vim.api.nvim_win_get_buf(state.win) == state.buf
end

function M.close_all()
  if vim.api.nvim_win_is_valid(state.preview_win) then
    pcall(vim.api.nvim_win_close, state.preview_win, false)
  end
  if vim.api.nvim_win_is_valid(state.win) then
    pcall(vim.api.nvim_win_close, state.win, false)
  end
end

function M.reopen()
  if not vim.api.nvim_buf_is_valid(state.buf) then
    vim.notify("gR: 没有保存的调用链，请重新按 gR", vim.log.levels.INFO)
    return
  end
  if M.is_open() then return end

  local src = vim.api.nvim_win_is_valid(state.source_win)
           and state.source_win or vim.fn.win_getid(1)

  create_windows(src)

  -- 预览第一个有效条目
  for i, e in ipairs(state.entries) do
    if e.file then
      vim.api.nvim_win_set_cursor(state.win, { i, 0 })
      update_preview(i)
      break
    end
  end
end

-- 动态调整最大递归深度（visited 防循环，此值只影响性能/结果量）
-- 用法：:lua require("user.call_hierarchy").set_max_depth(10)
function M.set_max_depth(n)
  MAX_DEPTH = math.max(1, n)
  vim.notify("gR 最大深度已设为 " .. MAX_DEPTH .. " 层", vim.log.levels.INFO)
end

return M
