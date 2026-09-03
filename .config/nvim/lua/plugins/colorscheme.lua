-- =============================================================================
--  plugins/colorscheme.lua
--  原 morhetz/gruvbox 保持不变。
--  配色需要在 lazy 加载完成后立即生效，因此用 priority = 1000。
-- =============================================================================

return {
  {
    "morhetz/gruvbox",
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("gruvbox")
      vim.o.background = "dark"
    end,
  },
}
