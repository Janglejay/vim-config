let mapleader = " "
" move 
map L <End>
map H <Home>

" keymap
nmap U :redo<Enter>
nnoremap <Leader><Enter> o<Esc>

" map <Space> <Insert><Space><Esc>
set scrolloff=5
set cursorline
set number
set noshowmode
set relativenumber

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
call plug#end()
