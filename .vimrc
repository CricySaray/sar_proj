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

""" INCREAMENTAL SETTINGS -------------------------------------------------------
"" you can write some misc config when you are in client env such as VDI/Xclient


""" KEYWORDS TO HIGHLIGHT -------------------------------------------------------


""" ABBR CONFIG -----------------------------------------------------------------
iabbrev hw Hello World
iabbrev SS ######################################<esc>oi# author     : sar <esc>oi# descrip    : this is blahblah ... <esc>oi######################################<esc>oi
iabbrev ec ecoChangeCell
iabbrev ea ecoAddRepeater
iabbrev ed ecoDeleteRepeater
cabbrev GG %!grep -B1 -A1
cabbrev bwp v/BWP/d
cabbrev a %!awk '{print }'
cabbrev 12 %!awk '{print $1,$2}'
cabbrev ) %s/(\|)//g
cabbrev ch12 %!awk '{print $2,$1}'
cabbrev rmulvt g/CPDULVT/d
cabbrev rmpinm %s/\/\w\+ / /
cabbrev rmpine %s/\/\w\+$//
cabbrev lvtm %s/CPD /CPDLVT /
cabbrev lvte %s/CPD$/CPDLVT/
cabbrev ulvtm %s/CPDLVT /CPDULVT /
cabbrev ulvte %s/CPDLVT$/CPDULVT/
cabbrev t16 %s/T\d\dP96/T16P96/
cabbrev ec %!awk '{print "ecoChangeCell -cell",$1,"-inst",$2}'
cabbrev vv vs ~/.vimrc
cabbrev co %!column -t -s '|'
cabbrev re r ~/project/scr_sar/ref_content/setEcoMode.tcl
cabbrev rt r ~/project/scr_sar/ref_content/head_of_proc.txt

""" SETTING CONFIG --------------------------------------------------------------
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
set expandtab
" set shiftwidth=4 "when indenting with '>', use 4 spaces width
set nobackup " 覆盖文件时不备份
" set autochdir " 自动切换当前目录为当前文件所在的目录
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
set textwidth=0


""" MAPPINGS --------------------------------------------------------------------

cnoremap dd !date +"%Y/%m/%d %H:%M:%S %A"

" .vimrc config
nnoremap <leader>ev :vsplit $MYVIMRC<cr>
nnoremap <leader>sv :source $MYVIMRC<cr>

" editing config
nnoremap <c-a> I
nnoremap <c-e> A
inoremap <c-a> <esc>I
inoremap <c-e> <esc>A
noremap - dd
nnoremap <F2> :g/^\s*$/d<CR>
nnoremap <F3> :tabnew .<CR>
nnoremap <F4> a<c-r>=strftime('%Y/%m/%d %H:%M:%S %A')<CR><Esc>
nnoremap <c-a> ggVG:ya
nnoremap <s-d> k
nnoremap <s-f> j

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


""" VIMSCRIPT & FUNCTIONS -------------------------------------------------------


" ---------------------------
" switch paste mode and show status of paste
function! TogglePaste()
    set invpaste
    if &paste
        echo "- paste mode on -"
    else
        echo "- paste mode off -"
    endif
endfunction
nnoremap <leader>p :call TogglePaste()<CR>
inoremap <leader>p <C-o>:call TogglePaste()<CR>

" ---------------------------
" replace all same name to new name, It can automatically identify the boundaries of variables
function! s:SmartReplace()
  let old_name = expand("<cword>")
  let new_name = input("replace to: ", old_name)
  if new_name != '' && new_name != old_name
    execute '%s/\<' . old_name . '\>/' . new_name . '/g'
  endif
endfunction
nnoremap <leader>r :call <SID>SmartReplace()<CR>

" for ctags, it can detect whole vars name such as vars(xjbe,cts,max_trans)
"		correspondingly, ~/.ctags file need modify suitable pattern to get correct var name!!!
"		such as : in ~/.ctags file :
"			--langdef=tcl
" 		--langmap=tcl:.tcl
" 		--regex-tcl=/^\s*set\s+((vars|FP)\([^)]+\))?\s+/\1/v,vars,variables/
" 		--extra=+q
function! TclGotoTag()
	execute "set tags=./tags;/"
	execute "set iskeyword+=$,(,),,"
  let l:word = expand("<cword>")
  let l:tag = substitute(l:word, '.*\$\(\(vars\|FP\)(.*)\)', '\1', '')  " 去除$符号
	execute "set iskeyword-=$,(,),,"
  execute "tag " . l:tag
endfunction
autocmd FileType tcl nnoremap <C-]> :call TclGotoTag()<CR>

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

" ----------------------------
" 仅对指定文件格式设置自动补全功能
" autocmd FileType c,cpp,sh,java,html,js,css,py exec AutoComplete()
" 对所有文件格式设置自动补全功能
autocmd FileType * exec AutoComplete()
func! AutoComplete()
    "相关映射
    :inoremap ( ()<Left>
    :inoremap ) <c-r>=ClosePair(')')<CR>
    :inoremap { {}<Left>
    :inoremap } <c-r>=ClosePair('}')<CR>
    :inoremap [ []<Left>
    :inoremap ] <c-r>=ClosePair(']')<CR>
    :inoremap " <c-r>=DQuote()<CR>
    :inoremap ' <c-r>=SQuote()<CR>
	" 将BackSpace键映射为RemovePairs函数
    :inoremap <BS> <c-r>=RemovePairs()<CR>
	" 将回车键映射为BracketIndent函数
	:inoremap <CR> <c-r>=BracketIndent()<CR>
endfunc

func! ClosePair(char)
    if getline('.')[col('.') - 1] == a:char
        return "\<Right>"
    else
        return a:char
    endif
endfunc
"自动补全双引号
func! DQuote()
    if getline('.')[col('.') - 1] == '"'
        return "\<Right>"
    else
		if getline('.')[col('.') - 2] == '"'
			return '"'
		else
			return "\"\"\<Left>"
    endif
endfunc
"自动补全单引号
func! SQuote()
    if getline('.')[col('.') - 1] == "'"
        return "\<Right>"
    else
		if getline('.')[col('.') - 2] == "'"
			return "'"
		else
	        return "''\<Left>"
    endif
endfunc
" 按BackSpace键时判断当前字符和前一字符是否为括号对或一对引号，如果是则两者均删除，并保留BackSpace正常功能
func! RemovePairs()
	let l:line = getline(".") " 取得当前行
	let l:current_char = l:line[col(".")-1] " 取得当前光标字符
	let l:previous_char = l:line[col(".")-2] " 取得光标前一个字符 
	if (l:previous_char == '"' || l:previous_char == "'") && l:previous_char == l:current_char
		return "\<delete>\<bs>"
	elseif index(["(", "[", "{"], l:previous_char) != -1
		" 将光标定位到前括号上并取得它的索引值
		execute "normal! h" 
		let l:front_col = col(".")
		" 将光标定位到后括号上并取得它的行和索引值
		execute "normal! %" 
		let l:line1 = getline(".")
		let l:back_col = col(".")
		" 将光标重新定位到前括号上
		execute "normal! %"
		" 当行相同且后括号的索引比前括号大1则匹配成功
		if l:line1 == l:line && l:back_col == l:front_col + 1
			return "\<right>\<delete>\<bs>"
		else
			return "\<right>\<bs>"
		end
	else
	  	return "\<bs>" 
	end
endfunc 
" 在大括号内换行时进行缩进
func! BracketIndent()
	let l:line = getline(".")
	let l:current_char = l:line[col(".")-1] 
	let l:previous_char = l:line[col(".")-2] 
	if l:previous_char == "{" && l:current_char == "}"
		" below statement need modify according to different env
		return "\<cr>\<cr>\<esc>\k\i\<tab>"
	else
		return "\<cr>"
	end
endfunc
"设置跳出自动补全的括号
func! SkipPair()
    if getline('.')[col('.') - 1] == ')' || getline('.')[col('.') - 1] == ']' || getline('.')[col('.') - 1] == '"' || getline('.')[col('.') - 1] == "'" || getline('.')[col('.') - 1] == '}'
        return "\<ESC>la"
    else
        return "\t"
    endif
endfunc
" 将tab键绑定为跳出括号
inoremap <TAB> <c-r>=SkipPair()<CR>

""" SIMPLE COMMAND OR AUTO COMMAND (AUTOCMD) ------------------------------------
" show the table of contents of vimrc
command! -nargs=0 TableOfVimrc :execute 'normal! :v/^""" [A-Z]\+/d<CR>'
" Automatically load custom dictionary for automatic completion function
"		you can get completion using ctrl x + ctrl k
autocmd FileType tcl set dictionary=~/.vim/dict/invs_commands.dict,~/.vim/dict/invs_options_of_command.dict,~/.vim/dict/pt_command_list.dict,~/.vim/dict/invs_dbxxx_commands.dict

""" STATUS LINE CONFIG ----------------------------------------------------------

" set status line  display (no need for other plugins)
set statusline=%n\ %F%m%r%h%w%=\ \ \ \ \ \ %l/%L,\ %c/%{col('$')-1}\ \ \ --%p%%--\
set laststatus=2

""" PLUGINS MANAGER CONFIG ------------------------------------------------------
"" Jetpack - vim-plug style
packadd vim-jetpack
call jetpack#begin()
Jetpack 'tani/vim-jetpack', {'opt': 1} "bootstrap
Jetpack 'tpope/vim-surround', { 'as' : 'surround'}
Jetpack 'junegunn/fzf', { 'do': { -> fzf#install() }}
Jetpack 'junegunn/fzf.vim'
Jetpack 'rickhowe/diffchar.vim', { 'as' : 'diffchar'}
Jetpack 'godlygeek/tabular'
" Jetpack 'https://github.com/dense-analysis/ale'
" Jetpack 'junegunn/fzf.vim'
" Jetpack 'junegunn/fzf', { 'do': {-> fzf#install()} }
" Jetpack 'neoclide/coc.nvim', { 'branch': 'release' }
" Jetpack 'neoclide/coc.nvim', { 'branch': 'master', 'do': 'yarn install --frozen-lockfile' }
" Jetpack 'vlime/vlime', { 'rtp': 'vim' }
" Jetpack 'dracula/vim', { 'as': 'dracula' }
" Jetpack 'tpope/vim-fireplace', { 'for': 'clojure' }
call jetpack#end()
" --------
" setting for plugs 
" for godlygeek/tabular
" 对齐 Tcl 变量的值（第三个参数），左侧不留空格
vnoremap <leader>ta :%Tabularize /set\s\+\S\+\s\+/l0<CR>
