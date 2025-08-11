return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    -- Default component configurations  
    default_component_configs = {
      container = {
        enable_character_fade = false, -- Disable fade to show full text
        width = "100%",
        right_padding = 0,
      },
      name = {
        trailing_slash = false,
        use_git_status_colors = true,
        highlight = "NeoTreeFileName",
      },
      -- Custom renderer for name to support wrapping
      indent = {
        indent_size = 2,
        padding = 1,
        with_markers = true,
        indent_marker = "│",
        last_indent_marker = "└",
        highlight = "NeoTreeIndentMarker",
      },
    },
    -- Window configuration
    window = {
      position = "left",
      width = 30,
      mapping_options = {
        noremap = true,
        nowait = true,
      },
      -- Neo-tree window configuration
      window_options = {
        -- Note: wrap is controlled by neo-tree internally and cannot be overridden
        -- Use custom name components for better filename display control
      },
      mappings = {
        ["<"] = "prev_source",
        [">"] = "next_source",
        ["<C-Left>"] = function() 
          vim.cmd("vertical resize -2")
          vim.defer_fn(function()
            require("neo-tree.sources.manager").refresh("filesystem")
          end, 10)
        end,
        ["<C-Right>"] = function() 
          vim.cmd("vertical resize +2")
          vim.defer_fn(function()
            require("neo-tree.sources.manager").refresh("filesystem")
          end, 10)
        end,
        ["<M-,>"] = function() 
          vim.cmd("vertical resize -5")
          vim.defer_fn(function()
            require("neo-tree.sources.manager").refresh("filesystem")
          end, 10)
        end,
        ["<M-.>"] = function() 
          vim.cmd("vertical resize +5")
          vim.defer_fn(function()
            require("neo-tree.sources.manager").refresh("filesystem")
          end, 10)
        end,
      },
    },
    -- Enable auto-expand for long filenames
    filesystem = {
      hijack_netrw_behavior = "disabled", -- 禁用自动打开
      window = {
        width = 30,
        mappings = {
          ["m"] = "move", -- 恢复默认的 move 命令
          ["M"] = "move_visual", -- 多选移动
          ["<C-m>"] = "move_with_telescope", -- 使用 Telescope 移动
          ["gm"] = "move_from_root",
          ["r"] = "rename_with_input",
        },
      },
    },
    commands = {
      -- Move visual (support multi-selection)
      move_visual = function(state, selected_nodes)
        local renderer = require("neo-tree.ui.renderer")
        
        -- Get selected nodes or current node
        local nodes = selected_nodes or {}
        if #nodes == 0 then
          local node = state.tree:get_node()
          if node then
            nodes = { node }
          end
        end
        
        if #nodes == 0 then
          vim.notify("No files selected", vim.log.levels.WARN)
          return
        end
        
        -- Get project root for default destination
        local project_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
        if vim.v.shell_error ~= 0 then
          project_root = vim.fn.getcwd()
        end
        
        -- Show file names being moved
        local file_names = {}
        for _, node in ipairs(nodes) do
          table.insert(file_names, vim.fn.fnamemodify(node.path, ":t"))
        end
        local files_str = table.concat(file_names, ", ")
        if #files_str > 50 then
          files_str = files_str:sub(1, 47) .. "..."
        end
        
        -- Ask for destination
        vim.ui.input({
          prompt = "Move " .. #nodes .. " file(s) to: ",
          default = project_root .. "/",
          completion = "file",
        }, function(destination)
          if not destination or destination == "" then
            return
          end
          
          -- Expand destination path
          destination = vim.fn.expand(destination)
          
          -- If destination is not a directory, create it
          if vim.fn.isdirectory(destination) == 0 then
            vim.fn.mkdir(destination, "p")
          end
          
          -- Move each file
          local success_count = 0
          local errors = {}
          
          for _, node in ipairs(nodes) do
            local source = node.path
            local name = vim.fn.fnamemodify(source, ":t")
            local dest = destination .. "/" .. name
            
            -- Check if destination exists
            if vim.fn.filereadable(dest) == 1 or vim.fn.isdirectory(dest) == 1 then
              table.insert(errors, name .. " already exists at destination")
            else
              local ok, err = pcall(function()
                vim.fn.rename(source, dest)
              end)
              
              if ok then
                success_count = success_count + 1
              else
                table.insert(errors, name .. ": " .. (err or "unknown error"))
              end
            end
          end
          
          -- Report results
          if success_count > 0 then
            vim.notify("Moved " .. success_count .. " file(s) to " .. destination, vim.log.levels.INFO)
          end
          
          if #errors > 0 then
            vim.notify("Errors:\n" .. table.concat(errors, "\n"), vim.log.levels.ERROR)
          end
          
          -- Refresh neo-tree
          require("neo-tree.sources.manager").refresh("filesystem")
        end)
      end,
      
      -- Custom move command with Telescope file browser
      move_with_telescope = function(state)
        local node = state.tree:get_node()
        local source_path = node:get_id()
        local source_name = vim.fn.fnamemodify(source_path, ":t")
        
        -- Get project root (try git root first, then cwd)
        local project_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
        if vim.v.shell_error ~= 0 then
          project_root = vim.fn.getcwd()
        end
        
        -- Use Telescope file browser to select destination
        require("telescope").extensions.file_browser.file_browser({
          prompt_title = "Move '" .. source_name .. "' to:",
          path = project_root,  -- Start from project root
          cwd = project_root,   -- Set cwd to project root
          hidden = true,
          respect_gitignore = false,
          grouped = true,
          files = false, -- Only show directories
          display_stat = false,
          initial_mode = "normal", -- Start in normal mode for easier navigation
          attach_mappings = function(prompt_bufnr, map)
            local actions = require("telescope.actions")
            local fb_actions = require("telescope").extensions.file_browser.actions
            local action_state = require("telescope.actions.state")
            
            -- Override default action to use selection as destination
            actions.select_default:replace(function()
              local selection = action_state.get_selected_entry()
              if selection then
                local dest_dir = selection.path or selection[1]
                
                -- Make sure we have a directory path
                if vim.fn.isdirectory(dest_dir) == 0 then
                  dest_dir = vim.fn.fnamemodify(dest_dir, ":h")
                end
                
                -- Close telescope
                actions.close(prompt_bufnr)
                
                -- Ask for new name with path completion
                vim.ui.input({
                  prompt = "Move to: ",
                  default = dest_dir .. "/" .. source_name,
                  completion = "file",
                }, function(new_path)
                  if new_path and new_path ~= "" and new_path ~= source_path then
                    -- Create parent directory if it doesn't exist
                    local new_dir = vim.fn.fnamemodify(new_path, ":h")
                    vim.fn.mkdir(new_dir, "p")
                    
                    -- Perform the move
                    local success, err = pcall(function()
                      vim.fn.rename(source_path, new_path)
                    end)
                    
                    if success then
                      vim.notify("Moved: " .. source_name .. " → " .. vim.fn.fnamemodify(new_path, ":~:."))
                      require("neo-tree.sources.manager").refresh("filesystem")
                    else
                      vim.notify("Failed to move: " .. (err or "unknown error"), vim.log.levels.ERROR)
                    end
                  end
                end)
              end
            end)
            
            -- Add mapping to toggle between files and directories
            map("i", "<C-f>", function()
              local current_picker = action_state.get_current_picker(prompt_bufnr)
              local finder = current_picker.finder
              finder.files = not finder.files
              current_picker:refresh(finder, { reset_prompt = false })
            end)
            
            -- Add mapping for direct input
            map("i", "<C-p>", function()
              actions.close(prompt_bufnr)
              vim.ui.input({
                prompt = "Move to: ",
                default = source_path,
                completion = "file",
              }, function(new_path)
                if new_path and new_path ~= "" and new_path ~= source_path then
                  -- Create parent directory if needed
                  local new_dir = vim.fn.fnamemodify(new_path, ":h")
                  vim.fn.mkdir(new_dir, "p")
                  
                  local success, err = pcall(function()
                    vim.fn.rename(source_path, new_path)
                  end)
                  
                  if success then
                    vim.notify("Moved: " .. source_name .. " → " .. vim.fn.fnamemodify(new_path, ":~:."))
                    require("neo-tree.sources.manager").refresh("filesystem")
                  else
                    vim.notify("Failed to move: " .. (err or "unknown error"), vim.log.levels.ERROR)
                  end
                end
              end)
            end)
            
            return true
          end,
        })
      end,
      
      -- Quick move with path completion
      move_quick = function(state)
        local node = state.tree:get_node()
        local source_path = node:get_id()
        local source_name = vim.fn.fnamemodify(source_path, ":t")
        local source_dir = vim.fn.fnamemodify(source_path, ":h")
        
        vim.ui.input({
          prompt = "Move to (use Tab for completion, ../ for parent): ",
          default = source_path,
          completion = "file",
        }, function(new_path)
          if new_path and new_path ~= "" and new_path ~= source_path then
            -- Handle relative paths
            if new_path:sub(1, 1) ~= "/" then
              -- If starts with ../, resolve relative to source directory
              if new_path:match("^%.%.") then
                new_path = vim.fn.simplify(source_dir .. "/" .. new_path)
              -- If starts with ./, resolve relative to source directory  
              elseif new_path:match("^%.") then
                new_path = vim.fn.simplify(source_dir .. "/" .. new_path)
              -- Otherwise, treat as relative to source directory
              else
                new_path = source_dir .. "/" .. new_path
              end
            end
            
            -- Expand ~ and environment variables
            new_path = vim.fn.expand(new_path)
            
            -- If only directory given, append filename
            if vim.fn.isdirectory(new_path) == 1 then
              new_path = new_path .. "/" .. source_name
            end
            
            -- Create parent directory if needed
            local new_dir = vim.fn.fnamemodify(new_path, ":h")
            vim.fn.mkdir(new_dir, "p")
            
            local success, err = pcall(function()
              vim.fn.rename(source_path, new_path)
            end)
            
            if success then
              vim.notify("Moved: " .. source_name .. " → " .. vim.fn.fnamemodify(new_path, ":~:."))
              require("neo-tree.sources.manager").refresh("filesystem")
            else
              vim.notify("Failed to move: " .. (err or "unknown error"), vim.log.levels.ERROR)
            end
          end
        end)
      end,
      
      -- Move from project root
      move_from_root = function(state)
        local node = state.tree:get_node()
        local source_path = node:get_id()
        local source_name = vim.fn.fnamemodify(source_path, ":t")
        
        -- Get project root
        local project_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
        if vim.v.shell_error ~= 0 then
          project_root = vim.fn.getcwd()
        end
        
        -- Get relative path from project root
        local relative_path = vim.fn.fnamemodify(source_path, ":~:.")
        
        vim.ui.input({
          prompt = "Move to (relative to project root): ",
          default = relative_path,
          completion = "file",
        }, function(new_path)
          if new_path and new_path ~= "" then
            -- Handle relative paths from project root
            if new_path:sub(1, 1) ~= "/" then
              new_path = project_root .. "/" .. new_path
            end
            
            -- Expand ~ and environment variables
            new_path = vim.fn.expand(new_path)
            
            -- If same as source, skip
            if new_path == source_path then
              return
            end
            
            -- If only directory given, append filename
            if vim.fn.isdirectory(new_path) == 1 then
              new_path = new_path .. "/" .. source_name
            end
            
            -- Create parent directory if needed
            local new_dir = vim.fn.fnamemodify(new_path, ":h")
            vim.fn.mkdir(new_dir, "p")
            
            local success, err = pcall(function()
              vim.fn.rename(source_path, new_path)
            end)
            
            if success then
              vim.notify("Moved: " .. source_name .. " → " .. vim.fn.fnamemodify(new_path, ":~:."))
              require("neo-tree.sources.manager").refresh("filesystem")
            else
              vim.notify("Failed to move: " .. (err or "unknown error"), vim.log.levels.ERROR)
            end
          end
        end)
      end,
      
      -- Custom rename with better input
      rename_with_input = function(state)
        local node = state.tree:get_node()
        local path = node:get_id()
        local name = vim.fn.fnamemodify(path, ":t")
        local dir = vim.fn.fnamemodify(path, ":h")
        
        vim.ui.input({
          prompt = "Rename: ",
          default = name,
          completion = "file",
        }, function(new_name)
          if new_name and new_name ~= "" and new_name ~= name then
            local new_path
            -- If new_name contains path separator, treat as full path
            if new_name:match("[/\\]") then
              -- If it's an absolute path, use as is
              if new_name:sub(1, 1) == "/" then
                new_path = new_name
              else
                -- Otherwise, treat as relative to current directory
                new_path = dir .. "/" .. new_name
              end
            else
              -- Just rename in same directory
              new_path = dir .. "/" .. new_name
            end
            
            local success, err = pcall(function()
              vim.fn.rename(path, new_path)
            end)
            
            if success then
              vim.notify("Renamed: " .. name .. " → " .. new_name)
              require("neo-tree.sources.manager").refresh("filesystem")
            else
              vim.notify("Failed to rename: " .. (err or "unknown error"), vim.log.levels.ERROR)
            end
          end
        end)
      end,
    },
  },
  config = function(_, opts)
    -- Register custom components
    local cc = require("neo-tree.sources.common.components")
    local custom = require("neo-tree-custom-components")
    cc.name_smart = custom.name_smart
    cc.name_full = custom.name_full
    cc.name_wrapped = custom.name_wrapped
    cc.name_dynamic = custom.name_dynamic
    
    -- Choose your preferred name display strategy:
    -- "name_wrapped" - Optimized truncation that maximizes visible content (RECOMMENDED)
    -- "name_dynamic" - Auto-adjusts neo-tree width based on longest filename
    -- "name_full" - Shows complete filenames (causes horizontal scrolling)
    -- "name_smart" - Intelligent truncation preserving extensions
    -- "name" - Default neo-tree behavior
    local name_component = "name_wrapped"  -- Change this to switch modes
    
    -- Add renderers configuration to opts before setup
    opts.renderers = {
      directory = {
        { "indent" },
        { "icon" },
        { name_component, use_git_status_colors = true },
        { "diagnostics" },
        { "git_status" },
      },
      file = {
        { "indent" },
        { "icon" },
        { name_component, use_git_status_colors = true },
        { "diagnostics" },
        { "git_status" },
      },
    }
    
    require("neo-tree").setup(opts)
    
    -- Configure neo-tree window behavior based on name component choice
    vim.api.nvim_create_autocmd({"FileType", "BufEnter", "BufWinEnter"}, {
      pattern = "neo-tree",
      callback = function()
        local buf = vim.api.nvim_get_current_buf()
        local win = vim.api.nvim_get_current_win()
        
        vim.schedule(function()
          if vim.api.nvim_win_is_valid(win) and vim.bo[buf].filetype == "neo-tree" then
            if name_component == "name_full" then
              -- Allow horizontal scrolling for full filenames  
              vim.wo[win].wrap = false
              vim.wo[win].sidescrolloff = 0
              vim.wo[win].sidescroll = 1
            end
            -- Note: name_wrapped uses intelligent truncation, no special window settings needed
            -- Note: name_dynamic will auto-adjust window width as needed
          end
        end)
        
        -- Store the initial width for comparison (used by name_dynamic)
        vim.b.neotree_last_width = vim.api.nvim_win_get_width(win)
      end,
    })
    
    -- Auto-refresh neo-tree on window resize
    vim.api.nvim_create_autocmd({"WinResized", "VimResized"}, {
      callback = function()
        -- Check all neo-tree windows
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          local buf = vim.api.nvim_win_get_buf(win)
          local ft = vim.api.nvim_buf_get_option(buf, "filetype")
          
          if ft == "neo-tree" then
            local current_width = vim.api.nvim_win_get_width(win)
            local last_width = vim.b[buf].neotree_last_width or 0
            
            -- Only refresh if width actually changed
            if current_width ~= last_width then
              vim.b[buf].neotree_last_width = current_width
              
              -- Refresh neo-tree to re-render with new width
              local ok, manager = pcall(require, "neo-tree.sources.manager")
              if ok then
                -- Small delay to ensure resize is complete
                vim.defer_fn(function()
                  manager.refresh("filesystem")
                end, 50)
              end
            end
          end
        end
      end,
    })
  end,
}