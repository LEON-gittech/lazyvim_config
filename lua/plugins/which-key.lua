-- Which-key configuration to resolve < and > conflicts
-- This disables which-key's operators preset for < and > to restore normal indentation

return {
  "folke/which-key.nvim",
  opts = {
    -- Disable < and > from operators list
    triggers = {
      { "<auto>", mode = "nxsot" },
    },
    defer = function(ctx)
      -- Defer which-key for < and > to allow normal indentation
      if ctx.keys == "<" or ctx.keys == ">" then
        return true
      end
    end,
  },
}