-- Call Hierarchy 右侧边栏
-- gR 打开，<CR> 跳转，p/o 预览不离开，q 关闭
-- gl (=<C-w>l) 从代码窗口进入侧边栏，gh 返回代码窗口

local M = {}

local state = {
  buf        = -1,   -- 侧边栏 buffer
  win        = -1,   -- 侧边栏 window
  entries    = {},   -- { file, lnum } 每行对应的跳转位置
  source_win = -1,   -- 触发 gR 时的代码窗口
}

-- 构建带树形连线的文本行
local function build_tree(root)
  local lines   = {}
  local entries = {}
  local visited = {}

  -- Root 行
  local root_file = vim.uri_to_fname(root.uri)
  local root_lnum = root.selectionRange.start.line + 1
  local root_fname = vim.fn.fnamemodify(root_file, ":t")
  table.insert(lines,   "◉ " .. root.name .. "  [" .. root_fname .. ":" .. root_lnum .. "]")
  table.insert(entries, { file = root_file, lnum = root_lnum })

  local function add_callers(item, prefix, depth)
    if depth > 4 then return end
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

      -- Maven 源码不再向上追溯
      if not is_m2 then
        add_callers(caller, child_pfx, depth + 1)
      end
    end
  end

  add_callers(root, "", 0)
  return lines, entries
end

-- 在 source_win 里打开文件并跳行
local function open_in_source(entry, back_to_sidebar)
  if not entry then return end
  local sw = state.source_win
  if not vim.api.nvim_win_is_valid(sw) then
    sw = vim.fn.win_getid(1)
  end

  vim.api.nvim_set_current_win(sw)
  vim.cmd("edit " .. vim.fn.fnameescape(entry.file))
  vim.api.nvim_win_set_cursor(sw, { entry.lnum, 0 })
  vim.cmd("normal! zz")

  if back_to_sidebar and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_set_current_win(state.win)
  end
end

-- 为侧边栏 buffer 绑定快捷键
local function setup_keymaps(buf)
  local o = { buffer = buf, noremap = true, silent = true }

  -- <CR>: 跳转到条目，焦点移到代码窗口
  vim.keymap.set("n", "<CR>", function()
    local row = vim.api.nvim_win_get_cursor(0)[1]
    open_in_source(state.entries[row], false)
  end, vim.tbl_extend("force", o, { desc = "Jump to entry" }))

  -- p / o: 预览条目（在代码窗口显示，但光标留在侧边栏）
  for _, key in ipairs({ "p", "o" }) do
    vim.keymap.set("n", key, function()
      local row = vim.api.nvim_win_get_cursor(0)[1]
      open_in_source(state.entries[row], true)
    end, vim.tbl_extend("force", o, { desc = "Preview entry (stay in sidebar)" }))
  end

  -- q: 关闭侧边栏
  vim.keymap.set("n", "q", function()
    if vim.api.nvim_win_is_valid(state.win) then
      vim.api.nvim_win_close(state.win, true)
    end
  end, vim.tbl_extend("force", o, { desc = "Close call hierarchy" }))
end

-- 主入口：打开/刷新 Call Hierarchy 侧边栏
function M.open()
  local source_win = vim.api.nvim_get_current_win()

  -- Step 1: prepareCallHierarchy
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

  -- Step 2: 递归构建树
  local lines, entries = build_tree(root_items[1])

  if #entries <= 1 then
    vim.notify("gR: 未找到调用者（索引未完成或该方法未被调用）", vim.log.levels.INFO)
    return
  end

  -- Step 3: 创建或复用 buffer
  if not vim.api.nvim_buf_is_valid(state.buf) then
    state.buf = vim.api.nvim_create_buf(false, true)
    vim.bo[state.buf].buftype   = "nofile"
    vim.bo[state.buf].bufhidden = "hide"
    vim.bo[state.buf].swapfile  = false
    pcall(vim.api.nvim_buf_set_name, state.buf, "CallHierarchy")
    setup_keymaps(state.buf)
  end

  -- 添加说明行
  -- 注意：vim.list_extend 会原地修改第一个参数，所以先固定 header_size
  local HEADER_SIZE = 2
  local FOOTER_SIZE = 2
  local all_lines = {}
  table.insert(all_lines, " Call Hierarchy: " .. root_items[1].name)
  table.insert(all_lines, string.rep("─", 50))
  for _, l in ipairs(lines)  do table.insert(all_lines, l) end
  table.insert(all_lines, string.rep("─", 50))
  table.insert(all_lines, " <CR> 跳转  p/o 预览  q 关闭  gl 进入")

  -- entries 偏移（header 占 HEADER_SIZE 行，footer 占 FOOTER_SIZE 行）
  local offset_entries = {}
  for _ = 1, HEADER_SIZE do table.insert(offset_entries, { file = nil, lnum = nil }) end
  for _, e in ipairs(entries) do table.insert(offset_entries, e) end
  for _ = 1, FOOTER_SIZE do table.insert(offset_entries, { file = nil, lnum = nil }) end

  vim.bo[state.buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, all_lines)
  vim.bo[state.buf].modifiable = false

  state.entries    = offset_entries
  state.source_win = source_win

  -- Step 4: 打开或复用侧边栏窗口
  local existing = nil
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(w) == state.buf then
      existing = w
      break
    end
  end

  if existing then
    state.win = existing
    vim.api.nvim_win_set_cursor(existing, { HEADER_SIZE + 1, 0 })
    vim.api.nvim_set_current_win(existing)
  else
    -- 保存到当前 source 窗口，用 botright vsplit 在最右边开
    vim.api.nvim_set_current_win(source_win)
    vim.cmd("botright 54vsplit")
    state.win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(state.win, state.buf)
    vim.wo[state.win].winfixwidth    = true
    vim.wo[state.win].number         = false
    vim.wo[state.win].relativenumber = false
    vim.wo[state.win].wrap           = false
    vim.wo[state.win].signcolumn     = "no"
    vim.wo[state.win].cursorline     = true
    vim.api.nvim_win_set_cursor(state.win, { HEADER_SIZE + 1, 0 })
  end
end

return M
