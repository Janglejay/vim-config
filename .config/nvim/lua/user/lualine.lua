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
-- ✓ jdtls（绿）= 已就绪  󰔟 索引中...（橙）= 构建中  ✗ jdtls（红）= 未连接
local _jdtls = {
  state   = "none",   -- "none" | "indexing" | "ready"
  message = "",
}

-- LspProgress 事件更新状态
vim.api.nvim_create_autocmd("LspProgress", {
  callback = function(ev)
    vim.schedule(function()
      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      if not client or client.name ~= "jdtls" then return end
      local val = (ev.data.params or {}).value or {}
      if val.kind == "end" then
        _jdtls.state   = "ready"
        _jdtls.message = ""
      else
        _jdtls.state = "indexing"
        local title = val.title or ""
        local pct   = val.percentage and (" " .. val.percentage .. "%") or ""
        _jdtls.message = title .. pct
      end
      pcall(vim.cmd, "redrawstatus")
    end)
  end,
})

-- 每 2 秒轮询 jdtls attach 状态（检测未连接 / 索引完成后变就绪）
vim.defer_fn(function()
  local timer = vim.uv.new_timer()
  if timer then
    timer:start(0, 2000, vim.schedule_wrap(function()
      local clients = vim.lsp.get_clients({ name = "jdtls" })
      local prev = _jdtls.state
      if #clients == 0 then
        _jdtls.state   = "none"
        _jdtls.message = ""
      elseif _jdtls.state == "none" then
        -- 刚刚连上，还不知道是否在索引，先标记 ready
        _jdtls.state = "ready"
      end
      -- 也兜底检测 vim.lsp.status()
      local s = vim.lsp.status()
      if s ~= "" and _jdtls.state ~= "indexing" then
        _jdtls.state   = "indexing"
        _jdtls.message = s
      end
      if _jdtls.state ~= prev then
        pcall(vim.cmd, "redrawstatus")
      end
    end))
  end
end, 2000)

local lsp_progress = {
  function()
    if _jdtls.state == "none" then
      return "✗ jdtls"
    elseif _jdtls.state == "indexing" then
      local msg = _jdtls.message ~= "" and _jdtls.message or "索引中..."
      if #msg > 50 then msg = msg:sub(1, 47) .. "..." end
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
