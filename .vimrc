" let mapleader="\<SPACE>"
"
" autocmd BufWrite * :echom "Writing buffer!"
let mapleader=","

" ----------
" origin keymap
" ----------
noremap U :redo<CR>
nnoremap <CR> o<Esc>
noremap vv <S-v> 
inoremap jk <ESC>
inoremap <ESC> <NOP>
vnoremap U ~
vnoremap ~ <NOP>
vnoremap <ESC> <NOP>
vnoremap u <ESC>
cnoremap jk <ESC>
" cnoremap <ESC> <NOP>
noremap J <C-d>
noremap K <C-u>
" ----------
" Register @ 
" ----------
let @c="\<Insert>\" ----------\<ESC>yypO"


" ----------
" Edit markdown
" ----------
augroup markdown_edit_group
    autocmd!
    autocmd BufNewFile,BufRead *.md noremap <silent><buffer> <Leader>f /<++><CR>:nohl<CR>4"-cl
    autocmd BufNewFile,BufRead *.md noremap <silent><buffer> <Leader>` <Insert>```<CR><++><CR>```<ESC>
    autocmd BufNewFile,BufRead *.md noremap <silent><buffer> <Leader>b <Insert>**<++>**<ESC>
    autocmd BufNewFile,BufRead *.md noremap <silent><buffer> <Leader>~ <Insert>~~<++>~~<ESC>
    autocmd BufNewFile,BufRead *.md noremap <silent><buffer> <Leader>l <Insert>[<++>](<++>)<ESC>
    autocmd BufNewFile,BufRead *.md noremap <silent><buffer> <Leader>m <Insert>![<++>](<++>)<ESC>
                                                     
    autocmd BufNewFile,BufRead *.md inoremap <silent><buffer> <Leader>f <ESC>/<++><CR>:nohl<CR>4"-cl
    autocmd BufNewFile,BufRead *.md inoremap <silent><buffer> <Leader>` ```<CR><++><CR>```
    autocmd BufNewFile,BufRead *.md inoremap <silent><buffer> <Leader>b **<++>**
    autocmd BufNewFile,BufRead *.md inoremap <silent><buffer> <Leader>~ ~~<++>~~
    autocmd BufNewFile,BufRead *.md inoremap <silent><buffer> <Leader>l [<++>](<++>)
    autocmd BufNewFile,BufRead *.md inoremap <silent><buffer> <Leader>m ![<++>](<++>)

    autocmd BufNewFile,BufRead *.md vmap <silent><buffer> <Leader>` <Leader>d<Insert>```<CR>```<CR><ESC>kO<ESC><Leader>p<ESC>
    autocmd BufNewFile,BufRead *.md vnoremap <silent><buffer> <Leader>~ d<Insert>~~~~<ESC>2hp
    autocmd BufNewFile,BufRead *.md vnoremap <silent><buffer> <Leader>b d<Insert>****<ESC>2hp
    autocmd BufNewFile,BufRead *.md vnoremap <silent><buffer> <Leader>l d<Insert>[<++>]()<ESC>hp
    autocmd BufNewFile,BufRead *.md vnoremap <silent><buffer> <Leader>m d<Insert>![<++>]()<ESC>hp
augroup END
" ----------
" Edit .vimrc
" ----------
noremap <silent> <Leader>ev :split $MYVIMRC<CR>
noremap <silent> <Leader>sv :source $MYVIMRC<CR>


" --------------
" Copy and paste
" --------------
set clipboard=unnamed
noremap <Leader>d "1d
noremap <Leader>p "1p
noremap x "-x
noremap c "-c
nnoremap cc "-cc
nnoremap s "-s
vnoremap p "1dp
noremap <Leader>y "1y
" noremap p "0p
" noremap P "0P
" noremap <Leader>p "*p
" noremap <Leader>P "*P

" nnoremap yy "0yy
" nnoremap <Leader>y "*y
" vnoremap y "0y
" vnoremap <Leader>y "*y
" nnoremap <Leader>d "0d
" vnoremap <Leader>d "0d
" noremap <Leader>D "0D

" ----------
" Mouse 
" ----------
set mouse=

" ----------
" Window
" ----------
set autowriteall
set showtabline=2
set splitbelow
set splitright

" set wildmenu=full
" set wildmode=list:longest:full
" set wildchar=<Tab> wildcharm=<C-Z>

map <C-w> <C-w><C-w>
inoremap <C-w> <ESC><C-w><C-w>

" ----------
" Search
" ----------
set hlsearch
" is nois
set incsearch
set smartcase
set ignorecase

noremap <silent> <Leader>n :nohlsearch<CR>


" ----------
" Mark
" ----------
noremap m `
noremap M m

" ----------
" Move
" ----------
noremap L <End>
" map H <Home>
noremap H <Home> 

" ----------
" Show
" ----------
set cursorline
set number
set noshowmode
set relativenumber
set scrolloff=5
" set nowrap

" ----------
" Indent
" ----------
"To change the number of space characters inserted for indentation"
set shiftwidth=4
"insert 4 spaces for a tab"
set softtabstop=4
set expandtab
" set tabstop=4
" set autoindent
" set smartindent

nnoremap <Tab> >>
nnoremap <S-Tab> <<
vnoremap <Tab> >
vnoremap <S-Tab> < 

" ----------
" Filetype
" ----------
filetype on
filetype plugin on

" ----------
" plugins
" ----------
call plug#begin("~/.vim/plugged")
Plug 'scrooloose/syntastic'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'preservim/nerdtree'
Plug 'instant-markdown/vim-instant-markdown', {'for': 'markdown', 'do': 'yarn install'}
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-surround'
call plug#end()
