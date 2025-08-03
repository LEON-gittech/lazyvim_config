-- Glance.nvim - VSCode 风格的 LSP 引用预览
return {
  "dnlhc/glance.nvim",
  event = "LspAttach",
  config = function()
    require("glance").setup({
      height = 20, -- 预览窗口高度
      zindex = 45,
      
      -- 预览窗口选项
      preview_win_opts = {
        cursorline = true,
        number = true,
        wrap = true,
      },
      
      -- 边框样式
      border = {
        enable = true,
        top_char = "―",
        bottom_char = "―",
      },
      
      -- 列表配置
      list = {
        position = "right", -- 列表位置: left/right
        width = 0.33, -- 列表宽度
      },
      
      -- 主题
      theme = {
        enable = true,
        mode = "auto", -- 自动检测主题
      },
      
      -- 上下文行数
      indent_lines = {
        enable = true,
        icon = "│",
      },
      
      -- 折叠/展开
      folds = {
        fold_closed = "",
        fold_open = "",
        folded = true, -- 默认折叠
      },
      
      -- 钩子函数
      hooks = {
        -- 在预览前可以添加额外的上下文行
        before_open = function(results, open, jump, method)
          if #results == 0 then
            vim.notify("No " .. method .. " found", vim.log.levels.WARN)
          else
            open(results)
          end
        end,
      },
    })
  end,
  keys = {
    { "gd", "<cmd>Glance definitions<cr>", desc = "Glance definitions" },
    { "gr", "<cmd>Glance references<cr>", desc = "Glance references" },
    { "gy", "<cmd>Glance type_definitions<cr>", desc = "Glance type definitions" },
    { "gi", "<cmd>Glance implementations<cr>", desc = "Glance implementations" },
  },
}