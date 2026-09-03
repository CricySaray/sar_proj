-- =============================================================================
--  plugins/fzf.lua
--  原 junegunn/fzf 与 junegunn/fzf.vim 保持不变。
--  - build 阶段调用 fzf#install() 下载 fzf 二进制
--  - 配置 g:fzf_vim 字典（与原 vimrc 一致）
-- =============================================================================

return {
  {
    "junegunn/fzf",
    build = function()
      -- 对应原 vimrc 中的 { 'do': { -> fzf#install() } }
      pcall(vim.cmd, "call fzf#install()")
    end,
  },

  {
    "junegunn/fzf.vim",
    dependencies = { "junegunn/fzf" },
    config = function()
      -- 用单条 :let 命令块初始化并填充 g:fzf_vim 字典
      -- 避免在 lua 中逐项 setf 时 vim 把 g:fzf_vim 当作空值处理
      vim.cmd([[
        let g:fzf_vim = {}
        let g:fzf_vim.buffers_jump = 1
        let g:fzf_vim.grep_multi_line = 1
        let g:fzf_vim.commits_log_options = '--graph --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr"'
        let g:fzf_vim.tags_command = 'ctags -R'
        let g:fzf_vim.commands_expect = 'alt-enter,ctrl-x'
        let g:fzf_vim.buffers_options = ['--style', 'full', '--border-label', ' Open Buffers ']
        let g:fzf_vim.preview_window = ['right,50%', 'ctrl-/']
        let g:fzf_vim.listproc     = function('fzf#vim#listproc#quickfix')
        let g:fzf_vim.listproc_ag  = function('fzf#vim#listproc#quickfix')
        let g:fzf_vim.listproc_rg  = function('fzf#vim#listproc#location')
      ]])
    end,
  },
}
