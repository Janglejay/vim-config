let NERDTreeMinimalUI = 1
let NERDTreeChDirMode = 2

nnoremap <silent> <F2> :NERDTreeToggle<Enter><ESC>
vmap <silent> <F2> <ESC>:NERDTreeToggle<Enter><ESC>
imap <silent> <F2> <ESC>:NERDTreeToggle<Enter><ESC>


" Exit Vim if NERDTree is the only window remaining in the only tab.
augroup nerd_tree_group
    autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif
augroup END
