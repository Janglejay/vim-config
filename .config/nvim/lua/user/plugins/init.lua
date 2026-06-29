-- 汇总所有 plugin spec
local specs = {}

local modules = {
  "user.plugins.ui",
  "user.plugins.lsp",
  "user.plugins.java",
  "user.plugins.search",
  "user.plugins.dap",
  "user.plugins.test",
  "user.plugins.editing",
  "user.plugins.spring",
}

for _, mod in ipairs(modules) do
  local ok, m = pcall(require, mod)
  if ok and type(m) == "table" then
    for _, spec in ipairs(m) do
      table.insert(specs, spec)
    end
  end
end

return specs
