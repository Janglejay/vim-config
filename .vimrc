"
exec "nohlsearch"
" exec "highlight Cursor guifg=blue guibg=blue"
" set highlight Cursor guifg=blue guibg=blue

" let mapleader="\<SPACE>"
"
" autocmd BufWrite * :echom "Writing buffer!"
let mapleader=","

nnoremap q <NOP>
nnoremap \ q

" ESC delay
set ttimeoutlen=0
set timeoutlen=500
" set timeoutlen=1500
" noremap <C-i> <nop>
" ----------
" origin keymap
" ----------
 nnoremap U :redo<CR>
 " noremap <C-u> <C-d>
 noremap <C-e> <C-d>
 noremap <C-r> <C-u>
 " nnoremap <C-d> <C-e>
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
 nnoremap go gi
 " cnoremap jk <ESC>
" 这一段加上会使得命令模式中的上下键成为字符
" cnoremap <ESC> <NOP>
" 翻半页
" noremap J <C-d>
" noremap K <C-u>
" 翻一段（空行为一段）
noremap J }
noremap K {
noremap <Leader>j *
noremap <Leader>k #
noremap W b
noremap zc zz
noremap zz zc
noremap zZ zM
noremap zO zR
" noremap vi> T>vt<
" noremap ci> T>ct<
" noremap T <Insert><Tab>

" ----------
" Register @ 
" ----------
" augroup vim_reg_group
"     autocmd!
"     autocmd BufNewFile,BufRead *.vim,*.vimrc let @c="\<Insert>\" ----------\<ESC>\"0yy\"0pO"
" augroup END

" ----------
" 
" ----------



" ----------
" Edit
" ----------

noremap { $a {<CR>}<ESC>O


" ----------
" Edit .vimrc
" ----------
" noremap <silent> <Leader>ev :split $MYVIMRC<CR>
" noremap <silent> <Leader>sv :source $MYVIMRC<CR>

" ----------
" Edit Json
" ----------
" command! JsonFormat :%!jq .

" augroup json_edit_group
"     autocmd!
"     autocmd BufNewFile,BufRead *.json nmap <silent><buffer> = :JsonFormat<CR>
" augroup END
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
" augroup java_edit_group
"     autocmd!
"     autocmd BufNewFile,BufRead *.java noremap <silent><buffer> ; $a;<ESC>
"     autocmd BufNewFile,BufRead *.java noremap <silent><buffer>{ $a {<CR>}<ESC>O
" augroup END
noremap <silent><buffer> ; $a;<ESC>
noremap <silent><buffer>{ $a {<CR>}<ESC>O

" ----------
" Edit Rust
" ----------
augroup rust_edit_group
  autocmd!
  autocmd BufNewFile,BufRead *.rs noremap <silent><buffer> ; $a;<ESC>
  autocmd BufNewFile,BufRead *.rs noremap <silent><buffer>{ $a {<CR>}<ESC>O
  " autocmd BufNewFile,BufRead *.rs noremap <silent><buffer>zr :RustRun<CR>
  " autocmd BufNewFile,BufRead *.rs noremap <silent><buffer>zR :!cargo run<CR>
  " autocmd BufNewFile,BufRead *.rs noremap <silent><buffer>zr <cmd>lua _RUST_TOGGLE()<CR>
  autocmd BufNewFile,BufRead *.rs noremap <silent><buffer>zr <cmd>w<CR><cmd>TermExec cmd="cargo run" dir="."<CR>
  autocmd BufNewFile,BufRead *.rs noremap <silent><buffer>zb <cmd>w<CR><cmd>TermExec cmd="cargo build" dir="."<CR>
  autocmd BufNewFile,BufRead *.rs noremap <silent><buffer>zc <cmd>w<CR><cmd>TermExec cmd="cargo check" dir="."<CR>
  autocmd BufNewFile,BufRead *.rs noremap <silent><buffer>zR <cmd>w<CR><cmd>RustRun<CR>
augroup END

" ----------
" Edit go
" ----------
augroup go_edit_group
    autocmd!
    autocmd BufNewFile,BufRead *.go noremap <silent><buffer> ; $a;<ESC>
    autocmd BufNewFile,BufRead *.go noremap <silent><buffer>{ $a {<CR>}<ESC>O
    autocmd BufNewFile,BufRead *.go noremap <silent><buffer>zr <cmd>TermExec cmd="go run main.go" dir="."<CR>
    " autocmd BufNewFile,BufRead *.go nnoremap <silent><buffer> zr :!go run %:p<CR>
augroup END

" ----------
" Edit markdown
" ----------
augroup markdown_edit_group
    autocmd!
    " autocmd BufNewFile,BufRead *.md noremap <silent><buffer> <Leader>f /<++><CR>:nohl<CR>4"-cl
    " autocmd BufNewFile,BufRead *.md noremap <silent><buffer> <Leader>` <Insert>```<CR><++><CR>```<ESC>
    " autocmd BufNewFile,BufRead *.md noremap <silent><buffer> <Leader>b <Insert>**<++>**<ESC>
    " autocmd BufNewFile,BufRead *.md noremap <silent><buffer> <Leader>s <Insert>~~<++>~~<ESC>
    " autocmd BufNewFile,BufRead *.md noremap <silent><buffer> <Leader>o <Insert>[<++>](<++>)<ESC>
    " autocmd BufNewFile,BufRead *.md noremap <silent><buffer> <Leader>p <Insert>![<++>](<++>)<ESC>
    " autocmd BufNewFile,BufRead *.md noremap <silent><buffer> <Leader>m <Insert>- [<++>]<ESC>
                                                     
    " autocmd BufNewFile,BufRead *.md inoremap <silent><buffer> <Leader>x <ESC>/<++><CR>:nohl<CR>4"-cl
    " autocmd BufNewFile,BufRead *.md inoremap <silent><buffer> <Leader>c ```<CR><++><CR>```
    " autocmd BufNewFile,BufRead *.md inoremap <silent><buffer> <Leader>b **<++>**
    " autocmd BufNewFile,BufRead *.md inoremap <silent><buffer> <Leader>s ~~<++>~~
    " autocmd BufNewFile,BufRead *.md inoremap <silent><buffer> <Leader>l [<++>](<++>)
    " autocmd BufNewFile,BufRead *.md inoremap <silent><buffer> <Leader>p ![<++>](<++>)
    " autocmd BufNewFile,BufRead *.md inoremap <silent><buffer> <Leader>m - [ ]

    autocmd BufNewFile,BufRead *.md nnoremap <silent><buffer> <Leader>x /<++><CR>:nohl<CR>4"-cl
    autocmd BufNewFile,BufRead *.md nnoremap <silent><buffer> <Leader>C i```<CR><++><CR>```<ESC>
    autocmd BufNewFile,BufRead *.md nnoremap <silent><buffer> <Leader>c i`<++>`<ESC>
    autocmd BufNewFile,BufRead *.md nnoremap <silent><buffer> <Leader>b i**<++>**<ESC>
    autocmd BufNewFile,BufRead *.md nnoremap <silent><buffer> <Leader>s i~~<++>~~<ESC>
    autocmd BufNewFile,BufRead *.md nnoremap <silent><buffer> <Leader>o i[<++>](<++>)<ESC>
    autocmd BufNewFile,BufRead *.md nnoremap <silent><buffer> <Leader>O i![<++>](<++>)<ESC>
    autocmd BufNewFile,BufRead *.md nnoremap <silent><buffer> <Leader>m i- [ ]<ESC>

    " autocmd BufNewFile,BufRead *.md vmap <silent><buffer> <Leader>c <Leader>d<Insert>```<CR>```<CR><ESC>kO<ESC><Leader>p<ESC>
    " autocmd BufNewFile,BufRead *.md vnoremap <silent><buffer> <Leader>s d<Insert>~~~~<ESC>2hp
    " autocmd BufNewFile,BufRead *.md vnoremap <silent><buffer> <Leader>b d<Insert>****<ESC>2hp
    " autocmd BufNewFile,BufRead *.md vnoremap <silent><buffer> <Leader>l d<Insert>[<++>]()<ESC>hp
    " autocmd BufNewFile,BufRead *.md vnoremap <silent><buffer> <Leader>p d<Insert>![<++>]()<ESC>hp

augroup END

nnoremap <silent><buffer> <Leader>x /<++><CR>:nohl<CR>4"-cl
" ----------
" Edit lua
" ----------
augroup lua_edit_group
    autocmd!
    " autocmd BufNewFile,BufRead *.lua nnoremap <silent><buffer> <Leader>r :!/opt/homebrew/bin/lua %:p<CR>
    " autocmd BufNewFile,BufRead *.lua vnoremap <silent><buffer> <Leader>r <ESC>:!/opt/homebrew/bin/lua %:p<CR>
    autocmd BufNewFile,BufRead *.lua nnoremap <silent><buffer> zr :!/opt/homebrew/bin/lua %:p<CR>
    " autocmd BufNewFile,BufRead *.lua vnoremap <silent><buffer> zr <ESC>:!/opt/homebrew/bin/lua %:p<CR>
    autocmd BufNewFile,BufRead *.lua noremap <silent><buffer> ; $a;<ESC>
    autocmd BufNewFile,BufRead *.lua noremap <silent><buffer>{ $a {<CR>}<ESC>O
augroup END

" --------------
" Copy and paste or replace
" --------------
set clipboard=unnamed
nnoremap Y gg^yG<End>
" nnoremap V gg^vG<End>
nnoremap <Leader>v gg^vG<End>
noremap <Leader>d "_d
" noremap <Leader>p "1p
noremap x "-x
noremap c "-c
nnoremap cc "-cc
nnoremap s "-s
" vnoremap p "1dp
" 防止每次都在后面粘贴，不符合习惯
vnoremap p "_dP
noremap <Leader>y "_y
nnoremap <Leader>r viw"_dP
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
noremap gh <C-w>h
noremap gj <C-w>j
noremap gk <C-w>k
noremap gl <C-w>l

noremap sV :sp<CR>
noremap sv :vs<CR>

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
" noremap mm mm
" noremap gm `m
" " other page mark
" noremap m1 mA
" noremap m2 mB
" noremap m3 mC
" noremap m4 mD
" noremap g1 `A
" noremap g2 `B
" noremap g3 `C
" noremap g4 `D
" noremap m5 mE
" noremap m6 mF
" noremap m7 mG
" noremap m8 mH
" noremap g5 `E
" noremap g6 `F
" noremap g7 `G
" noremap g8 `H
" noremap m9 mI
" noremap m0 mJ
" noremap g9 `I
" noremap g0 `J

" noremap go '^


" ----------
" Move
" ----------
noremap L <End>
" map H <Home>
" noremap H <Home> 
noremap H ^
" noremap gf <C-]>
noremap gn %

" ----------
" Show
" ----------
set cursorline
set number
set noshowmode
set relativenumber
" set scrolloff=25
set nowrap


nnoremap <Tab> >>
" nnoremap <S-Tab> <<
nnoremap <BS> <<
vnoremap <Tab> >
" vnoremap <S-Tab> < 
vnoremap <BS> < 

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
Plug 'preservim/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'instant-markdown/vim-instant-markdown', {'for': 'markdown', 'do': 'yarn install'}
" Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() }, 'for': ['markdown', 'vim-plug']}
" Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-surround'
Plug 'dhruvasagar/vim-table-mode'
Plug 'tiagofumo/vim-nerdtree-syntax-highlight'
Plug 'ryanoasis/vim-devicons'
" Plug 'rust-lang/rust.vim'
" Plug 'flazz/vim-colorschemes'
call plug#end()
