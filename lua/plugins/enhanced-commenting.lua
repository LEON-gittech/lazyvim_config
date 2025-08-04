-- Enhanced commenting configuration with treesitter-aware comment strings
-- Properly handles embedded languages like JSX, Vue templates, etc.

return {
  -- Re-enable and configure nvim-ts-context-commentstring for Neovim 0.11+
  {
    "JoosepAlviste/nvim-ts-context-commentstring",
    lazy = false, -- Load immediately for proper setup
    init = function()
      -- Skip backwards compatibility routines
      vim.g.skip_ts_context_commentstring_module = true
    end,
    opts = {
      enable_autocmd = false, -- We'll use the native commenting integration
    },
  },

  -- Configure treesitter to work with context commentstring
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- Ensure we have the necessary language parsers for common embedded scenarios
      opts.ensure_installed = vim.list_extend(opts.ensure_installed or {}, {
        "javascript",
        "typescript",
        "tsx",
        "html",
        "css",
        "vue",
        "svelte",
        "astro",
        "embedded_template",
      })
      
      -- Enable context_commentstring module
      if not opts.context_commentstring then
        opts.context_commentstring = {}
      end
      opts.context_commentstring.enable = true
      opts.context_commentstring.enable_autocmd = false
      
      return opts
    end,
  },

  -- Integrate with native commenting in Neovim 0.10+
  {
    "AstroNvim/astrocore",
    opts = function(_, opts)
      -- Add pre-hook for native commenting to use ts-context-commentstring
      if not opts.autocmds then opts.autocmds = {} end
      
      opts.autocmds.enhanced_commenting = {
        {
          event = "FileType",
          desc = "Setup enhanced commenting with treesitter context",
          callback = function()
            -- Get comment string from treesitter context
            local get_option = vim.filetype.get_option
            vim.filetype.get_option = function(filetype, option)
              if option == "commentstring" then
                local ts_context_avail, ts_context = pcall(require, "ts_context_commentstring.internal")
                if ts_context_avail then
                  return ts_context.calculate_commentstring() or get_option(filetype, option)
                end
              end
              return get_option(filetype, option)
            end
          end,
        },
      }
      
      -- Add visual feedback for comment type
      if not opts.mappings then opts.mappings = {} end
      if not opts.mappings.n then opts.mappings.n = {} end
      
      opts.mappings.n["<Leader>uc"] = {
        function()
          local ts_context_avail, ts_context = pcall(require, "ts_context_commentstring.internal")
          if ts_context_avail then
            local commentstring = ts_context.calculate_commentstring() or vim.bo.commentstring
            vim.notify("Current comment string: " .. commentstring, vim.log.levels.INFO, { title = "Comment Context" })
          else
            vim.notify("Context commentstring not available", vim.log.levels.WARN)
          end
        end,
        desc = "Show current comment string",
      }
      
      return opts
    end,
  },

  -- Add support for more embedded language scenarios
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      -- Additional queries for better comment detection
      autotag = {
        enable = true,
        enable_rename = true,
        enable_close = true,
        enable_close_on_slash = true,
      },
    },
  },
}