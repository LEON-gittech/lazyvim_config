local M = {}

local data_path = vim.fn.stdpath("data") .. "/buffer_groups.json"

M.groups = {}
M.path_to_bufnr_cache = {} -- Cache for mapping paths to bufnr

-- Nice color palette for groups
M.group_colors = {
  { fg = "#e06c75", bg = "#3e4452" }, -- Red
  { fg = "#98c379", bg = "#3e4452" }, -- Green
  { fg = "#61afef", bg = "#3e4452" }, -- Blue
  { fg = "#c678dd", bg = "#3e4452" }, -- Purple
  { fg = "#e5c07b", bg = "#3e4452" }, -- Yellow
  { fg = "#56b6c2", bg = "#3e4452" }, -- Cyan
  { fg = "#d19a66", bg = "#3e4452" }, -- Orange
  { fg = "#ff6c6b", bg = "#3e4452" }, -- Light Red
  { fg = "#98be65", bg = "#3e4452" }, -- Light Green
  { fg = "#51afef", bg = "#3e4452" }, -- Light Blue
  { fg = "#c678dd", bg = "#3e4452" }, -- Magenta
  { fg = "#ecbe7b", bg = "#3e4452" }, -- Light Yellow
  { fg = "#46d9ff", bg = "#3e4452" }, -- Light Cyan
  { fg = "#a9a1e1", bg = "#3e4452" }, -- Light Purple
}

-- Track color assignments
M.group_color_map = {}

-- Track current group context (for telescope-selected groups)
M.current_group_context = nil

function M.set_group_context(group_name)
  M.current_group_context = group_name
end

function M.get_group_context()
  return M.current_group_context
end

function M.clear_group_context()
  M.current_group_context = nil
end


local function ensure_data_dir()
  local dir = vim.fn.fnamemodify(data_path, ":h")
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end
end

function M.get_group_color(group_name)
  -- Return existing color if already assigned
  if M.group_color_map[group_name] then
    return M.group_color_map[group_name]
  end
  
  -- Find next available color
  local used_indices = {}
  for _, idx in pairs(M.group_color_map) do
    used_indices[idx] = true
  end
  
  -- Assign first unused color
  for i, _ in ipairs(M.group_colors) do
    if not used_indices[i] then
      M.group_color_map[group_name] = i
      return i
    end
  end
  
  -- If all colors are used, use a hash-based assignment
  local hash = 0
  for i = 1, #group_name do
    hash = (hash * 31 + string.byte(group_name, i)) % #M.group_colors
  end
  M.group_color_map[group_name] = hash + 1
  return hash + 1
end

function M.save_groups()
  ensure_data_dir()
  local file = io.open(data_path, "w")
  if file then
    -- Convert bufnr to paths for persistence
    local groups_with_paths = {}
    for group_name, group_data in pairs(M.groups) do
      local group_copy = vim.deepcopy(group_data)
      local paths = {}
      for _, bufnr in ipairs(group_data.buffers) do
        if vim.api.nvim_buf_is_valid(bufnr) then
          local path = vim.api.nvim_buf_get_name(bufnr)
          if path and path ~= "" then
            table.insert(paths, path)
          end
        end
      end
      group_copy.buffer_paths = paths
      group_copy.buffers = nil -- Don't save bufnr list
      groups_with_paths[group_name] = group_copy
    end
    
    local data = {
      groups = groups_with_paths,
      color_map = M.group_color_map
    }
    file:write(vim.json.encode(data))
    file:close()
  end
end

-- Helper function to find or create buffer for a path
local function get_or_create_bufnr(path)
  -- Check cache first
  if M.path_to_bufnr_cache[path] then
    local cached_bufnr = M.path_to_bufnr_cache[path]
    if vim.api.nvim_buf_is_valid(cached_bufnr) then
      return cached_bufnr
    end
  end
  
  -- Find existing buffer with this path
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      local buf_path = vim.api.nvim_buf_get_name(bufnr)
      if buf_path == path then
        M.path_to_bufnr_cache[path] = bufnr
        return bufnr
      end
    end
  end
  
  -- Buffer doesn't exist yet, will be created when file is opened
  return nil
end

function M.load_groups()
  local file = io.open(data_path, "r")
  if file then
    local content = file:read("*all")
    file:close()
    if content and content ~= "" then
      local ok, data = pcall(vim.json.decode, content)
      if ok and type(data) == "table" then
        if data.groups then
          -- Convert paths back to bufnr
          M.groups = {}
          for group_name, group_data in pairs(data.groups) do
            local buffers = {}
            
            -- Handle new format with buffer_paths
            if group_data.buffer_paths then
              for _, path in ipairs(group_data.buffer_paths) do
                local bufnr = get_or_create_bufnr(path)
                if bufnr then
                  table.insert(buffers, bufnr)
                end
              end
            -- Handle old format with buffers (bufnr)
            elseif group_data.buffers then
              -- Old format, try to recover valid buffers
              for _, bufnr in ipairs(group_data.buffers) do
                if vim.api.nvim_buf_is_valid(bufnr) then
                  table.insert(buffers, bufnr)
                end
              end
            end
            
            M.groups[group_name] = {
              name = group_data.name,
              buffers = buffers,
              created = group_data.created,
              buffer_paths = group_data.buffer_paths or {} -- Keep paths for reference
            }
          end
          M.group_color_map = data.color_map or {}
        else
          -- Very old format, ignore
          M.groups = {}
        end
      end
    end
  end
end

function M.create_group(name)
  if not name or name == "" then
    vim.notify("Group name cannot be empty", vim.log.levels.WARN)
    return false
  end
  
  if M.groups[name] then
    vim.notify("Group '" .. name .. "' already exists", vim.log.levels.WARN)
    return false
  end
  
  M.groups[name] = {
    name = name,
    buffers = {},
    created = os.time()
  }
  M.save_groups()
  vim.notify("Created group: " .. name, vim.log.levels.INFO)
  
  -- Trigger events to update UI
  vim.api.nvim_exec_autocmds("User", { pattern = "BufferGroupsUpdate" })
  
  return true
end

function M.delete_group(name)
  if not M.groups[name] then
    vim.notify("Group '" .. name .. "' does not exist", vim.log.levels.WARN)
    return false
  end
  
  M.groups[name] = nil
  M.group_color_map[name] = nil
  M.save_groups()
  vim.notify("Deleted group: " .. name, vim.log.levels.INFO)
  
  -- Trigger events to update UI
  vim.api.nvim_exec_autocmds("User", { pattern = "BufferGroupsUpdate" })
  
  return true
end

function M.rename_group(old_name, new_name)
  if not M.groups[old_name] then
    vim.notify("Group '" .. old_name .. "' does not exist", vim.log.levels.WARN)
    return false
  end
  
  if M.groups[new_name] then
    vim.notify("Group '" .. new_name .. "' already exists", vim.log.levels.WARN)
    return false
  end
  
  M.groups[new_name] = M.groups[old_name]
  M.groups[new_name].name = new_name
  M.groups[old_name] = nil
  
  -- Preserve color assignment
  if M.group_color_map[old_name] then
    M.group_color_map[new_name] = M.group_color_map[old_name]
    M.group_color_map[old_name] = nil
  end
  
  M.save_groups()
  vim.notify("Renamed group: " .. old_name .. " -> " .. new_name, vim.log.levels.INFO)
  
  -- Trigger events to update UI
  vim.api.nvim_exec_autocmds("User", { pattern = "BufferGroupsUpdate" })
  
  return true
end

function M.add_buffer_to_group(group_name, bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  
  if not vim.api.nvim_buf_is_valid(bufnr) then
    vim.notify("Invalid buffer", vim.log.levels.WARN)
    return false
  end
  
  if not M.groups[group_name] then
    vim.notify("Group '" .. group_name .. "' does not exist", vim.log.levels.WARN)
    return false
  end
  
  for _, buf in ipairs(M.groups[group_name].buffers) do
    if buf == bufnr then
      vim.notify("Buffer already in group", vim.log.levels.INFO)
      return false
    end
  end
  
  table.insert(M.groups[group_name].buffers, bufnr)
  M.save_groups()
  
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  local display_name = bufname ~= "" and vim.fn.fnamemodify(bufname, ":t") or "[No Name]"
  vim.notify("Added '" .. display_name .. "' to group: " .. group_name, vim.log.levels.INFO)
  
  -- Trigger events to update UI
  vim.api.nvim_exec_autocmds("User", { pattern = "BufferGroupsUpdate" })
  vim.api.nvim_exec_autocmds("BufAdd", { buffer = bufnr })
  
  return true
end

function M.remove_buffer_from_group(group_name, bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  
  if not M.groups[group_name] then
    vim.notify("Group '" .. group_name .. "' does not exist", vim.log.levels.WARN)
    return false
  end
  
  local removed = false
  for i, buf in ipairs(M.groups[group_name].buffers) do
    if buf == bufnr then
      table.remove(M.groups[group_name].buffers, i)
      removed = true
      break
    end
  end
  
  if removed then
    M.save_groups()
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    local display_name = bufname ~= "" and vim.fn.fnamemodify(bufname, ":t") or "[No Name]"
    vim.notify("Removed '" .. display_name .. "' from group: " .. group_name, vim.log.levels.INFO)
    
    -- Trigger events to update UI
    vim.api.nvim_exec_autocmds("User", { pattern = "BufferGroupsUpdate" })
    vim.api.nvim_exec_autocmds("BufDelete", { buffer = bufnr })
  else
    vim.notify("Buffer not in group", vim.log.levels.WARN)
  end
  
  return removed
end

function M.get_buffer_groups(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local groups = {}
  
  for group_name, group_data in pairs(M.groups) do
    for _, buf in ipairs(group_data.buffers) do
      if buf == bufnr then
        table.insert(groups, group_name)
        break
      end
    end
  end
  
  return groups
end

function M.list_groups()
  local groups = {}
  for name, _ in pairs(M.groups) do
    table.insert(groups, name)
  end
  table.sort(groups)
  return groups
end

function M.get_group_buffers(group_name)
  if not M.groups[group_name] then
    return {}
  end
  
  local valid_buffers = {}
  for _, bufnr in ipairs(M.groups[group_name].buffers) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      table.insert(valid_buffers, bufnr)
    end
  end
  
  if #valid_buffers < #M.groups[group_name].buffers then
    M.groups[group_name].buffers = valid_buffers
    M.save_groups()
  end
  
  return valid_buffers
end

function M.cleanup_invalid_buffers()
  local cleaned = false
  
  for group_name, group_data in pairs(M.groups) do
    local valid_buffers = {}
    for _, bufnr in ipairs(group_data.buffers) do
      if vim.api.nvim_buf_is_valid(bufnr) then
        table.insert(valid_buffers, bufnr)
      else
        cleaned = true
      end
    end
    M.groups[group_name].buffers = valid_buffers
  end
  
  if cleaned then
    M.save_groups()
    -- Don't notify on cleanup to avoid noise
  end
end

-- Update buffer mappings when files are opened
function M.update_buffer_mappings()
  for group_name, group_data in pairs(M.groups) do
    if group_data.buffer_paths then
      local updated_buffers = {}
      for _, path in ipairs(group_data.buffer_paths) do
        local bufnr = get_or_create_bufnr(path)
        if bufnr then
          table.insert(updated_buffers, bufnr)
        end
      end
      -- Merge with existing buffers that might not have paths yet
      for _, bufnr in ipairs(group_data.buffers) do
        if vim.api.nvim_buf_is_valid(bufnr) then
          local buf_path = vim.api.nvim_buf_get_name(bufnr)
          if buf_path and buf_path ~= "" then
            local found = false
            for _, existing_bufnr in ipairs(updated_buffers) do
              if existing_bufnr == bufnr then
                found = true
                break
              end
            end
            if not found then
              table.insert(updated_buffers, bufnr)
            end
          end
        end
      end
      group_data.buffers = updated_buffers
    end
  end
end

function M.get_group_info(group_name)
  return M.groups[group_name]
end

function M.get_buffers_by_groups()
  local result = {}
  local all_buffers = vim.tbl_filter(function(b)
    return vim.api.nvim_buf_is_valid(b) and vim.bo[b].buflisted
  end, vim.api.nvim_list_bufs())
  
  -- Add buffers that belong to groups
  local assigned_buffers = {}
  local group_names = vim.tbl_keys(M.groups)
  table.sort(group_names)
  
  for _, group_name in ipairs(group_names) do
    local group_data = M.groups[group_name]
    local group_buffers = {}
    for _, bufnr in ipairs(group_data.buffers) do
      if vim.tbl_contains(all_buffers, bufnr) then
        table.insert(group_buffers, bufnr)
        assigned_buffers[bufnr] = true
      end
    end
    if #group_buffers > 0 then
      table.insert(result, {
        name = group_name,
        buffers = group_buffers,
        is_group = true
      })
    end
  end
  
  -- Add ungrouped buffers at the beginning
  local ungrouped = {}
  for _, bufnr in ipairs(all_buffers) do
    if not assigned_buffers[bufnr] then
      table.insert(ungrouped, bufnr)
    end
  end
  
  if #ungrouped > 0 then
    -- Insert ungrouped at the beginning instead of the end
    table.insert(result, 1, {
      name = "Ungrouped",
      buffers = ungrouped,
      is_group = true
    })
  end
  
  return result
end

function M.get_tabline_buffers()
  local groups = M.get_buffers_by_groups()
  local buffers = {}
  
  for _, group in ipairs(groups) do
    -- Add group separator
    table.insert(buffers, {
      is_separator = true,
      group_name = group.name
    })
    -- Add group buffers
    for _, bufnr in ipairs(group.buffers) do
      table.insert(buffers, bufnr)
    end
  end
  
  return buffers
end


function M.setup()
  M.load_groups()
  
  local group = vim.api.nvim_create_augroup("BufferGroups", { clear = true })
  
  -- Auto-clear group context when switching to unrelated buffers
  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function(args)
      local bufnr = args.buf
      if M.current_group_context then
        local current_groups = M.get_buffer_groups(bufnr)
        -- If current buffer doesn't belong to the context group, clear context
        if M.current_group_context == "Ungrouped" then
          if #current_groups > 0 then
            M.clear_group_context()
          end
        elseif not vim.tbl_contains(current_groups, M.current_group_context) then
          M.clear_group_context()
        end
      end
    end,
  })
  
  -- Save on exit
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      M.cleanup_invalid_buffers()
      M.save_groups()
    end,
  })
  
  -- Update mappings when buffers are loaded
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
    group = group,
    callback = function(args)
      local bufnr = args.buf
      local path = vim.api.nvim_buf_get_name(bufnr)
      if path and path ~= "" then
        M.path_to_bufnr_cache[path] = bufnr
        -- Check if this buffer should be in any groups
        for group_name, group_data in pairs(M.groups) do
          if group_data.buffer_paths then
            for _, stored_path in ipairs(group_data.buffer_paths) do
              if stored_path == path then
                -- Add to buffers if not already there
                local found = false
                for _, existing_bufnr in ipairs(group_data.buffers) do
                  if existing_bufnr == bufnr then
                    found = true
                    break
                  end
                end
                if not found then
                  table.insert(group_data.buffers, bufnr)
                  vim.api.nvim_exec_autocmds("User", { pattern = "BufferGroupsUpdate" })
                end
              end
            end
          end
        end
      end
    end,
  })
  
  -- Periodically save groups
  vim.api.nvim_create_autocmd({ "BufWritePost", "FocusLost" }, {
    group = group,
    callback = function()
      M.save_groups()
    end,
  })
end

return M