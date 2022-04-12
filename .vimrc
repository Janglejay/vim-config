" let mapleader="\<SPACE>"
"
" autocmd BufWrite * :echom "Writing buffer!"
let mapleader=","
" ESC delay
set ttimeoutlen=0
" set timeoutlen=4000
" ----------
" origin keymap
" ----------
 nnoremap U :redo<CR>
"  nnoremap <CR> o<Esc>
 noremap <CR> ;
" use in GUI
" noremap <S-CR> ,
 noremap vv <S-v> 
 inoremap jk <ESC>
" inoremap <ESC> <NOP>
 vnoremap U ~
 vnoremap ~ <NOP>
" vnoremap <ESC> <NOP>
 vnoremap u <ESC>
 cnoremap jk <ESC>
" 这一段加上会使得命令模式中的上下键成为字符
" cnoremap <ESC> <NOP>
" 翻半页
" noremap J <C-d>
" noremap K <C-u>
" 翻一段（空行为一段）
noremap J }
noremap K {
" noremap T <Insert><Tab>

" ----------
" Register @ 
" ----------
augroup vim_reg_group
    autocmd!
    autocmd BufNewFile,BufRead *.vim,*.vimrc let @c="\<Insert>\" ----------\<ESC>\"0yy\"0pO"
augroup END

" ----------
" 
" ----------



" ----------
" Edit
" ----------

" ----------
" Edit .vimrc
" ----------
noremap <silent> <Leader>ev :split $MYVIMRC<CR>
noremap <silent> <Leader>sv :source $MYVIMRC<CR>

" ----------
" Edit Json
" ----------
command! JsonFormat :%!jq .

augroup json_edit_group
    autocmd!
    autocmd BufNewFile,BufRead *.json nmap <silent><buffer> == :JsonFormat<CR>
augroup END

" command! JsonFormat :execute '%!python2 -m json.tool'
" \ | :execute '%!python2 -c "import re,sys;sys.stdout.write(re.sub(r\"\\\u[0-9a-f]{4}\", lambda m:m.group().decode(\"unicode_escape\").encode(\"utf-8\"), sys.stdin.read()))"'
"augroup json_edit_group
"    autocmd!
"    autocmd BufNewFile,BufRead *.json nmap <silent><buffer> == :JsonFormat<CR>
"    autocmd BufNewFile,BufRead *.json nmap <silent><buffer> == :execute '%!python2 -m json.tool' | :execute '%!python2 -c "import re,sys;sys.stdout.write(re.sub(r\"\\\u[0-9a-f]{4}\", lambda m:m.group().decode(\"unicode_escape\").encode(\"utf-8\"), sys.stdin.read()))"'
"augroup END

" ----------
" Edit Java
" ----------
augroup java_edit_group
    autocmd!
    autocmd BufNewFile,BufRead *.java noremap <silent><buffer> ; $a;<ESC>
    autocmd BufNewFile,BufRead *.java noremap <silent><buffer>{ $a {<CR>}<ESC>O
augroup END

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
" Edit lua
" ----------
augroup lua_edit_group
    autocmd!
    autocmd BufNewFile,BufRead *.lua nnoremap <silent><buffer> <Leader>r :!/opt/homebrew/bin/lua %:p<CR>
    autocmd BufNewFile,BufRead *.lua vnoremap <silent><buffer> <Leader>r <ESC>:!/opt/homebrew/bin/lua %:p<CR>
    autocmd BufNewFile,BufRead *.lua noremap <silent><buffer> ; $a;<ESC>
    autocmd BufNewFile,BufRead *.lua noremap <silent><buffer>{ $a {<CR>}<ESC>O
augroup END

" --------------
" Copy and paste or replace
" --------------
set clipboard=unnamed
noremap <Leader>d "1d
noremap <Leader>p "1p
noremap x "-x
noremap c "-c
nnoremap cc "-cc
nnoremap s "-s
" vnoremap p "1dp
" 防止每次都在后面粘贴，不符合习惯
vnoremap p "1dP
noremap <Leader>y "1y
nnoremap <Leader>r viw"1dP
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

" map <C-w> <C-w><C-w>
" inoremap <C-w> <ESC><C-w><C-w>
noremap <Leader>h <C-w>h
noremap <Leader>j <C-w>j
noremap <Leader>k <C-w>k
noremap <Leader>l <C-w>l

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
" noremap m `
" noremap M m
" one page mark
noremap mm mm
noremap gm `m
" other page mark
noremap ma mA
noremap mb mB
noremap mc mC
noremap md mD
noremap ga `A
noremap gb `B
noremap gc `C
noremap gd `D
noremap m1 mE
noremap m2 mF
noremap m3 mG
noremap m4 mH
noremap g1 `E
noremap g2 `F
noremap g3 `G
noremap g4 `H
noremap m7 mI
noremap m8 mJ
noremap m9 mK
noremap m0 mL
noremap g7 `I
noremap g8 `J
noremap g9 `K
noremap g0 `L

" noremap go '^


" ----------
" Move
" ----------
noremap L <End>
" map H <Home>
" noremap H <Home> 
noremap H ^
noremap gf <C-]>
noremap gn %

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
" Plug 'scrooloose/syntastic'
" Plug 'vim-airline/vim-airline'
" Plug 'vim-airline/vim-airline-themes'
" Plug 'preservim/nerdtree'
" Plug 'instant-markdown/vim-instant-markdown', {'for': 'markdown', 'do': 'yarn install'}
" Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-surround'
" Plug 'flazz/vim-colorschemes'
call plug#end()
