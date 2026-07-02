-- Spring 接口搜索 picker
-- 快捷键: <Leader>ha（对应 IntelliJ Cool Request）

local function spring_endpoints()
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    vim.notify("fzf-lua 未加载，请先执行 :Lazy sync", vim.log.levels.ERROR)
    return
  end

  local project_root = (function()
    local path = vim.fs.root(0, { "pom.xml", "build.gradle", "mvnw", "gradlew" })
              or vim.fn.getcwd()
    local parent = vim.fn.fnamemodify(path, ":h")
    while vim.fn.filereadable(parent .. "/pom.xml") == 1 do
      path = parent
      parent = vim.fn.fnamemodify(path, ":h")
      if parent == path then break end
    end
    return path
  end)()

  -- 修正：ripgrep 用 -g 过滤文件类型，不是 --include（--include 是 grep 的参数）
  local rg_cmd = string.format(
    "rg --line-number --no-heading --color=never -g '*.java' " ..
    [[-e '@(Get|Post|Put|Delete|Patch|Request)Mapping' ]] ..
    "%s",
    vim.fn.shellescape(project_root)
  )

  local handle = io.popen(rg_cmd .. " 2>&1")
  if not handle then
    vim.notify("ripgrep 执行失败", vim.log.levels.ERROR)
    return
  end

  local entries   = {}
  local entry_map = {}

  -- 从文件的 start_lnum 行起，向后最多读 4 行，提取第一个 /开头 的引号路径
  local function lookahead_path(file, start_lnum)
    local f = io.open(file, "r")
    if not f then return nil end
    local cur = 0
    for l in f:lines() do
      cur = cur + 1
      if cur >= start_lnum and cur <= start_lnum + 4 then
        local p = l:match('value%s*=%s*"([^"]+)"')
               or l:match('path%s*=%s*"([^"]+)"')
               or l:match('"([^"]+)"')
        if p and p:match("^/") then f:close(); return p end
      end
      if cur > start_lnum + 4 then break end
    end
    f:close()
    return nil
  end

  -- 读文件到 `public [abstract] class` 声明行，从该行向上找 @RequestMapping 路径
  -- 支持单行注解和多行注解（value 在下一行的情况）
  local class_prefix_cache = {}
  local function get_class_prefix(file)
    if class_prefix_cache[file] ~= nil then return class_prefix_cache[file] end

    local f = io.open(file, "r")
    if not f then class_prefix_cache[file] = ""; return "" end

    local lines = {}
    local class_lnum = nil
    for l in f:lines() do
      table.insert(lines, l)
      if not class_lnum and l:match("^%s*public%s+.*class%s+%w+") then
        class_lnum = #lines
      end
      -- 找到类声明后再多读 2 行（应对多行注解值在类声明后缩进的极端情况），然后停止
      if class_lnum and #lines >= class_lnum + 2 then break end
    end
    f:close()

    local prefix = ""
    if class_lnum then
      -- 从类声明行往上扫，找最近的 @RequestMapping
      for i = class_lnum, 1, -1 do
        local l = lines[i]
        local p = l:match('@RequestMapping%s*%(%s*value%s*=%s*"([^"]+)"')
               or l:match('@RequestMapping%s*%(%s*"([^"]+)"')
               or l:match('@RequestMapping%s*"([^"]+)"')  -- 极少见的无括号形式
        if p then prefix = p; break end
        -- 遇到 import/package 行说明已经到文件头，停止
        if l:match("^import%s") or l:match("^package%s") then break end
      end
      -- 处理多行注解：@RequestMapping( \n value = "/..." 的情况
      if prefix == "" then
        for i = 1, math.min(class_lnum + 2, #lines) do
          if lines[i]:match("@RequestMapping") then
            for j = i, math.min(i + 4, #lines) do
              local p = lines[j]:match('value%s*=%s*"([^"]+)"')
                     or lines[j]:match('"([^"]+)"')
              if p and p:match("^/") then prefix = p; break end
            end
            if prefix ~= "" then break end
          end
        end
      end
    end

    class_prefix_cache[file] = prefix
    return prefix
  end

  local function parse_line(line)
    local file, lnum, content = line:match("^(.+):(%d+):(.*)")
    if not file or not content then return nil end

    local method = "ANY "
    if     content:match("@GetMapping")    then method = "GET "
    elseif content:match("@PostMapping")   then method = "POST"
    elseif content:match("@PutMapping")    then method = "PUT "
    elseif content:match("@DeleteMapping") then method = "DEL "
    elseif content:match("@PatchMapping")  then method = "PATC"
    elseif content:match("RequestMethod%.GET")    then method = "GET "
    elseif content:match("RequestMethod%.POST")   then method = "POST"
    elseif content:match("RequestMethod%.PUT")    then method = "PUT "
    elseif content:match("RequestMethod%.DELETE") then method = "DEL "
    elseif content:match("RequestMethod%.PATCH")  then method = "PATC"
    end

    -- 提取方法级路径；多行注解时回落到文件读取
    local lnum_n = tonumber(lnum)
    local path = content:match('value%s*=%s*"([^"]+)"')
              or content:match('path%s*=%s*"([^"]+)"')
              or content:match('"([^"]+)"')
    if path and not path:match("^/") then path = nil end
    if not path then
      path = lookahead_path(file, lnum_n)
    end

    -- 拼接类级别 @RequestMapping 前缀
    local prefix = get_class_prefix(file)
    local full_path
    if path then
      -- 避免双斜杠：prefix="/api" + path="/orders" → "/api/orders"
      full_path = prefix .. (path:sub(1,1) == "/" and path or ("/" .. path))
    else
      full_path = prefix ~= "" and (prefix .. "/*") or "(no path)"
    end

    local filename = vim.fn.fnamemodify(file, ":t")
    local display  = string.format("%-4s  %-65s  %s:%s", method, full_path, filename, lnum)
    return display, file, lnum_n
  end

  for line in handle:lines() do
    local display, file, lnum = parse_line(line)
    if display then
      table.insert(entries, display)
      entry_map[display] = { file = file, lnum = lnum }
    end
  end
  handle:close()

  if #entries == 0 then
    vim.notify(
      string.format("未找到 Spring 接口。搜索目录: %s\n命令: %s", project_root, rg_cmd),
      vim.log.levels.WARN
    )
    return
  end

  fzf.fzf_exec(entries, {
    prompt  = "Spring Endpoints❯ ",
    winopts = { title = " 🌿 Spring 接口 ", height = 0.6, width = 0.85 },
    actions = {
      ["default"] = function(selected)
        if not selected or not selected[1] then return end
        local info = entry_map[selected[1]]
        if info and info.file then
          vim.cmd("edit " .. vim.fn.fnameescape(info.file))
          vim.api.nvim_win_set_cursor(0, { info.lnum, 0 })
          vim.cmd("normal! zz")
        end
      end,
    },
  })
end

vim.keymap.set("n", "<Leader>ha", spring_endpoints, {
  noremap = true,
  silent  = true,
  desc    = "Spring Endpoints (Cool Request)",
})

return {}
