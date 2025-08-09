---@type LazySpec
return {
  "nosduco/remote-sshfs.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim",
  },
  opts = {},
  config = function(_, opts)
    require("remote-sshfs").setup(opts)
    require("telescope").load_extension("remote-sshfs")
  end,
  keys = {
    { "<leader>Rc", "<cmd>RemoteSSHFSConnect<cr>", desc = "Connect to remote host" },
    { "<leader>Rd", "<cmd>RemoteSSHFSDisconnect<cr>", desc = "Disconnect from remote host" },
    { "<leader>Re", "<cmd>RemoteSSHFSEdit<cr>", desc = "Edit remote file" },
    { "<leader>Rf", "<cmd>RemoteSSHFSFindFiles<cr>", desc = "Find files on remote host" },
    { "<leader>Rg", "<cmd>RemoteSSHFSLiveGrep<cr>", desc = "Live grep on remote host" },
  },
}