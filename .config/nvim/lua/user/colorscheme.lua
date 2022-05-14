vim.cmd [[
try
  colorscheme darkplus
  " colorscheme monokai_pro
catch /^Vim\%((\a\+)\)\=:E185/
  colorscheme default
  set background=dark
endtry
]]
