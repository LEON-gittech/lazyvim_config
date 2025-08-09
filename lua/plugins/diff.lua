-- Diff utilities plugin configuration
return {
  "AstroNvim/astrocore",
  opts = function(_, opts)
    local maps = opts.mappings
    maps.n["<Leader>D"] = { desc = "Diff" }
    maps.n["<Leader>Df"] = { 
      function() require("utils.diff").diff_with_file() end, 
      desc = "Diff with file" 
    }
    maps.n["<Leader>Dc"] = { 
      function() require("utils.diff").diff_with_clipboard() end, 
      desc = "Diff with clipboard" 
    }
    maps.n["<Leader>Db"] = { 
      function() require("utils.diff").diff_with_buffer() end, 
      desc = "Diff with buffer" 
    }
    maps.n["<Leader>Dg"] = { 
      function() require("utils.diff").diff_with_git() end, 
      desc = "Diff with git (HEAD)" 
    }
    maps.n["<Leader>Dq"] = { 
      function() require("utils.diff").diff_close() end, 
      desc = "Close diff" 
    }
    maps.n["<Leader>Dt"] = { 
      function() require("utils.diff").diff_toggle() end, 
      desc = "Toggle diff mode" 
    }
    
    -- Additional diffview mappings if you have it
    maps.n["<Leader>Dv"] = { desc = "Diffview" }
    maps.n["<Leader>Dvo"] = { "<cmd>DiffviewOpen<cr>", desc = "Open diffview" }
    maps.n["<Leader>Dvc"] = { "<cmd>DiffviewClose<cr>", desc = "Close diffview" }
    maps.n["<Leader>Dvh"] = { "<cmd>DiffviewFileHistory %<cr>", desc = "File history" }
    maps.n["<Leader>DvH"] = { "<cmd>DiffviewFileHistory<cr>", desc = "Branch history" }
    
    -- Quick diff mappings (when in diff mode)
    maps.n["]c"] = { desc = "Next diff change", cond = function() return vim.wo.diff end }
    maps.n["[c"] = { desc = "Previous diff change", cond = function() return vim.wo.diff end }
    
    -- User commands
    if not opts.commands then opts.commands = {} end
    
    opts.commands.DiffWithFile = {
      function() require("utils.diff").diff_with_file() end,
      desc = "Diff current buffer with a file",
    }
    
    opts.commands.DiffWithClipboard = {
      function() require("utils.diff").diff_with_clipboard() end,
      desc = "Diff current buffer with clipboard",
    }
    
    opts.commands.DiffWithBuffer = {
      function() require("utils.diff").diff_with_buffer() end,
      desc = "Diff current buffer with another buffer",
    }
    
    opts.commands.DiffWithGit = {
      function() require("utils.diff").diff_with_git() end,
      desc = "Diff current buffer with git HEAD",
    }
    
    opts.commands.DiffClose = {
      function() require("utils.diff").diff_close() end,
      desc = "Close all diff windows",
    }
    
    opts.commands.DiffToggle = {
      function() require("utils.diff").diff_toggle() end,
      desc = "Toggle diff mode for current window",
    }
    
    return opts
  end,
}