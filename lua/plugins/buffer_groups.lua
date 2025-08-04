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
      "<leader>G",
      function() require("telescope").extensions.buffer_groups.buffer_groups() end,
      desc = "Buffer Groups",
    },
    {
      "<leader>GM",
      function() require("telescope").extensions.buffer_groups.manage_groups() end,
      desc = "Manage Groups",
    },
    {
      "<leader>Ga",
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
      "<leader>Gr",
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
      "<leader>Gv",
      function() require("telescope").extensions.buffer_groups.group_buffers() end,
      desc = "View group buffers",
    },
    {
      "<leader>Gc",
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
      "<leader>Gf",
      function() require("telescope").extensions.buffer_groups.filter_by_group() end,
      desc = "Filter buffers by group",
    },
    {
      "<leader>Gs",
      function()
        local buffer_groups = require("utils.buffer_groups")
        local groups = buffer_groups.list_groups()
        
        if #groups == 0 then
          vim.notify("No buffer groups found", vim.log.levels.INFO)
          return
        end
        
        vim.ui.select(groups, { prompt = "Select group to open: " }, function(group_name)
          if not group_name then return end
          
          local buffers = buffer_groups.get_group_buffers(group_name)
          if #buffers > 0 then
            vim.api.nvim_set_current_buf(buffers[1])
            vim.notify("Opened first buffer in group: " .. group_name, vim.log.levels.INFO)
          else
            vim.notify("No buffers in group: " .. group_name, vim.log.levels.WARN)
          end
        end)
      end,
      desc = "Select group and open first buffer",
    },
    {
      "<leader>Gb",
      function()
        local buffer_groups = require("utils.buffer_groups")
        local current_buf = vim.api.nvim_get_current_buf()
        local groups = buffer_groups.get_buffer_groups(current_buf)
        
        if #groups == 0 then
          vim.notify("Current buffer not in any group", vim.log.levels.INFO)
          return
        end
        
        -- If buffer is in multiple groups, let user choose
        local group_name = groups[1]
        if #groups > 1 then
          vim.ui.select(groups, { prompt = "Select group: " }, function(choice)
            if choice then
              group_name = choice
            else
              return
            end
          end)
        end
        
        -- Get buffers in the selected group
        local buffers = buffer_groups.get_group_buffers(group_name)
        if #buffers == 0 then
          vim.notify("No buffers in group: " .. group_name, vim.log.levels.WARN)
          return
        end
        
        -- Create buffer list with names for selection
        local buffer_list = {}
        for _, bufnr in ipairs(buffers) do
          local name = vim.api.nvim_buf_get_name(bufnr)
          local display_name = name ~= "" and vim.fn.fnamemodify(name, ":t") or "[No Name]"
          table.insert(buffer_list, {
            bufnr = bufnr,
            display = display_name,
            path = name
          })
        end
        
        -- Show selection menu
        vim.ui.select(buffer_list, {
          prompt = "Select buffer in group '" .. group_name .. "': ",
          format_item = function(item)
            return item.display
          end
        }, function(choice)
          if choice then
            vim.api.nvim_set_current_buf(choice.bufnr)
          end
        end)
      end,
      desc = "Select buffer in current group",
    },
  },
}