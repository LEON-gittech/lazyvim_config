local M = {}

M.on_save = function()
  local buffer_groups = require("utils.buffer_groups")
  -- Clean up invalid buffers before saving
  buffer_groups.cleanup_invalid_buffers()
  
  -- Convert bufnr to paths for session saving
  local groups_with_paths = {}
  for group_name, group_data in pairs(buffer_groups.groups) do
    local group_copy = vim.deepcopy(group_data)
    local paths = {}
    
    -- Convert bufnr to paths
    for _, bufnr in ipairs(group_data.buffers) do
      if vim.api.nvim_buf_is_valid(bufnr) then
        local path = vim.api.nvim_buf_get_name(bufnr)
        if path and path ~= "" then
          table.insert(paths, path)
        end
      end
    end
    
    group_copy.buffer_paths = paths
    group_copy.buffers = nil -- Don't save bufnr
    groups_with_paths[group_name] = group_copy
  end
  
  -- Return the groups data to be saved with the session
  return {
    groups = groups_with_paths,
    color_map = buffer_groups.group_color_map
  }
end

M.on_load = function(data)
  if not data then return end
  
  local buffer_groups = require("utils.buffer_groups")
  
  -- Clear existing groups
  buffer_groups.groups = {}
  
  -- Load the saved groups and color map
  if data.groups then
    for group_name, group_data in pairs(data.groups) do
      local buffers = {}
      
      -- Convert paths back to bufnr for currently open buffers
      if group_data.buffer_paths then
        for _, path in ipairs(group_data.buffer_paths) do
          -- Find existing buffer with this path
          for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_valid(bufnr) then
              local buf_path = vim.api.nvim_buf_get_name(bufnr)
              if buf_path == path then
                table.insert(buffers, bufnr)
                break
              end
            end
          end
        end
      end
      
      buffer_groups.groups[group_name] = {
        name = group_data.name,
        buffers = buffers,
        created = group_data.created,
        buffer_paths = group_data.buffer_paths or {} -- Keep paths for later mapping
      }
    end
    
    buffer_groups.group_color_map = data.color_map or {}
    
    -- Save to the JSON file as well
    buffer_groups.save_groups()
    
    -- Update buffer mappings
    buffer_groups.update_buffer_mappings()
    
    -- Trigger UI update
    vim.api.nvim_exec_autocmds("User", { pattern = "BufferGroupsUpdate" })
  end
end

M.config = function(opts)
  -- Extension configuration if needed
end

return M