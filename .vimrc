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
cabbrev co %!column -t -s '\|'
""" KEYWORDS TO HIGHLIGHT -------------------------------------------------------

" 定义一个三维列表，支持两种匹配模式:
" - 直接匹配: ['Exact', 高亮组, [关键词1, 关键词2, ...]]
" - 正则匹配: ['Regex', 高亮组, [正则表达式1, 正则表达式2, ...]]
let g:highlight_groups = [
      \ ['Exact', 'Special', ['pw', 're', 'la', 'lo', 'al', 'ol', 'eo', 'er', 'ci', 'every', 'any', 'lextract', 'xor', 'pe']],
      \ ['Exact', 'Cursor',  ['songNOTE']],
      \ ['Exact', 'GruvboxFg0', ['TODO', 'FIXED', 'NOTICE', 'ADVANCE', 'BUG', 'partial', 'IMPORTANT', 'FASTER', 'DEPRECATED', 'RESERVED']],
      \ ['Regex', 'GruvboxFg0', ['U\d\{3}', 'ID\d\{4,}', 'AT\d\{3}']],
      \ ]
" 创建高亮组自动命令
augroup highlight_keywords
  autocmd!
  autocmd BufEnter * call SetupKeywordHighlights()
augroup END
" 设置关键词高亮的函数
function! SetupKeywordHighlights()
  " 遍历每个高亮组配置
  for group in g:highlight_groups
    let match_type = group[0]
    let highlight_group = group[1]
    let patterns = group[2]
    " 遍历模式列表，为每个模式设置语法匹配
    for pattern in patterns
      if match_type ==# 'Exact'
        " 直接匹配模式 (整词匹配)
        execute 'syn match HighlightKeyword_' . highlight_group . ' /\V\<'. escape(pattern, '/\') .'\>/ containedin=.*'
      elseif match_type ==# 'Regex'
        " 正则表达式匹配模式
        execute 'syn match HighlightKeyword_' . highlight_group . ' /\<'. pattern .'\>/ containedin=.*'
      endif
    endfor
    " 设置当前高亮组的高亮样式
    execute 'hi def link HighlightKeyword_' . highlight_group . ' ' . highlight_group
  endfor
endfunction


""" ABBR CONFIG -----------------------------------------------------------------
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
cabbrev re r ~/project/scr_sar/ref_content/setEcoMode.tcl
cabbrev dp r ~/project/scr_sar/ref_content/define_proc_arguments.tcl
cabbrev pdp r ~/project/scr_sar/ref_content/define_perl_options.txt
" insert head of proc for tcl or perl, can change DATE to time now
function! InsertProcessHead()
  " 读取文件的前9行到当前位置
  execute 'r! sed -n ''1,12p'' ~/project/scr_sar/ref_content/head_of_proc.txt'
  " 获取当前行号（即新插入内容的第一行）
  let end_line = line('.')
  " 计算结束行号（当前行 + 9）
  let start_line = end_line - 9
  " 构建并执行替换命令（将DATE替换为当前日期时间）
  let date_str = strftime('%Y/%m/%d %H:%M:%S %A')
  execute start_line . ',' . end_line . 's/DATE/' . escape(date_str, '/') . '/g'
endfunction
command! Rt call InsertProcessHead()


""" VIM VARIABLES SETTING -------------------------------------------------------
set path+=**


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
set foldmethod=syntax
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
" Linux/macOS系统示例（Monospace字体，大小14）
if has('gui_running') && (has('unix') || has('mac'))
  set guifont=Monospace\ 8
endif


""" MAPPINGS --------------------------------------------------------------------

" .vimrc config
nnoremap <leader>ev :vsplit $MYVIMRC<cr>
nnoremap <leader>sv :source $MYVIMRC<cr>
"" Define the gd command as first executing the native gd and then returning to
"" the original position
nnoremap <silent> gd :normal! m'gd<C-O><CR>

" editing config
nnoremap <c-h> <c-e>
nnoremap <c-a> I
nnoremap <c-e> A
inoremap <c-a> <esc>I
inoremap <c-e> <esc>A
noremap - dd
nnoremap <F3> :tabnew .<CR>
nnoremap <F4> a<c-r>=strftime('%Y/%m/%d %H:%M:%S %A')<CR><Esc>
nnoremap <c-a> ggVG:ya
nnoremap <s-d> k
nnoremap <s-f> j

" buffers config
nnoremap <c-n> :bn <CR>
nnoremap <c-p> :bp <CR>
" searching in vim
vnoremap <silent> <leader>y :<C-U>let @/=escape(@@, '/\')<CR>


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
" Custom column alignment script with indent preservation
" Usage:
" 1. Select lines in visual mode
" 2. Execute :AlignColumns [column range] [alignment method] [reset]
"    Default: Align columns 1-3 with left alignment, no reset
"    Examples: :AlignColumns              (Defaults: 1-3, left, no reset)
"              :AlignColumns 2-5 r        (Align 2-5 right, no reset)
"              :AlignColumns 1,3 c yes    (Align 1,3 center, no reset)
"              :AlignColumns 1-3 reset    (Reset columns 1-3 to original state)
"              :AlignColumns reset        (Reset default columns 1-3)

function! AlignSelectedColumns(...) range
  " Check if any lines are selected
  if a:firstline == a:lastline && getline(a:firstline) =~ '^\s*$'
    echo "Error: No lines selected or selected line is empty"
    return
  endif

  " Parse arguments with support for reset option
  let reset = 0
  let columns = '1-2'
  let alignment = 'l'
  
  " Handle reset as third or even first/second argument
  if a:0 >= 1
    if a:1 =~? '^reset$'
      let reset = 1
    else
      let columns = a:1
      
      if a:0 >= 2
        if a:2 =~? '^reset$'
          let reset = 1
        else
          let alignment = a:2
          
          if a:0 >= 3 && a:3 =~? '^reset$'
            let reset = 1
          endif
        endif
      endif
    endif
  endif

  " Validate alignment method (only if not resetting)
  if !reset && index(['l', 'r', 'c'], alignment) == -1
    echo "Error: Invalid alignment method. Use 'l' (left), 'r' (right), or 'c' (center)"
    return
  endif

  " Validate column range format
  if columns !~ '^\(\d\+[-,]\?\)\+$'
    echo "Error: Invalid column format. Use numbers with commas (1,3) or ranges (1-3)"
    return
  endif

  " Get selected lines
  let lines = getline(a:firstline, a:lastline)
  
  " Check for empty selection
  if empty(lines)
    echo "Error: No lines selected"
    return
  endif

  " Check if all lines are empty
  let all_empty = 1
  for line in lines
    if line !~ '^\s*$'
      let all_empty = 0
      break
    endif
  endfor
  if all_empty
    echo "Error: Selected lines are all empty"
    return
  endif

  let max_col = 0
  let split_lines = []
  let indents = []  " Store original indentation for each line
  
  " Split each line and determine maximum column count
  for line in lines
    " Skip empty lines but keep them in the list
    if line =~ '^\s*$'
      call add(split_lines, [])
      call add(indents, line)  " Preserve empty line as is
      continue
    endif
    
    " Extract leading indentation (preserve original whitespace)
    let indent = matchstr(line, '^\s*')
    call add(indents, indent)
    
    " Get content without indentation
    let content = substitute(line, '^\s*', '', '')
    
    " Use one or more spaces as delimiter for content
    let parts = split(content, '\s\+')
    call add(split_lines, parts)
    if len(parts) > max_col
      let max_col = len(parts)
    endif
  endfor
  
  " Check if there are enough columns to align
  if max_col == 0
    echo "Error: No columns found in selected lines"
    return
  endif

  " Parse columns to align/reset
  let cols_to_process = []
  let col_specs = split(columns, ',')
  for spec in col_specs
    " Validate individual column spec
    if spec =~ '^-\|-$' || spec =~ '--' || spec =~ ',-\|-,\|,,\|-\d\+-'
      echo "Error: Invalid column specification: " . spec
      return
    endif
    
    if stridx(spec, '-') != -1
      let range_parts = split(spec, '-')
      if len(range_parts) != 2
        echo "Error: Invalid range format: " . spec
        return
      endif
      
      let start = str2nr(range_parts[0])
      let end = str2nr(range_parts[1])
      
      " Validate range logic
      if start <= 0 || end <= 0 || start > end
        echo "Error: Invalid column range: " . spec . " (must be start <= end and > 0)"
        return
      endif
      
      for col in range(start, end)
        call add(cols_to_process, col - 1) " Convert to 0-based index
      endfor
    else
      let col = str2nr(spec)
      if col <= 0
        echo "Error: Column number must be greater than 0: " . spec
        return
      endif
      call add(cols_to_process, col - 1) " Convert to 0-based index
    endif
  endfor
  
  " Remove duplicate columns and sort
  let cols_to_process = sort(uniq(cols_to_process))
  
  " Check if any columns were parsed
  if empty(cols_to_process)
    echo "Error: No valid columns specified"
    return
  endif
  
  " Check if column indices are valid
  for col in cols_to_process
    if col < 0 || col >= max_col
      echo "Error: Column " . (col + 1) . " is out of range (max column: " . max_col . ")"
      return
    endif
  endfor
  
  " Process lines - either reset or align
  let new_lines = []
  let line_idx = 0  " Track index for indents array
  if reset
    " Reset mode - remove extra spaces from specified columns
    for parts in split_lines
      let indent = indents[line_idx]
      if empty(parts)
        call add(new_lines, indent)  " Preserve original indent for empty lines
      else
        " For reset, use original content without added padding
        call add(new_lines, indent . join(parts, ' '))
      endif
      let line_idx += 1
    endfor
  else
    " Alignment mode - calculate widths and align
    let max_widths = {}
    for col in cols_to_process
      let max_width = 0
      for parts in split_lines
        if !empty(parts) && col < len(parts) && len(parts[col]) > max_width
          let max_width = len(parts[col])
        endif
      endfor
      let max_widths[col] = max_width < 0 ? 0 : max_width
    endfor
    
    " Rebuild lines with alignment
    for parts in split_lines
      let indent = indents[line_idx]
      if empty(parts)
        call add(new_lines, indent)  " Preserve original indent for empty lines
        let line_idx += 1
        continue
      endif
      
      let new_parts = copy(parts)
      for col in cols_to_process
        if col >= len(new_parts)
          continue
        endif
        
        let current = new_parts[col]
        let width = max_widths[col]
        let padding = width - len(current)
        
        if alignment == 'l'
          let new_parts[col] = current . repeat(' ', padding)
        elseif alignment == 'r'
          let new_parts[col] = repeat(' ', padding) . current
        elseif alignment == 'c'
          let left = padding / 2
          let right = padding - left
          let new_parts[col] = repeat(' ', left) . current . repeat(' ', right)
        endif
      endfor
      call add(new_lines, indent . join(new_parts, ' '))
      let line_idx += 1
    endfor
  endif
  
  " Write processed lines back to buffer
  call setline(a:firstline, new_lines)
endfunction

" Create command with optional parameters (0-3 arguments)
command! -range -nargs=* AlignColumns <line1>,<line2>call AlignSelectedColumns(<f-args>)

" Visual mode mapping, trigger with <leader>al
vnoremap <leader>ta :AlignColumns<space><CR>


" ---------------------------
" In visual block mode, press <Leader>i to implement number increment (default start value 1, step 1)
vmap <Leader>i :call VisualBlockIncrement(1, 1)<CR>
" In visual block mode, press <Leader>I to implement formatted number increment (e.g., 001, 002...)
vmap <Leader>I :call VisualBlockIncrementWithFormat(1, 1, 3)<CR>
" Core function: Implement number increment
function! VisualBlockIncrement(start, step) range
    let l:lines = getline(a:firstline, a:lastline)
    let l:new_lines = []
    for i in range(len(l:lines))
        let l:num = a:start + i * a:step
        call add(l:new_lines, substitute(l:lines[i], '\d\+', l:num, ''))
    endfor
    call setline(a:firstline, l:new_lines)
endfunction
" Extended function: Formatted number increment (e.g., with leading zeros)
function! VisualBlockIncrementWithFormat(start, step, digits) range
    let l:lines = getline(a:firstline, a:lastline)
    let l:new_lines = []
    for i in range(len(l:lines))
        let l:num = a:start + i * a:step
        let l:formatted_num = printf("%0".a:digits."d", l:num)
        call add(l:new_lines, substitute(l:lines[i], '\d\+', l:formatted_num, ''))
    endfor
    call setline(a:firstline, l:new_lines)
endfunction

" ---------------------------
" Process current buffer: remove duplicates by specified columns, keep larger/smaller values, then sort
" Parameters (all column numbers are 1-based as input):
" [1] Retention rule ('keep_larger' or 'keep_smaller')
" [2] keep_only_specified_columns (optional: 0=keep all columns, 1=keep only 2 columns, default=0)
" [3] Name column number (positive integer, 1-based) - default 1
" [4] Value column number (positive integer, 1-based) - default 2
" Compatible with Vim 7.4
function! SortUniqueByColumn(...) abort
  let arg_count = a:0
  if arg_count < 1
    echoerr "Error: Missing retention rule parameter"
    return 0
  endif

  " Extract parameters with defaults (preserving 1-based input)
  let keep_option = a:1
  let keep_only_cols = (arg_count >= 2) ? a:2 : 0
  let name_col_1based = (arg_count >= 3) ? a:3 : 1  " User input: 1-based name column
  let value_col_1based = (arg_count >= 4) ? a:4 : 2  " User input: 1-based value column

  " Validate retention rule
  if keep_option !=# 'keep_larger' && keep_option !=# 'keep_smaller'
    echoerr "Error: First argument must be 'keep_larger' or 'keep_smaller'"
    return 0
  endif

  " Validate column retention flag
  if keep_only_cols !~# '^[01]$'
    echoerr "Error: Second argument must be 0 (keep all columns) or 1 (keep only 2 columns)"
    return 0
  endif
  let keep_only_cols = str2nr(keep_only_cols)

  " Validate column numbers are positive integers (1-based)
  if name_col_1based !~# '^\d\+$' || value_col_1based !~# '^\d\+$'
    echoerr "Error: Column numbers must be positive integers (1-based)"
    return 0
  endif

  " Convert to numbers and validate range (still 1-based)
  let name_col_1based = str2nr(name_col_1based)
  let value_col_1based = str2nr(value_col_1based)
  
  if name_col_1based < 1 || value_col_1based < 1
    echoerr "Error: Column numbers must be greater than 0 (1-based)"
    return 0
  endif
  
  if name_col_1based == value_col_1based
    echoerr "Error: Name column and value column cannot be the same"
    return 0
  endif

  " Critical conversion: 1-based input to 0-based index for internal operations
  let name_col_idx = name_col_1based - 1
  let value_col_idx = value_col_1based - 1

  " Check for empty buffer
  if line('$') == 0
    echoerr "Error: Buffer is empty"
    return 0
  endif

  let s:data = {}  " Stores {name: {value: number, original_line: string, columns: list}}
  let errors = []  " Tracks processing issues

  " Process each line in buffer
  for lnum in range(1, line('$'))
    let original_line = getline(lnum)
    let trimmed = substitute(substitute(original_line, '^\s*', '', ''), '\s*$', '', '')
    
    " Skip empty lines
    if trimmed ==# ''
      call add(errors, "Warning: Empty line at line " . lnum)
      continue
    endif

    " Split line into columns (handles multiple spaces)
    let columns = split(trimmed, '\s\+')
    let col_count = len(columns)

    " Validate sufficient columns (uses 1-based for user feedback)
    if col_count < name_col_1based || col_count < value_col_1based
      call add(errors, "Error: Line " . lnum . " has only " . col_count . " columns. Needs at least " 
        \ . max([name_col_1based, value_col_1based]) . " columns (name column: " 
        \ . name_col_1based . ", value column: " . value_col_1based . ")")
      continue
    endif

    " Extract values using 0-based indices for internal processing
    let name = columns[name_col_idx]
    let value_str = columns[value_col_idx]

    " Validate numeric format in value column
    if value_str !~# '^[+-]\?\d\+\(\.\d\+\)\?$'
      call add(errors, "Error: Invalid number format in value column (line " . lnum 
        \ . ", column " . value_col_1based . "): " . value_str)
      continue
    endif
    let value = str2float(value_str)

    " Update data with best value based on retention rule
    if !has_key(s:data, name) || 
          \ (keep_option ==# 'keep_larger' && value > s:data[name].value) ||
          \ (keep_option ==# 'keep_smaller' && value < s:data[name].value)
      let s:data[name] = { 
        \ 'value': value, 
        \ 'original_line': original_line, 
        \ 'columns': columns 
        \ }
    endif
  endfor

  " Handle collected errors
  if !empty(errors)
    echo "Processing issues:"
    for err in errors
      echo "  " . err
    endfor
    let user_choice = input("Continue with valid data? (y/n): ")
    if user_choice !=# 'y' && user_choice !=# 'Y'
      echo "Operation cancelled"
      return 0
    endif
  endif

  " Check for valid data
  if empty(s:data)
    echoerr "Error: No valid data to process"
    return 0
  endif

  " Sorting function (Vim 7.4 compatible)
  function! CompareValues(a, b)
    let diff_val = s:data[a:a].value - s:data[a:b].value
    if diff_val > 0
      return 1
    elseif diff_val < 0
      return -1
    else
      return 0
    endif
  endfunction

  let sorted_names = sort(keys(s:data), 'CompareValues')

  " Generate output content
  let new_content = []
  for name in sorted_names
    let item = s:data[name]
    if keep_only_cols == 1
      " Keep only specified columns (using 0-based indices)
      call add(new_content, item.columns[name_col_idx] . ' ' . string(item.value))
    else
      " Preserve original format with updated value
      let old_value = escape(item.columns[value_col_idx], '\.[]*')
      let new_line = substitute(item.original_line, '\V' . old_value, string(item.value), '')
      call add(new_content, new_line)
    endif
  endfor

  " Update buffer with results
  silent %d _
  call setline(1, new_content)

  " Display operation summary
  echo "Completed: " . len(s:data) . " unique entries"
  echo "Retention rule: " . (keep_option ==# 'keep_larger' ? 'keep larger values' : 'keep smaller values')
  echo "Columns used: name=" . name_col_1based . ", value=" . value_col_1based
  echo "Output format: " . (keep_only_cols ? 'Only specified columns' : 'All columns (original formatting)')
  
  " Clean up script-scoped variable
  unlet s:data
  return 1
endfunction

" Command definitions
" Usage examples:
" :SortKeepLarger               - Defaults: keep larger, all columns, name=1, value=2
" :SortKeepLarger (1)             - Keep larger, only 2 columns, name=1, value=2
" :SortKeepLarger (0) 3 5         - Keep larger, all columns, name=3, value=5
" :SortKeepSmaller [0/1] [name_col] [value_col] - Same logic for smaller values
command! -nargs=* SortKeepLarger call SortUniqueByColumn('keep_larger', 0, <f-args>)
command! -nargs=* SortKeepSmaller call SortUniqueByColumn('keep_smaller', 0, <f-args>)

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
" replace all same name to new name, It can automatically identify the boundaries of variables. case-sensitive
function! s:SmartReplace()
  let old_name = expand("<cword>")
  let new_name = input("replace to (case-sensitive): ", old_name)
  
  " 显式使用大小写敏感的字符串比较
  if new_name !=# '' && new_name !=# old_name
    " Case-sensitive replacement with proper variable boundary checks
    "
    " To avoid accidentally replacing keywords that appear in attributes (where they shouldn't be modified), 
		" you can restrict matches to instances where the keyword is preceded by a space or the `$` symbol. 
    " This ensures that only variables in valid contexts (like code, not attribute names) are replaced.
    " songNOTE: I have only tested it with languages like TCL and Perl so far. There might be other 
		" 			variable prefixes in other languages, but it won't be too late to add support for them when we encounter such cases.
    execute '%s/\(^\|[ $@%&\]})[{(]\)\zs\<'. old_name .'\>/' . new_name . '/g'
    echohl WarningMsg | echo "Replaced all instances of '" . old_name . "' with '" . new_name . "' (case-sensitive)" | echohl None
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
let g:my_custom_settings = 0
if g:my_custom_settings == 1 " if you have no auto-pair vimplug, you can use it
  autocmd FileType * exec AutoComplete()
  func! AutoComplete()
      "相关映射
      :inoremap ( ()<Left>
      :inoremap ) <c-r>=ClosePair(')')<CR>
      :inoremap { {}<Left>
      :inoremap } <c-r>=ClosePair('}')<CR>
      :inoremap [ []<Left>
      :inoremap ] <c-r>=ClosePair(']')<CR>
      :inoremap < <><Left>
      :inoremap > <c-r>=ClosePair('>')<CR>
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
      elseif getline('.')[col('.') - 2] == '"'
        return '"'
      else
        return "\"\"\<Left>"
      endif
  endfunc
  "自动补全单引号
  func! SQuote()
      if getline('.')[col('.') - 1] == "'"
          return "\<Right>"
      elseif getline('.')[col('.') - 2] == "'"
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
endif
"设置跳出自动补全的括号
func! SkipPair()
    if getline('.')[col('.') - 1] == ')' || getline('.')[col('.') - 1] == ']' || getline('.')[col('.') - 1] == '"' || getline('.')[col('.') - 1] == "'" || getline('.')[col('.') - 1] == '}'
        return "\<ESC>la"
    else
        return "\t"
    endif
endfunc
inoremap <TAB> <c-r>=SkipPair()<CR>
" 将tab键绑定为跳出括号
" end of completion for punction
" ---------------------------

""" SIMPLE COMMAND OR AUTO COMMAND (AUTOCMD) ------------------------------------
" show the table of contents of vimrc
command! -nargs=0 TableOfVimrc :execute 'normal! :v/^""" [A-Z]\+/d<CR>'
" Automatically load custom dictionary for automatic completion function
"		you can get completion using ctrl x + ctrl k
autocmd FileType tcl set dictionary=~/.vim/dict/invs_commands.dict,~/.vim/dict/invs_options_of_command.dict,~/.vim/dict/pt_command_list.dict,~/.vim/dict/invs_dbxxx_commands.dict,~/.vim/dict/PT_variables_and_attributes_2023_12.dict,~/.vim/dict/invs_commands_common_ui_22.12.dict,~/.vim/dict/invs_options_of_command_common_ui_22.12.dict,~/.vim/dict/invs_database_object_common_ui_22.11_simpleExtract.dict

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
" vnoremap setting : 对齐 Tcl 变量的值（第三个参数），左侧不留空格
Jetpack 'morhetz/gruvbox'
Jetpack 'luochen1990/rainbow'
Jetpack 'andymass/vim-matchup'
Jetpack 'jiangmiao/auto-pairs'
Jetpack 'preservim/nerdtree'
Jetpack 'ryanoasis/vim-devicons'
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
"" for jiangmiao/auto-pairs
let g:AutoPairsFlyMode = 0
let g:AutoPairsShortcutBackInsert = '<M-b>'

"" for luochen1990/rainbow
let g:rainbow_active = 1
let g:rainbow_conf = {
\    'guifgs': ['#FF7575', '#FFD166', '#06D6A0', '#118AB2', '#9381FF', '#FF9B85', '#B8C5D6', '#E9D985'],
\    'ctermfgs': ['203', '220', '48', '33', '105', '216', '152', '222'],
\    'guis': [''],
\    'cterms': [''],
\    'operators': '_,_',
\    'parentheses': ['start=/(/ end=/)/ fold', 'start=/\[/ end=/\]/ fold', 'start=/{/ end=/}/ fold'],
\    'separately': {
\        '*': {},
\        'tcl': {
\            'parentheses': ['start=/(/ end=/)/ fold', 'start=/\[/ end=/\]/ fold', 'start=/{/ end=/}/ fold'],
\            'guifgs': ['#FF7575', '#FFD166', '#06D6A0', '#118AB2', '#9381FF', '#FF9B85', '#B8C5D6', '#E9D985']
\        }
\    }
\}
" GUI 颜色 (guifgs)：
" #FF7575 (柔和的珊瑚红)
" #FFD166 (温暖的黄色)
" #06D6A0 (清新的薄荷绿)
" #118AB2 (明亮的靛蓝色)
" #9381FF (淡紫色)
" #FF9B85 (浅粉色)
" #B8C5D6 (淡蓝灰色)
" #E9D985 (米黄色)
" 终端颜色 (ctermfgs)：
" 使用了 ANSI 256 色代码，确保在支持 256 色的终端中也能呈现良好的对比度
" 这些颜色在深灰色背景上会更加突出，同时保持了莫兰迪色系的柔和特性，减轻长时间编程的视觉疲劳。
" 括号匹配与行号高亮配置
" ~/.vimrc 配置
"" ---------------------------------------------------------
" fzf.vim config
" 初始化 fzf.vim 配置字典
let g:fzf_vim = {}
" 配置选项
" [Buffers] 若可能，跳转到现有的窗口
let g:fzf_vim.buffers_jump = 1
" [Ag|Rg|RG] 在窄屏幕上，将路径显示在单独的一行
let g:fzf_vim.grep_multi_line = 1
" [[B]Commits] 自定义 'git log' 使用的选项
let g:fzf_vim.commits_log_options = '--graph --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr"'
" [Tags] 生成标签文件的命令
let g:fzf_vim.tags_command = 'ctags -R'
" [Commands] --expect 表达式，用于直接执行命令
let g:fzf_vim.commands_expect = 'alt-enter,ctrl-x'
" 命令级别的 fzf 选项
" 配置 Buffers 命令的外观
let g:fzf_vim.buffers_options = ['--style', 'full', '--border-label', ' Open Buffers ']
" 预览窗口配置
" 预览窗口在右侧，占50%宽度，使用 ctrl-/ 切换显示/隐藏
let g:fzf_vim.preview_window = ['right,50%', 'ctrl-/']
" 列表类型处理多选配置
" 默认使用快速修复列表
let g:fzf_vim.listproc = { list -> fzf#vim#listproc#quickfix(list) }
" 为 Ag 命令使用快速修复列表
let g:fzf_vim.listproc_ag = { list -> fzf#vim#listproc#quickfix(list) }
" 为 Rg 命令使用位置列表
let g:fzf_vim.listproc_rg = { list -> fzf#vim#listproc#location(list) }
" 快捷键设置 - 基础操作
" 搜索文件 (使用 $FZF_DEFAULT_COMMAND)
nnoremap <leader>ff <cmd>Files<CR>
" 搜索缓冲区
nnoremap <leader>fb <cmd>Buffers<CR>
" 搜索文件历史
nnoremap <leader>fh <cmd>History<CR>
" 搜索标签
nnoremap <leader>ft <cmd>Tags<CR>
" 搜索标记
nnoremap <leader>fm <cmd>Marks<CR>
" 搜索颜色方案
nnoremap <leader>fc <cmd>Colors<CR>
" 搜索窗口
nnoremap <leader>fw <cmd>Windows<CR>
" 快捷键设置 - Git 集成
" 搜索 Git 文件 (git ls-files)
nnoremap <leader>gf <cmd>GFiles<CR>
" 搜索 Git 状态文件
nnoremap <leader>gs <cmd>GFiles?<CR>
" 搜索 Git 提交
nnoremap <leader>gc <cmd>Commits<CR>
" 搜索当前文件的 Git 提交
nnoremap <leader>gb <cmd>BCommits<CR>
" 使用 git grep 搜索
nnoremap <leader>gg <cmd>GGrep<CR>
" 快捷键设置 - 文本搜索
" 使用 ripgrep 搜索
nnoremap <leader>rg <cmd>Rg<CR>
" 搜索所有缓冲区中的行
nnoremap <leader>lg <cmd>Lines<CR>
" 搜索当前缓冲区中的行
nnoremap <leader>bl <cmd>BLines<CR>
" 快捷键设置 - 命令与帮助
" 搜索命令
nnoremap <leader>cm <cmd>Commands<CR>
" 搜索帮助标签
nnoremap <leader>hm <cmd>Helptags<CR>
" 搜索映射
nnoremap <leader>mf <cmd>Maps<CR>
" 映射选择映射
nmap <leader><tab> <plug>(fzf-maps-n)
xmap <leader><tab> <plug>(fzf-maps-x)
omap <leader><tab> <plug>(fzf-maps-o)
" 插入模式补全
" 使用 fzf 进行单词补全
imap <c-x><c-k> <plug>(fzf-complete-word)
" 使用 fzf 进行路径补全
imap <c-x><c-f> <plug>(fzf-complete-path)
" 使用 fzf 进行行补全
imap <c-x><c-l> <plug>(fzf-complete-line)
" 自定义命令示例：ProjectFiles 只搜索 ~/projects 目录
command! -bang ProjectFiles call fzf#vim#files('~/projects', <bang>0)
" 搜索项目文件
nnoremap <leader>fp <cmd>ProjectFiles<CR>
" 自定义 Git grep 命令
command! -bang -nargs=* GGrep
  \ call fzf#vim#grep(
  \   'git grep --line-number -- '.fzf#shellescape(<q-args>),
  \   fzf#vim#with_preview({'dir': systemlist('git rev-parse --show-toplevel')[0]}), <bang>0)
" 自定义状态栏
function! s:fzf_statusline()
  " 自定义状态栏样式
  highlight fzf1 ctermfg=161 ctermbg=251
  highlight fzf2 ctermfg=23 ctermbg=251
  highlight fzf3 ctermfg=237 ctermbg=251
  setlocal statusline=%#fzf1#\ >\ %#fzf2#fz%#fzf3#f
endfunction
autocmd! User FzfStatusLine call <SID>fzf_statusline()

"" ---------------------------------------------------------
" NerdTree config

" 使用 F2 键快速切换 NERDTree
map <F2> :NERDTreeToggle<CR>
" 打开 Vim 时自动打开 NERDTree（无文件参数时）
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists('s:std_in') | NERDTree | endif
" 关闭最后一个 buffer 时自动退出 Vim
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
" 设置 NERDTree 窗口宽度
let NERDTreeWinSize = 50
" 显示行号
let NERDTreeShowLineNumbers = 1
" 隐藏 .git 目录
let NERDTreeIgnore = ['\.git', '\.hg', '\.svn']
" 显示文件图标（需要安装字体支持）
let g:NERDTreeDirArrowExpandable = '▸'
let g:NERDTreeDirArrowCollapsible = '▾'
" ----------------------------
" NERDTree 高级设置
" 启用语法高亮
let NERDTreeHighlightCursorline = 1
" 显示隐藏文件（默认不显示）
let NERDTreeShowHidden = 1
" 自动切换到当前文件所在目录
let NERDTreeAutoCenter = 1
" 显示文件大小
let NERDTreeShowFileInfo = 1
" 启用书签功能
let NERDTreeShowBookmarks = 1
" 自定义文件图标（需要安装 Powerline 字体）
let g:NERDTreeDirArrowExpandable = ''
let g:NERDTreeDirArrowCollapsible = ''
" 自定义快捷键
" 使用 <leader>n 切换 NERDTree
map <leader>n :NERDTreeToggle<CR>
" 使用 <leader>f 定位当前文件
map <leader>f :NERDTreeFind<CR>
" 关闭 NERDTree 时自动关闭对应标签页
function! CloseBufAndNerdTree()
  if bufname('%') =~ 'NERD_tree'
    wincmd p
    bd#
  else
    bd
  endif
endfunction
nnoremap <leader>q :call CloseBufAndNerdTree()<CR>
let g:NERDTreeShowIcons = 1
let g:NERDTreeGitStatusUseNerdFonts = 1
" 在 .vimrc 中添加
let g:NERDTreeGitStatus = 1

" 自定义 Git 状态符号
let g:NERDTreeGitStatusIndicators = {
    \ 'Modified'  : '✹',
    \ 'Staged'    : '✚',
    \ 'Untracked' : '✭',
    \ 'Renamed'   : '➜',
    \ 'Unmerged'  : '═',
    \ 'Deleted'   : '✖',
    \ 'Ignored'   : '☒'
    \ }
" 在 .vimrc 中添加
highlight NERDTreeDir guifg=#61afef ctermfg=blue
highlight NERDTreeExecFile guifg=#98c379 ctermfg=green
highlight NERDTreeSpecialFile guifg=#c678dd ctermfg=magenta
highlight NERDTreeLink guifg=#56b6c2 ctermfg=cyan
