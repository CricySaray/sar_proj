-- =============================================================================
--  options.lua
--  通用选项设置。
--  说明：
--  - nvim 默认已经开启 nocompatible / syntax / filetype detection / ruler /
--    incsearch / nobackup / t_Co=256 / shellcmdflag=-c 等，所以无需重复设置。
--  - 只保留与原 vimrc 行为一致但 nvim 默认不同的项。
-- =============================================================================

local opt = vim.opt

-- ---------- 搜索 ----------
opt.ignorecase = true   -- 忽略大小写
opt.smartcase = true    -- 包含大写字母时区分大小写
opt.incsearch = true    -- 增量搜索（nvim 默认也是 true，保留显式声明）
opt.hlsearch = true     -- 高亮搜索结果
opt.wrapscan = true     -- 搜索环绕到文件头/尾

-- ---------- 编辑 ----------
opt.showcmd = true      -- 状态栏显示未完成命令
opt.showmatch = true    -- 短暂跳转到匹配的括号
opt.matchtime = 2       -- 跳转到匹配括号的时间（0.5s 单位，nvim 中以 ms 计）
opt.smartindent = true  -- 智能缩进
opt.expandtab = true    -- tab 展开为空格
opt.shiftwidth = 2      -- 自动缩进宽度
opt.tabstop = 2         -- tab 显示宽度
opt.softtabstop = 2     -- 退格一次删 2 个空格
opt.backspace = { "indent", "eol", "start" } -- 退格可删缩进/换行/插入点之前的字符
opt.textwidth = 0       -- 不自动折行
opt.autowrite = true    -- 切换 buffer 时自动保存
opt.autoread = true     -- 文件被外部修改时自动重读
opt.updatetime = 500    -- CursorHold 触发检查的间隔（500ms）
opt.history = 10000      -- 命令历史保留条数

-- ---------- 折行 ----------
opt.wrap = true         -- 允许长行折行显示（与原 vim 一致；如需关闭用 <leader>w）
opt.linebreak = true    -- 按单词折行，不在单词中间断开
opt.breakindent = true  -- 折行保持缩进
opt.showbreak = "+++ "  -- 折行处的视觉前缀

-- ---------- 折叠 ----------
opt.foldenable = false  -- 默认不启用折叠（与原 vimrc 一致：nofoldenable）
opt.foldmethod = "syntax"
opt.foldcolumn = "0"    -- 折叠列宽
opt.foldlevel = 1       -- 默认展开 1 层

-- ---------- 外观 ----------
opt.number = true       -- 显示行号
opt.relativenumber = false -- 相对行号（方便 j/k 跳转）
opt.cursorline = true   -- 高亮当前行
opt.ruler = true        -- 右侧标尺（nvim 默认开启，保留）
opt.showmode = true     -- 模式显示
opt.list = false        -- 不显示 tab/行尾空格（与原 vimrc 中 set list=true 不一致；这里关闭以避免污染）
-- 如果你确实需要看到 tab/换行符，把上一行改成 opt.list = true
opt.signcolumn = "yes"  -- 给 gitsigns / nvim-tree 等插件留出 sign column
opt.cmdheight = 1       -- 命令行高度
opt.laststatus = 2      -- 总是显示状态栏
opt.scrolloff = 5       -- 光标上下保留 5 行
opt.sidescrolloff = 10  -- 光标左右保留 10 列
opt.sidescroll = 1      -- 横向滚动步长
opt.wildmenu = true     -- 命令行补全菜单
opt.wildmode = "list:longest"
opt.wildignorecase = true
opt.confirm = true      -- 未保存时操作给出确认对话框
opt.timeoutlen = 1000   -- 多键前缀等待时间（1s）

-- 忽略 wildmenu 列出的扩展名
opt.wildignore = {
  "*.docx", "*.jpg", "*.png", "*.gif", "*.pdf", "*.pyc",
  "*.exe", "*.flv", "*.img", "*.xlsx",
}

-- 搜索 path，包含递归子目录（用于 gf / :find 等）
opt.path:append({ "**" })

-- ---------- 配色 ----------
opt.background = "dark"
opt.termguicolors = true  -- 启用 24 位真彩色
-- colorscheme gruvbox 由 plugins/colorscheme.lua 设置（确保 lazy 加载完成）

-- ---------- 文件类型 ----------
-- nvim 默认开启 filetype detection + plugin；显式开启 indent on
vim.cmd("filetype plugin indent on")

-- ---------- t_Co / 终端编码 ----------
-- nvim 默认 t_Co=256，无需设置
opt.encoding = "utf-8"

-- ---------- 启动行为 ----------
-- 不自动 cd 到当前文件目录（与原 vimrc 注释中 set autochdir 被注释掉一致）
opt.autochdir = false

-- 禁用鼠标（"" 表示不使用鼠标，n/a/c/v/i 等模式都不响应鼠标事件）
opt.mouse = ""

-- ---------- 剪贴板（与系统剪贴板互通） ----------
-- 仅在 GUI / UI 已 attach 后才设置 clipboard，避免启动阶段报错
vim.api.nvim_create_autocmd("UIEnter", {
  callback = function()
    if not vim.tbl_isempty(vim.api.nvim_list_uis()) then
      -- 在支持 OSC 52 的终端中通常 unnamedplus 即可；不需要可注释掉
      -- opt.clipboard = "unnamedplus"
    end
  end,
})
