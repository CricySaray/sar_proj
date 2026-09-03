-- =============================================================================
--  nvim 入口文件
--  - 引导 lazy.nvim（包管理器）
--  - 设置 mapleader 为反斜杠（必须发生在 lazy.setup 之前，键位才会生效）
--  - 加载 config 下的各模块
-- =============================================================================

require("config.lazy") -- 这里面会 bootstrap lazy 并完成 .setup()

-- 通用设置
require("config.options")

-- 自定义函数（vimscript 保留为原样）和命令
require("config.functions")
require("config.commands")

-- 缩写 / 键位 / 自动命令
require("config.abbreviations")
require("config.keymaps")
require("config.autocmds")

-- 视觉相关（高亮组 + 状态栏）
require("config.highlights")
require("config.statusline")
