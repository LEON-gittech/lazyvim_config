local M = {}

-- Smart go to definition that:
-- - Jumps directly if there's only one result
-- - Shows list if there are multiple results
-- - Shows helpful message if none found
function M.smart_goto_definition()
  local params = vim.lsp.util.make_position_params()
  
  vim.lsp.buf_request(0, "textDocument/definition", params, function(err, result, ctx, config)
    if err then
      vim.notify("Error getting definition: " .. vim.inspect(err), vim.log.levels.ERROR)
      return
    end
    
    if not result or vim.tbl_isempty(result) then
      vim.notify("No definition found", vim.log.levels.INFO)
      return
    end
    
    -- Handle both single result and array of results
    local results = {}
    if result.uri or result.targetUri then
      -- Single result
      results = { result }
    else
      -- Array of results
      results = result
    end
    
    if #results == 1 then
      -- Single result: jump directly
      vim.lsp.util.jump_to_location(results[1], "utf-8")
      vim.notify("Jumped to definition", vim.log.levels.INFO)
    else
      -- Multiple results: show telescope picker
      require("telescope.builtin").lsp_definitions()
    end
  end)
end

-- Smart go to implementation with fallback handling
function M.smart_goto_implementation()
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
  
  local params = vim.lsp.util.make_position_params()
  
  vim.lsp.buf_request(0, "textDocument/implementation", params, function(err, result, ctx, config)
    if err then
      vim.notify("Error getting implementation: " .. vim.inspect(err), vim.log.levels.ERROR)
      return
    end
    
    if not result or vim.tbl_isempty(result) then
      vim.notify("No implementation found", vim.log.levels.INFO)
      return
    end
    
    -- Handle both single result and array of results
    local results = {}
    if result.uri or result.targetUri then
      -- Single result
      results = { result }
    else
      -- Array of results
      results = result
    end
    
    if #results == 1 then
      -- Single result: jump directly
      vim.lsp.util.jump_to_location(results[1], "utf-8")
      vim.notify("Jumped to implementation", vim.log.levels.INFO)
    else
      -- Multiple results: show telescope picker
      require("telescope.builtin").lsp_implementations()
    end
  end)
end

-- Enhanced references function that shows count
function M.smart_goto_references()
  local params = vim.lsp.util.make_position_params()
  params.context = { includeDeclaration = true }
  
  vim.lsp.buf_request(0, "textDocument/references", params, function(err, result, ctx, config)
    if err then
      vim.notify("Error getting references: " .. vim.inspect(err), vim.log.levels.ERROR)
      return
    end
    
    if not result or vim.tbl_isempty(result) then
      vim.notify("No references found", vim.log.levels.INFO)
      return
    end
    
    vim.notify(string.format("Found %d reference(s)", #result), vim.log.levels.INFO)
    require("telescope.builtin").lsp_references()
  end)
end

return M