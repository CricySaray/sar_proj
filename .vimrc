
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"               
"        ██╗   ██╗██╗███╗   ███╗██████╗  ██████╗
"        ██║   ██║██║████╗ ████║██╔══██╗██╔════╝
"        ██║   ██║██║██╔████╔██║██████╔╝██║     
"        ╚██╗ ██╔╝██║██║╚██╔╝██║██╔══██╗██║     
"         ╚████╔╝ ██║██║ ╚═╝ ██║██║  ██║╚██████╗
"          ╚═══╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝
"               

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" All system-wide defaults are set in $VIMRUNTIME/debian.vim and sourced by
" the call to :runtime you can find below.  If you wish to change any of those
" settings, you should do it in this file (/etc/vim/vimrc), since debian.vim
" will be overwritten everytime an upgrade of the vim packages is performed.
" It is recommended to make changes after sourcing debian.vim since it alters
" the value of the 'compatible' option.

runtime! debian.vim

" Set the backslash as the leader key.
let mapleader = "\\"

""" BASIC CONFIG ------------------------------------------------------------
if has("syntax")
  syntax on
endif
filetype plugin indent on
set scrolloff=5
set nocompatible
set showcmd  " Show (partial) command in status line.
set showmatch  " Show matching brackets.
set ignorecase  " Do case insensitive matching
set smartcase  " Do smart case matching
set incsearch  " Incremental search
set autowrite  " Automatically save before commands like :next and :make
set hidden  " Hide buffers when they are abandoned
"set mouse=a  " Enable mouse usage (all modes)
set bufhidden=hide " 当buffer被丢弃的时候隐藏它
set t_Co=256
set background=dark
colorscheme gruvbox " 设定配色方案
set number " 显示行号
set cursorline " 突出显示当前行
set ruler " 打开状态栏标尺
set shiftwidth=2 " 设定 << 和 >> 命令移动时的宽度为 3，同时，用=来格式化的时候也是根据这一项来设定indent的宽度为多少的。
set softtabstop=2 " 使得按退格键时可以一次删掉 2 个空格
set tabstop=2 " 设定 tab 长度为 2
" set shiftwidth=4 "when indenting with '>', use 4 spaces width
set nobackup " 覆盖文件时不备份
set autochdir " 自动切换当前目录为当前文件所在的目录
set backupcopy=yes " 设置备份时的行为为覆盖
set hlsearch " 搜索时高亮显示被找到的文本
set noerrorbells " 关闭错误信息响铃
set novisualbell " 关闭使用可视响铃代替呼叫
set t_vb= " 置空错误铃声的终端代码
set matchtime=2 " 短暂跳转到匹配括号的时间
set magic " 设置魔术
set smartindent " 开启新行时使用智能自动缩进
set backspace=indent,eol,start " 不设定在插入状态无法用退格键和 Delete 键删除回车符
set cmdheight=1 " 设定命令行的行数为 1
set nofoldenable " 开始折叠
set foldmethod=indent 
set foldcolumn=0 " 设置折叠区域的宽度
set foldlevel=1 " 设置折叠层数为 1
 au FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o
set showmode
set history=1000
set wildmenu
" Make wildmenu behave like similar to Bash completion.
set wildmode=list:longest
" There are certain files that we would never want to edit with Vim.
" Wildmenu will ignore files with these extensions.
set wildignore=*.docx,*.jpg,*.png,*.gif,*.pdf,*.pyc,*.exe,*.flv,*.img,*.xlsx
set laststatus=2
set backspace=indent,eol,start


""" MAPPINGS --------------------------------------------------------------- {{{
" .vimrc config
nnoremap <leader>ev :vsplit $MYVIMRC<cr>
nnoremap <leader>sv :source $MYVIMRC<cr>

" editing config
nnoremap <c-a> I
nnoremap <c-e> A
inoremap <c-a> <esc>I
inoremap <c-e> <esc>A
noremap - dd
" buffers config
nnoremap <c-n> :bn <CR>
nnoremap <c-p> :bp <CR>

" jump out of parenthesis, bracket, brace, quotes etc
inoremap <C-l> <C-\><C-n>:call search('[>)\]}"'']', 'W')<CR>a
" map the U to redo
nnoremap U :redo<CR>
" copy the error or warning message to buffers
nnoremap <silent><leader>x :put =trim(execute(input(':', '', 'command')))<CR>

" Mappings code goes here.
inoremap jj <esc>
vnoremap ii <esc>

"这个太牛啦
" Press the space bar to type the : character in command mode. 
nnoremap <space> :

" Pressing the letter o will open a new line below the current one.
" Exit insert mode after creating a new line above or below the current line.
nnoremap o o<esc>
nnoremap O O<esc>

" You can split the window in Vim by typing :split or :vsplit.
" Navigate the split view easier by pressing CTRL+j, CTRL+k, CTRL+h, or CTRL+l.
nnoremap <c-j> <c-w>j
nnoremap <c-k> <c-w>k
nnoremap <c-h> <c-w>h
nnoremap <c-l> <c-w>l

" Resize split windows using arrow keys by pressing:
" CTRL+UP, CTRL+DOWN, CTRL+LEFT, or CTRL+RIGHT.
noremap <c-up> <c-w>+
noremap <c-down> <c-w>-
noremap <c-left> <c-w>>
noremap <c-right> <c-w><


" Have nerdtree ignore certain files and directories.
let NERDTreeIgnore=['\.git$', '\.jpg$', '\.mp4$', '\.ogg$', '\.iso$', '\.pdf$', '\.pyc$', '\.odt$', '\.png$', '\.gif$', '\.db$']


""" VIMSCRIPT -------------------------------------------------------------- 

" ---------------------------
" auto reLoad file every 500ms
set autoread
au FocusGained,BufEnter * :silent! !
au CursorHold,CursorHoldI * checktime
set updatetime=500

" ----------------------------
"" Difference between buffer contents and file on disc
command! ToggleDiffSaved vert new | set bt=nofile | r # | 0d_ | diffthis
		\ | wincmd p | diffthis
nnoremap <leader>ds :ToggleDiffSaved<cr>  " 这里的<leader>是反斜杠 \

" ----------------------------
" This will enable code folding.
" Use the marker method of folding.
augroup filetype_vim
    autocmd!
    autocmd FileType vim setlocal foldmethod=marker
augroup END


""" STATUS LINE ------------------------------------------------------------ 

" set status line  display (no need for other plugins)
set statusline=%n\ %F%m%r%h%w%=\ \ \ \ \ \ %l/%L,\ %c/%{col('$')-1}\ \ \ --%p%%--\
set laststatus=2
