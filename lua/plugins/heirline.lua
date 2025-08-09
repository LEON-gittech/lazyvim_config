return {
  "rebelot/heirline.nvim",
  dependencies = {
    "AstroNvim/astrocore",
  },
  opts = function(_, opts)
    local status = require("astroui.status")
    local buffer_groups = require("utils.buffer_groups")
    local get_icon = require("astroui").get_icon
    
    -- Buffer Groups Component for statusline (temporarily disabled for debugging)
    local BufferGroups = {
      condition = function()
        return false -- Temporarily disabled
        -- Only show in reasonably sized windows to avoid E36 errors
        -- local win_width = vim.api.nvim_win_get_width(0)
        -- return win_width > 50 and #buffer_groups.get_buffer_groups() > 0
      end,
      update = {
        "User",
        pattern = { "BufferGroupsUpdate", "BufEnter" },
      },
      provider = function()
        local groups = buffer_groups.get_buffer_groups()
        if #groups > 0 then
          -- Create colored group names
          local colored_groups = {}
          for _, group in ipairs(groups) do
            local color_idx = buffer_groups.get_group_color(group)
            local color = buffer_groups.group_colors[color_idx]
            -- We'll use just the foreground color in text
            table.insert(colored_groups, group)
          end
          return " 󰷏 " .. table.concat(colored_groups, ", ") .. " "
        end
        return ""
      end,
      hl = function()
        -- Use the first group's color for the whole component
        local groups = buffer_groups.get_buffer_groups()
        if #groups > 0 then
          local color_idx = buffer_groups.get_group_color(groups[1])
          local color = buffer_groups.group_colors[color_idx]
          return { fg = color.fg, bg = "bg" }
        end
        return { fg = "purple", bg = "bg" }
      end,
      surround = {
        separator = "left",
        condition = false,
      },
    }
    
    -- Insert BufferGroups component into statusline
    if opts.statusline then
      -- Find position after file_info component
      local insert_pos = 4
      for i, component in ipairs(opts.statusline) do
        if component == status.component.file_info or 
           (type(component) == "table" and component.provider and 
            type(component.provider) == "function" and 
            tostring(component.provider):match("file_info")) then
          insert_pos = i + 1
          break
        end
      end
      
      -- Insert the BufferGroups component
      table.insert(opts.statusline, insert_pos, BufferGroups)
    end
    
    -- Create autocommand to refresh heirline when buffer groups change
    -- Use debouncing to avoid performance issues during search
    local redraw_timer = nil
    local function debounced_redraw()
      if redraw_timer then
        vim.fn.timer_stop(redraw_timer)
      end
      redraw_timer = vim.fn.timer_start(50, function()
        -- Don't redraw during command-line mode (search, commands, etc.)
        if vim.fn.mode() ~= "c" then
          -- Wrap in pcall to handle window size errors
          pcall(function()
            vim.api.nvim_exec_autocmds("User", { pattern = "BufferGroupsUpdate" })
            vim.cmd.redrawstatus()
            vim.cmd.redrawtabline()
          end)
        end
        redraw_timer = nil
      end)
    end
    
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "BufDelete", "TabEnter" }, {
      group = vim.api.nvim_create_augroup("BufferGroupsHeirline", { clear = true }),
      callback = function()
        -- Check if window has enough space
        local win_height = vim.api.nvim_win_get_height(0)
        local win_width = vim.api.nvim_win_get_width(0)
        -- Only redraw if window is reasonably sized
        if win_height > 5 and win_width > 20 then
          debounced_redraw()
        end
      end,
    })
    
    local group_map = {}
    
    -- Build group map on startup and changes
    local update_timer = nil
    local function update_group_map()
      -- Debounce updates
      if update_timer then
        vim.fn.timer_stop(update_timer)
      end
      update_timer = vim.fn.timer_start(100, function()
        group_map = {}
        local groups = buffer_groups.get_buffers_by_groups()
        
        -- First pass: collect all groups for each buffer
        for _, group in ipairs(groups) do
          if group.name ~= "Ungrouped" then  -- Handle ungrouped separately
            for _, bufnr in ipairs(group.buffers) do
              if vim.api.nvim_buf_is_valid(bufnr) then
                if not group_map[bufnr] then
                  group_map[bufnr] = {}
                end
                table.insert(group_map[bufnr], group.name)
              end
            end
          end
        end
        
        -- Second pass: mark ungrouped buffers
        for _, group in ipairs(groups) do
          if group.name == "Ungrouped" then
            for _, bufnr in ipairs(group.buffers) do
              if vim.api.nvim_buf_is_valid(bufnr) then
                if not group_map[bufnr] then
                  group_map[bufnr] = { "Ungrouped" }
                end
              end
            end
          end
        end
        update_timer = nil
      end)
    end
    
    -- Update group map when needed
    vim.api.nvim_create_autocmd({ "VimEnter", "BufAdd", "BufDelete" }, {
      group = vim.api.nvim_create_augroup("BufferGroupsMap", { clear = true }),
      callback = update_group_map,
    })
    
    -- Also update on User BufferGroupsUpdate event
    vim.api.nvim_create_autocmd("User", {
      pattern = "BufferGroupsUpdate",
      group = vim.api.nvim_create_augroup("BufferGroupsMapUpdate", { clear = true }),
      callback = update_group_map,
    })
    
    -- Create a group tag component for tabline that connects seamlessly
    local GroupTag = {
      static = {
        close_button = function() return "│" end,
      },
      condition = function()
        local win_width = vim.api.nvim_win_get_width(0)
        local current_buf = vim.api.nvim_get_current_buf()
        local filetype = vim.bo[current_buf].filetype
        local bufname = vim.api.nvim_buf_get_name(current_buf)
        
        -- Don't show in special buffers
        if filetype == "neo-tree" or 
           filetype == "NvimTree" or 
           filetype == "aerial" or 
           filetype == "qf" or 
           filetype == "help" or 
           bufname:match("neo%-tree") then
          return false
        end
        
        return win_width > 50  -- Only show in reasonably sized windows
      end,
      update = { "BufEnter", "TabEnter", "WinEnter" },
      provider = function()
        local current_buf = vim.api.nvim_get_current_buf()
        local group_context = buffer_groups.get_group_context()
        local current_groups = buffer_groups.get_buffer_groups(current_buf)
        
        -- Ensure current_groups is a table
        if type(current_groups) ~= "table" then
          current_groups = {}
        end
        
        -- Debug: force regenerate to avoid cache
        local result = ""
        
        -- Priority 1: Use telescope context if available and valid
        if group_context and group_context ~= "" then
          if group_context == "Ungrouped" and #current_groups == 0 then
            result = "📁Ungrouped"
          elseif vim.tbl_contains(current_groups, group_context) then
            result = "📁" .. group_context
          end
        end
        
        -- Priority 2: Show buffer's actual groups
        if result == "" then
          local group_count = #current_groups
          if group_count == 0 then
            result = "📁Ungrouped"
          elseif group_count == 1 then
            result = "📁" .. current_groups[1]
          else
            -- Multiple groups: show first + count (no spaces)
            result = "📂" .. current_groups[1] .. "(+" .. (group_count - 1) .. ")"
          end
        end
        
        return result
      end,
      hl = function()
        local current_buf = vim.api.nvim_get_current_buf()
        local group_context = buffer_groups.get_group_context()
        local current_groups = buffer_groups.get_buffer_groups(current_buf)
        
        -- Use context group color if available
        local target_group = nil
        if group_context and group_context ~= "Ungrouped" then
          if vim.tbl_contains(current_groups, group_context) then
            target_group = group_context
          end
        end
        
        -- Fallback to first group
        if not target_group and #current_groups > 0 then
          target_group = current_groups[1]
        end
        
        if target_group then
          local color_idx = buffer_groups.get_group_color(target_group)
          local color = buffer_groups.group_colors[color_idx]
          return { 
            fg = color.fg, 
            bg = "tabline_bg", 
            bold = true 
          }
        else
          -- Ungrouped style
          return { 
            fg = "gray", 
            bg = "tabline_bg", 
            bold = true 
          }
        end
      end,
      -- Add a tight separator after the group name
      {
        provider = function() return "│" end,
        hl = { fg = "gray", bg = "tabline_bg" },
      },
      on_click = {
        callback = function()
          vim.cmd("Telescope buffer_groups")
        end,
        name = "heirline_group_tag",
      },
    }

    -- Simple tabline with GroupTag at the beginning
    if opts.tabline then
      -- Find the buffer list component and add GroupTag before it
      for i, component in ipairs(opts.tabline) do
        if type(component) == "table" and component.init then
          -- This is the buffer list component, add GroupTag before it
          opts.tabline[i] = {
            GroupTag,
            component,  -- Original buffer list
          }
          break
        end
      end
    end
    
    -- Only show buffers from current buffer's group(s)
    local function update_tabline()
      update_group_map()
      
      local current_buf = vim.api.nvim_get_current_buf()
      local current_groups = buffer_groups.get_buffer_groups(current_buf)
      
      -- If current buffer has no groups, show all ungrouped buffers
      if #current_groups == 0 then
        current_groups = { "Ungrouped" }
      end
      
      local bufs = {}
      local groups = buffer_groups.get_buffers_by_groups()
      
      -- Only add buffers from the same group(s) as current buffer
      for _, group in ipairs(groups) do
        if vim.tbl_contains(current_groups, group.name) then
          for _, bufnr in ipairs(group.buffers) do
            if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buflisted then
              if not vim.tbl_contains(bufs, bufnr) then
                table.insert(bufs, bufnr)
              end
            end
          end
        end
      end
      
      -- If no buffers found (edge case), at least show current buffer
      if #bufs == 0 and vim.api.nvim_buf_is_valid(current_buf) then
        table.insert(bufs, current_buf)
      end
      
      vim.t.bufs = bufs
      vim.cmd.redrawtabline()
    end
    
    -- Update tabline when switching buffers
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "TabEnter" }, {
      group = vim.api.nvim_create_augroup("BufferGroupsTabline", { clear = true }),
      callback = function()
        -- Check if window has enough space
        local win_height = vim.api.nvim_win_get_height(0)
        local win_width = vim.api.nvim_win_get_width(0)
        -- Only update if window is reasonably sized
        if win_height > 5 and win_width > 20 then
          update_tabline()
        end
      end,
    })
    
    -- Also update when buffer groups change
    vim.api.nvim_create_autocmd("User", {
      pattern = "BufferGroupsUpdate",
      group = vim.api.nvim_create_augroup("BufferGroupsTablineUpdate", { clear = true }),
      callback = update_tabline,
    })
    
    return opts
  end,
}