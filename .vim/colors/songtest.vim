" 基础配置：支持明暗模式
let g:gruvbox_contrast_dark = 'medium'
let g:gruvbox_contrast_light = 'medium'

let s:bg_dark = {'soft': '#32302f', 'medium': '#282828', 'hard': '#1d2021'}
let s:bg_light = {'soft': '#f9f5d7', 'medium': '#f2e5bc', 'hard': '#ebdbb2'}
let s:fg_dark = '#ebdbb2'
let s:fg_light = '#504945'

" 颜色定义
let s:palette = {
\ 'dark0': '#282828', 'dark1': '#3c3836', 'dark2': '#504945',
\ 'light0': '#f2e5bc', 'light1': '#d5c4a1', 'light2': '#bdae93',
\ 'red': '#fb4934','green':'#b8bb26','yellow':'#fabd2f',
\ 'blue':'#83a598','purple':'#d3869b','aqua':'#8ec07c','orange':'#fe8019'
\}

" 自动切换明暗模式
if &background ==# 'light'
  let s:bg  = s:bg_light[g:gruvbox_contrast_light]
  let s:fg  = s:fg_light
  let s:bg0 = s:palette['light0']
  let s:bg1 = s:palette['light1']
  let s:bg2 = s:palette['light2']
else
  let s:bg  = s:bg_dark[g:gruvbox_contrast_dark]
  let s:fg  = s:fg_dark
  let s:bg0 = s:palette['dark0']
  let s:bg1 = s:palette['dark1']
  let s:bg2 = s:palette['dark2']
endif

" 重置颜色
hi clear
if exists('syntax_on')
  syntax reset
endif
let g:colors_name = 'gruvbox'

" ========== 下面全部修复了变量引用，不会再报错 ==========
execute 'hi Normal     guibg='.s:bg.' guifg='.s:fg
execute 'hi LineNr     guibg='.s:bg0.' guifg='.s:bg2
execute 'hi CursorLine guibg='.s:bg1
execute 'hi CursorColumn guibg='.s:bg1
execute 'hi Visual     guibg='.s:palette['yellow'].' guifg='.s:bg0
execute 'hi Search     guibg='.s:palette['yellow'].' guifg='.s:bg0
execute 'hi IncSearch  guibg='.s:palette['orange'].' guifg='.s:bg0
execute 'hi Error      guibg='.s:palette['red'].' guifg='.s:bg0
execute 'hi Comment    guifg='.s:bg2.' gui=italic'

execute 'hi String     guifg='.s:palette['green']
execute 'hi Number     guifg='.s:palette['purple']
execute 'hi Keyword    guifg='.s:palette['red']
execute 'hi Function   guifg='.s:palette['yellow']
execute 'hi Type       guifg='.s:palette['aqua']
execute 'hi Identifier guifg='.s:palette['blue']
execute 'hi Statement  guifg='.s:palette['red']
execute 'hi PreProc    guifg='.s:palette['orange']
execute 'hi Special    guifg='.s:palette['purple']

execute 'hi StatusLine  guibg='.s:bg1.' guifg='.s:fg
execute 'hi StatusLineNC guibg='.s:bg0.' guifg='.s:bg2
execute 'hi VertSplit   guibg='.s:bg0.' guifg='.s:bg1

execute 'hi Pmenu      guibg='.s:bg1.' guifg='.s:fg
execute 'hi PmenuSel   guibg='.s:palette['yellow'].' guifg='.s:bg0
execute 'hi PmenuSbar  guibg='.s:bg1
execute 'hi PmenuThumb guibg='.s:bg2
