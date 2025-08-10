return {
  "folke/noice.nvim",
  opts = function(_, opts)
    -- Merge with existing opts from AstroCommunity
    opts = opts or {}
    
    -- Initialize routes table if it doesn't exist
    opts.routes = opts.routes or {}
    
    -- Filter out telescope-related messages
    -- Pattern 1: Messages that start with "telescope"
    table.insert(opts.routes, {
      filter = {
        event = "msg_show",
        any = {
          { find = "^telescope" },
          { find = "^telescope {" },
          { find = "^telescope }" },
        },
      },
      opts = { skip = true },
    })
    
    -- Pattern 2: Messages containing just "}"
    table.insert(opts.routes, {
      filter = {
        event = "msg_show",
        find = "^}$",
      },
      opts = { skip = true },
    })
    
    -- Pattern 3: Messages that are telescope with curly braces
    table.insert(opts.routes, {
      filter = {
        event = "msg_show",
        find = "telescope%s*{",
      },
      opts = { skip = true },
    })
    
    -- Pattern 4: Messages that end with telescope }
    table.insert(opts.routes, {
      filter = {
        event = "msg_show",
        find = "telescope%s*}",
      },
      opts = { skip = true },
    })
    
    -- Pattern 5: Hide empty echo messages
    table.insert(opts.routes, {
      filter = {
        event = "msg_show",
        kind = "echo",
        find = "^%s*$",
      },
      opts = { skip = true },
    })
    
    -- Pattern 6: Hide search count messages (optional, uncomment if you want to hide them)
    -- table.insert(opts.routes, {
    --   filter = {
    --     event = "msg_show",
    --     kind = "search_count",
    --   },
    --   opts = { skip = true },
    -- })
    
    -- Pattern 7: More aggressive filtering for any line with just special characters
    table.insert(opts.routes, {
      filter = {
        event = "msg_show",
        find = "^[{}%[%]()]+$",
      },
      opts = { skip = true },
    })
    
    -- Configure messages view to be less intrusive
    opts.messages = vim.tbl_deep_extend("force", opts.messages or {}, {
      enabled = true,
      view = "mini",
      view_error = "mini",
      view_warn = "mini",
      view_history = "messages",
      view_search = false,
    })
    
    -- Configure presets
    opts.presets = vim.tbl_deep_extend("force", opts.presets or {}, {
      bottom_search = true,
      command_palette = true,
      long_message_to_split = true,
      inc_rename = false,
      lsp_doc_border = false,
    })
    
    -- Configure notify settings
    opts.notify = vim.tbl_deep_extend("force", opts.notify or {}, {
      enabled = true,
      view = "mini",
    })
    
    return opts
  end,
}