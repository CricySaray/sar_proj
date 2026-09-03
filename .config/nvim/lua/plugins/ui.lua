-- =============================================================================
--  plugins/ui.lua
--  - nvim-tree 替换 preservim/nerdtree
--  - nvim-web-devicons 替换 ryanoasis/vim-devicons（被 nvim-tree 依赖）
--  - gitsigns.nvim 替换 airblade/vim-gitgutter
-- =============================================================================

return {
  -- 图标字体支持（nvim-tree 与其他 UI 插件依赖）
  {
    "nvim-tree/nvim-web-devicons",
    opts = {},
  },

  -- 文件树（替代 NERDTree）
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({
        view = {
          width = 50,
          side = "left",
          preserve_window_proportions = true,
          number = true,
          relativenumber = true,
          signcolumn = "yes",
        },
        renderer = {
          indent_markers = { enable = true },
          icons = {
            show = {
              file = true,
              folder = true,
              folder_arrow = true,
              git = true,
              modified = true,
              hidden = true,
            },
            glyphs = {
              default = "",
              symlink = "➛",
              folder = {
                arrow_closed = "▸",
                arrow_open = "▾",
              },
              git = {
                unstaged = "✹",
                staged = "✚",
                untracked = "✭",
                renamed = "➜",
                unmerged = "═",
                deleted = "✖",
                ignored = "☒",
              },
            },
          },
        },
        filters = {
          dotfiles = false,
          custom = { "^.git$", "^.hg$", "^.svn$" },
        },
        git = {
          enable = true,
          ignore = false,
          timeout = 500,
        },
        actions = {
          -- 仅启用复制到系统剪贴板
          use_system_clipboard = false,
        },
        notify = {
          threshold = 2,
        },
      })
    end,
  },

  -- Git 状态（替代 vim-gitgutter）
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        signs = {
          add          = { text = "▎" },
          change       = { text = "▎" },
          delete       = { text = "" },
          topdelete    = { text = "" },
          changedelete = { text = "▎" },
          untracked    = { text = "▎" },
        },
        signs_staged = {
          add          = { text = "▎" },
          change       = { text = "▎" },
          delete       = { text = "" },
          topdelete    = { text = "" },
          changedelete = { text = "▎" },
        },
        signcolumn = true,
        numhl      = false,
        linehl     = false,
        word_diff  = false,
        watch_gitdir = {
          follow_files = true,
        },
        current_line_blame = false,
        current_line_blame_opts = {
          virt_text = true,
          virt_text_pos = "eol",
          delay = 500,
          ignore_whitespace = false,
        },
        update_debounce = 100,
      })
    end,
  },
}
