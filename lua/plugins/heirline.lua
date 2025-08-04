return {
  "rebelot/heirline.nvim",
  dependencies = {
    "AstroNvim/astrocore",
  },
  opts = function(_, opts)
    local status = require("astroui.status")
    local buffer_groups = require("utils.buffer_groups")
    local get_icon = require("astroui").get_icon
    
    -- Buffer Groups Component for statusline
    local BufferGroups = {
      condition = function()
        return #buffer_groups.get_buffer_groups() > 0
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
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "BufDelete", "TabEnter" }, {
      group = vim.api.nvim_create_augroup("BufferGroupsHeirline", { clear = true }),
      callback = function()
        vim.api.nvim_exec_autocmds("User", { pattern = "BufferGroupsUpdate" })
        vim.cmd.redrawstatus()
        vim.cmd.redrawtabline()
      end,
    })
    
    -- Track current group for visual separators
    local current_group = nil
    local group_map = {}
    
    -- Build group map on startup and changes
    local function update_group_map()
      group_map = {}
      local groups = buffer_groups.get_buffers_by_groups()
      for _, group in ipairs(groups) do
        for _, bufnr in ipairs(group.buffers) do
          group_map[bufnr] = group.name
        end
      end
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
    
    -- Override the tabline file info component to add group indicators
    if opts.tabline then
      -- Find the buflist component (usually at position 2)
      for i, component in ipairs(opts.tabline) do
        if type(component) == "table" and component.init then
          -- This is likely the buflist, wrap the file info component
          local original_make_buflist = status.heirline.make_buflist
          
          -- Create a wrapper that adds group information
          status.heirline.make_buflist = function(file_component)
            -- Wrap the file component to add group prefix
            local wrapped_component = {
              init = function(self)
                if file_component.init then
                  file_component.init(self)
                end
                
                -- Check if we need to show group separator
                local bufnr = self.bufnr
                local this_group = group_map[bufnr] or "Ungrouped"
                
                if current_group ~= this_group then
                  self.show_group_separator = true
                  self.group_name = this_group
                  current_group = this_group
                else
                  self.show_group_separator = false
                end
              end,
              {
                -- Group separator
                condition = function(self) return self.show_group_separator end,
                {
                  provider = function(self)
                    return " " .. get_icon("FolderClosed") .. " " .. self.group_name .. " "
                  end,
                  hl = function(self)
                    local color_idx = buffer_groups.get_group_color(self.group_name)
                    local color = buffer_groups.group_colors[color_idx]
                    return { 
                      fg = color.fg, 
                      bg = color.bg or "tabline_bg", 
                      bold = true 
                    }
                  end,
                },
              },
              -- Original file component
              file_component,
            }
            
            return original_make_buflist(wrapped_component)
          end
          
          -- Re-create the buflist with our wrapper
          opts.tabline[i] = status.heirline.make_buflist(status.component.tabline_file_info())
          break
        end
      end
    end
    
    -- Ensure vim.t.bufs is sorted by groups
    local function update_tabline()
      update_group_map()
      
      local bufs = {}
      local groups = buffer_groups.get_buffers_by_groups()
      
      -- Reset current group for next redraw
      current_group = nil
      
      -- Add buffers in group order
      for _, group in ipairs(groups) do
        for _, bufnr in ipairs(group.buffers) do
          if not vim.tbl_contains(bufs, bufnr) then
            table.insert(bufs, bufnr)
          end
        end
      end
      
      vim.t.bufs = bufs
      vim.cmd.redrawtabline()
    end
    
    vim.api.nvim_create_autocmd({ "TabEnter", "BufAdd", "BufDelete" }, {
      group = vim.api.nvim_create_augroup("BufferGroupsTablineSort", { clear = true }),
      callback = update_tabline,
    })
    
    -- Also update on BufferGroupsUpdate event
    vim.api.nvim_create_autocmd("User", {
      pattern = "BufferGroupsUpdate",
      group = vim.api.nvim_create_augroup("BufferGroupsTablineUpdate", { clear = true }),
      callback = update_tabline,
    })
    
    -- Initial setup
    update_group_map()
    
    return opts
  end,
}