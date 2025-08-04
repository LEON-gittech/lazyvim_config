-- Auto-close and auto-rename HTML/JSX tags
return {
  "windwp/nvim-ts-autotag",
  event = "InsertEnter",
  dependencies = "nvim-treesitter/nvim-treesitter",
  config = function()
    require("nvim-ts-autotag").setup({
      opts = {
        -- Defaults:
        enable_close = true, -- Auto close tags
        enable_rename = true, -- Auto rename pairs of tags
        enable_close_on_slash = false, -- Auto close on trailing </
      },
      -- Override individual filetype configs
      per_filetype = {
        ["html"] = {
          enable_close = true,
        },
        ["jsx"] = {
          enable_close = true,
        },
        ["tsx"] = {
          enable_close = true,
        },
        ["vue"] = {
          enable_close = true,
        },
        ["svelte"] = {
          enable_close = true,
        },
        ["xml"] = {
          enable_close = true,
        },
      },
    })
  end,
}