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
    
    -- Create colored group displays
    for _, group in ipairs(groups) do
      local color_idx = buffer_groups.get_group_color(group)
      local color = buffer_groups.group_colors[color_idx]
      
      -- Create highlight group for this group if it doesn't exist
      local hl_name = "BufferGroup_" .. group:gsub("[^%w]", "_")
      vim.api.nvim_set_hl(0, hl_name, { fg = color.fg, bg = color.bg })
      
      table.insert(group_displays, { text = "[" .. group .. "]", hl = hl_name })
    end
    
    local group_str = #groups > 0 and table.concat(vim.tbl_map(function(g) return g.text end, group_displays), " ") or ""
    
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
      ordinal = get_buffer_display_name(bufnr) .. " " .. get_buffer_path(bufnr),
      display = function(entry)
        local display_items = {
          { tostring(entry.bufnr), "TelescopeResultsNumber" },
          { get_buffer_display_name(entry.bufnr), "TelescopeResultsIdentifier" },
          { get_buffer_path(entry.bufnr), "TelescopeResultsComment" },
        }
        
        -- Add colored group names
        if #groups > 0 then
          table.insert(display_items, { group_str, group_displays[1] and group_displays[1].hl or "TelescopeResultsFunction" })
        end
        
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
  
  local bufnrs = vim.tbl_filter(function(b)
    return vim.api.nvim_buf_is_valid(b) and vim.bo[b].buflisted
  end, vim.api.nvim_list_bufs())
  
  -- Filter by group if specified
  if opts.filter_group then
    local group_buffers = buffer_groups.get_group_buffers(opts.filter_group)
    bufnrs = vim.tbl_filter(function(b)
      return vim.tbl_contains(group_buffers, b)
    end, bufnrs)
  end
  
  local prompt_title = "Buffers"
  if opts.filter_group then
    prompt_title = "Buffers in: " .. opts.filter_group
  else
    prompt_title = "Buffers (C-f: filter, C-a: add to group, C-d: remove)"
  end
  
  pickers.new(opts, {
    prompt_title = prompt_title,
    finder = finders.new_table({
      results = bufnrs,
      entry_maker = make_buffer_entry(),
    }),
    sorter = conf.generic_sorter(opts),
    previewer = conf.grep_previewer(opts),
    attach_mappings = function(prompt_bufnr, map)
      local function filter_by_group()
        local groups = buffer_groups.list_groups()
        if #groups == 0 then
          vim.notify("No groups created yet", vim.log.levels.INFO)
          return
        end
        
        actions.close(prompt_bufnr)
        
        local choices = vim.list_extend({ "All Buffers" }, groups)
        vim.ui.select(choices, { prompt = "Filter by group: " }, function(choice)
          if not choice then 
            -- Re-open without filter if cancelled
            buffer_picker(opts)
            return 
          end
          
          if choice == "All Buffers" then
            buffer_picker(opts)
          else
            buffer_picker(vim.tbl_extend("force", opts, { filter_group = choice }))
          end
        end)
      end
      
      local function add_to_group()
        local entry = action_state.get_selected_entry()
        if not entry then 
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
        if not entry then return end
        
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
      
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        if entry then
          actions.close(prompt_bufnr)
          vim.api.nvim_set_current_buf(entry.bufnr)
        end
      end)
      
      local function delete_buffer_i()
        local entry = action_state.get_selected_entry()
        if not entry then 
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
        if not entry then 
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
      map("i", "<Tab>", actions.toggle_selection + actions.move_selection_next)
      map("n", "<Tab>", actions.toggle_selection + actions.move_selection_next)
      map("i", "<S-Tab>", actions.toggle_selection + actions.move_selection_previous)
      map("n", "<S-Tab>", actions.toggle_selection + actions.move_selection_previous)
      
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
  if #groups == 0 then
    vim.notify("No groups created yet", vim.log.levels.INFO)
    return
  end
  
  -- Add "All Buffers" option
  local choices = vim.list_extend({ "All Buffers" }, groups)
  
  vim.ui.select(choices, { prompt = "Filter by group: " }, function(choice)
    if not choice then return end
    
    if choice == "All Buffers" then
      buffer_picker(opts)
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