-- =============================================================================
--  keymaps.lua
--  迁移自原 vimrc 的所有键位映射。
--  - mapleader = "\" (反斜杠)，与原 vimrc 一致
--  - 空格 <space> 在 normal 模式下映射为 ":"，与原 vimrc 一致
--  - 多键映射 / 插件映射（如 fzf.vim）放在这里
-- =============================================================================

local map = vim.keymap.set
local opts = { silent = true }

-- -----------------------------------------------------------------------------
--  编辑器基础
-- -----------------------------------------------------------------------------

-- 把 <space> 映射为 ":"：normal 模式下按空格直接进入命令行（用户要求保留）
map("n", "<Space>", ":", { remap = true })

-- o / O 在新建行后回到 normal 模式
map("n", "o", "o<Esc>", { remap = true })
map("n", "O", "O<Esc>", { remap = true })

-- jj / ii 退出插入模式 / 可视模式
map("i", "jj", "<Esc>")
map("v", "ii", "<Esc>")

-- U redo（覆盖默认的撤销恢复，恢复原 vim 行为）
map("n", "U", "<cmd>redo<CR>")

-- - 映射为 dd（保留原行为）
map({"n","v"}, "-", "dd", { remap = true })

-- 光标快捷移动
map("n", "<C-a>", "ggVG:ya")  -- 注意：原 vimrc 中 <c-a> 被两次映射，最终生效是 ggVG:ya
map("i", "<C-a>", "<Esc>I")   -- 插入模式下：退出插入 + 行首插入
map("i", "<C-e>", "<Esc>A")   -- 插入模式下：退出插入 + 行尾追加

-- Shift + 方向键：向上/下移动（用 j/k 替代，避免与终端/系统冲突）
map("n", "<S-d>", "k", { remap = true })
map("n", "<S-f>", "j", { remap = true })

-- 在可视模式中按 <leader>y：把选区内容送到搜索寄存器（@@）
map("v", "<leader>y", function()
  local sel = vim.fn.getreg('@@')
  vim.fn.setreg('/', vim.fn.escape(sel, '/\\'))
end, { expr = true, silent = true })

-- 跳出括号 / 引号（C-l 在插入模式下）
map("i", "<C-l>", function()
  return vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true)
    .. ":call search('[>)\\]}\"'']', 'W')<CR>a"
end, { expr = true, replace_keycodes = true })

-- 在 normal 模式下执行任意命令，结果 put 到 buffer
map("n", "<leader>x", function()
  local cmd = vim.fn.input(":", "", "command")
  if cmd ~= "" then
    local out = vim.fn.trim(vim.fn.execute(cmd))
    vim.api.nvim_put(vim.split(out, "\n", { plain = true }), "", true, true)
  end
end, { silent = true })

-- gd：跳转到定义后回到原位置（保留原 m' 标记）
map("n", "gd", "m'gd<C-O>")

-- <leader>p：切换 paste 模式
map("n", "<leader>p", function() vim.cmd("call TogglePaste()") end)
map("i", "<leader>p", "<C-o>:call TogglePaste()<CR>")

-- <leader>r：智能替换（大小写敏感，限定变量边界）
map("n", "<leader>r", function() vim.cmd("call SmartReplace()") end)

-- <leader>w：切换折行（normal + visual）
map({"n","v"}, "<leader>w", "<cmd>ToggleWrap<CR>")

-- <leader>ev / <leader>sv / <leader>q：编辑/重载配置/关闭 buffer
map("n", "<leader>ev", "<cmd>vsplit $MYVIMRC<cr>")
map("n", "<leader>sv", "<cmd>source $MYVIMRC<cr>")
map("n", "<leader>q", function() vim.cmd("call CloseBufAndNerdTree()") end)

-- <F3>：打开新标签页浏览当前目录
map("n", "<F3>", "<cmd>tabnew .<CR>")

-- <F4>：在光标位置插入当前时间
map("n", "<F4>", function()
  local t = os.date("%Y/%m/%d %H:%M:%S") .. " " .. os.date("%A")
  return vim.api.nvim_replace_termcodes("a<C-r>='' .. table.concat({'" .. t .. "'}, '')<CR><Esc>", true, false, true)
end, { expr = true })

-- 简化版 <F4>（更稳）
map("n", "<F4>", function()
  local t = os.date("%Y/%m/%d %H:%M:%S") .. " " .. os.date("%A")
  vim.api.nvim_feedkeys("a" .. t .. "<Esc>", "n", false)
end)

-- 块自增数字（visual 模式）
map("x", "<leader>i", ":<C-u>call VisualBlockIncrement(1, 1)<CR>")
map("x", "<leader>I", ":<C-u>call VisualBlockIncrementWithFormat(1, 1, 3)<CR>")

-- 块对齐列
map("x", "<leader>ta", ":<C-u>AlignColumns <CR>")

-- Buffer 切换
map("n", "<C-n>", "<cmd>bn<CR>")
map("n", "<C-p>", "<cmd>bp<CR>")

-- -----------------------------------------------------------------------------
--  窗口导航
--  注：原 vimrc 中 <c-h> / <c-l> / <c-j> / <c-k> 都被映射为 <c-w>hjkl。
--  第二个 <c-h> 映射 <c-w>h 会覆盖第一个 <c-e>，与原 vimrc 行为一致。
-- -----------------------------------------------------------------------------
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-h>", "<C-w>h")
map("n", "<C-l>", "<C-w>l")

-- Alt + hjkl：与 init.lua 中的逻辑一致（terminal + insert + normal 模式）
map({"t","i"}, "<A-h>", "<C-\\><C-n><C-w>h")
map({"t","i"}, "<A-j>", "<C-\\><C-n><C-w>j")
map({"t","i"}, "<A-k>", "<C-\\><C-n><C-w>k")
map({"t","i"}, "<A-l>", "<C-\\><C-n><C-w>l")
map("n", "<A-h>", "<C-w>h")
map("n", "<A-j>", "<C-w>j")
map("n", "<A-k>", "<C-w>k")
map("n", "<A-l>", "<C-w>l")

-- 调整窗口大小
map("n", "<C-Up>",   "<C-w>+")
map("n", "<C-Down>", "<C-w>-")
map("n", "<C-Left>", "<C-w>>")
map("n", "<C-Right>","<C-w><")

-- -----------------------------------------------------------------------------
--  terminal 模式
-- -----------------------------------------------------------------------------
map("t", "<Esc>", "<C-\\><C-n>")

-- -----------------------------------------------------------------------------
--  差分（diff）
-- -----------------------------------------------------------------------------
map("n", "<leader>ds", "<cmd>ToggleDiffSaved<cr>")

-- -----------------------------------------------------------------------------
--  文件浏览器（由 nvim-tree 接管，原 nerdtree 映射会被 nvim-tree 插件覆盖，
--  这里只保留 <leader>f 作为通用 "find file" 入口，留给 fzf.vim 使用）
-- -----------------------------------------------------------------------------
map("n", "<F2>", function()
  require("nvim-tree.api").tree.toggle("cwd")
end, { silent = true })

map("n", "<leader>n", function()
  require("nvim-tree.api").tree.toggle("cwd")
end, { silent = true })

map("n", "<leader>f", function()
  require("nvim-tree.api").tree.find_file()
end, { silent = true })

-- -----------------------------------------------------------------------------
--  fzf.vim 快捷键（依赖 fzf.vim 插件加载）
-- -----------------------------------------------------------------------------
-- 文件 / buffer / 历史
map("n", "<leader>ff", "<cmd>Files<CR>")
map("n", "<leader>fb", "<cmd>Buffers<CR>")
map("n", "<leader>fh", "<cmd>History<CR>")
map("n", "<leader>ft", "<cmd>Tags<CR>")
map("n", "<leader>fm", "<cmd>Marks<CR>")
map("n", "<leader>fc", "<cmd>Colors<CR>")
map("n", "<leader>fw", "<cmd>Windows<CR>")
-- Git
map("n", "<leader>gf", "<cmd>GFiles<CR>")
map("n", "<leader>gs", "<cmd>GFiles?<CR>")
map("n", "<leader>gc", "<cmd>Commits<CR>")
map("n", "<leader>gb", "<cmd>BCommits<CR>")
map("n", "<leader>gg", "<cmd>GGrep<CR>")
-- 文本搜索
map("n", "<leader>rg", "<cmd>Rg<CR>")
map("n", "<leader>lg", "<cmd>Lines<CR>")
map("n", "<leader>bl", "<cmd>BLines<CR>")
-- 命令与帮助
map("n", "<leader>cm", "<cmd>Commands<CR>")
map("n", "<leader>hm", "<cmd>Helptags<CR>")
map("n", "<leader>mf", "<cmd>Maps<CR>")
map("n", "<leader>fp", "<cmd>ProjectFiles<CR>")
-- 通用 maps 列表
map({"n","x","o"}, "<leader><Tab>", function()
  local mode = vim.api.nvim_get_mode().mode
  if mode:sub(1,1) == "v" then
    return vim.api.nvim_replace_termcodes("<plug>(fzf-maps-x)", true, false, true)
  elseif mode:sub(1,1) == "n" then
    return vim.api.nvim_replace_termcodes("<plug>(fzf-maps-n)", true, false, true)
  end
end, { expr = true })

-- -----------------------------------------------------------------------------
--  nvim-tree 关闭（<leader>q 已在前面定义）
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
--  yank 后高亮
-- -----------------------------------------------------------------------------
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  callback = function() vim.hl.on_yank() end,
})
