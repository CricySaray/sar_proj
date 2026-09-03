-- =============================================================================
--  plugins/editor.lua
--  - tpope/vim-surround
--  - jiangmiao/auto-pairs
--  - luochen1990/rainbow
--  - andymass/vim-matchup
--  - rickhowe/diffchar.vim
-- =============================================================================

return {
  -- vim-surround：快速处理配对符号（括号、引号、HTML 标签等）
  {
    "tpope/vim-surround",
  },

  -- auto-pairs：自动补全括号 / 引号
  {
    "jiangmiao/auto-pairs",
    config = function()
      vim.g.AutoPairsFlyMode = 0
      vim.g.AutoPairsShortcutBackInsert = "<M-b>"
    end,
  },

  -- rainbow：括号彩色高亮
  {
    "luochen1990/rainbow",
    config = function()
      vim.g.rainbow_active = 1
      vim.g.rainbow_conf = {
        guifgs = {
          "#FF7575", "#FFD166", "#06D6A0", "#118AB2",
          "#9381FF", "#FF9B85", "#B8C5D6", "#E9D985",
        },
        ctermfgs = { "203", "220", "48", "33", "105", "216", "152", "222" },
        guis = { "" },
        cterms = { "" },
        operators = "_,_",
        parentheses = {
          "start=/(/ end=/)/ fold",
          "start=/\\[/ end=/\\]/ fold",
          "start=/{/ end=/}/ fold",
        },
        separately = {
          ["*"] = {},
          tcl = {
            parentheses = {
              "start=/(/ end=/)/ fold",
              "start=/\\[/ end=/\\]/ fold",
              "start=/{/ end=/}/ fold",
            },
            guifgs = {
              "#FF7575", "#FFD166", "#06D6A0", "#118AB2",
              "#9381FF", "#FF9B85", "#B8C5D6", "#E9D985",
            },
          },
        },
      }
    end,
  },

  -- vim-matchup：在 % / [# ]# / * 等匹配上做增强
  {
    "andymass/vim-matchup",
    config = function()
      vim.g.matchup_matchparen_offscreen = { fallthrough = false }
      vim.g.matchup_delim = { enabled = false }
      vim.g.matchup_match_words_enabled = 0
    end,
  },

  -- diffchar.vim：逐字符 diff
  {
    "rickhowe/diffchar.vim",
  },
}
