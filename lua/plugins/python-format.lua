-- Disable isort for Python files

---@type LazySpec
return {
  -- Override conform.nvim settings from AstroCommunity Python pack
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      -- Remove isort from Python formatters
      if opts.formatters_by_ft and opts.formatters_by_ft.python then
        -- Only keep black, remove isort
        opts.formatters_by_ft.python = { "black" }
      end
      return opts
    end,
  },
  
  -- Also disable isort in AstroLSP
  {
    "AstroNvim/astrolsp",
    opts = {
      formatting = {
        filter = function(client)
          -- Disable isort formatting
          if client.name == "isort" then
            return false
          end
          return true
        end,
      },
    },
  },
}