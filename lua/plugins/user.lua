-- You can also add or configure plugins by creating files in this `plugins/` folder
-- Here are some custom plugins:

---@type LazySpec
return {
  -- AI 辅助编程
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    lazy = false,
    version = false,
    opts = {
      -- 你的 AI 配置
    },
    build = "make",
    dependencies = {
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },
  },

  -- 代码导航增强
  {
    "nvim-telescope/telescope-file-browser.nvim",
    dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
    config = function()
      require("telescope").load_extension("file_browser")
    end,
    keys = {
      { "<leader>fb", "<cmd>Telescope file_browser<cr>", desc = "File Browser" },
    },
  },
  {
    "Wansmer/symbol-usage.nvim",
    event = "BufReadPre",
    config = function()
      require("symbol-usage").setup()
    end,
  },

  -- 项目管理增强已移至 session.lua

  -- 性能优化
  {
    "hinell/lsp-timeout.nvim",
    dependencies = { "neovim/nvim-lspconfig" },
    init = function()
      vim.g.lspTimeoutConfig = {
        stopTimeout = 1000 * 60 * 5, -- 5 分钟后停止
        startTimeout = 1000 * 10,    -- 10 秒后启动
        silent = false,
        filetypes = {
          ignore = { "markdown", "text" },
        },
      }
    end,
  },

  -- Remote development
  {
    "amitds1997/remote-nvim.nvim",
    version = "*", -- Pin to GitHub releases
    dependencies = {
      "nvim-lua/plenary.nvim", -- For standard functions
      "MunifTanjim/nui.nvim", -- To build the plugin UI
      "nvim-telescope/telescope.nvim", -- For picking b/w different remote methods
    },
    config = true,
  },
}