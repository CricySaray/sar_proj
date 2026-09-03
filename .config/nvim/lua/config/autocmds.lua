-- =============================================================================
--  autocmds.lua
--  迁移自原 vimrc 的所有 autocmd。
--  - 高亮关键词（highlight_keywords）
--  - 文件类型相关（tcl 字典、python tab 宽度、vim marker 折叠）
--  - 自动重载外部修改
--  - 启动时自动打开文件树
-- =============================================================================

-- -----------------------------------------------------------------------------
--  highlight_keywords：每次进入 buffer 时设置关键词高亮
-- -----------------------------------------------------------------------------
vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("highlight_keywords", { clear = true }),
  callback = function()
    pcall(vim.cmd, "call SetupKeywordHighlights()")
  end,
})

-- -----------------------------------------------------------------------------
--  自动重新加载文件（与原 vimrc 一致）
--  FocusGained / BufEnter 时检查磁盘上的文件是否被修改，
--  CursorHold / CursorHoldI 时调用 :checktime
-- -----------------------------------------------------------------------------
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
  group = vim.api.nvim_create_augroup("auto_reload", { clear = true }),
  callback = function()
    -- silent! 检查 buffer
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) then
        pcall(vim.api.nvim_command, "checktime " .. buf)
      end
    end
  end,
})

vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
  group = vim.api.nvim_create_augroup("auto_reload_checktime", { clear = true }),
  callback = function()
    vim.cmd("checktime")
  end,
})

-- -----------------------------------------------------------------------------
--  tcl 文件：加载自定义补全字典
-- -----------------------------------------------------------------------------
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("tcl_dictionary", { clear = true }),
  pattern = "tcl",
  callback = function()
    vim.opt_local.dictionary = {
      "~/.vim/dict/invs_commands.dict",
      "~/.vim/dict/invs_options_of_command.dict",
      "~/.vim/dict/pt_command_list.dict",
      "~/.vim/dict/invs_dbxxx_commands.dict",
      "~/.vim/dict/PT_variables_and_attributes_2023_12.dict",
      "~/.vim/dict/invs_commands_common_ui_22.12.dict",
      "~/.vim/dict/invs_options_of_command_common_ui_22.12.dict",
      "~/.vim/dict/invs_database_object_common_ui_22.11_simpleExtract.dict",
    }
  end,
})

-- -----------------------------------------------------------------------------
--  tcl 文件：<C-]> 调用 TclGotoTag
-- -----------------------------------------------------------------------------
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("tcl_gototag", { clear = true }),
  pattern = "tcl",
  callback = function()
    vim.keymap.set("n", "<C-]>", function() vim.cmd("call TclGotoTag()") end, { silent = true })
  end,
})

-- -----------------------------------------------------------------------------
--  python 文件：tab 宽度设为 4
-- -----------------------------------------------------------------------------
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

-- -----------------------------------------------------------------------------
--  vim 文件：用 marker 折叠
-- -----------------------------------------------------------------------------
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("filetype_vim", { clear = true }),
  pattern = "vim",
  callback = function()
    vim.opt_local.foldmethod = "marker"
  end,
})

-- -----------------------------------------------------------------------------
--  所有文件：禁用自动注释续行（c, r, o）
--  原 vimrc: au FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o
-- -----------------------------------------------------------------------------
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("format_options", { clear = true }),
  callback = function()
    vim.opt_local.formatoptions:remove("c")
    vim.opt_local.formatoptions:remove("r")
    vim.opt_local.formatoptions:remove("o")
  end,
})

-- -----------------------------------------------------------------------------
--  启动时自动打开 nvim-tree（替代原 NERDTree 行为）
--  - 无文件参数时打开
--  - 不在 stdin 模式下
-- -----------------------------------------------------------------------------
local opened_from_stdin = false
vim.api.nvim_create_autocmd("StdinReadPre", {
  group = vim.api.nvim_create_augroup("stdin_check", { clear = true }),
  callback = function() opened_from_stdin = true end,
})

vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("auto_open_tree", { clear = true }),
  callback = function()
    if vim.fn.argc() == 0 and not opened_from_stdin then
      pcall(function()
        require("nvim-tree.api").tree.open()
      end)
    end
  end,
})
