# 我的 Neovim 配置总结与修改指南

> 目标读者：你自己（之前没用过 Lua，但已经写过一个可用的 nvim 配置）。
> 目的：以后修改 `~/.config/nvim` 时，把这份文档当"字典 + 路线图"查。
>
> **配置存放位置**：`~/.config/nvim/`
> **入口文件**：`~/.config/nvim/init.lua`
>
> 同目录下还有一份 `lua_guide_for_neovim.md`，是**通用的 Lua 语言教程**；
> 本文件专门讲**你这份配置本身的结构、思想和改法**。

---

## 目录

1. [配置文件结构总览](#一配置文件结构总览)
2. [核心配置思想（读懂这份配置前必须知道的事）](#二核心配置思想读懂这份配置前必须知道的事)
3. [Lua 最小语法速通（够改配置就行）](#三lua-最小语法速通够改配置就行)
4. [文件逐一拆解：每个文件做什么、放什么、怎么改](#四文件逐一拆解每个文件做什么放什么怎么改)
5. [常用修改模式速查表](#五常用修改模式速查表)
6. [插件（lazy.nvim）配置规范](#六插件lazy.nvim配置规范)
7. [vimscript 与 Lua 混用的注意事项](#七vimscript-与-lua-混用的注意事项)
8. [典型修改任务示例](#八典型修改任务示例)
9. [常见报错与排查](#九常见报错与排查)

---

## 一、配置文件结构总览

```
~/.config/nvim/
├── init.lua                      # 入口：引导 lazy 并 require 各个 config 模块
├── lazy-lock.json                # 插件版本锁定（一般不要手改）
└── lua/
    ├── config/                   # 配置主体（按职责拆成多个文件）
    │   ├── lazy.lua              #   引导 + 安装 lazy.nvim
    │   ├── options.lua           #   vim 全局选项（set xxx）
    │   ├── keymaps.lua           #   键位映射
    │   ├── abbreviations.lua     #   缩写（iabbrev / cabbrev）
    │   ├── autocmds.lua          #   自动命令（autocmd）
    │   ├── commands.lua          #   自定义 :Command
    │   ├── functions.lua         #   自定义函数（用 vimscript 写）
    │   ├── highlights.lua        #   高亮覆盖
    │   └── statusline.lua        #   状态栏格式
    └── plugins/                  # 插件声明（每个文件 = 一组相关插件）
        ├── colorscheme.lua       #   gruvbox 配色
        ├── editor.lua           #   围绕"编辑"的小插件
        ├── fzf.lua               #   fzf + fzf.vim
        └── ui.lua                #   nvim-tree、gitsigns、devicons
```

### 1.1 这个结构传递的信息

| 目录 / 文件 | 职责 | 修改频率 |
|-------------|------|---------|
| `init.lua` | 加载顺序入口 | 几乎不改（除非新增 config 文件） |
| `lua/config/options.lua` | 改 vim 行为（缩进、显示、搜索…） | 高 |
| `lua/config/keymaps.lua` | 加 / 改键位 | 高 |
| `lua/config/autocmds.lua` | 按事件自动做事 | 中 |
| `lua/config/commands.lua` | 注册 `:xxx` 命令 | 中 |
| `lua/config/functions.lua` | 写复杂函数（保留 vimscript） | 中 |
| `lua/config/abbreviations.lua` | 缩写 | 低 |
| `lua/config/highlights.lua` | 改颜色 | 低 |
| `lua/config/statusline.lua` | 改状态栏 | 低 |
| `lua/plugins/*.lua` | 加 / 删 / 改插件 | 中 |

### 1.2 加载顺序（关键！）

`init.lua` 按下面顺序逐个 `require`：

```
config.lazy       → 引导 lazy.nvim（必须最先）
config.options    → 设置选项
config.functions  → 用 vimscript 装载自定义函数
config.commands   → 注册 :Command（依赖上面 functions）
config.abbreviations
config.keymaps
config.autocmds
config.highlights
config.statusline
```

> **为什么是这个顺序？**
> - `functions` 必须在 `commands` 前面：很多 `:Command` 直接调用函数，函数没装载就会报 *undefined function*。
> - `lazy.lua` 内部会执行 `vim.g.mapleader = "\\"`，所以 `keymaps` 里 `<leader>` 才会被解析成反斜杠。
> - 修改时**保持这个顺序**就行，新加的 config 文件也按"被依赖的先 require"插进来。

---

## 二、核心配置思想（读懂这份配置前必须知道的事）

### 2.1 思想 1：用 `require` 拆文件，而不是写一个超大的 init.lua

`init.lua` 里只写 `require("config.options")`、`require("config.keymaps")`……
每个文件只负责一件事（选项、键位、缩写……）。
**好处**：改一处不会碰坏另一处，找东西快。

### 2.2 思想 2：配置里同时存在 Lua 和 vimscript，不要混用

| 场景 | 推荐用 | 原因 |
|------|--------|------|
| 改选项 / 设变量 | Lua（`vim.opt` / `vim.g`） | 更快、类型安全 |
| 写键位、缩写、自动命令 | Lua（`vim.keymap.set` / `vim.cmd("iabbrev ..")` / `vim.api.nvim_create_autocmd`） | 统一风格 |
| 复杂函数（带 if/for/正则） | **保留 vimscript**，包在 `vim.cmd([[ ... ]])` 里 | 不用重写老逻辑 |
| 注册 `:Command` | `vim.cmd([[command! ...]])` 或 `vim.api.nvim_create_user_command` | 见 [第 7 节](#七vimscript-与-lua-混用的注意事项) |

> 简单说：**新东西尽量用 Lua 写；老函数维持 vimscript**。
> 你的 `functions.lua` 里 6 个函数（`InsertProcessHead`、`AlignSelectedColumns`、`VisualBlockIncrement`、`SortUniqueByColumn`、`TogglePaste`、`SmartReplace`、`TclGotoTag` 等）都是 vimscript 形式——这是有意保留的，不要"重写一遍"。

### 2.3 思想 3：插件用 lazy.nvim 管理，写在 `lua/plugins/*.lua` 里

每个文件 `return { ... }` 是一组插件的清单；`config/lazy.lua` 里
`{ import = "plugins" }` 会自动加载 `lua/plugins/` 下**所有** `.lua` 文件。
新增插件：建新文件或加到现有文件里，**最后都 return 一个表格**。

### 2.4 思想 4：`mapleader` 是 `\`（反斜杠），不是空格

这是从你原来的 vimrc 继承的。
所以 `keymaps.lua` 里所有 `<leader>xx` 在你按下时，实际是 `\xx`。
改 leader 只能改 `config/lazy.lua` 里的 `vim.g.mapleader = "\\"` 一行。

### 2.5 思想 5：mapleader 必须在 lazy.setup 之前设置

`config/lazy.lua` 里这两行非常关键：

```lua
vim.g.mapleader = "\\"
vim.g.maplocalleader = "\\"
require("lazy").setup({ ... })   -- setup 在 leader 之后
```

因为 lazy 自己也会读 `<leader>`，**调换顺序会导致所有 lazy 自带键位失效**。

### 2.6 思想 6：高亮 / 配色 / 状态栏独立成文件，便于换主题

`colorscheme.lua` 里 `priority = 1000` 是为了让 gruvbox **在所有其他插件加载前**生效；
`highlights.lua` 里写的颜色（`#ffb86c` 等）都是基于 gruvbox 调的，**换主题要同步改**。

---

## 三、Lua 最小语法速通（够改配置就行）

> 这一节只列**改这份配置必须知道**的语法。完整教程见同目录的 `lua_guide_for_neovim.md`。

### 3.1 你最常用的 10 个语法点

| 写法 | 含义 | 配置里的例子 |
|------|------|--------------|
| `-- ...` | 单行注释 | `-- 启用 24 位真彩色` |
| `--[[ ... ]]` | 多行注释 | 块注释 / 文档头 |
| `local x = 1` | 局部变量（必加 `local`，否则污染全局） | `local opt = vim.opt` |
| `"a" .. "b"` | 字符串拼接（不是 `+`） | `t = os.date(...) .. " " .. os.date(...)` |
| `t = { 1, 2, 3 }` | 表（数组 + 字典都用这个） | `vim.g.highlight_groups = { {...}, {...} }` |
| `t.key` 或 `t["key"]` | 取字段 | `opt.shiftwidth = 2` |
| `t[#t]` | 数组最后一个元素（`#t` 是长度） | `local end_line = ...` |
| `function() ... end` | 匿名函数 | `callback = function() ... end` |
| `if ... then ... end` | if（没有括号，`then` 必写） | `if vim.fn.argc() == 0 then ... end` |
| `for i, v in ipairs(t) do ... end` | 遍历数组 | `for _, buf in ipairs(vim.api.nvim_list_bufs()) do ... end` |

### 3.2 几个和别的语言不一样的点（容易踩坑）

| 坑 | 正确写法 | 错误写法 |
|----|---------|---------|
| 数组从 1 开始 | `t[1]` | 写成 `t[0]`（那是个独立字段） |
| 不等于 | `a ~= b` | `a != b`（Lua 里这是语法错误） |
| 字符串拼接 | `"a" .. "b"` | `"a" + "b"`（会试图加法） |
| 假值 | 只有 `nil` 和 `false` 是假 | 不要把 `0` / `""` 当假判断 |
| 没有 `++` | `i = i + 1` | `i++`（语法错误） |
| 变量默认全局 | 必须 `local` | 裸写 `x = 1` 会污染全局 |

### 3.3 字符串里有反斜杠怎么办

| 场景 | 在 lua 里写 | vim 收到 |
|------|------------|---------|
| 反斜杠字面量 | `"\\\\"` | `\\` |
| 单个反斜杠 | `"\\"` | `\` |
| 正则里要 `\d` | `'\d'`（单引号）或 `"\\d"` | `\d` |

`abbreviations.lua` 里的 `cabbr("inst", "%s/\\\\(.*\\\\)\\\\/.*/\\\\1/g")`
就是"vim 正则里的 `\\` → lua 字符串里写成 `\\\\`"的典型例子。

---

## 四、文件逐一拆解：每个文件做什么、放什么、怎么改

### 4.1 `init.lua`（入口）

**做什么**：依次 `require` 所有 `config/*.lua`，建立加载顺序。

**改它的时机**：
- 新建了一个 `config/xxx.lua`，要在末尾加一行 `require("config.xxx")`。
- 千万不要动 `require("config.lazy")` 的位置——它必须第一行。

**当前结构**：

```lua
require("config.lazy")        -- 1. 引导 lazy
require("config.options")     -- 2. 选项
require("config.functions")   -- 3. 函数（vimscript 容器）
require("config.commands")    -- 4. 命令（依赖 3）
require("config.abbreviations") -- 5. 缩写
require("config.keymaps")     -- 6. 键位
require("config.autocmds")    -- 7. 自动命令
require("config.highlights")  -- 8. 高亮
require("config.statusline")  -- 9. 状态栏
```

### 4.2 `lua/config/lazy.lua`（插件管理器）

**做什么**：
1. 如果 `~/.local/share/nvim/lazy/lazy.nvim` 不存在，就 `git clone` 装上。
2. 设 `mapleader` / `maplocalleader` 为 `\`。
3. 调 `require("lazy").setup({...})`，里面 `spec = { { import = "plugins" } }` 表示**自动加载 `lua/plugins/` 下所有文件**。

**改它的时机**：
- 想改 leader 键：改第 21、22 行。
- 想给 lazy 换主题：改 `install = { colorscheme = { "gruvbox" } }`。
- 想加 `lazy` 的全局选项：塞到 `setup({...})` 表格里。

**不要改**：
- `require("lazy").setup` 里的 `spec` 字段结构，除非你知道在做什么。
- `vim.g.mapleader` 这两行的位置（必须在 setup 之前）。

### 4.3 `lua/config/options.lua`（vim 选项）

**做什么**：调 vim 的各项选项（缩进、显示、搜索、配色…）。

**最常用的改法**：

| 想改什么 | 找哪一行 | 改法示例 |
|---------|---------|---------|
| tab 宽度 | `opt.tabstop` / `opt.shiftwidth` | `opt.tabstop = 4` |
| 是否显示行号 | `opt.number` | `opt.number = false` |
| 行号模式 | `opt.relativenumber` | `opt.relativenumber = true` |
| 搜索是否忽略大小写 | `opt.ignorecase` | `opt.ignorecase = false` |
| 是否折行 | `opt.wrap` | `opt.wrap = false` |
| 命令行高度 | `opt.cmdheight` | `opt.cmdheight = 2` |
| 配色背景 | `opt.background` | `opt.background = "light"` |
| 编码 | `opt.encoding` | `opt.encoding = "utf-8"` |

**Lua 设置选项 vs vimscript `set` 的对应关系**：

| vimscript | Lua（推荐） |
|-----------|------------|
| `set number` | `vim.opt.number = true` |
| `set nonumber` | `vim.opt.number = false` |
| `set number?` | `print(vim.opt.number:get())` |
| `set tabstop=2` | `vim.opt.tabstop = 2` |
| `set shiftwidth=2` | `vim.opt.shiftwidth = 2` |
| `set list` | `vim.opt.list = true` |
| `set wrap` | `vim.opt.wrap = true` |
| `set background=dark` | `vim.opt.background = "dark"` |
| `set backspace=indent,eol,start` | `vim.opt.backspace = { "indent", "eol", "start" }` |

**特殊用法**：

```lua
-- 列表型选项（追加 / 移除）
opt.wildignore:append("*.tmp")
opt.wildignore:remove("*.bak")

-- 路径类（追加）
opt.path:append({ "**" })

-- 多值字符串（用数组）
opt.backspace = { "indent", "eol", "start" }
```

> 文件第 10 行 `local opt = vim.opt` 是一个常用小技巧：
> 给 `vim.opt` 起个短名字（`opt`），后面写 `opt.number` 比 `vim.opt.number` 短。

### 4.4 `lua/config/keymaps.lua`（键位）

**做什么**：把按键映射到操作、命令、函数。

**最常用的 4 种映射形式**：

#### 形式 A：映射到 Ex 命令（最简单）

```lua
-- 把 normal 模式下的 <leader>ff 映射为 :Files<CR>
map("n", "<leader>ff", "<cmd>Files<CR>")
```

#### 形式 B：映射到按键序列（保持用户按键习惯）

```lua
-- o 在新建行后自动回到 normal（避免留在 insert）
map("n", "o", "o<Esc>", { remap = true })
```

#### 形式 C：映射到一段 vimscript（用 `vim.cmd`）

```lua
-- 调自定义函数 TogglePaste
map("n", "<leader>p", function() vim.cmd("call TogglePaste()") end)
```

#### 形式 D：映射到一段 Lua 函数（最灵活）

```lua
-- 弹输入框，把命令执行结果 put 到 buffer
map("n", "<leader>x", function()
  local cmd = vim.fn.input(":", "", "command")
  if cmd ~= "" then
    local out = vim.fn.trim(vim.fn.execute(cmd))
    vim.api.nvim_put(vim.split(out, "\n", { plain = true }), "", true, true)
  end
end, { silent = true })
```

**通用模板**：

```lua
vim.keymap.set("n", "<leader>xx", "<动作>", {  -- n=normal, i=insert, v=visual, x=visual+select
  silent = true,    -- 不回显
  remap = true,     -- 允许递归映射（默认 false）
  expr = true,      -- 右侧是表达式，每次按都求值
  desc = "说明",    -- 描述（:Telescope keymaps 会显示）
})
```

**文件顶部的两个简写**：

```lua
local map = vim.keymap.set
local opts = { silent = true }
```

`map` 是 `vim.keymap.set` 的缩写，全文件统一用 `map`。
`opts` 在这个文件里**其实没被用到**（每一行都重新写 `{ silent = true }`），可以删，也可以留着当模板。

**想新增一个键位的步骤**：

1. 选个区段（在文件里找注释 `-- 编辑器基础` / `-- 窗口导航` / `-- fzf.vim 快捷键`…）。
2. 决定模式（`n` / `i` / `v` / `x` / `t`）。
3. 决定动作（按键序列 / Ex 命令 / Lua 函数）。
4. 写一行 `map("n", "<leader>xx", ...)`。
5. `:luafile %` 重新加载（或者 `<leader>sv`，见 [第 4.9 节](#49-luaconfigstatuslinelua-状态栏)）。

**特殊键名**：

| 想表达 | 写法 |
|--------|------|
| `Ctrl + x` | `<C-x>` |
| `Alt + x` | `<A-x>` |
| `Shift + x` | `<S-x>` |
| `空格` | `<Space>` |
| `Tab` | `<Tab>` |
| `Enter` | `<CR>` |
| `Esc` | `<Esc>` |
| 反斜杠 | `\\`（在 lua 字符串里） |
| 管道 `|` | `<Bar>` 或在 `vim.cmd` 字符串里用 `\|` |
| 你的 leader | `<leader>`（运行时会被替换成 `\`） |

### 4.5 `lua/config/abbreviations.lua`（缩写）

**做什么**：在插入模式 / 命令行模式下，输入 `ec` 自动展开成 `ecoChangeCell` 这种。

**当前结构**：

```lua
local function iabbr(lhs, rhs)
  vim.cmd("iabbrev " .. vim.fn.escape(lhs, " |") .. " " .. rhs)
end

local function cabbr(lhs, rhs)
  vim.cmd("cabbrev " .. vim.fn.escape(lhs, " |") .. " " .. rhs)
end

iabbr("ec", "ecoChangeCell")
cabbr("GG", "%!grep -B1 -A1")
```

> 为什么要 `vim.fn.escape(lhs, " |")`？
> 因为 vim 的 `iabbrev` 命令以空格分参数，缩写词里如果含空格或 `|` 会被切断。
> 同样 `rhs` 里的 `|` 也要用 `\|` 转义，**参考 `rmpinm` 那行的写法**。

**新增一个缩写的步骤**：

1. 决定是插入模式（`iabbr`）还是命令行模式（`cabbr`）。
2. 写一行 `iabbr("你的缩写", "展开后的内容")`。
3. **不要缩写 vim 命令的关键字**（`q`、`w`、`wq` 等），会冲突。

### 4.6 `lua/config/autocmds.lua`（自动命令）

**做什么**：在某个**事件**触发时自动跑一段 Lua。

**当前的所有 autocmd**：

| 事件 | 触发时机 | 干什么 |
|------|---------|--------|
| `BufEnter` | 进入 buffer | 设关键词高亮 |
| `FocusGained` / `BufEnter` | 窗口获焦 / 进入 buffer | 自动重载外部修改 |
| `CursorHold` / `CursorHoldI` | 光标停 500ms | `checktime` |
| `FileType` (pattern=tcl) | 打开 tcl 文件 | 加载自定义补全字典 |
| `FileType` (pattern=tcl) | 打开 tcl 文件 | 设 `<C-]>` 跳到 tag |
| `FileType` (pattern=python) | 打开 py 文件 | tab 宽度 4 |
| `FileType` (pattern=vim) | 打开 vim 文件 | 折叠方式 marker |
| `FileType` (无 pattern) | 任意文件 | 关闭自动注释续行 |
| `StdinReadPre` | 从 stdin 读入 | 记一个标志位 |
| `VimEnter` | 启动后 | 如果无文件参数且非 stdin，自动打开 nvim-tree |

**通用模板**：

```lua
vim.api.nvim_create_autocmd("事件名", {
  group = vim.api.nvim_create_augroup("组名", { clear = true }),  -- 建议每次都加
  pattern = "tcl",       -- 可选：只对匹配的文件名触发
  callback = function()  -- 要做的事
    -- 你的 lua 代码
  end,
})
```

**几个要点**：

- `group = vim.api.nvim_create_augroup("xxx", { clear = true })` 让你**重复加载这个文件时不会重复注册**。
- `callback` 接收一个参数 `args`（事件信息），但你的现有代码都没用，需要时再写 `function(args) ... end`。
- 如果想"对所有文件做这件事"：不写 `pattern` 字段。
- 想做多事件：用 `vim.api.nvim_create_autocmd({ "A", "B" }, {...})`（见 `auto_reload` 的写法）。

**典型新增例子**：在保存 markdown 时自动格式化：

```lua
vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("md_format", { clear = true }),
  pattern = "*.md",
  callback = function() vim.cmd("normal! gg=G") end,
})
```

### 4.7 `lua/config/commands.lua`（自定义命令）

**做什么**：注册 `:` 开头的命令。

**两种写法**：

#### 写法 A：用 `vim.cmd([[ ... ]])` 包一段 vimscript

```lua
cmd([[command! Rt call InsertProcessHead()]])
```

适合：
- 命令体里就是 `call 某个函数()`。
- 需要 `-range` / `-nargs` / `-bang` 等属性。

#### 写法 B：用 `vim.api.nvim_create_user_command`

```lua
vim.api.nvim_create_user_command("GitBlameLine", function()
  local line_number = vim.fn.line(".")
  local filename = vim.api.nvim_buf_get_name(0)
  local result = vim.system({ "git", "blame", "-L", line_number .. ",+1", filename }):wait()
  print(result.stdout)
end, { desc = "Print the git blame for the current line" })
```

适合：
- 命令体是 Lua 逻辑。
- 想要更结构化的 `desc` / `nargs` / `range` 配置。

**`command!` 上的常用属性**：

| 属性 | 含义 | 例子 |
|------|------|------|
| `-nargs=0` | 不接参数 | `command! -nargs=0 Foo echo "hi"` |
| `-nargs=1` | 必接 1 个参数 | `command! -nargs=1 Bar echo <q-args>` |
| `-nargs=*` | 0 或多个参数 | `command! -nargs=* Baz ...` |
| `-range` | 接受范围（如 `:'<,'>Baz`） | `command! -range Baz ...` |
| `-bang` | 接受 `!` | `command! -bang Quz ...` |
| `-complete=file` | 参数按文件名补全 | `command! -nargs=1 -complete=file Open ...` |

**新增命令的步骤**：

1. 在 `functions.lua` 写好函数（如果需要）。
2. 在 `commands.lua` 加一行 `cmd([[command! ... ]])` 或 `nvim_create_user_command(...)`。
3. 重新加载配置。

### 4.8 `lua/config/functions.lua`（自定义函数）

**做什么**：用 `vim.cmd([[ ... ]])` 把 vimscript 函数原样塞进来。

**当前函数清单**：

| 函数 | 作用 | 调用它的命令 / 键位 |
|------|------|------------------|
| `InsertProcessHead()` | 插入 proc 模板头 | `:Rt` |
| `AlignSelectedColumns(...)` | 按列对齐选区 | `:AlignColumns` / `<leader>ta` |
| `VisualBlockIncrement(start, step)` | 块自增数字 | `<leader>i` |
| `VisualBlockIncrementWithFormat(start, step, digits)` | 块自增数字（带位数补零） | `<leader>I` |
| `SortUniqueByColumn(...)` | 按列去重保留较大/较小 | `:SortKeepLarger` / `:SortKeepSmaller` |
| `TogglePaste()` | 切换 paste 模式 | `<leader>p` |
| `s:SmartReplace()` | 大小写敏感智能替换 | `<leader>r` |
| `TclGotoTag()` | tcl 文件的 tag 跳转 | tcl 文件下 `<C-]>` |
| `CloseBufAndNerdTree()` | 关 buffer / 文件树 | `<leader>q` |
| `s:fzf_statusline()` | fzf 状态栏 | fzf 自动调 |
| `SetupKeywordHighlights()` | 关键词高亮 | `BufEnter` |
| `ToggleWrap()` | 切换 wrap | `:ToggleWrap` / `<leader>w` |

**为什么是 vimscript？**

- 老 vimrc 里的逻辑，避免重写。
- 复杂正则 / 字符串处理 / `syn match` / `execute` 链等，用 vimscript 更直观。
- 新写的简单函数可以慢慢迁移到 Lua，但**没必要一次全改**。

**改函数的注意事项**：

- vimscript 在 `[[ ... ]]` 字符串里写。
- 如果函数体里有 `]]`，把外层用 `[==[ ... ]==]`（`=` 越多越安全）。
- 函数里访问 lua 变量：先存到 `g:` 全局，再用 `let g:xxx` 读。

**新增函数的步骤**：

1. 在 `functions.lua` 末尾加一段：
   ```lua
   vim.cmd([[
   function! MyNewFunc()
     " vimscript 代码
   endfunction
   ]])
   ```
2. 在 `commands.lua` 注册命令（如果需要）。
3. 在 `keymaps.lua` 绑键位（如果需要）。
4. 重新加载。

### 4.9 `lua/config/highlights.lua`（高亮覆盖）

**做什么**：调个别高亮组的颜色。

**当前只覆盖了 5 个组**：`Cursor`、`Visual`、`Search`、`IncSearch`、`CurSearch`、`Folded`。

**改颜色**：

```lua
hi("Search", { bg = "#ffb86c", fg = "#282828", bold = true })
-- 常用字段：
--   fg        前景色
--   bg        背景色
--   bold      加粗
--   italic    斜体
--   underline 下划线
```

颜色值可以是：
- `"#ffb86c"`（HEX）
- `"red"` / `"DarkOrange"`（命名色，但终端支持有限）
- `ctermfg = 161`（256 色号）

**新增一个高亮覆盖**：

```lua
hi("Comment", { fg = "#888888", italic = true })
```

> 注意：换 colorscheme 时这些设置会被覆盖。
> 想跨主题生效，需要放在 `vim.api.nvim_create_autocmd("ColorScheme", ...)` 里。

### 4.10 `lua/config/statusline.lua`（状态栏）

**做什么**：用 `table.concat` 拼出状态栏格式字符串，赋给 `vim.opt.statusline`。

**当前格式**：

```
[buffer 编号] [文件名+修改标记]    <-- 分隔符 -->     [当前行/总行] [当前列/总列]   --进度%--
```

| 占位符 | 含义 |
|--------|------|
| `%n` | buffer 编号 |
| `%F` | 完整路径 |
| `%m` | 修改标记 `[+]` |
| `%r` | 只读标记 `[RO]` |
| `%h` | 帮助缓冲标记 |
| `%w` | 预览窗口标记 |
| `%=` | 左 / 右对齐分隔点 |
| `%l` | 当前行号 |
| `%L` | 总行数 |
| `%c` | 当前列号 |
| `%{expr}` | 表达式结果（这里是 `col('$')-1` 总列数） |
| `%p` | 文件位置百分比 |
| `%%` | 字面 `%` |

**改状态栏**：
- 想加一个段：往数组里加一项字符串。
- 想用 `%{...}` 求值：写 `{ "%c/%{col('$')-1}" }` 这种。
- 想自定义颜色：用 `%#GroupName#...%*` 切高亮组。

---

## 五、常用修改模式速查表

> 改配置时，先在表里找匹配的任务，照模板改。

| 我想… | 改哪个文件 | 模板 |
|------|----------|------|
| 改 tab 宽度 | `options.lua` | `opt.tabstop = 4` / `opt.shiftwidth = 4` |
| 改缩进用空格还是 tab | `options.lua` | `opt.expandtab = true` (空格) / `false` (tab) |
| 关掉相对行号 | `options.lua` | `opt.relativenumber = false` |
| 加一个键位 | `keymaps.lua` | `map("n", "<leader>xx", "<动作>")` |
| 改现有键位 | `keymaps.lua` | 找到对应行，替换右侧 |
| 加一个插入模式缩写 | `abbreviations.lua` | `iabbr("缩写", "展开")` |
| 加一个命令行模式缩写 | `abbreviations.lua` | `cabbr("缩写", "展开")` |
| 加一个自动命令 | `autocmds.lua` | `vim.api.nvim_create_autocmd("事件", { group=..., pattern=..., callback=function() ... end })` |
| 加一个 `:命令` | `functions.lua` 写函数 + `commands.lua` 注册 | 见 [第 4.7 / 4.8 节](#47-luaconfigcommandslua-自定义命令) |
| 加一个插件 | `lua/plugins/xxx.lua` 新建或追加 | `return { { "author/name", config=function() ... end } }` |
| 改 colorscheme | `colorscheme.lua` | `vim.cmd.colorscheme("xxx")` |
| 改主题 | `colorscheme.lua` 改插件 + `highlights.lua` 改颜色 |  |
| 改状态栏 | `statusline.lua` | 改 `table.concat({...})` 里的字符串 |
| 改 leader | `lazy.lua` | `vim.g.mapleader = ","` |
| 改函数体 | `functions.lua` | 在 `vim.cmd([[ ... ]])` 块里改 vimscript |
| 重新加载配置 | 命令行 | `:luafile %` 或 `<leader>sv` |
| 编辑当前配置文件 | 命令行 | `<leader>ev` |

---

## 六、插件（lazy.nvim）配置规范

### 6.1 文件结构

`lua/plugins/xxx.lua` 必须 `return` 一个**数组**，每个元素是一个**插件表格**。

```lua
return {
  {
    "作者/插件名",          -- 必填：GitHub user/repo
    dependencies = { ... }, -- 可选：依赖的插件
    priority = 1000,        -- 可选：加载优先级（数字越大越先）
    opts = { ... },        -- 可选：传给 setup() 的配置（最简方式）
    config = function()     -- 可选：自定义 setup 逻辑
      require("xxx").setup({ ... })
    end,
    build = function() ... end,  -- 可选：安装时执行的命令
  },
  { "另一个插件" },
}
```

### 6.2 三种配置方式

| 方式 | 何时用 | 例子 |
|------|--------|------|
| `opts = { ... }` | 插件支持 `setup({...})`，配置简单 | `nvim-web-devicons` |
| `config = function() require("xxx").setup({...}) end` | 需要更多控制 / 多步初始化 | `nvim-tree`、`gitsigns` |
| `build = function() ... end` | 安装后要跑命令（如 `fzf#install()`） | `junegunn/fzf` |

### 6.3 当前所有插件一览

| 插件 | 替代 / 作用 | 配置文件 |
|------|------------|---------|
| `nvim-tree/nvim-web-devicons` | 图标字体 | `plugins/ui.lua` |
| `nvim-tree/nvim-tree.lua` | 替代 NERDTree | `plugins/ui.lua` |
| `lewis6991/gitsigns.nvim` | 替代 vim-gitgutter | `plugins/ui.lua` |
| `junegunn/fzf` | 命令行模糊查找 | `plugins/fzf.lua` |
| `junegunn/fzf.vim` | fzf 与 vim 的桥 | `plugins/fzf.lua` |
| `tpope/vim-surround` | 配对符号处理 | `plugins/editor.lua` |
| `jiangmiao/auto-pairs` | 自动补全括号 | `plugins/editor.lua` |
| `luochen1990/rainbow` | 括号彩色 | `plugins/editor.lua` |
| `andymass/vim-matchup` | 增强 % 匹配 | `plugins/editor.lua` |
| `rickhowe/diffchar.vim` | 逐字符 diff | `plugins/editor.lua` |
| `morhetz/gruvbox` | 配色 | `plugins/colorscheme.lua` |

### 6.4 新增插件的步骤

1. 去 [github.com](https://github.com) 找插件，记下 `作者/仓库名`。
2. 决定放哪个文件：同类插件放一起（如 UI 类的放 `ui.lua`），新类别建新文件（如 `plugins/lsp.lua`）。
3. 在文件末尾追加：
   ```lua
   {
     "作者/仓库名",
     config = function()
       require("xxx").setup({  -- 查插件文档看 setup 接受什么
         -- 配置
       })
     end,
   },
   ```
4. 保存文件 → `:Lazy` 打开 lazy 界面 → 按 `I` 安装（或下次启动自动装）。
5. 在 `keymaps.lua` 绑键位（如果需要）。

### 6.5 改插件配置的步骤

1. 找到对应文件。
2. 改 `opts` 表格 / `config` 函数里的 `setup({...})`。
3. 保存 → `:Lazy` → 选插件 → `R` 重新加载 / `S` 同步。

---

## 七、vimscript 与 Lua 混用的注意事项

### 7.1 三种"在 lua 里跑 vimscript"的方式

| 方式 | 语法 | 用途 |
|------|------|------|
| 一行命令 | `vim.cmd("set number")` | 单行 |
| 多行（不解析 `]]`） | `vim.cmd([[ ... ]])` | 函数体 |
| 多行（更安全） | `vim.cmd([==[ ... ]==])` | 函数体含 `]]` |

### 7.2 反斜杠的转义陷阱

| 想给 vim 的 | lua 字符串要写 |
|------------|---------------|
| `\` | `"\\"` |
| `\\` | `"\\\\"` |
| `\d`（正则） | `"\\d"` |

**例子**：

```lua
-- 想要 vim 看到：iabbrev vv vs ~/.vimrc
vim.cmd("iabbrev vv vs ~/.vimrc")

-- 想要 vim 看到：%s/\/\w\+ / /  （正则：匹配反斜杠开头的词）
-- 在 lua 字符串里：%s/\\/\\w\\+ / /
cabbr("rmpinm", "%s/\\/\\w\\+ / /")
```

### 7.3 跨语言传值

| 方向 | 做法 |
|------|------|
| lua → vim 变量 | `vim.g.myvar = "value"`（vim 里 `:let g:myvar` 可见） |
| vim 变量 → lua | `vim.g.myvar` 直接读 |
| lua 数组 → vim 列表 | `vim.list = lua_table`（基本无缝） |
| lua 字典 → vim 字典 | 同上 |
| lua 函数 → vim 函数 | `vim.cmd(string.format("let g:F = %s", vim.inspect(myfn)))` —— **不要这样**，直接保留 vimscript 函数 |

**典型用法**（你的 `functions.lua` 里就有）：

```lua
-- lua 端：把 lua 表赋给 g:highlight_groups
vim.g.highlight_groups = {
  { "Exact", "Special", { "pw", "re", "la" } },
  { "Regex", "GruvboxFg0", { "U\\d\\{3}" } },
}

-- vimscript 端：直接当 vim 列表用
-- for group in g:highlight_groups | ...
```

### 7.4 哪些情况优先用 vimscript 而不是 lua

- 函数里有 `syn match` / `execute` 链（`SetupKeywordHighlights`）。
- 需要 `function!`（函数名带 `!` 覆盖旧定义）。
- 需要 `s:` 局部函数（脚本局部）。
- 老 vimrc 里就有的逻辑，不值得重写。

---

## 八、典型修改任务示例

### 示例 1：把 tab 宽度从 2 改成 4

**改的文件**：`lua/config/options.lua`

```lua
-- 找到这几行
opt.tabstop = 2         -- 改成 4
opt.shiftwidth = 2      -- 改成 4
opt.softtabstop = 2     -- 改成 4
```

**重新加载**：`:luafile %` 或 `<leader>sv`

### 示例 2：新增一个键位：`<leader>w` 打开 todo 列表

**改的文件**：`lua/config/keymaps.lua`

```lua
-- 在文件末尾追加
map("n", "<leader>w", "<cmd>TodoList<CR>")
```

（前提：你装了 todolist 插件并已 `setup`）

### 示例 3：让 Python 文件的 tab 宽度自动变成 4

**改的文件**：`lua/config/autocmds.lua`

打开就有现成的：

```lua
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("python_tab", { clear = true }),
  pattern = "python",
  callback = function()
    vim.opt_local.expandtab = true
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
  end,
})
```

**改成 YAML 的 tab 宽度 2**：

```lua
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("yaml_tab", { clear = true }),
  pattern = "yaml",
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
  end,
})
```

### 示例 4：加一个自定义命令 `:Wc` 统计字数

**改的文件**：
1. `lua/config/commands.lua`
2. （如果逻辑复杂）`lua/config/functions.lua`

**简单版**（直接在 commands.lua 写）：

```lua
vim.api.nvim_create_user_command("Wc", function()
  local n = vim.fn.wordcount()
  print(string.format("Words: %d, Lines: %d, Chars: %d",
    n.words, n.lines, n.chars))
end, { desc = "Word count" })
```

### 示例 5：新增一个插件

例：加 `telescope.nvim`（模糊查找）

1. 新建 `lua/plugins/telescope.lua`：

   ```lua
   return {
     {
       "nvim-telescope/telescope.nvim",
       dependencies = { "nvim-lua/plenary.nvim" },
       config = function()
         require("telescope").setup({})
       end,
     },
   }
   ```

2. 保存文件，启动 nvim，`:Lazy` → `I` 安装。
3. 在 `keymaps.lua` 加键位：

   ```lua
   map("n", "<leader>ff", "<cmd>Telescope find_files<CR>")
   ```

> ⚠️ 这会**覆盖**现有 `<leader>ff`（fzf 的 Files）。要么换键，要么删 fzf 版的。

### 示例 6：让 search 高亮更醒目

**改的文件**：`lua/config/highlights.lua`

```lua
hi("Search", { bg = "#ffb86c", fg = "#282828", bold = true })
```

改 `bg` / `fg` 后面的色值即可。

---

## 九、常见报错与排查

| 报错关键字 | 大概率原因 | 怎么办 |
|----------|----------|--------|
| `attempt to call ... a nil value` | 函数名拼错 / 函数没 require | 检查 `functions.lua` 是否被加载 |
| `E5113: Error while ...` 后跟 lua 报错 | lua 语法错 | 看行号，对照 [第 3 节](#三lua-最小语法速通够改配置就行) |
| `E117: Unknown function: xxx` | vimscript 函数没装载 | 检查 `functions.lua` 加载顺序（必须在 commands 前） |
| `Invalid 'syntax' argument` 等 | vimscript 命令里 lua 转义有问题 | 多一个 `\\` 或少一个 `\\` |
| 改完配置没生效 | 没重新加载 | `:luafile %` 或 `<leader>sv` 或重启 nvim |
| `<leader>` 键没反应 | leader 没设或被覆盖 | 检查 `lazy.lua` 里 `vim.g.mapleader` |
| 插件没装 / 没生效 | 没在 `plugins/` 里写 / 没装 | `:Lazy` 看状态 |
| 配色变回默认 | colorscheme 在 `setup` 之后跑 | 确认 `colorscheme.lua` 里 `priority = 1000` |

**调试小技巧**：

- `:messages` —— 看 vim 积累的所有报错。
- `:lua print(vim.inspect(vim.g.highlight_groups))` —— 在命令行临时跑 lua 看变量。
- `nvim --clean` —— 用干净配置启动，排查是不是其他配置干扰。
- `git diff` + `git stash` —— 改坏了回退。

---

## 附录 A：核心概念对照表（Lua ↔ vimscript ↔ nvim API）

| 想做的事 | vimscript | Lua（推荐） |
|---------|-----------|------------|
| 设置选项 | `set number` | `vim.opt.number = true` |
| 读选项 | `echo &number` | `print(vim.opt.number:get())` |
| 设全局变量 | `let g:foo = 1` | `vim.g.foo = 1` |
| 读全局变量 | `let g:foo` | `vim.g.foo` |
| 键位映射 | `nnoremap <leader>x :Foo<CR>` | `vim.keymap.set("n", "<leader>x", "<cmd>Foo<CR>")` |
| 缩写 | `iabbrev ec ecoChangeCell` | `vim.cmd("iabbrev ec ecoChangeCell")` |
| 自动命令 | `autocmd BufEnter * call Foo()` | `vim.api.nvim_create_autocmd("BufEnter", { callback = function() ... end })` |
| 用户命令 | `command! Foo echo "hi"` | `vim.api.nvim_create_user_command("Foo", function() print("hi") end, {})` |
| 调 vimscript 函数 | `call Foo()` | `vim.cmd("call Foo()")` 或 `vim.fn.Foo()` |
| 取 buffer 内容 | `getline(1, '$')` | `vim.api.nvim_buf_get_lines(0, 0, -1, false)` |
| 写 buffer 内容 | `setline(1, list)` | `vim.api.nvim_buf_set_lines(0, 0, -1, false, list)` |
| 输入 | `input("prompt")` | `vim.fn.input("prompt")` |
| echo | `echo "hi"` | `print("hi")` 或 `vim.api.nvim_echo({{"hi"}}, false, {})` |

## 附录 B：加载顺序一览（修改任何文件前先确认）

```
init.lua
  ↓
lazy.lua        ← 装 lazy + 设 mapleader
  ↓
options.lua     ← 全局选项
  ↓
functions.lua   ← vimscript 自定义函数
  ↓
commands.lua    ← :Command（依赖 functions）
  ↓
abbreviations.lua
  ↓
keymaps.lua
  ↓
autocmds.lua
  ↓
highlights.lua
  ↓
statusline.lua
```

## 附录 C：常用的"诊断 / 维护"命令

| 命令 | 作用 |
|------|------|
| `:luafile %` | 重新加载当前 lua 文件 |
| `<leader>sv` | 重新加载整个配置（同上） |
| `<leader>ev` | 打开 `$MYVIMRC`（即 `init.lua`） |
| `:checkhealth` | nvim 自检 |
| `:Lazy` | 打开 lazy 插件管理界面 |
| `:messages` | 看历史报错 |
| `:nmap` | 列出所有 normal 模式映射 |
| `:imap` | 列出所有 insert 模式映射 |
| `:command` | 列出所有用户命令 |
| `:augroup` / `:autocmd` | 列出自动命令 |
| `:hi` | 列出高亮组 |
| `:set all` | 列出所有选项当前值 |

---

**最后**：这份配置最大的特点是**"老 vimscript + 新 lua + 插件按 lazy 规范"三件套混搭**。
改的时候**保持这个混搭风格**，不要把所有 vimscript 都重写成 lua（吃力不讨好），也不要把 lua 写得花里胡哨。
**小步前进**：改一点 → `:luafile %` → 看效果 → 不对就还原。
