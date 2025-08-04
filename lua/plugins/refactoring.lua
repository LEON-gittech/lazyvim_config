-- Refactoring plugin configuration
-- This configures refactoring mappings under <Leader>r

return {
  "refactoring.nvim",
  dependencies = {
    { "nvim-lua/plenary.nvim" },
    { "nvim-treesitter/nvim-treesitter" },
  },
  opts = function()
    return {
      -- Disable default mappings to prevent conflicts
      prompt_func_return_type = {
        go = false,
        java = false,
        cpp = false,
        c = false,
        h = false,
        hpp = false,
        cxx = false,
      },
      prompt_func_param_type = {
        go = false,
        java = false,
        cpp = false,
        c = false,
        h = false,
        hpp = false,
        cxx = false,
      },
    }
  end,
  config = function(_, opts)
    require("refactoring").setup(opts)
    
    -- Manually set up keymaps with <Leader>r for refactoring operations
    local refactoring = require("refactoring")
    vim.keymap.set("x", "<Leader>re", function() refactoring.refactor("Extract Function") end, { desc = "Extract Function" })
    vim.keymap.set("x", "<Leader>rf", function() refactoring.refactor("Extract Function To File") end, { desc = "Extract Function To File" })
    vim.keymap.set("x", "<Leader>rv", function() refactoring.refactor("Extract Variable") end, { desc = "Extract Variable" })
    vim.keymap.set("n", "<Leader>ri", function() refactoring.refactor("Inline Variable") end, { desc = "Inline Variable" })
    vim.keymap.set({ "n", "x" }, "<Leader>rib", function() refactoring.refactor("Inline func") end, { desc = "Inline func" })
    vim.keymap.set("n", "<Leader>rb", function() refactoring.refactor("Extract Block") end, { desc = "Extract Block" })
    vim.keymap.set("n", "<Leader>rbf", function() refactoring.refactor("Extract Block To File") end, { desc = "Extract Block To File" })
    
    -- Debug mappings
    vim.keymap.set({ "x", "n" }, "<Leader>rp", function() refactoring.debug.printf({ below = false }) end, { desc = "Debug: Print Function" })
    vim.keymap.set({ "x", "n" }, "<Leader>rd", function() refactoring.debug.print_var() end, { desc = "Debug: Print Variable" })
    vim.keymap.set("n", "<Leader>rc", function() refactoring.debug.cleanup() end, { desc = "Debug: Clean Up" })
    
    -- Rename operations
    vim.keymap.set("n", "<Leader>rn", function() vim.lsp.buf.rename() end, { desc = "Rename variable" })
    vim.keymap.set("n", "<Leader>rF", "<cmd>lua require('astrocore.utils').rename_file()<cr>", { desc = "Rename file" })
  end,
}