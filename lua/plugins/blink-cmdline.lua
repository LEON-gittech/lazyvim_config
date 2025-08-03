-- Based on official blink.cmp cmdline documentation
return {
  "saghen/blink.cmp",
  opts = function(_, opts)
    -- Override completion menu to always show (including cmdline)
    opts.completion = vim.tbl_deep_extend("force", opts.completion or {}, {
      menu = {
        auto_show = true, -- This will make it show automatically for ALL modes
      },
    })
    
    -- Configure cmdline specifically
    opts.cmdline = vim.tbl_deep_extend("force", opts.cmdline or {}, {
      enabled = true,
      keymap = {
        -- Use the same keymaps as insert mode
        preset = 'inherit',
        -- Or define specific mappings:
        -- ['<Tab>'] = { 'show', 'select_next' },
        -- ['<S-Tab>'] = { 'select_prev' },
        -- ['<Up>'] = { 'select_prev', 'fallback' },
        -- ['<Down>'] = { 'select_next', 'fallback' },
        -- ['<CR>'] = { 'accept', 'fallback' },
      },
      completion = {
        menu = {
          -- Can also set auto_show here specifically for cmdline
          auto_show = true,
        },
      },
    })
    
    return opts
  end,
}