let mapleader = "\<space>"
" set encoding=utf-8
" set termencoding=utf-8
" set fileencodings=ucs-bom,utf-8,cp936,gb18030,big5,euc-jp,euc-kr
" set fileencoding=utf-8
"
" fomatter
" unicode
" autocmd BufNewFile,BufRead *.json map <Leader>l :%!python -m json.tool<CR>


" autocmd
"autocmd CursorMoved * setlocal hlsearch
"autocmd CursorMovedI * setlocal nohlsearch

nmap <Leader>i ysiw
nmap <Leader>I yss
nmap <Leader>a ysaw
nmap <Leader>d ds
"noremap <ESC> <ESC>:setlocal nohlsearch<CR>
"noremap / :setlocal hlsearch<CR>/
map <C-w> <C-w><C-w>
inoremap <C-w> <ESC><C-w><C-w>
" nnoremap <Leader>c cs
vmap s S

" search
" hls nohls
set hlsearch
" is nois
set incsearch

" window
set showtabline=2
set splitbelow

" mark
map m `
noremap M m


" move 
map L <End>
map H <Home>

" keymap
nmap U :redo<Enter>
nnoremap <Enter> o<Esc>

" map <Space> <Insert><Space><Esc>
set scrolloff=5
set cursorline
set number
set noshowmode
set relativenumber
" set nowrap

"indent
nmap <Tab> >>
nmap <S-Tab> <<
vmap <Tab> >
vmap <S-Tab> < 
"To change the number of space characters inserted for indentation"
set shiftwidth=4
"insert 4 spaces for a tab"
set tabstop=4
set autoindent
set smartindent

set ignorecase

" color
" syntax on
filetype on
" filetype indent on
filetype plugin on

" plugins
call plug#begin("~/.vim/plugged")
Plug 'scrooloose/syntastic'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'preservim/nerdtree'
" Plug 'plasticboy/vim-markdown'
Plug 'instant-markdown/vim-instant-markdown', {'for': 'markdown', 'do': 'yarn install'}
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-surround'
" Plug 'iamcco/mathjax-support-for-mkdp'
" Plug 'iamcco/markdown-preview.vim'
call plug#end()
