# Lua 知识文档（面向 Neovim 配置与 Lua 编程）

> 目标：为「配置 Neovim」这一实际场景，系统讲清 Lua 语言本身与 Neovim 中 Lua 的用法。
> 版本说明：**Neovim 内置的是 LuaJIT，等价于 Lua 5.1**。本文件所有语法均以 Lua 5.1 / LuaJIT 为准；5.3+ 才有的特性（整数除 `//`、按位运算 `& | ~ << >>`、`goto`、utf8 库等）会特别标注「5.3+」，**在 nvim 里默认不可用**，别误用。

---

## 目录

1. [学习路径建议](#一学习路径建议)
2. [先记住这 8 个「和其它语言不一样」的点](#二先记住这-8-个和其它语言不一样的点)
3. [基础语法](#三基础语法)
4. [字符串](#四字符串)
5. [表 table（Lua 的核心）](#五表-tablelua-的核心)
6. [控制流](#六控制流)
7. [函数](#七函数)
8. [元表与面向对象](#八元表与面向对象)
9. [模块与 require](#九模块与-require)
10. [Neovim 中的 Lua 用法](#十neovim-中的-lua-用法)
11. [常见陷阱汇总](#十一常见陷阱汇总)
12. [速查表](#十二速查表)

---

## 一、学习路径建议

1. **先读第 2 节**——把 Lua 和 JS/Python/C 不一样的「坑」提前建立预期，避免一直按旧习惯写错。
2. **再读第 3~7 节**——这是语法主体，每节都有 Neovim 配置里的真实例子。
3. **第 8 节（元表）可以后置**——它用于理解插件内部的「类」写法，初学配置时不太需要自己写。
4. **第 9~10 节**——模块化与 `vim.*` API，是「真刀真枪写配置」的部分，反复回来查。
5. 写配置时遇到记不清的 API，用 nvim 内 `:help lua`、`:h vim.keymap.set` 之类查，比硬记强。

---

## 二、先记住这 8 个「和其它语言不一样」的点

| # | 要点 | 说明 |
|---|------|------|
| 1 | **数组下标从 1 开始** | `t[1]` 是第一个元素，`t[0]` 不是。`#t` 是长度 |
| 2 | **不等于用 `~=`** | 不是 `!=`，没有 `===` |
| 3 | **没有 `++` / `--` / `+=`** | 只能 `i = i + 1` |
| 4 | **只有 `nil` 和 `false` 是「假」** | `0`、`""`（空字符串）都是「真」！ |
| 5 | **字符串拼接用 `..`** | 不是 `+`。`"a" .. "b"` → `"ab"` |
| 6 | **没有 `continue`，循环里只能 `break`** | 需要用条件嵌套或标志变量替代 |
| 7 | **变量默认是全局的** | 一定要养成 `local` 习惯，否则污染全局、还更慢 |
| 8 | **未声明的变量值为 `nil`** | 访问不存在的表字段也是 `nil`，不会报错 |

---

## 三、基础语法

### 3.1 注释

```lua
-- 单行注释

--[[
  多行（块）注释
]]

--[=[  含 ] 的长注释，用 = 提高层级  ]=]
```

### 3.2 变量与作用域

```lua
x = 10        -- 全局变量（危险，尽量避免）
local y = 20  -- 局部变量（推荐）

local a, b = 1, 2        -- 多重赋值
local c, d = 1            -- d 为 nil
a, b = b, a              -- 交换两个值（无需临时变量）
```

作用域规则：

```lua
local x = 1
do
  local x = 2            -- 块级局部变量，遮蔽外层
  print(x)               -- 2
end
print(x)                 -- 1
```

**Neovim 配置惯例**：每个 `init.lua` 或模块文件里，临时变量一律 `local`；只有极少数需要跨文件共享的才放全局或 `vim.g`。

### 3.3 数据类型

| 类型 | 字面量示例 | 备注 |
|------|-----------|------|
| `nil` | `nil` | 表示「无值」，未初始化变量、不存在的字段都是它 |
| `boolean` | `true` / `false` | |
| `number` | `3.14`, `42`, `1e3`, `0x1F` | LuaJIT 下全部是**双精度浮点**，没有独立的 int |
| `string` | `"hi"`, `'hi'`, `[[hi]]` | 不可变 |
| `function` | `function() end` | 函数是一等公民 |
| `table` | `{1, 2, 3}`, `{a=1}` | 唯一的复合结构，数组+哈希都是它 |
| `thread` | `coroutine.create()` | 协程，少用 |
| `userdata` | （C 侧对象） | Neovim 里 `vim.fn` 返回的一些对象属此类 |

类型判断：

```lua
print(type(nil))      -- "nil"
print(type(10))       -- "number"
print(type("x"))      -- "string"
print(type({}))       -- "table"
print(type(print))    -- "function"
print(type(nil) == "nil")  -- true
```

### 3.4 运算符

```lua
-- 算术
a + b   a - b   a * b   a / b
a % b            -- 取模
a ^ b            -- 幂（不是按位异或！Lua 里 ^ 是乘方）
-a               -- 取负

-- 关系（注意 ~=）
a == b   a ~= b   a < b   a > b   a <= b   a >= b

-- 逻辑（返回操作数本身，见下）
a and b   a or b   not a

-- 其它
s1 .. s2        -- 字符串拼接
#t              -- 取长度（字符串或表）
```

逻辑运算符的「短路 + 返回操作数」特性非常常用：

```lua
-- or 常用来给默认值（因为 nil/false 是假）
local name = opts.name or "default"

-- and 常用来做「条件满足才执行」
local ok = cond and do_something()
```

⚠️ 注意 `or` 给默认值只对 `nil`/`false` 生效；如果 0 或空串也是「合法值」，这个写法会误判（见第 11 节陷阱）。

---

## 四、字符串

### 4.1 定义与转义

```lua
local s1 = "hello"
local s2 = 'hello'
local s3 = [[多行
原始字符串，引号和 \n 都按字面处理]]
```

长括号 `[[ ]]` 内**不处理转义**，写文件路径、正则、Vimscript 片段时特别省心：

```lua
local path = [[C:\Users\anrui\nvim]]   -- 反斜杠无需转义
```

需要包含 `]]` 本身时，提升层级用 `[=[ ]=]`（等号数量任意，只要前后一致）：

```lua
local s = [=[ 这里可以安全出现 ]] 与 ]=]  =]
```

常用转义：`\n` 换行、`\t` 制表符、`\\` 反斜杠、`\"` 双引号。

### 4.2 常用字符串函数

```lua
local s = "Hello, Neovim"

#s                        --> 13        （长度，等价 string.len(s)）
string.len(s)             --> 13
string.upper(s)           --> "HELLO, NEOVIM"
string.lower(s)           --> "hello, neovim"
string.sub(s, 1, 5)       --> "Hello"   （注意：索引从 1 开始，且闭区间！）
string.rep("ab", 3)       --> "ababab"
string.reverse(s)         --> "mivoeN ,olleH"
string.byte("A")          --> 65
string.char(65)           --> "A"
```

### 4.3 查找与替换（模式匹配，类似「简化版正则」）

Lua 用的是 **patterns**，不是完整正则。常用：

```lua
local s = "foo123bar456"

string.find(s, "%d+")              --> 4   （第一个数字起始位置）
string.match(s, "%d+")             --> "123"  （返回匹配内容）
string.gmatch(s, "%d+")            --> 迭代器，逐个返回 "123","456"
string.gsub(s, "%d+", "X")         --> "fooXbarX"（替换，返回 (新串, 替换次数)）
```

常用 pattern 字符：

| pattern | 含义 |
|---------|------|
| `.` | 任意字符 |
| `%d` | 数字 |
| `%a` | 字母 |
| `%w` | 字母或数字 |
| `%s` | 空白 |
| `%p` | 标点 |
| `%u` / `%l` | 大写 / 小写字母 |
| `+` `*` `-` `?` | 1+ / 0+ / 非贪婪 / 0或1 次 |
| `^` `$` | 锚定开头 / 结尾 |
| `(...)` | 捕获组（`string.match` 可返回多个捕获值）|

```lua
-- 捕获组示例：拆 "key=value"
local k, v = string.match("color=blue", "(%w+)=(%w+)")
print(k, v)  -- color  blue
```

### 4.4 格式化

```lua
string.format("%s is %d years old", "Tom", 30)   --> "Tom is 30 years old"
string.format("%.2f", 3.14159)                    --> "3.14"
string.format("%5d", 42)                          --> "   42"
string.format("%x", 255)                          --> "ff"
```

---

## 五、表 table（Lua 的核心）

`table` 同时扮演「数组」「字典/哈希」「对象」「模块」四种角色。**没有独立的数组或 map 类型**。

### 5.1 数组用法（下标从 1 开始）

```lua
local arr = {10, 20, 30, 40}
print(arr[1])     -- 10   （不是 0！）
print(arr[#arr])  -- 40   （#arr = 4，最后一个元素）

-- 常用操作
table.insert(arr, 50)            -- 尾部追加 → {10,20,30,40,50}
table.insert(arr, 2, 15)         -- 指定位置插入 → {10,15,20,30,40,50}
table.remove(arr)                -- 移除并返回最后一个
table.remove(arr, 1)             -- 移除第一个
table.concat(arr, ", ")          -- 拼接成字符串 "10, 20, 30, 40, 50"
table.sort(arr)                  -- 原地排序
```

⚠️ `#t` 取长度对「**有洞（nil 中间）**」的数组是**未定义行为**，结果可能不对。数组要保持连续。

### 5.2 字典/哈希用法

```lua
local conf = { theme = "tokyonight", number = true }
-- 等价于
local conf = { ["theme"] = "tokyonight", ["number"] = true }

print(conf.theme)          -- "tokyonight"（点语法）
print(conf["theme"])       -- 等价（方括号语法）
conf.foo = "bar"           -- 新增键
conf.number = false        -- 修改
conf.theme = nil           -- 删除键（赋 nil 即删）
```

> 只有合法的「标识符」才能用点语法（不能是数字、不能带空格/连字符）。所以 `vim.g.foo_bar` 可以，但 `vim.g["foo-bar"]` 必须用方括号。

### 5.3 混合使用

同一张表既能当数组又能当字典（底层就是一张表，不冲突）：

```lua
local t = { "a", "b", name = "list" }
print(t[1])   -- a
print(t.name) -- list
```

### 5.4 遍历

```lua
-- ipairs：按 1,2,3... 顺序遍历数组部分，遇到第一个 nil 停止
local arr = {"a", "b", "c"}
for i, v in ipairs(arr) do
  print(i, v)   -- 1 a / 2 b / 3 c
end

-- pairs：遍历所有键值对（顺序不保证，哈希部分无序）
local map = { x = 1, y = 2 }
for k, v in pairs(map) do
  print(k, v)   -- 顺序不定
end
```

> 规则：**数组用 `ipairs`，字典用 `pairs`**。对「混用」的表遍历哈希键要用 `pairs`。

### 5.5 遍历时不要新增键

`pairs` 过程中新增键行为未定义；`ipairs` 过程中插入会破坏顺序。需要先收集再改。

---

## 六、控制流

### 6.1 if

```lua
if x > 10 then
  print("big")
elseif x > 5 then
  print("mid")
else
  print("small")
end
```

条件里**任何非 nil、非 false 的值都是真**，包括 0 和空字符串：

```lua
if 0 then print("0 是真") end        -- 会打印！
if "" then print("空串是真") end     -- 会打印！
```

### 6.2 while 与 repeat

```lua
-- while：先判断后执行
local i = 1
while i <= 3 do
  print(i)
  i = i + 1
end

-- repeat...until：先执行后判断（至少执行一次）
local j = 1
repeat
  print(j)
  j = j + 1
until j > 3
```

### 6.3 for

```lua
-- 数值 for：从 1 到 3（闭区间，含 3），步长默认 1
for i = 1, 3 do print(i) end            -- 1 2 3

-- 指定步长：从 10 到 1，步长 -1
for i = 10, 1, -1 do print(i) end       -- 10 9 ... 1

-- 泛型 for：配合迭代器
for k, v in pairs(t) do ... end
for i, v in ipairs(t) do ... end
for w in string.gmatch(s, "%a+") do ... end
```

### 6.4 break（没有 continue）

```lua
for i = 1, 10 do
  if i == 5 then break end
end
```

**没有 `continue`**，常见替代写法：用 `if` 反向包裹逻辑；或用 Lua 5.2+ 的 `goto`（但 nvim 的 LuaJIT/5.1 不支持 `goto`，别用）。

---

## 七、函数

### 7.1 定义

```lua
-- 具名函数
local function add(a, b)
  return a + b
end

-- 匿名函数（赋给变量）
local add = function(a, b) return a + b end

-- 函数是一等公民：可以当参数传、当返回值返回
local function call_twice(fn)
  fn()
  fn()
end
call_twice(function() print("hi") end)
```

### 7.2 多返回值

Lua 函数**可以返回多个值**，这是它的一大特色：

```lua
local function minmax(a, b)
  if a < b then return a, b else return b, a end
end

local lo, hi = minmax(9, 3)   -- lo=3, hi=9

-- string.find 就是多返回值：start, finish
local s, e = string.find("hello", "ll")   -- s=3, e=4
```

### 7.3 变长参数 `...`

```lua
local function join(sep, ...)
  local args = {...}          -- 打包成表
  return table.concat(args, sep)
end
print(join("-", "a", "b", "c"))   -- "a-b-c"

-- select("#", ...) 取参数个数；select(n, ...) 取第 n 个起的参数
local function count(...)
  return select("#", ...)
end
print(count(1, 2, 3))   -- 3
```

### 7.4 方法语法：冒号 `:` 与点 `.`

```lua
-- 冒号定义：隐式传入 self
local obj = { value = 10 }
function obj:get()
  return self.value
end
-- 等价于
function obj.get(self) return self.value end

-- 冒号调用：自动把对象当第一个参数
obj:get()        -- 等价 obj.get(obj)
```

Neovim 里 `vim.fn` 那些 Vimscript 函数都是**点调用**；只有自己定义「类方法」时才用冒号。

### 7.5 闭包（配置里极常用）

函数能捕获外部局部变量，并长期持有它：

```lua
local function make_counter()
  local n = 0
  return function()
    n = n + 1
    return n
  end
end
local c = make_counter()
print(c(), c(), c())   -- 1 2 3
```

Neovim 典型场景——**回调里捕获变量**：

```lua
-- 给每个 buffer 注册一个「显示当前 buffer 号」的快捷键
for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
  vim.keymap.set("n", "<leader>x", function()
    print("buffer: " .. bufnr)   -- 闭包记住了本次循环的 bufnr
  end, { buffer = bufnr })
end
```

> ⚠️ 经典坑：如果在循环里用 `var` 变量创建闭包（老式 `var` 是同一份），所有闭包会共享同一个值。用 `local` 变量（如上例的 `for _, bufnr in` 每次迭代都是新的 `bufnr`）就没这个问题。Lua 的 `for` 循环变量天然是每次迭代新建的 `local`，放心用。

---

## 八、元表与面向对象

> 初学可跳过；理解插件源码里的「类」写法时再回来看。

### 8.1 元表基础

每个表可以挂一张「元表」，定义特殊行为：

```lua
local mt = { __add = function(a, b) return a.v + b.v end }
local a = setmetatable({ v = 1 }, mt)
local b = setmetatable({ v = 2 }, mt)
print(a + b)   -- 3（触发 __add）
print(getmetatable(a))   -- mt
```

常用元方法：

| 元方法 | 触发场景 |
|--------|---------|
| `__index` | **读不存在的键**时 |
| `__newindex` | **写不存在的键**时 |
| `__add` `__sub` `__mul` `__div` 等 | 算术运算 |
| `__eq` `__lt` `__le` | 比较 |
| `__call` | 把表当函数调用 |
| `__tostring` | `tostring(t)` 时 |

### 8.2 用 `__index` 模拟「类」继承

Lua 没有内置 class，靠 `__index` 指向一张「原型表」实现方法查找：

```lua
-- 原型（相当于「类」）
local Animal = {}
Animal.__index = Animal

function Animal.new(name)
  local self = setmetatable({}, Animal)
  self.name = name
  return self
end

function Animal:speak()
  return self.name .. " makes a sound"
end

-- 派生（相当于「子类」）
local Dog = setmetatable({}, { __index = Animal })
Dog.__index = Dog

function Dog.new(name)
  local self = Animal.new(name)
  return setmetatable(self, Dog)
end

function Dog:speak()
  return self.name .. " barks"
end

local d = Dog.new("Rex")
print(d:speak())   -- "Rex barks"
```

Neovim 生态里 `plenary`、部分插件的类就是这么写的。**自己写配置基本用不到**，看懂即可。

---

## 九、模块与 require

### 9.1 一个文件即一个模块：`return` 一张表

`lua/myconf/keys.lua`：

```lua
local M = {}      -- M = module，惯例名

local function private_helper()   -- 不导出，模块内可见
  return "internal"
end

function M.setup()
  vim.keymap.set("n", "<leader>w", "<cmd>w<CR>")
end

M.default_opts = { silent = true }

return M          -- 关键：返回表
```

其它文件里：

```lua
local keys = require("myconf.keys")   -- 不含 .lua 后缀，用 . 分隔路径
keys.setup()
print(keys.default_opts.silent)
```

### 9.2 require 的规则

- `require("myconf.keys")` 会按 `package.path` 去**找 `myconf/keys.lua`**（或 `myconf/keys/init.lua`）。
- 模块**只加载一次**，结果缓存在 `package.loaded` 里；多次 `require` 拿到同一张表。
- 修改模块文件后需 `:luafile %` 或重启 nvim 才生效（可用 `package.loaded["myconf.keys"] = nil` 强制重载，调试时用）。

### 9.3 配置里的 require 惯例

```lua
-- init.lua 顶部集中 require 各子模块
require("core.options")     -- 基础选项
require("core.keymaps")     -- 快捷键
require("core.autocmds")    -- 自动命令
require("plugins")          -- 插件（lazy.nvim）
```

目录结构示意：

```
~/.config/nvim/
├── init.lua
└── lua/
    ├── core/
    │   ├── options.lua
    │   ├── keymaps.lua
    │   └── autocmds.lua
    └── plugins/
        └── ...
```

---

## 十、Neovim 中的 Lua 用法

Neovim 把大量 Vim 能力暴露成 `vim.*`。下表是写配置最高频的几个。

### 10.1 选项：`vim.opt` / `vim.o` / `vim.g` 等

| 写法 | 作用 | 示例 |
|------|------|------|
| `vim.opt.xxx` | 设「选项」（推荐，支持表、自动转换） | `vim.opt.number = true` |
| `vim.o.xxx` | 字符串形式的选项 | `vim.o.cmdheight = 1` |
| `vim.bo.xxx` | buffer 局部选项 | `vim.bo.filetype = "lua"` |
| `vim.wo.xxx` | window 局部选项 | `vim.wo.wrap = false` |
| `vim.g.xxx` | 全局变量（`g:`） | `vim.g.mapleader = " "` |
| `vim.b.xxx` | buffer 变量 | `vim.b.foo = 1` |
| `vim.w.xxx` | window 变量 | `vim.w.bar = 2` |

```lua
-- vim.opt 的好处：直观、支持批量
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"
vim.opt.ignorecase = true
vim.opt.smartcase = true
```

> `vim.o` 与 `vim.opt` 的区别：`vim.opt.xxx` 返回一个「可赋值的表式对象」，能 `vim.opt.wildignore:append({...})` 做增删；`vim.o.xxx` 是朴素字符串/布尔。**日常设置一律用 `vim.opt`**。

### 10.2 快捷键：`vim.keymap.set`

```lua
vim.g.mapleader = " "   -- 设置 leader 键（必须在映射之前）

vim.keymap.set("n", "<leader>w", "<cmd>w<CR>", { desc = "Save file" })

-- 参数说明：set(模式, 左键, 右键, opts)
-- 模式："n" 普通、"i" 插入、"v" 可视、"x" 仅可视、"t" 终端，逗号可多模式 "n,v"
vim.keymap.set({ "n", "v" }, "<C-s>", "<cmd>w<CR>", { desc = "Save" })

-- 常用 opts
{ desc = "..." }          -- 描述（which-key 等插件展示用）
{ silent = true }         -- 不回显命令
{ noremap = true }        -- 不递归映射（默认已是 true，无需写）
{ buffer = bufnr }        -- 只在该 buffer 生效
{ expr = true }           -- 右值是表达式
```

**右值写法**：优先用 `<cmd>` 前缀执行 Ex 命令；或用回调函数：

```lua
vim.keymap.set("n", "<leader>h", function()
  vim.cmd("nohlsearch")
  print("search highlight cleared")
end, { desc = "Clear search highlight" })
```

### 10.3 执行 Ex 命令：`vim.cmd`

```lua
vim.cmd("set number")                 -- 单条
vim.cmd([[                           -- 多行（长括号，引号/转义无忧）
  set number
  set relativenumber
]])
vim.cmd("colorscheme tokyonight")
```

字符串拼接进命令时**务必小心**（文件名含特殊字符会被当命令解析）。更安全的是用 API：

```lua
-- 不推荐：vim.cmd("edit " .. path)   -- path 含空格/|/引号会出问题
-- 推荐：
vim.api.nvim_command("edit " .. vim.fn.fnameescape(path))
```

### 10.4 自动命令：`vim.api.nvim_create_autocmd`

```lua
-- 语法：nvim_create_autocmd({事件}, {opts})
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = { "*.c", "*.h" },          -- 匹配文件
  callback = function(ev)
    print("saved: " .. ev.file)        -- ev.file / ev.match / ev.buf 可用
  end,
  group = mygroup,                     -- 推荐放 group，便于统一清空
})
```

分组规范：

```lua
local group = vim.api.nvim_create_augroup("MyGroup", { clear = true })
-- clear = true 保证重载时不重复注册
```

### 10.5 调用 Vimscript 函数：`vim.fn`

老 Vimscript 内建函数几乎都能通过 `vim.fn` 调：

```lua
vim.fn.expand("%")          -- 当前文件名
vim.fn.getcwd()             -- 当前目录
vim.fn.system({ "git", "status" })   -- 执行外部命令
vim.fn.has("nvim-0.10")     -- 判断特性（返回 1/0）
```

> 注意：`vim.fn.xxx(...)` 的参数与返回值语义跟 Vimscript 完全一致（有些返回「列表/字典」是 Vim 风格，可能需要 `vim.fn` 转 Lua 表，如 `vim.fn.json_decode` 配合 `vim.json.decode` 的选择）。

### 10.6 定时器与延迟：`vim.defer_fn`

```lua
vim.defer_fn(function()
  print("3 秒后执行")
end, 3000)   -- 单位毫秒
```

### 10.7 lazy.nvim 插件配置结构

Neovim 社区主流插件管理器，配置本质就是 Lua 表：

```lua
-- lua/plugins/init.lua 简化示例
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- 每个插件一张表
  { "folke/tokyonight.nvim", lazy = false, priority = 1000,
    config = function()
      vim.cmd("colorscheme tokyonight")
    end },
  { "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function() require("nvim-treesitter.configs").setup({ ... }) end },
  { "neovim/nvim-lspconfig", config = function() ... end },
  { "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" } },   -- 依赖
})
```

这就是「把配置写成 Lua 数据结构」的典型：**表 + 回调函数**的组合。

---

## 十一、常见陷阱汇总

| 陷阱 | 错误写法 | 正确做法 |
|------|---------|---------|
| 下标从 0 开始 | `t[0]` | `t[1]` 是第一个 |
| 用 `!=` / `++` / `+=` | `if a != b`、`i++` | `a ~= b`、`i = i + 1` |
| 认为 `0`/`""` 为假 | `if 0 then`（以为不执行） | 它们是**真**；只有 `nil`/`false` 是假 |
| 用 `+` 拼字符串 | `"a" + "b"`（报错） | `"a" .. "b"` |
| 忘记 `local` | `x = 1` | `local x = 1` |
| 用 `continue` | `continue`（报错） | 用 `if` 包裹，或重构循环 |
| `#` 作用在有洞数组 | `{1, nil, 3}` 取 `#` | 保持数组连续，字典用 `pairs` |
| `or` 默认值误判 0/空串 | `local n = x or 1`（x=0 也变 1） | 明确判断 `if x == nil then ... end` |
| 循环闭包共享变量 | 用 `while`+老式 var 建回调 | 用 `for` 循环变量（每次新建 local） |
| 在 `pairs`/`ipairs` 中增删键 | 边遍历边 `table.insert` | 先收集改动，遍历完再应用 |
| 以为 `//`、`&`、`goto` 能用 | 5.3+ 特性 | nvim 是 LuaJIT/5.1，这些**不可用** |
| 直接 `vim.cmd("edit "..path)` 拼命令 | 路径注入 | `vim.fn.fnameescape(path)` |

---

## 十二、速查表

```lua
-- ===== 注释 =====
-- 行注释
--[[ 块注释 ]]

-- ===== 变量 =====
local x = 1            -- 局部（推荐）
y = 2                  -- 全局（避免）
local a, b = 1, 2      -- 多重赋值
a, b = b, a            -- 交换

-- ===== 类型判断 =====
type(v)                -- "nil"|"boolean"|"number"|"string"|"function"|"table"|...

-- ===== 运算符 =====
+ - * / % ^            -- 算术（^ 是乘方）
== ~= < > <= >=        -- 比较（~= 是不等）
and or not             -- 逻辑
..                     -- 拼接
#t                     -- 长度

-- ===== 字符串 =====
"a" .. "b"             -- 拼接
[[ 原始多行 ]]         -- 长括号
string.len(s) / #s     -- 长度
string.sub(s,1,3)      -- 子串（闭区间）
string.find / match / gmatch / gsub   -- 模式匹配
string.format("%d %s", 1, "x")        -- 格式化
tostring(v) / tonumber(s)             -- 转换

-- ===== 表 =====
local t = {1, 2, 3}    -- 数组
local m = {a=1, b=2}   -- 字典
t[1]  m.a  m["a"]      -- 访问（数组 1 起）
t.key = v              -- 增/改
t.key = nil            -- 删
#t                     -- 数组长度
table.insert/remove/sort/concat

-- ===== 循环 =====
for i = 1, n do ... end              -- 数值 for
for i = 1, n, 2 do ... end           -- 步长
for k, v in pairs(t) do ... end      -- 字典
for i, v in ipairs(t) do ... end     -- 数组（有序）
while cond do ... end
repeat ... until cond
break                                 -- 无 continue

-- ===== 函数 =====
local function f(a, b) return a, b end
local f = function() end
function obj:method() ... end         -- 冒号：隐式 self
obj:method()                          -- 等价 obj.method(obj)
local function f(...) local args = {...} end   -- 变长参数
select("#", ...)                      -- 参数个数

-- ===== 元表 =====
setmetatable(t, mt) / getmetatable(t)
mt = { __index = ..., __newindex = ..., __call = ... }

-- ===== 模块 =====
local M = {}
function M.setup() ... end
return M
local m = require("path.to.mod")

-- ===== Neovim 高频 =====
vim.g / vim.b / vim.w           -- 全局/buffer/window 变量
vim.opt.xxx = true              -- 选项（推荐）
vim.o / vim.bo / vim.wo         -- 字符串式选项
vim.keymap.set(mode, lhs, rhs, opts)
vim.cmd("...")                  -- 执行 Ex 命令
vim.fn.xxx(...)                 -- Vimscript 函数
vim.api.nvim_create_autocmd(ev, opts)
vim.api.nvim_create_augroup(name, { clear = true })
vim.api.nvim_create_user_command(name, fn, opts)
vim.defer_fn(fn, ms)            -- 定时器
```

---

## 附：继续深入的学习资源

- nvim 内：`:help lua`、`:help lua-guide`（官方 Lua 指南，非常详细）、`:h vim.keymap.set`、`:h vim.opt`
- 官方手册：[lua.org/manual/5.1](https://www.lua.org/manual/5.1/)（nvim 用 5.1，最贴合）
- 经典入门书《Programming in Lua》：lua.org/pil（前 5 章即覆盖本文）
- 中文参考：Lua 官方手册中文版（5.1）网上可搜
