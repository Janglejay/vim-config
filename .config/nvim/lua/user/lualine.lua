local status_ok, lualine = pcall(require, "lualine")
if not status_ok then
	return
end

local hide_in_width = function()
	return vim.fn.winwidth(0) > 80
end

local diagnostics = {
	"diagnostics",
	sources = { "nvim_diagnostic" },
	sections = { "error", "warn" },
	symbols = { error = " ", warn = " " },
	colored = false,
	update_in_insert = false,
	always_visible = true,
}

local diff = {
	"diff",
	colored = false,
	symbols = { added = " ", modified = " ", removed = " " }, -- changes diff symbols
  cond = hide_in_width
}

local mode = {
	"mode",
	fmt = function(str)
		return "-- " .. str .. " --"
	end,
}

local filetype = {
	"filetype",
	icons_enabled = false,
	icon = nil,
}

local branch = {
	"branch",
	icons_enabled = true,
	icon = "",
}

local location = {
	"location",
	padding = 0,
}

-- cool function for progress
local progress = function()
	local current_line = vim.fn.line(".")
	local total_lines = vim.fn.line("$")
	local chars = { "__", "▁▁", "▂▂", "▃▃", "▄▄", "▅▅", "▆▆", "▇▇", "██" }
	local line_ratio = current_line / total_lines
	local index = math.ceil(line_ratio * #chars)
	return chars[index]
end

local spaces = function()
	return "spaces: " .. vim.api.nvim_buf_get_option(0, "shiftwidth")
end

-- jdtls 三状态常驻指示器
local _jdtls = {
  state      = "none",   -- "none" | "indexing" | "ready"
  percentage = nil,      -- 真实进度百分比（nil = 无数据）
  title      = "",       -- 当前任务名
  last_ts    = 0,        -- 最近一次 LspProgress 时间戳（ms）
}

local function _redraw() pcall(vim.cmd, "redrawstatus") end

-- 从 progress value 中提取百分比（兼容字段和消息字符串两种格式）
local function _extract_pct(val)
  if val.percentage then return math.floor(tonumber(val.percentage) or 0) end
  local msg = val.message or ""
  local n = msg:match("(%d+)%%")
  return n and tonumber(n) or nil
end

-- jdtls 断开：确认所有客户端消失才标为断开
vim.api.nvim_create_autocmd("LspDetach", {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client or client.name ~= "jdtls" then return end
    vim.schedule(function()
      if #vim.lsp.get_clients({ name = "jdtls" }) == 0 then
        _jdtls.state = "none"
        _jdtls.percentage = nil
        _jdtls.title = ""
        _redraw()
      end
    end)
  end,
})

-- jdtls 连接 → 只有从断开状态才标为 indexing
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client or client.name ~= "jdtls" then return end
    if _jdtls.state == "none" then
      _jdtls.state      = "indexing"
      _jdtls.title      = "初始化中..."
      _jdtls.percentage = nil
      _redraw()
    end
  end,
})

-- LspProgress：兼容 Neovim 各版本的数据结构，提取真实进度
vim.api.nvim_create_autocmd("LspProgress", {
  callback = function(ev)
    vim.schedule(function()
      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      if not client or client.name ~= "jdtls" then return end

      -- 兼容不同 Neovim 版本的 progress 数据位置
      local val = vim.tbl_get(ev, "data", "params", "value")
             or vim.tbl_get(ev, "data", "result")
             or {}

      _jdtls.last_ts = vim.loop.now()

      local kind = val.kind or ""
      if kind == "begin" then
        _jdtls.state      = "indexing"
        _jdtls.title      = val.title or ""
        _jdtls.percentage = _extract_pct(val)
      elseif kind == "report" then
        if val.title and val.title ~= "" then _jdtls.title = val.title end
        _jdtls.percentage = _extract_pct(val)
      elseif kind == "end" then
        _jdtls.percentage = nil
        _jdtls.title      = ""
        -- "end" 不立即变绿，交给 ServiceReady 或 idle 定时器决定
      end
      _redraw()
    end)
  end,
})

-- ServiceReady via window/showMessage → 立即变绿
local _orig_show_msg = vim.lsp.handlers["window/showMessage"]
vim.lsp.handlers["window/showMessage"] = function(err, result, ctx, config)
  if result and (result.message or ""):match("[Ss]ervice[Rr]eady") then
    local client = vim.lsp.get_client_by_id(ctx.client_id)
    if client and client.name == "jdtls" then
      _jdtls.state = "ready"
      _jdtls.percentage = nil
      _jdtls.title = ""
      _redraw()
    end
  end
  if _orig_show_msg then _orig_show_msg(err, result, ctx, config) end
end

-- 兜底定时器：无 progress 事件超过 4s 且有客户端 → 就绪
vim.defer_fn(function()
  local timer = vim.uv.new_timer()
  if not timer then return end
  timer:start(2000, 2000, vim.schedule_wrap(function()
    local clients = vim.lsp.get_clients({ name = "jdtls" })
    if #clients == 0 then
      if _jdtls.state ~= "none" then
        _jdtls.state = "none"
        _jdtls.percentage = nil
        _redraw()
      end
    elseif _jdtls.state == "indexing" then
      local idle = vim.loop.now() - _jdtls.last_ts
      if idle > 4000 then  -- 4 秒没有新 progress 事件，认为索引结束
        _jdtls.state = "ready"
        _jdtls.percentage = nil
        _redraw()
      end
    end
  end))
end, 2000)

local lsp_progress = {
  function()
    if _jdtls.state == "none" then
      return "✗ jdtls"
    elseif _jdtls.state == "indexing" then
      -- 有真实百分比时显示进度条，否则只显示文字
      if _jdtls.percentage then
        local pct      = math.max(0, math.min(100, _jdtls.percentage))
        local filled   = math.floor(pct / 10)  -- 10格进度条
        local bar      = string.rep("█", filled) .. string.rep("░", 10 - filled)
        return string.format("󰔟 [%s] %d%%", bar, pct)
      end
      local msg = _jdtls.title ~= "" and _jdtls.title or "索引中..."
      if #msg > 40 then msg = msg:sub(1, 37) .. "..." end
      return "󰔟 " .. msg
    else
      return "✓ jdtls"
    end
  end,
  -- 不加 cond，始终显示
  color = function()
    if _jdtls.state == "none"     then return { fg = "#f38ba8" }  -- red
    elseif _jdtls.state == "indexing" then return { fg = "#fab387" }  -- orange
    else                               return { fg = "#a6e3a1" }  -- green
    end
  end,
}

lualine.setup({
	options = {
		icons_enabled = true,
		theme = "auto",
		component_separators = { left = "", right = "" },
		section_separators = { left = "", right = "" },
		disabled_filetypes = { "alpha", "dashboard", "NvimTree", "Outline" },
		always_divide_middle = true,
	},
	sections = {
		lualine_a = { branch, diagnostics },
		lualine_b = { mode },
		lualine_c = { lsp_progress },
		-- lualine_x = { "encoding", "fileformat", "filetype" },
		lualine_x = { diff, spaces, "encoding", filetype },
		lualine_y = { location },
		lualine_z = { progress },
	},
	inactive_sections = {
		lualine_a = {},
		lualine_b = {},
		lualine_c = { "filename" },
		lualine_x = { "location" },
		lualine_y = {},
		lualine_z = {},
	},
	tabline = {},
	extensions = {},
})
