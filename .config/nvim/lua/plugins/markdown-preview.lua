-- =============================================================================
--  plugins/markdown-preview.lua
--  - iamcco/markdown-preview.nvim
--    浏览器中实时预览 markdown，支持 GFM、代码高亮、KaTeX、Mermaid、
--    与 nvim 同步滚动。需要 Node.js（系统已检测到 v18+）。
--  - 键位：\mp   切换预览窗口（与原 <leader>mf=查看键位 不冲突）
-- =============================================================================

return {
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = "markdown",
    -- build 阶段进入 app/ 目录并安装 Node 依赖（需系统已装 Node.js）
    build = "cd app && npx --yes yarn install",
    init = function()
      -- 仅对 markdown 系文件启用，避免误触发
      vim.g.mkdp_filetypes = { "markdown" }
      -- 关闭浏览器自动打开，首次 \mp 后再按一次即可
      vim.g.mkdp_open_to_the_world = 0
      -- 同步滚动：nvim 移动时预览跟着滚
      vim.g.mkdp_sync_scroll = 1
      -- 端口冲突时自动换端口
      vim.g.mkdp_port = nil
    end,
    keys = {
      { "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", desc = "Markdown Preview 切换" },
      { "<leader>ms", "<cmd>MarkdownPreviewStop<cr>",   desc = "Markdown Preview 停止" },
    },
  },
}
