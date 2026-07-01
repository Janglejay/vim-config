local M = {}

-- ── 诊断配置 ────────────────────────────────────────────────────
M.setup = function()
  local signs = {
    { name = "DiagnosticSignError", text = "" },
    { name = "DiagnosticSignWarn",  text = "" },
    { name = "DiagnosticSignHint",  text = "" },
    { name = "DiagnosticSignInfo",  text = "" },
  }
  for _, sign in ipairs(signs) do
    vim.fn.sign_define(sign.name, { texthl = sign.name, text = sign.text, numhl = "" })
  end

  vim.diagnostic.config({
    virtual_text    = false,
    signs           = { active = signs },
    update_in_insert = true,
    underline       = true,
    severity_sort   = true,
    float = {
      focusable = false, style = "minimal", border = "rounded",
      source = "always", header = "", prefix = "",
    },
  })

  -- Hover / signature_help 圆角边框
  local function wrap_with_border(handler)
    return function(err, result, ctx, cfg)
      cfg = vim.tbl_extend("force", cfg or {}, { border = "rounded" })
      handler(err, result, ctx, cfg)
    end
  end
  vim.lsp.handlers.hover         = wrap_with_border(vim.lsp.handlers.hover)
  vim.lsp.handlers.signature_help = wrap_with_border(vim.lsp.handlers.signature_help)
end

-- ── 文档高亮（光标停留高亮同名符号）──────────────────────────────
local function lsp_highlight_document(client)
  if not (client.server_capabilities or {}).documentHighlightProvider then return end
  local grp = vim.api.nvim_create_augroup("lsp_doc_highlight", { clear = true })
  vim.api.nvim_create_autocmd("CursorHold",  { group = grp, buffer = 0,
    callback = vim.lsp.buf.document_highlight })
  vim.api.nvim_create_autocmd("CursorMoved", { group = grp, buffer = 0,
    callback = vim.lsp.buf.clear_references })
end

-- ── Buffer 快捷键 ────────────────────────────────────────────────
local function lsp_keymaps(bufnr)
  local o = { noremap = true, silent = true, buffer = bufnr }

  -- gD: 跳到声明
  vim.keymap.set("n", "gD", vim.lsp.buf.declaration, vim.tbl_extend("force", o, { desc = "Declaration" }))

  -- gd: 上下文感知（IDEA Cmd+B 风格）
  --   • 在引用处 → 跳到定义
  --   • 在定义处 → 显示所有引用（支持字段/属性/Lombok 生成的 getter/setter）
  vim.keymap.set("n", "gd", function()
    -- 检查是否有支持 definition 的 client
    -- 必须检查 definitionProvider，否则 spring_boot_ls 等不支持的 server 会触发
    -- "method not supported" 错误（Neovim 原生报错，而非我们的提示）
    local has_def = false
    for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
      local dp = c.server_capabilities.definitionProvider
      if dp ~= nil and dp ~= false then has_def = true; break end
    end
    if not has_def then
      -- 用 DEBUG 级别避免频繁打扰，状态栏 󰔟 消失后就好了
      vim.notify(
        "jdtls 初始化中，等状态栏变 ✓ 后重试",
        vim.log.levels.WARN, { title = "gd" })
      return
    end
    local fzf    = require("fzf-lua")
    local params = vim.lsp.util.make_position_params()
    local def_res = vim.lsp.buf_request_sync(0, "textDocument/definition", params, 10000)

    local defs = {}
    if def_res then
      for _, res in pairs(def_res) do
        for _, item in ipairs(type(res.result) == "table" and res.result or {}) do
          table.insert(defs, item)
        end
      end
    end

    -- 判断是否在定义处（严格匹配行号，不用 abs <= 1 防误判）
    local cur_uri  = vim.uri_from_bufnr(0)
    local cur_line = vim.api.nvim_win_get_cursor(0)[1] - 1
    local at_def   = (#defs == 0)  -- 无定义 → 本身就是定义
    for _, d in ipairs(defs) do
      local uri  = d.uri or d.targetUri or ""
      local line = (d.range and d.range.start.line)
                or (d.targetRange and d.targetRange.start.line) or -1
      if uri == cur_uri and line == cur_line then
        at_def = true; break
      end
    end

    if at_def then
      -- vim.schedule 推迟到下个事件循环，避免 buf_request_sync 后状态不一致导致 fzf-lua crash
      vim.schedule(function() fzf.lsp_references() end)
    elseif #defs == 1 then
      local d   = defs[1]
      local uri = d.uri or d.targetUri
      local ln  = ((d.range and d.range.start.line)
                or (d.targetRange and d.targetRange.start.line) or 0) + 1
      local col = (d.range and d.range.start.character)
               or (d.targetRange and d.targetRange.start.character) or 0
      vim.cmd("edit " .. vim.fn.fnameescape(vim.uri_to_fname(uri)))
      vim.api.nvim_win_set_cursor(0, { ln, col })
      vim.cmd("normal! zz")
    else
      fzf.lsp_definitions()          -- 多定义 → fzf 选择
    end
  end, vim.tbl_extend("force", o, { desc = "gd: smart goto" }))

  -- 其他 LSP 快捷键
  vim.keymap.set("n", "<c-p>",    vim.lsp.buf.hover,        vim.tbl_extend("force", o, { desc = "Hover" }))
  vim.keymap.set("n", "gi",      "<cmd>lua require('fzf-lua').lsp_implementations()<CR>", o)
  vim.keymap.set("n", "<Leader>R", vim.lsp.buf.rename,      vim.tbl_extend("force", o, { desc = "Rename" }))
  vim.keymap.set("n", "ga",      vim.lsp.buf.code_action,   vim.tbl_extend("force", o, { desc = "Code Action" }))
  vim.keymap.set("n", "se",      vim.diagnostic.open_float, vim.tbl_extend("force", o, { desc = "Show Diagnostic" }))
  vim.keymap.set("n", "<F2>",    function()
    vim.diagnostic.goto_next({ float = { border = "rounded" } })
  end, vim.tbl_extend("force", o, { desc = "Next Diagnostic" }))
end

-- ── on_attach ────────────────────────────────────────────────────
M.on_attach = function(client, bufnr)
  lsp_keymaps(bufnr)
  lsp_highlight_document(client)

  -- Inlay hints（内联类型/参数名提示，Neovim 0.10+ 原生支持）
  -- 效果：orderService.create(userId: id, quantity: 3) ← 灰色的是提示
  if client.server_capabilities.inlayHintProvider then
    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
    -- <Leader>ih 切换显示/隐藏（提示太多时可临时关掉）
    vim.keymap.set("n", "<Leader>ih", function()
      local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
      vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
      vim.notify("Inlay hints " .. (enabled and "关闭" or "开启"), vim.log.levels.INFO)
    end, { noremap = true, silent = true, buffer = bufnr, desc = "Toggle inlay hints" })
  end
end

-- ── capabilities（修复：cmp 失败时不再 return nil）──────────────
local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
M.capabilities = ok
  and cmp_lsp.default_capabilities()
  or  vim.lsp.protocol.make_client_capabilities()

return M
