map L <End>
map H <Home>
nmap <Tab> >>
nmap <S-Tab> <<
vmap <Tab> >
vmap <S-Tab> < 
map <Space> <Insert><Space><Esc>
set scrolloff=5
set cursorline
set number

" color
syntax on
filetype on
filetype indent on
filetype plugin on

" plugins
call plug#begin()
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
call plug#end()
