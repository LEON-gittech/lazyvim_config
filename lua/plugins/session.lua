return {
  -- 配置 resession 保存更多内容
  {
    "stevearc/resession.nvim",
    opts = {
      -- 自动保存会话
      autosave = {
        enabled = true,
        interval = 60, -- 每60秒自动保存
        notify = false, -- 不显示保存通知
      },
      -- 保存更多内容
      extensions = {
        -- 移除 astronvim 扩展，使用默认扩展
      },
      -- 配置要保存的内容
      buf_filter = function(bufnr)
        local buftype = vim.bo[bufnr].buftype
        local filetype = vim.bo[bufnr].filetype
        -- 保存普通文件和特定的窗口类型
        if buftype == "" then
          return true
        end
        -- 只保存 neo-tree 窗口，不保存 outline 或 aerial
        if filetype == "neo-tree" then
          return true
        end
        -- 排除 aerial 窗口
        if filetype == "aerial" then
          return false
        end
        return false
      end,
    },
  },
  
  -- 增强的会话管理按键
  {
    "AstroNvim/astrocore",
    opts = {
      mappings = {
        n = {
          -- 会话管理快捷键
          ["<Leader>ss"] = { "<Cmd>SessionSave<CR>", desc = "Save session" },
          ["<Leader>sl"] = { "<Cmd>SessionLoad<CR>", desc = "Load session" },
          ["<Leader>sd"] = { "<Cmd>SessionDelete<CR>", desc = "Delete session" },
          ["<Leader>sf"] = { "<Cmd>Telescope resession<CR>", desc = "Find sessions" },
          ["<Leader>s."] = { 
            function() require("resession").load(vim.fn.getcwd(), { dir = "dirsession" }) end, 
            desc = "Load current directory session" 
          },
          ["<Leader>sS"] = { 
            function() require("resession").save(vim.fn.getcwd(), { dir = "dirsession" }) end, 
            desc = "Save current directory session" 
          },
        },
      },
      -- 自动命令
      autocmds = {
        -- 自动保存和加载会话
        session_autosave = {
          {
            event = "VimLeavePre",
            desc = "Save session on exit",
            callback = function()
              require("resession").save(vim.fn.getcwd(), { dir = "dirsession", notify = false })
            end,
          },
          {
            event = "VimEnter",
            desc = "Restore session on enter",
            callback = function()
              -- 只在没有传入文件参数时恢复会话
              if vim.fn.argc() == 0 then
                vim.schedule(function()
                  require("resession").load(
                    vim.fn.getcwd(),
                    { dir = "dirsession", silence_errors = true }
                  )
                end)
              end
            end,
          },
        },
      },
    },
  },
  
  -- 配置 neo-tree 恢复
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      window = {
        position = "left",
        width = 30,
        -- 确保 neo-tree 可以被会话保存
        mappings = {
          ["<space>"] = false, -- 禁用空格键避免冲突
        },
      },
    },
  },
}