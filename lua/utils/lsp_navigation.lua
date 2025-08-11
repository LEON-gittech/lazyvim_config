local M = {}

-- Ensure LSP is started for the current buffer
local function ensure_lsp_started()
  local clients = vim.lsp.get_active_clients({ bufnr = 0 })
  if #clients == 0 then
    -- Try to start LSP
    vim.cmd.LspStart()
    -- Wait a bit for LSP to start
    vim.wait(1000, function()
      clients = vim.lsp.get_active_clients({ bufnr = 0 })
      return #clients > 0
    end, 100)
    
    if #clients == 0 then
      vim.notify("No LSP server available for this file type", vim.log.levels.WARN)
      return false
    end
  end
  return true
end

-- Smart go to definition that:
-- - Ensures LSP is started
-- - Jumps directly if there's only one result
-- - Shows list if there are multiple results
-- - Shows helpful message if none found
function M.smart_goto_definition()
  -- Ensure LSP is started
  if not ensure_lsp_started() then
    return
  end
  
  -- Use vim.lsp.buf.definition which handles single/multiple results properly
  vim.lsp.buf.definition()
end

-- Smart go to implementation with fallback handling
function M.smart_goto_implementation()
  -- Ensure LSP is started
  if not ensure_lsp_started() then
    return
  end
  
  -- Check if any attached LSP client supports implementation
  local clients = vim.lsp.get_active_clients({ bufnr = 0 })
  local supports_implementation = false
  
  for _, client in ipairs(clients) do
    if client.supports_method("textDocument/implementation") then
      supports_implementation = true
      break
    end
  end
  
  if not supports_implementation then
    vim.notify("Implementation not supported by current language server", vim.log.levels.WARN)
    return
  end
  
  -- Use vim.lsp.buf.implementation which handles single/multiple results properly
  vim.lsp.buf.implementation()
end

-- Enhanced references function
function M.smart_goto_references()
  -- Ensure LSP is started
  if not ensure_lsp_started() then
    return
  end
  
  -- Custom previewer that correctly positions the cursor
  local previewers = require("telescope.previewers")
  local from_entry = require("telescope.from_entry")
  local conf = require("telescope.config").values
  
  local custom_previewer = previewers.new_buffer_previewer({
    title = "LSP References Preview",
    get_buffer_by_name = function(_, entry)
      return from_entry.path(entry, false, false)
    end,
    define_preview = function(self, entry)
      local p = from_entry.path(entry, true, false)
      if p == nil or p == "" then
        return
      end
      
      conf.buffer_previewer_maker(p, self.state.bufnr, {
        bufname = self.state.bufname,
        winid = self.state.winid,
        callback = function(bufnr)
          -- Clear previous highlights
          pcall(vim.api.nvim_buf_clear_namespace, bufnr, vim.api.nvim_create_namespace("telescope_preview"), 0, -1)
          
          if entry.lnum and entry.lnum > 0 then
            -- Highlight the line
            pcall(
              vim.api.nvim_buf_add_highlight,
              bufnr,
              vim.api.nvim_create_namespace("telescope_preview"),
              "TelescopePreviewLine",
              entry.lnum - 1,
              0,
              -1
            )
            
            -- Position cursor exactly at the referenced line (not middle of range)
            pcall(vim.api.nvim_win_set_cursor, self.state.winid, { entry.lnum, 0 })
            
            -- Center the view on the cursor
            vim.api.nvim_buf_call(bufnr, function()
              vim.cmd("norm! zz")
            end)
          end
        end,
      })
    end,
  })
  
  -- Use telescope's lsp_references with custom previewer
  require("telescope.builtin").lsp_references({
    include_declaration = true,
    previewer = custom_previewer,
  })
end

-- Smart go to declaration with fallback to definition
function M.smart_goto_declaration()
  -- Ensure LSP is started
  if not ensure_lsp_started() then
    return
  end
  
  -- Check if any client supports declaration
  local clients = vim.lsp.get_active_clients({ bufnr = 0 })
  local supports_declaration = false
  
  for _, client in ipairs(clients) do
    if client.supports_method("textDocument/declaration") then
      supports_declaration = true
      break
    end
  end
  
  if supports_declaration then
    vim.lsp.buf.declaration()
  else
    -- Fallback to definition if declaration not supported
    vim.notify("Declaration not supported, using definition instead", vim.log.levels.INFO)
    M.smart_goto_definition()
  end
end

return M