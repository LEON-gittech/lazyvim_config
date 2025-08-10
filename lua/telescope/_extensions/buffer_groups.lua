local telescope = require("telescope")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local sorters = require("telescope.sorters")
local entry_display = require("telescope.pickers.entry_display")
local previewers = require("telescope.previewers")
local buffer_groups = require("utils.buffer_groups")
local conf = require("telescope.config").values

local function get_buffer_display_name(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return "[No Name]"
  end
  return vim.fn.fnamemodify(name, ":t")
end

local function get_buffer_path(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return ""
  end
  return vim.fn.fnamemodify(name, ":~:.:h")
end

-- Create a grouped buffer picker with visual separators
local function make_grouped_buffer_entry()
  local displayer = entry_display.create({
    separator = " ",
    items = {
      { width = 70 },  -- Full line for borders and content
    },
  })

  return function(entry_data)
    -- Handle separator entries
    if entry_data.is_separator then
      local group_name = entry_data.group_name
      
      -- Handle empty separators (spacing lines)
      if group_name == "" then
        if entry_data.is_empty_line then
          -- Empty line for spacing
          return {
            value = nil,
            ordinal = "\0",
            display = function() return "" end,
            is_separator = true,
            group_name = "",
          }
        end
      end
      
      -- Handle closing separator
      if entry_data.is_closing then
        local color_idx = buffer_groups.get_group_color(entry_data.parent_group)
        local color = buffer_groups.group_colors[color_idx]
        local hl_name = "BufferGroupSep_" .. entry_data.parent_group:gsub("[^%w]", "_")
        vim.api.nvim_set_hl(0, hl_name, { fg = color.fg })
        
        return {
          value = nil,
          ordinal = "\0",
          display = function()
            -- Create bottom border line
            local line = "└" .. string.rep("─", 66) .. "┘"
            return displayer({
              { line, hl_name },
            })
          end,
          is_separator = true,
          group_name = "",
        }
      end
      
      -- Handle actual group headers
      local color_idx = buffer_groups.get_group_color(group_name)
      local color = buffer_groups.group_colors[color_idx]
      
      -- Create highlight group for this separator
      local hl_name = "BufferGroupSep_" .. group_name:gsub("[^%w]", "_")
      vim.api.nvim_set_hl(0, hl_name, { fg = color.fg, bold = true })
      
      -- Create top border with group name
      local separator_char = "─"
      local header = " " .. group_name .. " "
      
      return {
        value = nil, -- Separators are not selectable
        ordinal = "\0", -- Non-searchable ordinal for separators
        display = function()
          -- Create the top border line
          local line = "┌─── " .. header .. string.rep(separator_char, 60 - vim.fn.strwidth(header)) .. "┐"
          return displayer({
            { line, hl_name },
          })
        end,
        is_separator = true,
        group_name = group_name,
      }
    end
    
    -- Handle buffer entries
    local bufnr = entry_data.bufnr
    local group_name = entry_data.group_name
    
    -- Get group color for buffer entries
    local color_idx = buffer_groups.get_group_color(group_name)
    local color = buffer_groups.group_colors[color_idx]
    
    -- Create highlight groups for buffer entries
    local hl_border = "BufferGroupBorder_" .. group_name:gsub("[^%w]", "_")
    vim.api.nvim_set_hl(0, hl_border, { fg = color.fg })
    
    local filename = vim.api.nvim_buf_get_name(bufnr)
    local bufname = filename ~= "" and filename or "[No Name]"
    local lnum = 1
    
    -- Get buffer info for last cursor position
    local bufinfo = vim.fn.getbufinfo(bufnr)[1]
    if bufinfo and bufinfo.lnum and bufinfo.lnum ~= 0 then
      lnum = bufinfo.lnum
    end
    
    -- Add left border for buffer entries
    local left_border = "│ "
    
    return {
      value = bufnr,
      ordinal = tostring(bufnr) .. " " .. get_buffer_display_name(bufnr) .. " " .. get_buffer_path(bufnr),
      display = function(entry)
        -- Format buffer line with borders
        local buf_num = string.format("%-4s", tostring(bufnr))
        local buf_name = string.format("%-25s", get_buffer_display_name(bufnr))
        local buf_path = string.format("%-35s", get_buffer_path(bufnr))
        local line = left_border .. buf_num .. " " .. buf_name .. " " .. buf_path
        -- Add right border with padding
        local padding = 67 - vim.fn.strwidth(line)
        if padding > 0 then
          line = line .. string.rep(" ", padding)
        end
        line = line .. "│"
        
        return displayer({
          { line, hl_border },
        })
      end,
      bufnr = bufnr,
      filename = filename ~= "" and filename or nil,
      path = filename,
      lnum = lnum,
      group_name = group_name,
    }
  end
end

local function make_buffer_entry()
  local displayer = entry_display.create({
    separator = " ",
    items = {
      { width = 4 },  -- buffer number
      { width = 20 }, -- file name
      { width = 30 }, -- path
      { remaining = true }, -- groups
    },
  })

  return function(bufnr)
    local groups = buffer_groups.get_buffer_groups(bufnr)
    local group_displays = {}
    
    -- If no groups, show as Ungrouped
    if #groups == 0 then
      groups = { "Ungrouped" }
    end
    
    -- Create colored group displays
    for _, group in ipairs(groups) do
      local color_idx = buffer_groups.get_group_color(group)
      local color = buffer_groups.group_colors[color_idx]
      
      -- Create highlight group for this group if it doesn't exist
      local hl_name = "BufferGroup_" .. group:gsub("[^%w]", "_")
      vim.api.nvim_set_hl(0, hl_name, { fg = color.fg, bg = color.bg })
      
      table.insert(group_displays, { text = "[" .. group .. "]", hl = hl_name })
    end
    
    local group_str = table.concat(vim.tbl_map(function(g) return g.text end, group_displays), " ")
    
    local filename = vim.api.nvim_buf_get_name(bufnr)
    local bufname = filename ~= "" and filename or "[No Name]"
    local lnum = 1
    
    -- Get buffer info for last cursor position
    local bufinfo = vim.fn.getbufinfo(bufnr)[1]
    if bufinfo and bufinfo.lnum and bufinfo.lnum ~= 0 then
      lnum = bufinfo.lnum
    end
    
    return {
      value = bufnr,
      ordinal = tostring(bufnr) .. " " .. get_buffer_display_name(bufnr) .. " " .. get_buffer_path(bufnr),
      display = function(entry)
        local display_items = {
          { tostring(entry.bufnr), "TelescopeResultsNumber" },
          { get_buffer_display_name(entry.bufnr), "TelescopeResultsIdentifier" },
          { get_buffer_path(entry.bufnr), "TelescopeResultsComment" },
        }
        
        -- Add colored group names (always show, including Ungrouped)
        table.insert(display_items, { group_str, group_displays[1] and group_displays[1].hl or "TelescopeResultsFunction" })
        
        return displayer(display_items)
      end,
      bufnr = bufnr,
      filename = filename ~= "" and filename or nil,
      path = filename,
      lnum = lnum,
    }
  end
end

local function buffer_picker(opts)
  opts = opts or {}
  
  -- Build grouped results
  local grouped_results = {}
  local groups_data = buffer_groups.get_buffers_by_groups()
  
  for i, group in ipairs(groups_data) do
    -- Count valid buffers in this group
    local valid_buffers = {}
    for _, bufnr in ipairs(group.buffers) do
      if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buflisted then
        table.insert(valid_buffers, bufnr)
      end
    end
    
    -- Only show groups that have buffers (or Ungrouped even if empty)
    if #valid_buffers > 0 or group.name == "Ungrouped" then
      -- Add empty line between groups (but not before the first group)
      if #grouped_results > 0 then
        table.insert(grouped_results, { is_separator = true, group_name = "", is_empty_line = true })
      end
      
      -- Add group header (top border)
      table.insert(grouped_results, { is_separator = true, group_name = group.name })
      
      -- Add buffers in this group
      for _, bufnr in ipairs(valid_buffers) do
        table.insert(grouped_results, { bufnr = bufnr, group_name = group.name })
      end
      
      -- Add group footer (bottom border)
      table.insert(grouped_results, { is_separator = true, is_closing = true, parent_group = group.name })
      
      -- If Ungrouped has no buffers, show a message
      if #valid_buffers == 0 and group.name == "Ungrouped" then
        -- Could add a placeholder here if desired
      end
    end
  end
  
  -- Filter by group if specified
  if opts.filter_group then
    local filtered_results = {}
    local in_group = false
    
    for _, entry in ipairs(grouped_results) do
      if entry.is_separator and entry.group_name == opts.filter_group then
        in_group = true
        table.insert(filtered_results, entry)
      elseif entry.is_separator and in_group and (entry.is_closing or entry.group_name ~= "") then
        table.insert(filtered_results, entry)
        if entry.group_name ~= "" then
          in_group = false
        end
      elseif in_group and not entry.is_separator then
        table.insert(filtered_results, entry)
      end
    end
    
    grouped_results = filtered_results
  elseif opts.filter_ungrouped then
    -- Filter to show only ungrouped buffers
    local filtered_results = {}
    local in_ungrouped = false
    
    for _, entry in ipairs(grouped_results) do
      if entry.is_separator and entry.group_name == "Ungrouped" then
        in_ungrouped = true
        table.insert(filtered_results, entry)
      elseif entry.is_separator and in_ungrouped then
        table.insert(filtered_results, entry)
        if entry.group_name ~= "" and entry.group_name ~= "Ungrouped" then
          in_ungrouped = false
        end
      elseif in_ungrouped and not entry.is_separator then
        table.insert(filtered_results, entry)
      end
    end
    
    grouped_results = filtered_results
  end
  
  local prompt_title = "Buffers"
  if opts.filter_group then
    prompt_title = "Buffers in: " .. opts.filter_group
  elseif opts.filter_ungrouped then
    prompt_title = "Ungrouped Buffers"
  else
    prompt_title = "Grouped Buffers (C-f: filter, C-a: add to group, C-d: remove)"
  end
  
  -- Calculate the index of the current buffer or first non-separator entry
  local current_bufnr = vim.api.nvim_get_current_buf()
  local default_index = 1
  local first_buffer_index = nil
  
  for i, entry_data in ipairs(grouped_results) do
    if not entry_data.is_separator then
      -- Found a buffer entry
      if not first_buffer_index then
        first_buffer_index = i
      end
      if entry_data.bufnr == current_bufnr then
        default_index = i
        break
      end
    end
  end
  
  -- If current buffer not found, use first buffer entry
  if default_index == 1 and first_buffer_index then
    default_index = first_buffer_index
  end
  
  pickers.new(opts, {
    prompt_title = prompt_title,
    finder = finders.new_table({
      results = grouped_results,
      entry_maker = make_grouped_buffer_entry(),
    }),
    sorter = conf.generic_sorter(opts),
    previewer = conf.grep_previewer(opts),
    sorting_strategy = "ascending", -- Show results from top to bottom
    default_selection_index = default_index, -- Start at current buffer or first buffer
    attach_mappings = function(prompt_bufnr, map)
      local function filter_by_group()
        local groups = buffer_groups.list_groups()
        
        actions.close(prompt_bufnr)
        
        -- Add "All Buffers" and "Ungrouped" options
        local choices = { "All Buffers", "Ungrouped" }
        vim.list_extend(choices, groups)
        
        vim.ui.select(choices, { prompt = "Filter by group: " }, function(choice)
          if not choice then 
            -- Re-open without filter if cancelled
            buffer_picker(opts)
            return 
          end
          
          if choice == "All Buffers" then
            buffer_picker(opts)
          elseif choice == "Ungrouped" then
            buffer_picker(vim.tbl_extend("force", opts, { filter_ungrouped = true }))
          else
            buffer_picker(vim.tbl_extend("force", opts, { filter_group = choice }))
          end
        end)
      end
      
      local function add_to_group()
        local entry = action_state.get_selected_entry()
        if not entry or entry.is_separator then 
          vim.notify("No buffer selected", vim.log.levels.WARN)
          return 
        end
        
        local selected = { entry.bufnr }
        
        if #selected > 0 then
          actions.close(prompt_bufnr)
          
          vim.ui.input({ prompt = "Group name: " }, function(group_name)
            if not group_name or group_name == "" then
              return
            end
            
            if not buffer_groups.groups[group_name] then
              buffer_groups.create_group(group_name)
            end
            
            for _, bufnr in ipairs(selected) do
              buffer_groups.add_buffer_to_group(group_name, bufnr)
            end
          end)
        end
      end
      
      local function remove_from_group()
        local entry = action_state.get_selected_entry()
        if not entry or entry.is_separator then return end
        
        local groups = buffer_groups.get_buffer_groups(entry.bufnr)
        if #groups == 0 then
          vim.notify("Buffer not in any group", vim.log.levels.INFO)
          return
        end
        
        actions.close(prompt_bufnr)
        
        if #groups == 1 then
          buffer_groups.remove_buffer_from_group(groups[1], entry.bufnr)
        else
          vim.ui.select(groups, { prompt = "Remove from group: " }, function(choice)
            if choice then
              buffer_groups.remove_buffer_from_group(choice, entry.bufnr)
            end
          end)
        end
      end
      
      -- Override movement to skip separators completely
      local move_selection_next_impl = function()
        -- Suppress any output during navigation
        local ok, _ = pcall(function()
          local picker = action_state.get_current_picker(prompt_bufnr)
          if not picker then return end
          
          actions.move_selection_next(prompt_bufnr)
          
          -- Skip separators
          local entry = action_state.get_selected_entry()
          local attempts = 0
          while entry and entry.is_separator and attempts < 100 do
            actions.move_selection_next(prompt_bufnr)
            entry = action_state.get_selected_entry()
            attempts = attempts + 1
          end
        end)
        return ok
      end
      
      local move_selection_previous_impl = function()
        -- Suppress any output during navigation
        local ok, _ = pcall(function()
          local picker = action_state.get_current_picker(prompt_bufnr)
          if not picker then return end
          
          actions.move_selection_previous(prompt_bufnr)
          
          -- Skip separators
          local entry = action_state.get_selected_entry()
          local attempts = 0
          while entry and entry.is_separator and attempts < 100 do
            actions.move_selection_previous(prompt_bufnr)
            entry = action_state.get_selected_entry()
            attempts = attempts + 1
          end
        end)
        return ok
      end
      
      -- Replace default movement mappings
      map("i", "<Down>", move_selection_next_impl)
      map("i", "<C-n>", move_selection_next_impl)
      map("n", "j", move_selection_next_impl)
      map("i", "<Up>", move_selection_previous_impl)
      map("i", "<C-p>", move_selection_previous_impl)
      map("n", "k", move_selection_previous_impl)
      
      -- Custom toggle selection that skips separators
      local function toggle_selection_and_move_next()
        local entry = action_state.get_selected_entry()
        if entry and not entry.is_separator then
          actions.toggle_selection(prompt_bufnr)
        end
        move_selection_next_impl()
      end
      
      local function toggle_selection_and_move_previous()
        local entry = action_state.get_selected_entry()
        if entry and not entry.is_separator then
          actions.toggle_selection(prompt_bufnr)
        end
        move_selection_previous_impl()
      end
      
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        if entry and not entry.is_separator then
          actions.close(prompt_bufnr)
          
          -- Set group context based on current filter or entry's group
          if opts.filter_group then
            buffer_groups.set_group_context(opts.filter_group)
          elseif opts.filter_ungrouped then
            buffer_groups.set_group_context("Ungrouped")
          elseif entry.group_name then
            buffer_groups.set_group_context(entry.group_name)
          else
            buffer_groups.clear_group_context()
          end
          
          vim.api.nvim_set_current_buf(entry.bufnr)
        end
      end)
      
      local function delete_buffer_i()
        local entry = action_state.get_selected_entry()
        if not entry or entry.is_separator then 
          vim.notify("No buffer selected", vim.log.levels.WARN)
          return 
        end
        
        local bufnr = entry.bufnr
        local current_buf = vim.api.nvim_get_current_buf()
        
        -- 如果要删除的是当前buffer，先切换到其他buffer
        if bufnr == current_buf then
          local buffers = vim.api.nvim_list_bufs()
          local found_alternative = false
          
          for _, buf in ipairs(buffers) do
            if buf ~= bufnr and vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted then
              vim.api.nvim_set_current_buf(buf)
              found_alternative = true
              break
            end
          end
          
          -- 如果没有其他buffer，创建一个新的空buffer
          if not found_alternative then
            vim.cmd("enew")
          end
        end
        
        -- 安全删除buffer
        local ok, err = pcall(vim.api.nvim_buf_delete, bufnr, { force = false })
        if not ok then
          vim.notify("Failed to delete buffer: " .. tostring(err), vim.log.levels.ERROR)
          return
        end
        
        -- 延迟刷新telescope显示，保持insert mode
        vim.defer_fn(function()
          actions.close(prompt_bufnr)
          local new_opts = vim.tbl_extend("force", opts, { initial_mode = "insert" })
          buffer_picker(new_opts)
        end, 100)
      end
      
      local function delete_buffer_n()
        local entry = action_state.get_selected_entry()
        if not entry or entry.is_separator then 
          vim.notify("No buffer selected", vim.log.levels.WARN)
          return 
        end
        
        local bufnr = entry.bufnr
        local current_buf = vim.api.nvim_get_current_buf()
        
        -- 如果要删除的是当前buffer，先切换到其他buffer
        if bufnr == current_buf then
          local buffers = vim.api.nvim_list_bufs()
          local found_alternative = false
          
          for _, buf in ipairs(buffers) do
            if buf ~= bufnr and vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted then
              vim.api.nvim_set_current_buf(buf)
              found_alternative = true
              break
            end
          end
          
          -- 如果没有其他buffer，创建一个新的空buffer
          if not found_alternative then
            vim.cmd("enew")
          end
        end
        
        -- 安全删除buffer
        local ok, err = pcall(vim.api.nvim_buf_delete, bufnr, { force = false })
        if not ok then
          vim.notify("Failed to delete buffer: " .. tostring(err), vim.log.levels.ERROR)
          return
        end
        
        -- 延迟刷新telescope显示，保持normal mode
        vim.defer_fn(function()
          actions.close(prompt_bufnr)
          local new_opts = vim.tbl_extend("force", opts, { initial_mode = "normal" })
          buffer_picker(new_opts)
        end, 100)
      end
      
      map("i", "<C-a>", add_to_group)
      map("n", "<C-a>", add_to_group)
      map("i", "<C-d>", remove_from_group)
      map("n", "<C-d>", remove_from_group)
      map("i", "<C-f>", filter_by_group)
      map("n", "<C-f>", filter_by_group)
      map("i", "<C-x>", delete_buffer_i)
      map("n", "<C-x>", delete_buffer_n)
      map("n", "dd", delete_buffer_n)
      map("i", "<Tab>", toggle_selection_and_move_next)
      map("n", "<Tab>", toggle_selection_and_move_next)
      map("i", "<S-Tab>", toggle_selection_and_move_previous)
      map("n", "<S-Tab>", toggle_selection_and_move_previous)
      
      return true
    end,
  }):find()
end

local function manage_groups(opts)
  opts = opts or {}
  
  local groups = buffer_groups.list_groups()
  
  if #groups == 0 then
    vim.notify("No groups created yet", vim.log.levels.INFO)
    return
  end
  
  pickers.new(opts, {
    prompt_title = "Manage Groups",
    finder = finders.new_table({
      results = groups,
      entry_maker = function(group_name)
        local group_info = buffer_groups.get_group_info(group_name)
        local buffer_count = #group_info.buffers
        return {
          value = group_name,
          ordinal = group_name,
          display = string.format("%s (%d buffers)", group_name, buffer_count),
        }
      end,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      local function delete_group()
        local entry = action_state.get_selected_entry()
        if entry then
          vim.ui.confirm("Delete group '" .. entry.value .. "'?", function(confirmed)
            if confirmed then
              buffer_groups.delete_group(entry.value)
              local current_picker = action_state.get_current_picker(prompt_bufnr)
              current_picker:refresh(finders.new_table({
                results = buffer_groups.list_groups(),
                entry_maker = function(group_name)
                  local group_info = buffer_groups.get_group_info(group_name)
                  local buffer_count = #group_info.buffers
                  return {
                    value = group_name,
                    ordinal = group_name,
                    display = string.format("%s (%d buffers)", group_name, buffer_count),
                  }
                end,
              }), { reset_prompt = false })
            end
          end)
        end
      end
      
      local function rename_group()
        local entry = action_state.get_selected_entry()
        if entry then
          vim.ui.input({ prompt = "New name: ", default = entry.value }, function(new_name)
            if new_name and new_name ~= "" and new_name ~= entry.value then
              buffer_groups.rename_group(entry.value, new_name)
              local current_picker = action_state.get_current_picker(prompt_bufnr)
              current_picker:refresh(finders.new_table({
                results = buffer_groups.list_groups(),
                entry_maker = function(group_name)
                  local group_info = buffer_groups.get_group_info(group_name)
                  local buffer_count = #group_info.buffers
                  return {
                    value = group_name,
                    ordinal = group_name,
                    display = string.format("%s (%d buffers)", group_name, buffer_count),
                  }
                end,
              }), { reset_prompt = false })
            end
          end)
        end
      end
      
      local function view_group_buffers()
        local entry = action_state.get_selected_entry()
        if entry then
          actions.close(prompt_bufnr)
          group_buffers({ group_name = entry.value })
        end
      end
      
      actions.select_default:replace(view_group_buffers)
      
      map("i", "<C-d>", delete_group)
      map("n", "<C-d>", delete_group)
      map("i", "<C-r>", rename_group)
      map("n", "<C-r>", rename_group)
      
      return true
    end,
  }):find()
end

local function group_buffers(opts)
  opts = opts or {}
  local group_name = opts.group_name
  
  if not group_name then
    local groups = buffer_groups.list_groups()
    if #groups == 0 then
      vim.notify("No groups created yet", vim.log.levels.INFO)
      return
    end
    
    vim.ui.select(groups, { prompt = "Select group: " }, function(choice)
      if choice then
        group_buffers({ group_name = choice })
      end
    end)
    return
  end
  
  local bufnrs = buffer_groups.get_group_buffers(group_name)
  
  if #bufnrs == 0 then
    vim.notify("No buffers in group '" .. group_name .. "'", vim.log.levels.INFO)
    return
  end
  
  pickers.new(opts, {
    prompt_title = "Group: " .. group_name,
    finder = finders.new_table({
      results = bufnrs,
      entry_maker = make_buffer_entry(),
    }),
    sorter = conf.generic_sorter(opts),
    previewer = conf.grep_previewer(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        if entry then
          actions.close(prompt_bufnr)
          vim.api.nvim_set_current_buf(entry.bufnr)
        end
      end)
      
      local function remove_from_group()
        local entry = action_state.get_selected_entry()
        if entry then
          buffer_groups.remove_buffer_from_group(group_name, entry.bufnr)
          local current_picker = action_state.get_current_picker(prompt_bufnr)
          current_picker:refresh(finders.new_table({
            results = buffer_groups.get_group_buffers(group_name),
            entry_maker = make_buffer_entry(),
          }), { reset_prompt = false })
        end
      end
      
      map("i", "<C-r>", remove_from_group)
      map("n", "<C-r>", remove_from_group)
      
      return true
    end,
  }):find()
end

local function filter_by_group(opts)
  opts = opts or {}
  
  local groups = buffer_groups.list_groups()
  
  -- Add "All Buffers" and "Ungrouped" options
  local choices = { "All Buffers", "Ungrouped" }
  vim.list_extend(choices, groups)
  
  vim.ui.select(choices, { prompt = "Filter by group: " }, function(choice)
    if not choice then return end
    
    if choice == "All Buffers" then
      buffer_picker(opts)
    elseif choice == "Ungrouped" then
      -- Filter to show only ungrouped buffers
      buffer_picker(vim.tbl_extend("force", opts, { filter_ungrouped = true }))
    else
      buffer_picker(vim.tbl_extend("force", opts, { filter_group = choice }))
    end
  end)
end

return telescope.register_extension({
  setup = function(ext_config)
    buffer_groups.setup()
  end,
  exports = {
    buffer_groups = buffer_picker,
    manage_groups = manage_groups,
    group_buffers = group_buffers,
    filter_by_group = filter_by_group,
  },
})