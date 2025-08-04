-- AstroCore provides a central place to modify mappings, vim options, autocommands, and more!
-- Configuration documentation can be found with `:h astrocore`
-- NOTE: We highly recommend setting up the Lua Language Server (`:LspInstall lua_ls`)
--       as this provides autocomplete and documentation while editing

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    -- Configure core features of AstroNvim
    features = {
      large_buf = { size = 1024 * 256, lines = 10000 }, -- set global limits for large files for disabling features like treesitter
      autopairs = true, -- enable autopairs at start
      cmp = true, -- enable completion at start
      diagnostics = { virtual_text = true, virtual_lines = false }, -- diagnostic settings on startup
      highlighturl = true, -- highlight URLs at start
      notifications = true, -- enable notifications at start
    },
    -- Diagnostics configuration (for vim.diagnostics.config({...})) when diagnostics are on
    diagnostics = {
      virtual_text = true,
      underline = true,
    },
    -- passed to `vim.filetype.add`
    filetypes = {
      -- see `:h vim.filetype.add` for usage
      extension = {
        foo = "fooscript",
      },
      filename = {
        [".foorc"] = "fooscript",
      },
      pattern = {
        [".*/etc/foo/.*"] = "fooscript",
      },
    },
    -- vim options can be configured here
    options = {
      opt = { -- vim.opt.<key>
        relativenumber = true, -- sets vim.opt.relativenumber
        number = true, -- sets vim.opt.number
        spell = false, -- sets vim.opt.spell
        signcolumn = "yes", -- sets vim.opt.signcolumn to yes
        wrap = true, -- sets vim.opt.wrap
        linebreak = true, -- 在单词边界处换行，而不是在字符中间
        textwidth = 0, -- 禁用硬换行（不插入实际的换行符）
        showbreak = "↪ ", -- 在换行处显示的符号
      },
      g = { -- vim.g.<key>
        -- configure global vim variables (vim.g)
        -- NOTE: `mapleader` and `maplocalleader` must be set in the AstroNvim opts or before `lazy.setup`
        -- This can be found in the `lua/lazy_setup.lua` file
      },
    },
    -- Mappings can be configured through AstroCore as well.
    -- NOTE: keycodes follow the casing in the vimdocs. For example, `<Leader>` must be capitalized
    mappings = {
      -- first key is the mode
      n = {
        -- second key is the lefthand side of the map

        -- navigate buffer tabs
        ["]b"] = { function() require("astrocore.buffer").nav(vim.v.count1) end, desc = "Next buffer" },
        ["[b"] = { function() require("astrocore.buffer").nav(-vim.v.count1) end, desc = "Previous buffer" },

        -- navigate between classes
        ["]c"] = { function() require("utils.aerial_nav").goto_next_class() end, desc = "Next class" },
        ["[c"] = { function() require("utils.aerial_nav").goto_prev_class() end, desc = "Previous class" },

        -- Tab movement with wrap-around
        ["<t"] = { 
          function()
            local current_tab = vim.api.nvim_tabpage_get_number(0)
            local total_tabs = #vim.api.nvim_list_tabpages()
            if total_tabs > 1 then
              if current_tab == 1 then
                vim.cmd("tabmove")  -- Move to end
              else
                vim.cmd("-tabmove")  -- Move left
              end
            end
          end,
          desc = "Move tab left"
        },
        [">t"] = {
          function()
            local current_tab = vim.api.nvim_tabpage_get_number(0)
            local total_tabs = #vim.api.nvim_list_tabpages()
            if total_tabs > 1 then
              if current_tab == total_tabs then
                vim.cmd("tabmove 0")  -- Move to start
              else
                vim.cmd("+tabmove")  -- Move right
              end
            end
          end,
          desc = "Move tab right"
        },

        -- show/preview with Glance (s prefix)
        ["sD"] = { desc = "Show definitions (Glance)" },
        ["sR"] = { desc = "Show references (Glance)" },

        -- window navigation
        ["<C-h>"] = { "<C-w>h", desc = "Move to left window" },
        ["<C-j>"] = { "<C-w>j", desc = "Move to below window" },
        ["<C-k>"] = { "<C-w>k", desc = "Move to above window" },
        ["<C-l>"] = { "<C-w>l", desc = "Move to right window" },

        -- 软换行导航（使用 gj/gk 在显示行间移动）
        ["j"] = { "v:count == 0 ? 'gj' : 'j'", expr = true, desc = "Move down by display lines" },
        ["k"] = { "v:count == 0 ? 'gk' : 'k'", expr = true, desc = "Move up by display lines" },

        -- Write buffer
        ["<Leader>w"] = { "<cmd>w<cr>", desc = "Write buffer" },
        
        -- 窗口分割
        ["<Leader>Wv"] = { "<cmd>vsplit<cr>", desc = "Vertical split" },
        ["<Leader>Ws"] = { "<cmd>split<cr>", desc = "Horizontal split" },
        ["<Leader>Wc"] = { "<cmd>close<cr>", desc = "Close window" },
        ["<Leader>Wo"] = { "<cmd>only<cr>", desc = "Close other windows" },
        
        -- 窗口大小调整
        ["<Leader>W="] = { "<C-w>=", desc = "Equal window sizes" },
        ["<Leader>W>"] = { "10<C-w>>", desc = "Increase window width" },
        ["<Leader>W<"] = { "10<C-w><", desc = "Decrease window width" },
        ["<Leader>W+"] = { "5<C-w>+", desc = "Increase window height" },
        ["<Leader>W-"] = { "5<C-w>-", desc = "Decrease window height" },
        
        -- 使用方向键调整窗口大小
        ["<C-Up>"] = { "<cmd>resize +2<cr>", desc = "Increase window height" },
        ["<C-Down>"] = { "<cmd>resize -2<cr>", desc = "Decrease window height" },
        ["<C-Left>"] = { "<cmd>vertical resize -2<cr>", desc = "Decrease window width" },
        ["<C-Right>"] = { "<cmd>vertical resize +2<cr>", desc = "Increase window width" },

        -- mappings seen under group name "Buffer"
        ["<Leader>bd"] = {
          function()
            require("astroui.status.heirline").buffer_picker(
              function(bufnr) require("astrocore.buffer").close(bufnr) end
            )
          end,
          desc = "Close buffer from tabline",
        },
        
        -- Buffer 导航增强
        ["<Leader>bb"] = { "<cmd>Telescope buffers<cr>", desc = "Browse buffers with Telescope" },
        ["<Leader>bp"] = { 
          function() 
            require("astroui.status.heirline").buffer_picker(
              function(bufnr) vim.api.nvim_set_current_buf(bufnr) end
            ) 
          end, 
          desc = "Pick buffer to switch" 
        },
        ["<Tab>"] = { function() require("astrocore.buffer").nav(1) end, desc = "Next buffer" },
        ["<S-Tab>"] = { function() require("astrocore.buffer").nav(-1) end, desc = "Previous buffer" },
        
        -- Buffer 排序
        ["<Leader>bsa"] = { 
          function() 
            require("astrocore.buffer").sort(function(a, b)
              -- 按文件名字典序排序
              local a_name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(a), ":t")
              local b_name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(b), ":t")
              return a_name < b_name
            end)
            -- 记录排序方法
            vim.t.buffer_sort_method = "alphabetical"
            vim.g.buffer_sort_method = "alphabetical"
          end, 
          desc = "Sort buffers alphabetically" 
        },
        ["<Leader>bsf"] = { 
          function() 
            require("astrocore.buffer").sort(function(a, b)
              -- 按首字母分组排序
              local a_name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(a), ":t"):lower()
              local b_name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(b), ":t"):lower()
              local a_first = a_name:sub(1,1)
              local b_first = b_name:sub(1,1)
              if a_first == b_first then
                return a_name < b_name
              else
                return a_first < b_first
              end
            end)
            -- 记录排序方法
            vim.t.buffer_sort_method = "first_letter"
            vim.g.buffer_sort_method = "first_letter"
          end, 
          desc = "Sort buffers by first letter" 
        },
        ["<Leader>bsp"] = {
          function()
            require("astrocore.buffer").sort(function(a, b)
              -- 按完整路径排序
              local a_path = vim.api.nvim_buf_get_name(a)
              local b_path = vim.api.nvim_buf_get_name(b)
              return a_path < b_path
            end)
            -- 记录排序方法
            vim.t.buffer_sort_method = "full_path"
            vim.g.buffer_sort_method = "full_path"
          end,
          desc = "Sort buffers by full path"
        },
        ["<Leader>bsm"] = {
          function()
            -- 按修改时间排序（最近修改的在前）
            require("astrocore.buffer").sort("modified")
            -- 记录排序方法
            vim.t.buffer_sort_method = "modified"
            vim.g.buffer_sort_method = "modified"
          end,
          desc = "Sort buffers by modified time"
        },

        
        -- Grep 搜索
        ["<Leader>fg"] = { "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
        ["<Leader>fG"] = { "<cmd>Telescope grep_string<cr>", desc = "Grep current word" },
        
        -- Notification (使用 Noice)
        ["<Leader>sn"] = { "<cmd>Noice<cr>", desc = "Show notifications" },

        -- 文件名和路径复制
        ["<Leader>fn"] = { 
          function() 
            local filename = vim.fn.expand("%:t")
            vim.fn.setreg("+", filename)
            vim.notify("Copied: " .. filename)
          end, 
          desc = "Copy file name" 
        },
        ["<Leader>fp"] = { 
          function() 
            local filepath = vim.fn.expand("%:p")
            vim.fn.setreg("+", filepath)
            vim.notify("Copied: " .. filepath)
          end, 
          desc = "Copy full path" 
        },
        ["<Leader>fr"] = { 
          function() 
            local relative_path = vim.fn.expand("%")
            vim.fn.setreg("+", relative_path)
            vim.notify("Copied: " .. relative_path)
          end, 
          desc = "Copy relative path" 
        },

        -- LSP 增强映射（使用智能导航和 Telescope）
        ["gR"] = { 
          function() require("utils.lsp_navigation").smart_goto_references() end, 
          desc = "Smart find references" 
        },
        ["gD"] = { "<cmd>Telescope lsp_definitions<cr>", desc = "Find definitions (Telescope)" },
        
        -- gi 现在可以用于其他功能（如回到插入模式的最后位置）
        ["gi"] = { "`^", desc = "Go to last insert position" },
        
        -- Leader + l 的 LSP 菜单
        ["<Leader>lR"] = { "<cmd>Telescope lsp_references<cr>", desc = "Find references" },
        ["<Leader>lD"] = { "<cmd>Telescope lsp_definitions<cr>", desc = "Find definitions" },
        ["<Leader>lI"] = { "<cmd>Telescope lsp_implementations<cr>", desc = "Find implementations" },
        ["<Leader>ls"] = { "<cmd>Telescope lsp_document_symbols<cr>", desc = "Document symbols" },
        ["<Leader>lS"] = { "<cmd>Telescope lsp_workspace_symbols<cr>", desc = "Workspace symbols" },

        -- tables with just a `desc` key will be registered with which-key if it's installed
        -- this is useful for naming menus
        ["<Leader>b"] = { desc = "Buffers" },
        ["<Leader>bs"] = { desc = "Sort buffers" },
        ["<Leader>f"] = { desc = "File" },
        ["<Leader>l"] = { desc = "LSP" },
        ["<Leader>r"] = { desc = "Refactor" },
        ["<Leader>W"] = { desc = "Windows" },

        -- setting a mapping to false will disable it
        -- ["<C-S>"] = false,
        
        -- Restore normal < and > behavior for indentation
        ["<"] = { "<<", desc = "Indent line left" },
        [">"] = { ">>", desc = "Indent line right" },
      },
      -- Visual mode mappings
      v = {
        -- Restore < and > for visual mode indentation
        ["<"] = { "<gv", desc = "Indent left and reselect" },
        [">"] = { ">gv", desc = "Indent right and reselect" },
      },
      -- Visual block mode mappings
      x = {
        -- Restore < and > for visual block mode indentation
        ["<"] = { "<gv", desc = "Indent left and reselect" },
        [">"] = { ">gv", desc = "Indent right and reselect" },
      },
    },
  },
}
