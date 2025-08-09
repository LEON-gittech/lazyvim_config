return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      hijack_netrw_behavior = "disabled", -- 禁用自动打开
      window = {
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
    require("neo-tree").setup(opts)
    
    -- Disable horizontal scrolling in neo-tree windows
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "neo-tree",
      callback = function()
        local buf = vim.api.nvim_get_current_buf()
        -- Disable horizontal scroll wheel events
        vim.keymap.set({"n", "i", "v"}, "<ScrollWheelLeft>", "<nop>", { buffer = buf, silent = true })
        vim.keymap.set({"n", "i", "v"}, "<ScrollWheelRight>", "<nop>", { buffer = buf, silent = true })
        vim.keymap.set({"n", "i", "v"}, "<S-ScrollWheelLeft>", "<nop>", { buffer = buf, silent = true })
        vim.keymap.set({"n", "i", "v"}, "<S-ScrollWheelRight>", "<nop>", { buffer = buf, silent = true })
        vim.keymap.set({"n", "i", "v"}, "<C-ScrollWheelLeft>", "<nop>", { buffer = buf, silent = true })
        vim.keymap.set({"n", "i", "v"}, "<C-ScrollWheelRight>", "<nop>", { buffer = buf, silent = true })
      end,
    })
  end,
}