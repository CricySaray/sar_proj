-- =============================================================================
--  highlights.lua
--  自定义高亮组。
--  - 关键词高亮（SetupKeywordHighlights）由 functions.lua 定义，
--    在 autocmds.lua 的 BufEnter 钩子中触发，无需在此处重复声明。
--  - 这里只放一些通用的、跨 colorscheme 生效的高亮覆盖。
-- =============================================================================

local function hi(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

-- -----------------------------------------------------------------------------
--  一些常用高亮覆盖（颜色基于 gruvbox）
-- -----------------------------------------------------------------------------
hi("Cursor",         { bold = true })
hi("Visual",         { bg = "#444444" })

-- 让搜索结果更醒目
hi("Search",         { bg = "#ffb86c", fg = "#282828", bold = true })
hi("IncSearch",      { bg = "#ff79c6", fg = "#282828", bold = true })
hi("CurSearch",      { bg = "#ff79c6", fg = "#282828", bold = true })

-- 折叠文本
hi("Folded",         { fg = "#928374", italic = true })
