return {
  "stevearc/aerial.nvim",
  lazy = true,
  cmd = {
    "AerialToggle",
    "AerialOpen",
    "AerialOpenAll",
    "AerialClose",
    "AerialCloseAll",
    "AerialNext",
    "AerialPrev",
    "AerialGo",
    "AerialInfo",
    "AerialNavToggle",
  },
  keys = {
    { "<leader>o", "<cmd>AerialToggle<cr>", desc = "Toggle Aerial" },
    { "<leader>O", "<cmd>AerialNavToggle<cr>", desc = "Toggle Aerial Navigation" },
    { "{", "<cmd>AerialPrev<cr>", desc = "Previous aerial symbol" },
    { "}", "<cmd>AerialNext<cr>", desc = "Next aerial symbol" },
  },
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  opts = {
    backends = { "treesitter", "lsp", "markdown", "man" },
    layout = {
      default_direction = "right",
      placement = "window",
      preserve_equality = false,
      max_width = { 60, 0.3 },
      min_width = 30,
      win_opts = {
        winhl = "Normal:NormalFloat,FloatBorder:NormalFloat,SignColumn:SignColumnSB",
        signcolumn = "yes",
        statuscolumn = " ",
      },
    },
    attach_mode = "window",
    close_automatic_events = {},
    show_guides = true,
    guides = {
      mid_item = "├─",
      last_item = "└─",
      nested_top = "│ ",
      whitespace = "  ",
    },
    filter_kind = false,
    highlight_mode = "split_width",
    highlight_closest = true,
    highlight_on_hover = true,
    highlight_on_jump = 300,
    autojump = false,
    manage_folds = false,
    link_folds_to_tree = false,
    link_tree_to_folds = true,
    nerd_font = "auto",
    on_attach = function(bufnr)
      -- Jump forwards/backwards with '{' and '}'
      vim.keymap.set("n", "{", "<cmd>AerialPrev<CR>", { buffer = bufnr })
      vim.keymap.set("n", "}", "<cmd>AerialNext<CR>", { buffer = bufnr })
    end,
    nav = {
      border = "rounded",
      max_height = 0.9,
      min_height = { 10, 0.1 },
      max_width = 0.5,
      min_width = { 0.2, 20 },
      win_opts = {
        cursorline = true,
        winblend = 10,
      },
      autojump = false,
      preview = false,
      keymaps = {
        ["<CR>"] = "actions.jump",
        ["<2-LeftMouse>"] = "actions.jump",
        ["<C-v>"] = "actions.jump_vsplit",
        ["<C-s>"] = "actions.jump_split",
        ["h"] = "actions.left",
        ["l"] = "actions.right",
        ["<C-c>"] = "actions.close",
      },
    },
    float = {
      border = "rounded",
      relative = "cursor",
      max_height = 0.9,
      height = nil,
      min_height = { 8, 0.1 },
      override = function(conf, source_winid)
        conf.anchor = "NE"
        conf.col = vim.fn.winwidth(source_winid)
        conf.row = 0
        return conf
      end,
    },
    lsp = {
      diagnostics_trigger_update = true,
      update_when_errors = true,
      update_delay = 300,
    },
    treesitter = {
      update_delay = 300,
    },
    markdown = {
      update_delay = 300,
    },
    man = {
      update_delay = 300,
    },
  },
  config = function(_, opts)
    require("aerial").setup(opts)
    
    -- Set up autocmd for aerial buffer
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "aerial",
      callback = function()
        local buf = vim.api.nvim_get_current_buf()
        
        -- Enable double-click to jump (should already work, but ensure it's set)
        vim.keymap.set('n', '<2-LeftMouse>', '<CR>', {
          buffer = buf,
          desc = "Jump to symbol",
          silent = true,
        })
        
        -- Class navigation in aerial window
        vim.keymap.set('n', '[', function()
          -- Move to previous class-like symbol
          local aerial = require('aerial')
          local data = require('aerial.data')
          local current_line = vim.fn.line('.')
          local bufnr = vim.api.nvim_get_current_buf()
          local items = data.get_or_create(0).items
          
          -- Find previous class-like symbol
          local found = nil
          for i = #items, 1, -1 do
            local item = items[i]
            if (item.kind == "Class" or item.kind == "Struct" or 
                item.kind == "Interface" or item.kind == "Enum") and
               item.lnum < current_line then
              found = item
              break
            end
          end
          
          if found then
            aerial.select({index = found.idx})
          end
        end, {
          buffer = buf,
          desc = "Previous class in aerial",
          silent = true,
        })
        
        vim.keymap.set('n', ']', function()
          -- Move to next class-like symbol
          local aerial = require('aerial')
          local data = require('aerial.data')
          local current_line = vim.fn.line('.')
          local bufnr = vim.api.nvim_get_current_buf()
          local items = data.get_or_create(0).items
          
          -- Find next class-like symbol
          local found = nil
          for _, item in ipairs(items) do
            if (item.kind == "Class" or item.kind == "Struct" or 
                item.kind == "Interface" or item.kind == "Enum") and
               item.lnum > current_line then
              found = item
              break
            end
          end
          
          if found then
            aerial.select({index = found.idx})
          end
        end, {
          buffer = buf,
          desc = "Next class in aerial",
          silent = true,
        })
      end,
    })
    
    -- Load telescope extension if available
    local telescope_avail, telescope = pcall(require, "telescope")
    if telescope_avail then
      telescope.load_extension("aerial")
      
      -- Add telescope keymap
      vim.keymap.set('n', '<leader>fs', '<cmd>Telescope aerial<cr>', {
        desc = "Search symbols (Aerial)",
      })
    end
  end,
}