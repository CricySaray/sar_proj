-- =============================================================================
--  functions.lua
--  自定义函数全部以 vimscript 形式保留（无需重写为 lua）。
--  命令、autocmd 在被调用前必须先 require 这个文件。
-- =============================================================================

-- -----------------------------------------------------------------------------
--  InsertProcessHead
--  把 ~/project/scr_sar/ref_content/head_of_proc.txt 的前 12 行插入到当前行，
--  并把其中的 DATE 替换为当前日期。
-- -----------------------------------------------------------------------------
vim.cmd([[
function! InsertProcessHead()
  " 读取文件的前12行到当前位置
  execute 'r! sed -n ''1,12p'' ~/project/scr_sar/ref_content/head_of_proc.txt'
  " 获取当前行号（即新插入内容的第一行）
  let end_line = line('.')
  " 计算结束行号（当前行 + 11）
  let start_line = end_line - 11
  " 构建并执行替换命令（将DATE替换为当前日期时间）
  let date_str = strftime('%Y/%m/%d %H:%M:%S %A')
  execute start_line . ',' . end_line . 's/DATE/' . escape(date_str, '/') . '/g'
endfunction
]])

-- -----------------------------------------------------------------------------
--  AlignSelectedColumns
--  对选中的行按指定列进行对齐（左/右/居中），并保留原缩进。
-- -----------------------------------------------------------------------------
vim.cmd([[
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
]])

-- -----------------------------------------------------------------------------
--  VisualBlockIncrement / VisualBlockIncrementWithFormat
--  块选择模式下按行号自增数字。
-- -----------------------------------------------------------------------------
vim.cmd([[
function! VisualBlockIncrement(start, step) range
    let l:lines = getline(a:firstline, a:lastline)
    let l:new_lines = []
    for i in range(len(l:lines))
        let l:num = a:start + i * a:step
        call add(l:new_lines, substitute(l:lines[i], '\d\+', l:num, ''))
    endfor
    call setline(a:firstline, l:new_lines)
endfunction

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
]])

-- -----------------------------------------------------------------------------
--  SortUniqueByColumn
--  按指定列去重并排序；可选择保留较大或较小的值。
-- -----------------------------------------------------------------------------
vim.cmd([[
function! SortUniqueByColumn(...) abort
  let arg_count = a:0
  if arg_count < 1
    echoerr "Error: Missing retention rule parameter"
    return 0
  endif

  let keep_option = a:1
  let keep_only_cols = (arg_count >= 2) ? a:2 : 0
  let name_col_1based = (arg_count >= 3) ? a:3 : 1
  let value_col_1based = (arg_count >= 4) ? a:4 : 2

  if keep_option !=# 'keep_larger' && keep_option !=# 'keep_smaller'
    echoerr "Error: First argument must be 'keep_larger' or 'keep_smaller'"
    return 0
  endif

  if keep_only_cols !~# '^[01]$'
    echoerr "Error: Second argument must be 0 (keep all columns) or 1 (keep only 2 columns)"
    return 0
  endif
  let keep_only_cols = str2nr(keep_only_cols)

  if name_col_1based !~# '^\d\+$' || value_col_1based !~# '^\d\+$'
    echoerr "Error: Column numbers must be positive integers (1-based)"
    return 0
  endif

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

  let name_col_idx = name_col_1based - 1
  let value_col_idx = value_col_1based - 1

  if line('$') == 0
    echoerr "Error: Buffer is empty"
    return 0
  endif

  let s:data = {}
  let errors = []

  for lnum in range(1, line('$'))
    let original_line = getline(lnum)
    let trimmed = substitute(substitute(original_line, '^\s*', '', ''), '\s*$', '', '')

    if trimmed ==# ''
      call add(errors, "Warning: Empty line at line " . lnum)
      continue
    endif

    let columns = split(trimmed, '\s\+')
    let col_count = len(columns)

    if col_count < name_col_1based || col_count < value_col_1based
      call add(errors, "Error: Line " . lnum . " has only " . col_count . " columns. Needs at least "
        \ . max([name_col_1based, value_col_1based]) . " columns (name column: "
        \ . name_col_1based . ", value column: " . value_col_1based . ")")
      continue
    endif

    let name = columns[name_col_idx]
    let value_str = columns[value_col_idx]

    if value_str !~# '^[+-]\?\d\+\(\.\d\+\)\?$'
      call add(errors, "Error: Invalid number format in value column (line " . lnum
        \ . ", column " . value_col_1based . "): " . value_str)
      continue
    endif
    let value = str2float(value_str)

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

  if empty(s:data)
    echoerr "Error: No valid data to process"
    return 0
  endif

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

  let new_content = []
  for name in sorted_names
    let item = s:data[name]
    if keep_only_cols == 1
      call add(new_content, item.columns[name_col_idx] . ' ' . string(item.value))
    else
      let old_value = escape(item.columns[value_col_idx], '\.[]*')
      let new_line = substitute(item.original_line, '\V' . old_value, string(item.value), '')
      call add(new_content, new_line)
    endif
  endfor

  silent %d _
  call setline(1, new_content)

  echo "Completed: " . len(s:data) . " unique entries"
  echo "Retention rule: " . (keep_option ==# 'keep_larger' ? 'keep larger values' : 'keep smaller values')
  echo "Columns used: name=" . name_col_1based . ", value=" . value_col_1based
  echo "Output format: " . (keep_only_cols ? 'Only specified columns' : 'All columns (original formatting)')

  unlet s:data
  return 1
endfunction
]])

-- -----------------------------------------------------------------------------
--  TogglePaste
--  切换粘贴模式（&paste）并显示当前状态。
-- -----------------------------------------------------------------------------
vim.cmd([[
function! TogglePaste()
    set invpaste
    if &paste
        echo "- paste mode on -"
    else
        echo "- paste mode off -"
    endif
endfunction
]])

-- -----------------------------------------------------------------------------
--  SmartReplace
--  对光标下的单词进行大小写敏感的批量替换，限定在变量边界。
-- -----------------------------------------------------------------------------
vim.cmd([[
function! SmartReplace()
  let old_name = expand("<cword>")
  let new_name = input("replace to (case-sensitive): ", old_name)

  if new_name !=# '' && new_name !=# old_name
    execute '%s/\(^\|[ $@%&\]})[{(]\)\zs\<'. old_name .'\>/' . new_name . '/g'
    echohl WarningMsg | echo "Replaced all instances of '" . old_name . "' with '" . new_name . "' (case-sensitive)" | echohl None
  endif
endfunction
]])

-- -----------------------------------------------------------------------------
--  TclGotoTag
--  Tcl 文件下 <C-]> 跳转到 vars()/FP() 等复杂变量名对应的 ctag。
-- -----------------------------------------------------------------------------
vim.cmd([[
function! TclGotoTag()
  execute "set tags=./tags;/"
  execute "set iskeyword+=$,(,),,"
  let l:word = expand("<cword>")
  let l:tag = substitute(l:word, '.*\$\(\(vars\|FP\)(.*)\)', '\1', '')
  execute "set iskeyword-=$,(,),,"
  execute "tag " . l:tag
endfunction
]])

-- -----------------------------------------------------------------------------
--  CloseBufAndNerdTree
--  关闭 NERDTree 窗口或当前 buffer。nvim-tree 适配版见 plugins/ui.lua。
-- -----------------------------------------------------------------------------
vim.cmd([[
function! CloseBufAndNerdTree()
  if bufname('%') =~ 'NERD_tree'
    wincmd p
    bd#
  else
    bd
  endif
endfunction
]])

-- -----------------------------------------------------------------------------
--  fzf_statusline
--  fzf 打开时的状态栏样式（保留供 fzf.vim 使用）。
-- -----------------------------------------------------------------------------
vim.cmd([[
function! s:fzf_statusline()
  highlight fzf1 ctermfg=161 ctermbg=251
  highlight fzf2 ctermfg=23  ctermbg=251
  highlight fzf3 ctermfg=237 ctermbg=251
  setlocal statusline=%#fzf1#\ >\ %#fzf2#fz%#fzf3#f
endfunction
]])

-- -----------------------------------------------------------------------------
--  SetupKeywordHighlights
--  根据 g:highlight_groups 动态设置 syntax match 高亮。
--  - g:highlight_groups 在 lua 中赋值（nvim 把 lua table 透明地桥接为 vim list/dict）
--  - 函数体仍保留为 vimscript，因为里面用了 syn match / execute 等
-- -----------------------------------------------------------------------------

-- 在 lua 中直接给 g:highlight_groups 赋值
-- 注意：lua 字符串中的 '\\' 实际就是反斜杠字符，vimscript 读取后会正确处理
vim.g.highlight_groups = {
  { "Exact", "Special",    { "pw", "re", "la", "lo", "al", "ol", "eo", "er", "ci", "every", "any", "lextract", "xor", "pe" } },
  { "Exact", "Cursor",     { "songNOTE" } },
  { "Exact", "GruvboxFg0", { "TODO", "FIXED", "NOTICE", "ADVANCE", "BUG", "partial", "IMPORTANT", "FASTER", "DEPRECATED", "RESERVED" } },
  { "Regex", "GruvboxFg0", { "U\\d\\{3}", "ID\\d\\{4,}", "AT\\d\\{3}" } },
}

vim.cmd([[
function! SetupKeywordHighlights()
  for group in g:highlight_groups
    let match_type = group[0]
    let highlight_group = group[1]
    let patterns = group[2]
    for pattern in patterns
      if match_type ==# 'Exact'
        execute 'syn match HighlightKeyword_' . highlight_group . ' /\V\<'. escape(pattern, '/\') .'\>/ containedin=.*'
      elseif match_type ==# 'Regex'
        execute 'syn match HighlightKeyword_' . highlight_group . ' /\<'. pattern .'\>/ containedin=.*'
      endif
    endfor
    execute 'hi def link HighlightKeyword_' . highlight_group . ' ' . highlight_group
  endfor
endfunction
]])

-- -----------------------------------------------------------------------------
--  ToggleWrap
--  切换 wrap 选项的命令实现（被 :ToggleWrap 使用）。
-- -----------------------------------------------------------------------------
vim.cmd([[
function! ToggleWrap()
  set wrap!
endfunction
]])

-- 让 fzf.vim 自动调用自定义状态栏
vim.cmd([[
autocmd! User FzfStatusLine call <SID>fzf_statusline()
]])
