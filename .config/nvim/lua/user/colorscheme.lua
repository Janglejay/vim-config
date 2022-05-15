vim.cmd [[
try
  " colorscheme darkplus
  " colorscheme monokai_pro
  colorscheme gruvbox
catch /^Vim\%((\a\+)\)\=:E185/
  colorscheme default
  set background=dark
endtry
]]
