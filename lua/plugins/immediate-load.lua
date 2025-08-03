return {
  -- 让 neo-tree 立即加载
  {
    "nvim-neo-tree/neo-tree.nvim",
    lazy = false, -- 立即加载，不懒加载
    priority = 1000, -- 高优先级加载
    cmd = nil, -- 移除命令触发
    event = nil, -- 移除事件触发
    opts = {
      -- 启动时自动显示
      filesystem = {
        hijack_netrw_behavior = "open_current",
      },
    },
  },
  
  
  -- 启动时自动打开 neo-tree 和 outline
  {
    "AstroNvim/astrocore",
    opts = {
      autocmds = {
        auto_open_panels = {
          {
            event = "VimEnter",
            desc = "Auto open neo-tree on startup",
            callback = function()
              -- 延迟执行，确保其他插件已加载
              vim.defer_fn(function()
                -- 只在没有文件参数时自动打开
                if vim.fn.argc() == 0 then
                  -- 只打开 neo-tree
                  vim.cmd("Neotree show")
                  -- 聚焦到主窗口
                  vim.cmd("wincmd l")
                end
              end, 100)
            end,
          },
        },
      },
    },
  },
}