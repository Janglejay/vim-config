let mapleader="\<SPACE>"


" ----------
" Register @ 
" ----------
let @c="\<Insert>\" ----------\<ESC>yypO"


" --------------
" Copy and paste
" --------------
" set clipboard=unnamed
noremap p "0p
noremap P "0P
noremap <Leader>p "*p
noremap <Leader>P "*P

nnoremap yy "0yy
nnoremap <Leader>yy "*yy
vnoremap y "0y
vnoremap <Leader>y "*y

nnoremap <Leader>d "0d
vnoremap <Leader>d "0d
noremap <Leader>D "0D

" ----------
" Mouse 
" ----------
set mouse=a

" ----------
" Window
" ----------
set autowriteall
set showtabline=2
set splitbelow
set splitright

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

nmap <silent> <Leader>n :nohlsearch<CR>


" ----------
" Mark
" ----------
map m `
noremap M m

" ----------
" Move
" ----------
map L <End>
map H <Home>

" ----------
" Undo
" ----------
nmap U :redo<Enter>
nnoremap <Enter> o<Esc>

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

nmap <Tab> >>
nmap <S-Tab> <<
vmap <Tab> >
vmap <S-Tab> < 

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
