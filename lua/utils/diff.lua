local M = {}

-- Diff current buffer with a file
function M.diff_with_file()
  -- Get current buffer info
  local current_buf = vim.api.nvim_get_current_buf()
  local current_file = vim.api.nvim_buf_get_name(current_buf)
  
  -- Prompt for file to diff with
  vim.ui.input({
    prompt = "Diff with file: ",
    default = current_file,
    completion = "file",
  }, function(target_file)
    if not target_file or target_file == "" then
      return
    end
    
    -- Expand the path
    target_file = vim.fn.expand(target_file)
    
    -- Check if file exists
    if vim.fn.filereadable(target_file) == 0 then
      vim.notify("File not found: " .. target_file, vim.log.levels.ERROR)
      return
    end
    
    -- Open the target file in a vertical split
    vim.cmd("vertical diffsplit " .. vim.fn.fnameescape(target_file))
  end)
end

-- Diff current buffer with clipboard content
function M.diff_with_clipboard()
  -- Get clipboard content
  local clipboard_content = vim.fn.getreg("+")
  
  if not clipboard_content or clipboard_content == "" then
    vim.notify("Clipboard is empty", vim.log.levels.WARN)
    return
  end
  
  -- Create a temporary buffer with clipboard content
  vim.cmd("vertical new")
  local temp_buf = vim.api.nvim_get_current_buf()
  
  -- Set buffer options
  vim.bo[temp_buf].buftype = "nofile"
  vim.bo[temp_buf].bufhidden = "wipe"
  vim.bo[temp_buf].swapfile = false
  vim.bo[temp_buf].filetype = vim.bo[vim.fn.winbufnr(vim.fn.winnr("#"))].filetype -- inherit filetype
  
  -- Set buffer name
  vim.api.nvim_buf_set_name(temp_buf, "[Clipboard]")
  
  -- Insert clipboard content
  local lines = vim.split(clipboard_content, "\n")
  vim.api.nvim_buf_set_lines(temp_buf, 0, -1, false, lines)
  
  -- Start diff mode
  vim.cmd("diffthis")
  
  -- Go back to original window and start diff
  vim.cmd("wincmd p")
  vim.cmd("diffthis")
  
  vim.notify("Diffing with clipboard content", vim.log.levels.INFO)
end

-- Diff current buffer with system clipboard using external diff tool
function M.diff_with_clipboard_external()
  local clipboard_content = vim.fn.getreg("+")
  
  if not clipboard_content or clipboard_content == "" then
    vim.notify("Clipboard is empty", vim.log.levels.WARN)
    return
  end
  
  -- Create temporary file for clipboard content
  local temp_file = vim.fn.tempname()
  local file = io.open(temp_file, "w")
  if file then
    file:write(clipboard_content)
    file:close()
    
    -- Use Diffview if available
    local ok, _ = pcall(require, "diffview")
    if ok then
      vim.cmd("DiffviewOpen " .. temp_file)
    else
      -- Fallback to built-in diff
      vim.cmd("vertical diffsplit " .. temp_file)
    end
    
    -- Clean up temp file after a delay
    vim.defer_fn(function()
      os.remove(temp_file)
    end, 5000)
  else
    vim.notify("Failed to create temporary file", vim.log.levels.ERROR)
  end
end

-- Diff current buffer with another buffer
function M.diff_with_buffer()
  -- Get list of all buffers
  local buffers = vim.tbl_filter(function(buf)
    return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted
  end, vim.api.nvim_list_bufs())
  
  -- Get current buffer
  local current_buf = vim.api.nvim_get_current_buf()
  
  -- Remove current buffer from list
  buffers = vim.tbl_filter(function(buf)
    return buf ~= current_buf
  end, buffers)
  
  if #buffers == 0 then
    vim.notify("No other buffers to diff with", vim.log.levels.WARN)
    return
  end
  
  -- Create choices for selection
  local choices = {}
  for _, buf in ipairs(buffers) do
    local name = vim.api.nvim_buf_get_name(buf)
    if name == "" then
      name = "[No Name]"
    else
      name = vim.fn.fnamemodify(name, ":t")
    end
    table.insert(choices, { buf = buf, name = name })
  end
  
  -- Let user select buffer
  vim.ui.select(choices, {
    prompt = "Select buffer to diff with: ",
    format_item = function(item) return item.name end,
  }, function(choice)
    if not choice then return end
    
    -- Open selected buffer in split and diff
    vim.cmd("vertical sb " .. choice.buf)
    vim.cmd("diffthis")
    vim.cmd("wincmd p")
    vim.cmd("diffthis")
  end)
end

-- Diff with git version (requires fugitive or gitsigns)
function M.diff_with_git()
  -- Try to use Gitsigns if available
  local ok, gitsigns = pcall(require, "gitsigns")
  if ok then
    gitsigns.diffthis()
    return
  end
  
  -- Try to use Fugitive if available
  if vim.fn.exists(":Gdiffsplit") > 0 then
    vim.cmd("Gdiffsplit")
    return
  end
  
  -- Try to use Diffview if available
  local ok_diffview, _ = pcall(require, "diffview")
  if ok_diffview then
    vim.cmd("DiffviewOpen HEAD -- %")
    return
  end
  
  vim.notify("No git diff plugin available (install gitsigns, fugitive, or diffview)", vim.log.levels.WARN)
end

-- Close all diff windows
function M.diff_close()
  vim.cmd("diffoff!")
  vim.cmd("only")
end

-- Toggle diff mode for current window
function M.diff_toggle()
  if vim.wo.diff then
    vim.cmd("diffoff")
    vim.notify("Diff mode disabled", vim.log.levels.INFO)
  else
    vim.cmd("diffthis")
    vim.notify("Diff mode enabled", vim.log.levels.INFO)
  end
end

return M