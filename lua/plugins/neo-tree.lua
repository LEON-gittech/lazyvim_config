return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      hijack_netrw_behavior = "disabled", -- 禁用自动打开
    },
  },
  config = function(_, opts)
    require("neo-tree").setup(opts)
    
    -- Disable horizontal scrolling in neo-tree windows
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "neo-tree",
      callback = function()
        local buf = vim.api.nvim_get_current_buf()
        -- Disable horizontal scroll wheel events
        vim.keymap.set({"n", "i", "v"}, "<ScrollWheelLeft>", "<nop>", { buffer = buf, silent = true })
        vim.keymap.set({"n", "i", "v"}, "<ScrollWheelRight>", "<nop>", { buffer = buf, silent = true })
        vim.keymap.set({"n", "i", "v"}, "<S-ScrollWheelLeft>", "<nop>", { buffer = buf, silent = true })
        vim.keymap.set({"n", "i", "v"}, "<S-ScrollWheelRight>", "<nop>", { buffer = buf, silent = true })
        vim.keymap.set({"n", "i", "v"}, "<C-ScrollWheelLeft>", "<nop>", { buffer = buf, silent = true })
        vim.keymap.set({"n", "i", "v"}, "<C-ScrollWheelRight>", "<nop>", { buffer = buf, silent = true })
      end,
    })
  end,
}