local M = {}

-- Jump to next class using aerial
function M.goto_next_class()
  local aerial = require('aerial')
  local data = require('aerial.data')
  
  -- Get current buffer data
  local bufdata = data.get_or_create(0)
  if not bufdata or not bufdata.items or #bufdata.items == 0 then
    vim.notify("No symbols found in current buffer", vim.log.levels.INFO)
    return
  end
  
  local current_line = vim.fn.line('.')
  local items = bufdata.items
  
  -- Find next class-like symbol
  local found = nil
  for _, item in ipairs(items) do
    if (item.kind == "Class" or item.kind == "Struct" or 
        item.kind == "Interface" or item.kind == "Enum") and
       item.lnum > current_line then
      found = item
      break
    end
  end
  
  -- If no next class, wrap to first
  if not found then
    for _, item in ipairs(items) do
      if item.kind == "Class" or item.kind == "Struct" or 
         item.kind == "Interface" or item.kind == "Enum" then
        found = item
        break
      end
    end
  end
  
  if found then
    vim.api.nvim_win_set_cursor(0, {found.lnum, found.col})
    vim.notify("Jumped to " .. found.kind .. ": " .. found.name, vim.log.levels.INFO)
  else
    vim.notify("No class symbols found in current buffer", vim.log.levels.INFO)
  end
end

-- Jump to previous class using aerial
function M.goto_prev_class()
  local aerial = require('aerial')
  local data = require('aerial.data')
  
  -- Get current buffer data
  local bufdata = data.get_or_create(0)
  if not bufdata or not bufdata.items or #bufdata.items == 0 then
    vim.notify("No symbols found in current buffer", vim.log.levels.INFO)
    return
  end
  
  local current_line = vim.fn.line('.')
  local items = bufdata.items
  
  -- Find previous class-like symbol
  local found = nil
  for i = #items, 1, -1 do
    local item = items[i]
    if (item.kind == "Class" or item.kind == "Struct" or 
        item.kind == "Interface" or item.kind == "Enum") and
       item.lnum < current_line then
      found = item
      break
    end
  end
  
  -- If no previous class, wrap to last
  if not found then
    for i = #items, 1, -1 do
      local item = items[i]
      if item.kind == "Class" or item.kind == "Struct" or 
         item.kind == "Interface" or item.kind == "Enum" then
        found = item
        break
      end
    end
  end
  
  if found then
    vim.api.nvim_win_set_cursor(0, {found.lnum, found.col})
    vim.notify("Jumped to " .. found.kind .. ": " .. found.name, vim.log.levels.INFO)
  else
    vim.notify("No class symbols found in current buffer", vim.log.levels.INFO)
  end
end

return M