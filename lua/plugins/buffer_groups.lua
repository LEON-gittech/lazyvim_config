return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("telescope").load_extension("buffer_groups")
  end,
  keys = {
    {
      "<leader>bg",
      function() require("telescope").extensions.buffer_groups.buffer_groups() end,
      desc = "Buffer Groups",
    },
    {
      "<leader>bG",
      function() require("telescope").extensions.buffer_groups.manage_groups() end,
      desc = "Manage Groups",
    },
    {
      "<leader>bga",
      function()
        local buffer_groups = require("utils.buffer_groups")
        local groups = buffer_groups.list_groups()
        
        if #groups == 0 then
          vim.ui.input({ prompt = "Create new group: " }, function(group_name)
            if group_name and group_name ~= "" then
              buffer_groups.create_group(group_name)
              buffer_groups.add_buffer_to_group(group_name)
            end
          end)
        else
          local choices = vim.list_extend({ "Create new group..." }, groups)
          vim.ui.select(choices, { prompt = "Add to group: " }, function(choice)
            if not choice then return end
            
            if choice == "Create new group..." then
              vim.ui.input({ prompt = "New group name: " }, function(group_name)
                if group_name and group_name ~= "" then
                  buffer_groups.create_group(group_name)
                  buffer_groups.add_buffer_to_group(group_name)
                end
              end)
            else
              buffer_groups.add_buffer_to_group(choice)
            end
          end)
        end
      end,
      desc = "Add buffer to group",
    },
    {
      "<leader>bgr",
      function()
        local buffer_groups = require("utils.buffer_groups")
        local groups = buffer_groups.get_buffer_groups()
        
        if #groups == 0 then
          vim.notify("Current buffer not in any group", vim.log.levels.INFO)
        elseif #groups == 1 then
          buffer_groups.remove_buffer_from_group(groups[1])
        else
          vim.ui.select(groups, { prompt = "Remove from group: " }, function(choice)
            if choice then
              buffer_groups.remove_buffer_from_group(choice)
            end
          end)
        end
      end,
      desc = "Remove buffer from group",
    },
    {
      "<leader>bgv",
      function() require("telescope").extensions.buffer_groups.group_buffers() end,
      desc = "View group buffers",
    },
    {
      "<leader>bgc",
      function()
        vim.ui.input({ prompt = "New group name: " }, function(group_name)
          if group_name and group_name ~= "" then
            require("utils.buffer_groups").create_group(group_name)
          end
        end)
      end,
      desc = "Create buffer group",
    },
    {
      "<leader>bgf",
      function() require("telescope").extensions.buffer_groups.filter_by_group() end,
      desc = "Filter buffers by group",
    },
  },
}