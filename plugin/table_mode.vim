augroup table_mode_group
    autocmd!
    autocmd BufNewFile,BufRead *.md noremap <silent><buffer> <Leader>tm :TableModeToggle<CR>
augroup END

