-- AstroCommunity: import any community modules here
-- We import this file in `lazy_setup.lua` before the `plugins/` folder.
-- This guarantees that the specs are processed before any user plugins.

---@type LazySpec
return {
  "AstroNvim/astrocommunity",
  { import = "astrocommunity.pack.lua" },
  -- import/override with your plugins folder
  { import = "astrocommunity.pack.python" },
  { import = "astrocommunity.colorscheme.catppuccin" },
  
  -- 编辑体验提升
  { import = "astrocommunity.motion.flash-nvim" },
  { import = "astrocommunity.motion.nvim-surround" },
  
  -- 调试增强
  { import = "astrocommunity.debugging.nvim-dap-virtual-text" },
  { import = "astrocommunity.debugging.persistent-breakpoints-nvim" },
  
  -- Git 增强
  { import = "astrocommunity.git.diffview-nvim" },
  
  -- 项目管理
  { import = "astrocommunity.project.project-nvim" },
  
  -- UI 美化
  { import = "astrocommunity.utility.noice-nvim" },
  
  -- Tab 隔离的 Buffer 管理
  { import = "astrocommunity.bars-and-lines.scope-nvim" },
  
  -- 代码质量
  { import = "astrocommunity.diagnostics.trouble-nvim" },
  { import = "astrocommunity.editing-support.refactoring-nvim" },
  
  -- 性能优化
  { import = "astrocommunity.editing-support.bigfile-nvim" },
}
