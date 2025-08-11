local M = {}

-- Optimized display component - maximizes filename visibility within neo-tree limitations
M.name_wrapped = function(config, node, state)
  local highlight = config.highlight or "NeoTreeFileName"
  local name = node.name or node.path:match("([^/]+)$") or ""
  
  if config.use_git_status_colors == nil or config.use_git_status_colors then
    local git_status = state.components.git_status({}, node, state)
    if git_status and git_status.highlight then
      highlight = git_status.highlight
    end
  end
  
  -- Get window width using multiple methods for reliability
  local win_width = 30
  
  -- Method 1: Try state.winid first (most reliable)
  if state.winid and vim.api.nvim_win_is_valid(state.winid) then
    local ok, width = pcall(vim.api.nvim_win_get_width, state.winid)
    if ok and width > 0 then
      win_width = width
    end
  -- Method 2: Try state.window.winid
  elseif state.window and state.window.winid and vim.api.nvim_win_is_valid(state.window.winid) then
    local ok, width = pcall(vim.api.nvim_win_get_width, state.window.winid)
    if ok and width > 0 then
      win_width = width
    end
  -- Method 3: Use state.win_width if available
  elseif state.win_width and state.win_width > 0 then
    win_width = state.win_width
  end
  
  -- Calculate available space for the filename
  local level = node.level or 0
  local indent_width = level * 2 + 1
  local icon_width = 3
  local available_width = win_width - indent_width - icon_width - 1
  
  
  -- Check if name needs intelligent handling
  local name_width = vim.fn.strwidth(name)
  if name_width > available_width and available_width > 8 then
    -- Strategy 1: For very long names, try to show most important parts
    local base, ext = name:match("^(.-)(%.[^.]+)$")
    if base and ext and vim.fn.strwidth(ext) <= 8 then
      -- Prioritize showing the extension and as much of the base as possible
      local ext_width = vim.fn.strwidth(ext)
      local available_for_base = available_width - ext_width - 1 -- 1 for the ellipsis
      
      if available_for_base > 3 then
        -- Try to keep the beginning of the filename for context
        local keep_start = math.max(3, math.floor(available_for_base * 0.7))
        local keep_end = available_for_base - keep_start
        
        if keep_end > 0 and #base > keep_start then
          name = base:sub(1, keep_start) .. "…" .. base:sub(-keep_end) .. ext
        else
          name = base:sub(1, available_for_base) .. "…" .. ext
        end
      else
        -- Not enough space for smart truncation, just truncate normally
        name = name:sub(1, available_width - 1) .. "…"
      end
    else
      -- For names without extension or very long extensions
      -- Show the beginning of the filename (most context-rich part)
      if available_width > 6 then
        -- Try to find a good break point near the end
        local truncate_at = available_width - 1
        local break_chars = "[%s%-%.%_/\\]"
        
        -- Look for a natural break point in the last 30% of the available space
        local search_start = math.max(1, truncate_at - math.floor(available_width * 0.3))
        for i = truncate_at, search_start, -1 do
          if name:sub(i, i):match(break_chars) then
            truncate_at = i - 1
            break
          end
        end
        
        name = name:sub(1, truncate_at) .. "…"
      else
        name = name:sub(1, available_width - 1) .. "…"
      end
    end
  end
  
  return {
    text = name,
    highlight = highlight,
  }
end

-- Full name component - shows complete filename (may cause horizontal scroll)
M.name_full = function(config, node, state)
  local highlight = config.highlight or "NeoTreeFileName"
  local name = node.name or node.path:match("([^/]+)$") or ""
  
  if config.use_git_status_colors == nil or config.use_git_status_colors then
    local git_status = state.components.git_status({}, node, state)
    if git_status and git_status.highlight then
      highlight = git_status.highlight
    end
  end
  
  return {
    text = name,
    highlight = highlight,
  }
end

-- Smart truncation component - intelligent shortening of long names  
M.name_smart = function(config, node, state)
  local highlight = config.highlight or "NeoTreeFileName"
  local name = node.name or node.path:match("([^/]+)$") or ""
  local original_name = name
  
  if config.use_git_status_colors == nil or config.use_git_status_colors then
    local git_status = state.components.git_status({}, node, state)
    if git_status and git_status.highlight then
      highlight = git_status.highlight
    end
  end
  
  -- Get window width using multiple methods for reliability
  local win_width = 30
  
  -- Method 1: Try state.winid first (most reliable)
  if state.winid and vim.api.nvim_win_is_valid(state.winid) then
    local ok, width = pcall(vim.api.nvim_win_get_width, state.winid)
    if ok and width > 0 then
      win_width = width
    end
  -- Method 2: Try state.window.winid
  elseif state.window and state.window.winid and vim.api.nvim_win_is_valid(state.window.winid) then
    local ok, width = pcall(vim.api.nvim_win_get_width, state.window.winid)
    if ok and width > 0 then
      win_width = width
    end
  -- Method 3: Use state.win_width if available
  elseif state.win_width and state.win_width > 0 then
    win_width = state.win_width
  end
  
  -- Calculate available space for the filename
  local level = node.level or 0
  local indent_width = level * 2 + 1
  local icon_width = 3
  local available_width = win_width - indent_width - icon_width - 1
  
  -- Only truncate if name is significantly longer than available space
  local name_width = vim.fn.strwidth(name)
  if name_width > available_width and available_width > 8 then
    -- Try intelligent truncation strategies
    
    -- Strategy 1: For paths with separators, show just the final component
    local parts = {}
    for part in name:gmatch("[^/\\]+") do
      table.insert(parts, part)
    end
    
    if #parts > 1 then
      local final_part = parts[#parts]
      if vim.fn.strwidth(final_part) <= available_width - 2 then
        name = "…/" .. final_part
      else
        name = "…/" .. final_part:sub(1, available_width - 5) .. "…"
      end
    else
      -- Strategy 2: For single long filename, preserve extension if possible
      local base, ext = name:match("^(.-)(%.[^.]+)$")
      if base and ext and vim.fn.strwidth(ext) < available_width / 3 then
        local max_base = available_width - vim.fn.strwidth(ext) - 1
        if max_base > 3 then
          name = base:sub(1, max_base) .. "…" .. ext
        else
          name = name:sub(1, available_width - 1) .. "…"
        end
      else
        -- Strategy 3: Simple truncation
        name = name:sub(1, available_width - 1) .. "…"
      end
    end
  end
  
  return {
    text = name,
    highlight = highlight,
  }
end

-- Original truncation version (kept for reference)
M.name_truncate = function(config, node, state)
  local highlight = config.highlight or "NeoTreeFileName"
  local name = node.name or node.path:match("([^/]+)$") or ""
  
  if config.use_git_status_colors == nil or config.use_git_status_colors then
    local git_status = state.components.git_status({}, node, state)
    if git_status and git_status.highlight then
      highlight = git_status.highlight
    end
  end
  
  -- Get window width and calculate available space
  local win_width = 30  -- Default neo-tree width
  
  -- Try to get actual window width
  if state.window and state.window.winid and vim.api.nvim_win_is_valid(state.window.winid) then
    local ok, width = pcall(vim.api.nvim_win_get_width, state.window.winid)
    if ok and width > 0 then
      win_width = width
    end
  end
  
  local level = node.level or 0
  local indent_size = 2
  local padding = 1
  local indent_width = level * indent_size + padding
  local icon_width = 3
  local available_width = win_width - indent_width - icon_width - 2
  
  -- Only truncate if absolutely necessary
  local display_width = vim.fn.strwidth(name)
  if display_width > available_width and available_width > 10 then
    local ext = name:match("%.([^%.]+)$")
    if ext then
      local max_base = available_width - #ext - 4
      if max_base > 0 then
        local base = name:sub(1, #name - #ext - 1)
        if #base > max_base then
          name = base:sub(1, max_base) .. "..." .. "." .. ext
        end
      else
        name = name:sub(1, available_width - 3) .. "..."
      end
    else
      name = name:sub(1, available_width - 3) .. "..."
    end
  end
  
  return {
    text = name,
    highlight = highlight,
  }
end

-- Dynamic width component - automatically adjusts neo-tree width based on content
M.name_dynamic = function(config, node, state)
  local highlight = config.highlight or "NeoTreeFileName"
  local name = node.name or node.path:match("([^/]+)$") or ""
  
  if config.use_git_status_colors == nil or config.use_git_status_colors then
    local git_status = state.components.git_status({}, node, state)
    if git_status and git_status.highlight then
      highlight = git_status.highlight
    end
  end
  
  -- Store longest filename for potential auto-resize
  if not state.longest_filename_width then
    state.longest_filename_width = 0
  end
  
  local level = node.level or 0
  local indent_width = level * 2 + 1
  local icon_width = 3
  local name_width = vim.fn.strwidth(name)
  local total_width = indent_width + icon_width + name_width + 2
  
  if total_width > state.longest_filename_width then
    state.longest_filename_width = total_width
    
    -- Auto-expand neo-tree if needed (but limit the maximum width)
    local max_width = math.min(60, math.max(35, total_width))
    if state.winid and vim.api.nvim_win_is_valid(state.winid) then
      local current_width = vim.api.nvim_win_get_width(state.winid)
      if total_width > current_width and max_width > current_width then
        vim.schedule(function()
          if vim.api.nvim_win_is_valid(state.winid) then
            vim.api.nvim_win_set_width(state.winid, max_width)
          end
        end)
      end
    end
  end
  
  return {
    text = name,
    highlight = highlight,
  }
end

return M