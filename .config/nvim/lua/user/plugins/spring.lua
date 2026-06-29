-- Spring 接口搜索 picker
-- 快捷键: <Leader>ha（对应 IntelliJ Cool Request）

local function spring_endpoints()
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    vim.notify("fzf-lua 未加载，请先执行 :Lazy sync", vim.log.levels.ERROR)
    return
  end

  local project_root = vim.fs.root(0, { "pom.xml", "build.gradle", ".git" }) or vim.fn.getcwd()

  -- ripgrep 扫描所有 Spring mapping 注解
  local rg_cmd = string.format(
    "rg --line-number --no-heading --color=never " ..
    [['@(Get|Post|Put|Delete|Patch|Request)Mapping' ]] ..
    "--include='*.java' %s",
    vim.fn.shellescape(project_root)
  )

  -- 解析每行，提取 HTTP 方法和路径
  local function parse_line(line)
    local file, lnum, content = line:match("^(.+):(%d+):(.*)")
    if not file or not content then return nil end

    local method = "ANY "
    if     content:match("@GetMapping")    then method = "GET "
    elseif content:match("@PostMapping")   then method = "POST"
    elseif content:match("@PutMapping")    then method = "PUT "
    elseif content:match("@DeleteMapping") then method = "DEL "
    elseif content:match("@PatchMapping")  then method = "PATC"
    end

    -- 提取路径：支持 value="..." 和 "/path" 两种写法
    local path = content:match('value%s*=%s*["\']([^"\']+)["\']')
               or content:match('["\']([^"\']+)["\']')
               or "(no path)"

    local filename = vim.fn.fnamemodify(file, ":t")
    local display  = string.format("%-4s  %-55s  %s:%s", method, path, filename, lnum)
    return display, file, tonumber(lnum)
  end

  -- 执行 rg
  local handle = io.popen(rg_cmd .. " 2>/dev/null")
  if not handle then
    vim.notify("ripgrep 执行失败", vim.log.levels.ERROR)
    return
  end

  local entries   = {}
  local entry_map = {}

  for line in handle:lines() do
    local display, file, lnum = parse_line(line)
    if display then
      table.insert(entries, display)
      entry_map[display] = { file = file, lnum = lnum }
    end
  end
  handle:close()

  if #entries == 0 then
    vim.notify("未找到 Spring 接口（@*Mapping）。确认当前在 Spring Boot 项目目录", vim.log.levels.WARN)
    return
  end

  -- fzf-lua 展示
  fzf.fzf_exec(entries, {
    prompt   = "Spring Endpoints❯ ",
    winopts  = {
      title  = " 🌿 Spring 接口 ",
      height = 0.6,
      width  = 0.85,
    },
    actions  = {
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

-- 注册快捷键
vim.keymap.set("n", "<Leader>ha", spring_endpoints, {
  noremap = true,
  silent  = true,
  desc    = "Spring Endpoints (Cool Request)",
})

return {}  -- lazy spec 为空，纯 Lua 实现
