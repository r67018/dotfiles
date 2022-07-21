" ----------------------------------------------------------------------------
"  python setting
" ----------------------------------------------------------------------------
if !exists('python3_host_prog')
    let g:python3_host_prog = expand('~/AppData/Local/Programs/Python/Python310/python.exe')
endif

" ----------------------------------------------------------------------------
"  dein setting
" ----------------------------------------------------------------------------
let s:dein_dir = expand('~/.cache/dein')
let s:dein_repo_dir = s:dein_dir . '/repos/github.com/Shougo/dein.vim'

if &runtimepath !~# '/dein.vim'
    if !isdirectory(s:dein_repo_dir)
        execute '!git clone https://github.com/Shougo/dein.vim' s:dein_repo_dir
    endif
    execute 'set runtimepath+=' . fnamemodify(s:dein_repo_dir, ':p')
endif

if dein#load_state(s:dein_dir)
    call dein#begin(s:dein_dir)

    let g:rc_dir    = expand('~/.vim/rc/')
    let s:toml      = g:rc_dir . 'dein.toml'

    let s:lazy_toml = g:rc_dir . 'dein_lazy.toml'
    call dein#load_toml(s:toml,      {'lazy': 0})
    call dein#load_toml(s:lazy_toml, {'lazy': 1})

    call dein#end()
    call dein#save_state()
endif

if dein#check_install()
    call dein#install()
endif

" ----------------------------------------------------------------------------
"  key bind
" ----------------------------------------------------------------------------
let mapleader = "\<Space>"

" do not use register
nnoremap x "_x
nnoremap s "_s

" new line
nnoremap <CR> o<Esc>
nnoremap <Tab><CR> O<Esc>

" move window
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-h> <C-w>h
nnoremap <C-l> <C-w>l


" macros
nnoremap <silent> <Esc><Esc> :<C-u>nohlsearch<CR>
nnoremap <Leader>. :new ~/.vimrc<CR>
inoremap <C-t> <Esc><Left>"zx"zpa


" ----------------------------------------------------------------------------
"  Terminal
" ----------------------------------------------------------------------------
if has('nvim')
    " :Tv でターミナルを開く(垂直)
    command! -nargs=* T vsplit | wincmd j | terminal /bin/fish <args>
    " :T でターミナルを開く(水平)
    command! -nargs=* Th split | wincmd j | resize 15 | terminal /bin/fish <args>
    " インサートモードでターミナルを開く
    autocmd TermOpen * startinsert
    " @t で新しいタブでターミナルを開く
    nnoremap @t :tabe<CR>:terminal<CR>
    " ノーマルモードへESCで移行
    tnoremap <silent><Esc> <C-\><C-n>
endif

" ----------------------------------------------------------------------------
"  Utility
" ----------------------------------------------------------------------------
" common setting
set noswapfile

" file setting
set fileformats=unix,dos,mac
set fileencodings=utf-8,sjis

" theme setting
syntax on
set termguicolors
set t_Co=256
colorscheme iceberg
let g:airline_theme='iceberg'
autocmd vimenter * hi Normal guibg=NONE ctermbg=NONE
autocmd vimenter * hi EndOfBuffer guibg=NONE ctermbg=NONE
" autocmd vimenter * hi LineNr guibg=NONE ctermbg=NONE

" editer setting
set number                     " 行番号表示
set splitbelow                 " 水平分割時に下に表示
set splitright                 " 縦分割時を右に表示
set noequalalways              " 分割時に自動調整を無効化
set nowrap                     " 長い行を折り返さない
set wildmenu                   " コマンドモードの補完
set nolist                     " 空白文字の可視化無効
set backspace=indent,eol,start " バックスペースを行頭などでも使えるようにする

" search setting
set hlsearch                   " 検索結果ハイライト
set incsearch                  " インクリメンタルサーチ有効化
set ignorecase                 " 大文字小文字を区別しない
set smartcase                  " 小文字なら大文字を無視、大文字なら無視しない
set wrapscan                   " ファイル末尾まで検索したら先頭までループする

" cursorl setting
set ruler                      " カーソルの位置表示
set whichwrap=b,s,h,l,[,],<,>,~      " カーソルの回り込み有効化
set cursorline " 現在の行をハイライト
highlight CursorLine guifg=NONE guibg=NONE

" tab setting
set expandtab                  " tabを複数のspaceに置き換え
set tabstop=4                  " tabは半角4文字
set shiftwidth=4               " tabの幅
set smartindent                " 自動インデント
set autoindent                 " 新しい行のインデントを現在の行と同じ量にする


" ----------------------------------------------------------------------------
"  Plugins
" ----------------------------------------------------------------------------
" ctags
set tags=./.tags;$HOME
nnoremap <C-]> g<C-]>
inoremap <C-]> <Esc>g<C-]>
" easymotion
map  <Leader>s <Plug>(easymotion-bd-f2)
nmap <Leader>s <Plug>(easymotion-overwin-f2)
map  <Leader>l <Plug>(easymotion-bd-jk)
nmap <Leader>l <Plug>(easymotion-overwin-line)
" easy-align
xmap ga <Plug>(EasyAlign)
nmap ga <Plug>(EasyAlign)
" deoplete
" autocmd VimEnter * inoremap <expr><CR> ((pumvisible()) ? (deoplete#close_popup() "\<CR>" sleep 1 "\<CR>") : "\<CR>")
" inoremap <expr><CR> ((pumvisible()) ? (deoplete#close_popup() "\<CR>" "\<CR>") : "\<CR>")
" autocmd VimEnter * inoremap <expr><CR> pumvisible() ? "<Esc>:call deoplete#close_popup()<CR>a<CR>" : "<CR>"


" ----------------------------------------------------------------------------
"  Others
" ----------------------------------------------------------------------------
" change shape of cursor
if has('vim_starting')
    " Insert mode
    let &t_SI .="\e[6 q"
    " Normal mode
    let &t_EI .= "\e[2 q"
endif

" load .vimrc automatically
augroup vimrc_loading
    au!
    au BufWritePost .vimrc,_vimrc,_vimrc,.gvimrc,_gvimrc,gvimrc,init.vim so $MYVIMRC | if has('gui_running') | so $MYGVIMRC | endif
augroup END


" share clipboard with windows"
if system('uname -a | grep -i Microsoft') != ''
    augroup windows_yank
        au!
        au TextYankPost * :call system('clip.exe', @")
    augroup END
endif
