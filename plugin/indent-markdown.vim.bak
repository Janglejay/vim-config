" Uncomment to override defaults:
" let g:instant_markdown_slow = 1
let g:instant_markdown_autostart = 0
" let g:instant_markdown_open_to_the_world = 1
" let g:instant_markdown_allow_unsafe_content = 1
" let g:instant_markdown_allow_external_content = 0
" let g:instant_markdown_mathjax = 1
" let g:instant_markdown_mermaid = 1
let g:instant_markdown_logfile = '/tmp/instant_markdown.log'
" let g:instant_markdown_autoscroll = 0
let g:instant_markdown_port = 10010 
" let g:instant_markdown_python = 1


augroup indent_markdown_group
    autocmd!
    " autocmd BufNewFile,BufRead *.md noremap <silent> <F12> :InstantMarkdownPreview<CR>
    autocmd BufNewFile,BufRead *.md noremap <silent> == :InstantMarkdownPreview<CR>
    " autocmd BufNewFile,BufRead *.md noremap <silent> <S-F12> :InstantMarkdownStop<CR>
    autocmd BufNewFile,BufRead *.md noremap <silent> ++ :InstantMarkdownStop<CR>
    " autocmd BufNewFile,BufRead *.md inoremap <silent> <F12> <ESC>:InstantMarkdownPreview<CR>
    " autocmd BufNewFile,BufRead *.md inoremap <silent> <S-F12> <ESC>:InstantMarkdownStop<CR>
augroup END
