local M = {}

M.on_save = function()
  local buffer_groups = require("utils.buffer_groups")
  -- Clean up invalid buffers before saving
  buffer_groups.cleanup_invalid_buffers()
  
  -- Return the groups data to be saved with the session
  return {
    groups = buffer_groups.groups,
    color_map = buffer_groups.group_color_map
  }
end

M.on_load = function(data)
  if not data then return end
  
  local buffer_groups = require("utils.buffer_groups")
  
  -- Load the saved groups and color map
  if data.groups then
    buffer_groups.groups = data.groups
    buffer_groups.group_color_map = data.color_map or {}
    
    -- Save to the JSON file as well
    buffer_groups.save_groups()
    
    -- Trigger UI update
    vim.api.nvim_exec_autocmds("User", { pattern = "BufferGroupsUpdate" })
  end
end

M.config = function(opts)
  -- Extension configuration if needed
end

return M