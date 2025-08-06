-- Custom Git Commits Picker with Time Display
-- Workaround for telescope git_command not working properly
return {
  "nvim-telescope/telescope.nvim",
  keys = {
    { "<leader>gc", "<cmd>GitCommits<cr>", desc = "Git Commits (with time)" },
    { "<leader>gC", "<cmd>GitBCommits<cr>", desc = "Git Buffer Commits (with time)" },
  },
  config = function()
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local previewers = require("telescope.previewers")
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local conf = require("telescope.config").values
    local entry_display = require("telescope.pickers.entry_display")
    
    -- Create displayer for git commits with time
    local displayer = entry_display.create({
      separator = " │ ",
      items = {
        { width = 8 },      -- commit hash
        { width = 19 },     -- date time
        { width = 15 },     -- author
        { remaining = true }, -- commit message
      },
    })
    
    -- Entry maker for git commits with time
    local function make_entry_maker(opts)
      return function(entry)
        if entry == "" then
          return nil
        end
        
        -- Parse git output: hash|date|author|message
        local parts = vim.split(entry, "|", { plain = true })
        if #parts < 4 then
          return nil
        end
        
        local hash = parts[1]
        local date = parts[2]
        local author = parts[3]
        local message = parts[4]
        
        return {
          value = hash,
          ordinal = hash .. " " .. date .. " " .. message .. " " .. author,
          display = function()
            return displayer({
              { hash, "TelescopeResultsNumber" },
              { date, "TelescopeResultsConstant" }, 
              { author, "TelescopeResultsIdentifier" },
              message,
            })
          end,
          hash = hash,
          date = date,
          author = author,
          message = message,
        }
      end
    end
    
    -- Custom git commits picker
    local function git_commits_with_time(opts)
      opts = opts or {}
      
      local cmd = {
        "git",
        "log",
        "--pretty=format:%h|%ad|%an|%s",
        "--date=format:%Y-%m-%d %H:%M:%S",
        "--abbrev-commit",
      }
      
      -- Add file path for bcommits
      if opts.current_file then
        table.insert(cmd, "--")
        table.insert(cmd, vim.fn.expand("%"))
      end
      
      pickers.new(opts, {
        prompt_title = opts.current_file and "Git Buffer Commits" or "Git Commits",
        finder = finders.new_oneshot_job(cmd, {
          entry_maker = make_entry_maker(opts),
        }),
        sorter = conf.generic_sorter(opts),
        previewer = previewers.git_commit_diff_to_parent.new(opts),
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            local entry = action_state.get_selected_entry()
            if entry then
              actions.close(prompt_bufnr)
              -- Show commit details
              vim.cmd("Git show " .. entry.hash)
            end
          end)
          return true
        end,
      }):find()
    end
    
    -- Create user commands
    vim.api.nvim_create_user_command("GitCommits", function()
      git_commits_with_time()
    end, { desc = "Show git commits with time" })
    
    vim.api.nvim_create_user_command("GitBCommits", function()
      git_commits_with_time({ current_file = true })
    end, { desc = "Show git commits for current buffer with time" })
    
    -- Override default telescope git pickers to use our custom ones
    local builtin = require("telescope.builtin")
    local original_git_commits = builtin.git_commits
    local original_git_bcommits = builtin.git_bcommits
    
    builtin.git_commits = function(opts)
      git_commits_with_time(opts)
    end
    
    builtin.git_bcommits = function(opts)
      git_commits_with_time(vim.tbl_extend("force", opts or {}, { current_file = true }))
    end
  end,
}