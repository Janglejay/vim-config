local M = {}

-- TODO: backfill this to template
M.setup = function()
  local signs = {
    { name = "DiagnosticSignError", text = "" },
    { name = "DiagnosticSignWarn", text = "" },
    { name = "DiagnosticSignHint", text = "" },
    { name = "DiagnosticSignInfo", text = "" },
  }

  for _, sign in ipairs(signs) do
    vim.fn.sign_define(sign.name, { texthl = sign.name, text = sign.text, numhl = "" })
  end

  local config = {
    -- disable virtual text
    virtual_text = false,
    -- show signs
    signs = {
      active = signs,
    },
    update_in_insert = true,
    underline = true,
    severity_sort = true,
    float = {
      focusable = false,
      style = "minimal",
      border = "rounded",
      source = "always",
      header = "",
      prefix = "",
    },
  }

  vim.diagnostic.config(config)

  -- Neovim 0.11+: vim.lsp.with is deprecated, use direct handler assignment with wrapper
  local orig_hover = vim.lsp.handlers.hover
  vim.lsp.handlers.hover = function(err, result, ctx, config)
    config = config or {}
    config.border = config.border or "rounded"
    return orig_hover(err, result, ctx, config)
  end

  local orig_signature = vim.lsp.handlers.signature_help
  vim.lsp.handlers.signature_help = function(err, result, ctx, config)
    config = config or {}
    config.border = config.border or "rounded"
    return orig_signature(err, result, ctx, config)
  end
end

local function lsp_highlight_document(client)
  local caps = client.server_capabilities
  if caps and caps.documentHighlightProvider then
    vim.api.nvim_exec(
      [[
      augroup lsp_document_highlight
        autocmd! * <buffer>
        autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
        autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
      augroup END
    ]] ,
      false
    )
  end
end

local function lsp_keymaps(bufnr)
  local opts = { noremap = true, silent = true }
  local bopts = { noremap = true, silent = true, buffer = bufnr }

  -- gD: 跳到声明（Declaration，比 Definition 更原始）
  vim.api.nvim_buf_set_keymap(bufnr, "n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", opts)

  -- gd: 上下文感知（IDEA 风格）
  --   • 在引用处 → 跳到定义
  --   • 在定义处 → 显示所有引用（含属性/字段引用）
  vim.keymap.set("n", "gd", function()
    local fzf = require("fzf-lua")
    local params = vim.lsp.util.make_position_params()

    -- 查询定义位置（超时 6s）
    local def_res = vim.lsp.buf_request_sync(0, "textDocument/definition", params, 6000)
    local defs = {}
    if def_res then
      for _, res in pairs(def_res) do
        for _, item in ipairs(type(res.result) == "table" and res.result or {}) do
          table.insert(defs, item)
        end
      end
    end

    -- 判断光标是否在定义处
    local cur_uri  = vim.uri_from_bufnr(0)
    local cur_line = vim.api.nvim_win_get_cursor(0)[1] - 1  -- 0-indexed

    local at_def = (#defs == 0)  -- 没有找到定义 → 本身就是定义
    for _, d in ipairs(defs) do
      local uri  = d.uri or d.targetUri or ""
      local line = (d.range and d.range.start.line)
                or (d.targetRange and d.targetRange.start.line) or -1
      if uri == cur_uri and math.abs(line - cur_line) <= 1 then
        at_def = true
        break
      end
    end

    if at_def then
      -- 在定义处 → 显示引用（属性/方法均适用）
      fzf.lsp_references({
        fzf_opts = { ["--query"] = "!.m2" },
        winopts  = { title = " gd → References (at declaration) " },
      })
    elseif #defs == 1 then
      -- 只有一个定义 → 直接跳转
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
      -- 多个定义 → fzf 选择
      fzf.lsp_definitions()
    end
  end, vim.tbl_extend("force", bopts, { desc = "gd: smart goto (def→refs, ref→def)" }))

  vim.api.nvim_buf_set_keymap(bufnr, "n", "<c-p>", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)
  -- gi: buffer-local（fzf-lua 全局映射的 buffer-local 备份，保证 LSP attach 后即可用）
  vim.api.nvim_buf_set_keymap(bufnr, "n", "gi",
    "<cmd>lua require('fzf-lua').lsp_implementations()<CR>", opts)
  -- vim.api.nvim_buf_set_keymap(bufnr, "n", "<c-p>", "<cmd>lua vim.lsp.buf.document_symbol()<CR>", opts)
  -- vim.api.nvim_buf_set_keymap(bufnr, "n", "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opts)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "<Leader>R", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
  -- vim.api.nvim_buf_set_keymap(bufnr, "n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", opts)
  -- vim.api.nvim_buf_set_keymap(bufnr, "n", "gr", "<cmd>Telescope lsp_references<CR>", opts)  -- replaced by fzf-lua
  -- vim.api.nvim_buf_set_keymap(bufnr, "n", "<c-y>", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "ga", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "se", "<cmd>lua vim.diagnostic.open_float()<CR>", opts)
  -- vim.api.nvim_buf_set_keymap(bufnr, "n", "<S-F2>", '<cmd>lua vim.diagnostic.goto_prev({ border = "rounded" })<CR>', opts)
  -- vim.api.nvim_buf_set_keymap(
  --   bufnr,
  --   "n",
  --   "se",
  --   '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics({ border = "rounded" })<CR>',
  --   opts
  -- )
  vim.api.nvim_buf_set_keymap(bufnr, "n", "<F2>", '<cmd>lua vim.diagnostic.goto_next({ border = "rounded" })<CR>', opts)
  --  vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>q", "<cmd>lua vim.diagnostic.setloclist()<CR>", opts)
  --  vim.cmd [[ command! Format execute 'lua vim.lsp.buf.formatting()' ]]
end

M.on_attach = function(client, bufnr)
  lsp_keymaps(bufnr)
  lsp_highlight_document(client)
end

local capabilities = vim.lsp.protocol.make_client_capabilities()

local status_ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if not status_ok then
  return
end

-- M.capabilities = cmp_nvim_lsp.update_capabilities(capabilities)
M.capabilities = cmp_nvim_lsp.default_capabilities()


return M
