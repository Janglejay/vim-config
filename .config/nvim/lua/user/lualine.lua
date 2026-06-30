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

-- jdtls 索引进度：双保险方案
-- 1. LspProgress 事件（vim.schedule 确保主线程执行）
-- 2. vim.lsp.status() 轮询（每秒刷新，兜底）
local _lsp_msg = ""

vim.api.nvim_create_autocmd("LspProgress", {
  callback = function(ev)
    vim.schedule(function()
      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      if not client then return end
      local val = (ev.data.params or {}).value or {}
      if val.kind == "end" then
        _lsp_msg = ""
      else
        local title = val.title or ""
        local msg   = val.message or ""
        local pct   = val.percentage and (" " .. val.percentage .. "%") or ""
        local text  = title .. (msg ~= "" and (": " .. msg) or "") .. pct
        if text ~= "" then
          _lsp_msg = client.name .. ": " .. text
        end
      end
      pcall(vim.cmd, "redrawstatus")
    end)
  end,
})

-- 兜底轮询：直接读 vim.lsp.status()（每秒检查一次）
vim.defer_fn(function()
  local timer = vim.uv.new_timer()
  if timer then
    timer:start(0, 1000, vim.schedule_wrap(function()
      local s = vim.lsp.status()
      if s ~= _lsp_msg then
        _lsp_msg = s
        pcall(vim.cmd, "redrawstatus")
      end
    end))
  end
end, 3000)

local lsp_progress = {
  function()
    if _lsp_msg == "" then return "" end
    local msg = _lsp_msg
    if #msg > 60 then msg = msg:sub(1, 57) .. "..." end
    return "󰔟 " .. msg
  end,
  cond = function() return _lsp_msg ~= "" end,
  color = { fg = "#ffbc67" },
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
