-- =============================================================================
--  commands.lua
--  自定义命令迁移。所有命令依赖的 vimscript 函数必须在 functions.lua 中
--  先被加载（init.lua 中已经保证了顺序：functions -> commands）。
-- =============================================================================

local cmd = vim.cmd

-- -----------------------------------------------------------------------------
--  :Rt
--  在当前行下方插入 proc 头模板。
-- -----------------------------------------------------------------------------
cmd([[command! Rt call InsertProcessHead()]])

-- -----------------------------------------------------------------------------
--  :TableOfVimrc
--  把当前 buffer 中以 """ [A-Z] 开头以外的所有行删除（用于查看 vimrc 大纲）。
-- -----------------------------------------------------------------------------
cmd([[command! -nargs=0 TableOfVimrc execute 'normal! :v/^""" [A-Z]\+/d<CR>']])

-- -----------------------------------------------------------------------------
--  :ToggleWrap
--  切换 wrap，可视模式下也可用。
-- -----------------------------------------------------------------------------
cmd([[command! ToggleWrap call ToggleWrap()]])

-- -----------------------------------------------------------------------------
--  :AlignColumns [range]
--  对选中范围按列对齐（参数透传给 AlignSelectedColumns）。
-- -----------------------------------------------------------------------------
cmd([[
command! -range -nargs=* AlignColumns <line1>,<line2>call AlignSelectedColumns(<f-args>)
]])

-- -----------------------------------------------------------------------------
--  :SortKeepLarger / :SortKeepSmaller
--  按列去重并保留较大/较小值。
-- -----------------------------------------------------------------------------
cmd([[command! -nargs=* SortKeepLarger call SortUniqueByColumn('keep_larger', 0, <f-args>)]])
cmd([[command! -nargs=* SortKeepSmaller call SortUniqueByColumn('keep_smaller', 0, <f-args>)]])

-- -----------------------------------------------------------------------------
--  :ToggleDiffSaved
--  与磁盘上的文件进行 diff 展示。
-- -----------------------------------------------------------------------------
cmd([[
command! ToggleDiffSaved vert new | set bt=nofile | r # | 0d_ | diffthis
      \ | wincmd p | diffthis
]])

-- -----------------------------------------------------------------------------
--  :ProjectFiles / :GGrep
--  fzf.vim 自定义命令，绑定到 <leader>fp / <leader>gg。
-- -----------------------------------------------------------------------------
cmd([[command! -bang ProjectFiles call fzf#vim#files('~/projects', <bang>0)]])
cmd([[
command! -bang -nargs=* GGrep
  \ call fzf#vim#grep(
  \   'git grep --line-number -- '.fzf#shellescape(<q-args>),
  \   fzf#vim#with_preview({'dir': systemlist('git rev-parse --show-toplevel')[0]}), <bang>0)
]])

-- -----------------------------------------------------------------------------
--  :GitBlameLine
--  用 git blame 查看当前行（保留原 init.lua 中的便捷命令）。
-- -----------------------------------------------------------------------------
vim.api.nvim_create_user_command("GitBlameLine", function()
  local line_number = vim.fn.line(".")
  local filename = vim.api.nvim_buf_get_name(0)
  local result = vim.system({ "git", "blame", "-L", line_number .. ",+1", filename }):wait()
  print(result.stdout)
end, { desc = "Print the git blame for the current line" })

-- -----------------------------------------------------------------------------
--  :EditVimrc / :SourceVimrc
--  方便地编辑 / 重新加载 nvim 配置。
-- -----------------------------------------------------------------------------
cmd([[command! EditVimrc edit $MYVIMRC]])
cmd([[command! SourceVimrc source $MYVIMRC]])
