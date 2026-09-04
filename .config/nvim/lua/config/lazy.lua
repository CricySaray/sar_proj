-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- 重要：setup 之前必须先设置好 mapleader / maplocalleader，
-- 这样 lazy 内部、以及插件里的映射才会使用正确的 leader。
-- 与原 vimrc 保持一致：mapleader 与 maplocalleader 都使用反斜杠。
vim.g.mapleader = "\\"
vim.g.maplocalleader = "\\"

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    -- 自动 import lua/plugins/ 下的所有 spec
    { import = "plugins" },
  },
  -- 安装插件时使用的 colorscheme
  install = { colorscheme = { "gruvbox" } },
  -- 自动检查插件更新
  checker = { enabled = true },
  -- 禁用 luarocks 支持：本配置没有任何依赖 luarocks 的插件，
  -- 关闭后可消除 checkhealth 中 hererocks/luarocks 的 ERROR。
  rocks = { enabled = false },
  -- 性能选项：禁用一些 vim 自带但用不到的插件
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
