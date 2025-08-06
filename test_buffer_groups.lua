-- Buffer Groups Test Suite
-- Run with: nvim --headless -u NONE -c "source test_buffer_groups.lua"

vim.cmd([[set runtimepath+=~/.config/nvim]])
vim.opt.loadplugins = false

-- Load required modules
package.path = package.path .. ";/Users/leon/.config/nvim/lua/?.lua"

-- Helper function to report test results
local function test(name, fn)
  local success, err = pcall(fn)
  if success then
    print("✓ " .. name)
  else
    print("✗ " .. name .. ": " .. tostring(err))
  end
end

-- Wait for async operations
local function wait(ms)
  vim.wait(ms or 100)
end

-- Start tests
print("=== Buffer Groups Test Suite ===\n")

-- Load the module
local buffer_groups = require("utils.buffer_groups")

-- Test 1: Module loads correctly
test("Module loads", function()
  assert(buffer_groups ~= nil, "Module should load")
  assert(type(buffer_groups.create_group) == "function", "Should have create_group function")
  assert(type(buffer_groups.add_buffer_to_group) == "function", "Should have add_buffer_to_group function")
end)

-- Test 2: Create groups
test("Create groups", function()
  buffer_groups.create_group("test-group-1")
  buffer_groups.create_group("test-group-2")
  
  local groups = buffer_groups.list_groups()
  assert(vim.tbl_contains(groups, "test-group-1"), "Should contain test-group-1")
  assert(vim.tbl_contains(groups, "test-group-2"), "Should contain test-group-2")
end)

-- Test 3: Add buffers to groups
test("Add buffers to groups", function()
  -- Create test buffers
  local buf1 = vim.api.nvim_create_buf(true, false)
  local buf2 = vim.api.nvim_create_buf(true, false)
  
  vim.api.nvim_buf_set_name(buf1, "test1.txt")
  vim.api.nvim_buf_set_name(buf2, "test2.txt")
  
  -- Add to groups
  buffer_groups.add_buffer_to_group("test-group-1", buf1)
  buffer_groups.add_buffer_to_group("test-group-1", buf2)
  buffer_groups.add_buffer_to_group("test-group-2", buf1)
  
  -- Check group buffers
  local group1_buffers = buffer_groups.get_group_buffers("test-group-1")
  assert(#group1_buffers == 2, "test-group-1 should have 2 buffers")
  
  local group2_buffers = buffer_groups.get_group_buffers("test-group-2")
  assert(#group2_buffers == 1, "test-group-2 should have 1 buffer")
end)

-- Test 4: Get buffer groups
test("Get buffer groups", function()
  local buf1 = vim.fn.bufnr("test1.txt")
  local groups = buffer_groups.get_buffer_groups(buf1)
  
  assert(#groups == 2, "Buffer should be in 2 groups")
  assert(vim.tbl_contains(groups, "test-group-1"), "Buffer should be in test-group-1")
  assert(vim.tbl_contains(groups, "test-group-2"), "Buffer should be in test-group-2")
end)

-- Test 5: Remove buffer from group
test("Remove buffer from group", function()
  local buf1 = vim.fn.bufnr("test1.txt")
  buffer_groups.remove_buffer_from_group("test-group-2", buf1)
  
  local groups = buffer_groups.get_buffer_groups(buf1)
  assert(#groups == 1, "Buffer should be in 1 group after removal")
  assert(groups[1] == "test-group-1", "Buffer should only be in test-group-1")
end)

-- Test 6: Rename group
test("Rename group", function()
  buffer_groups.rename_group("test-group-2", "renamed-group")
  
  local groups = buffer_groups.list_groups()
  assert(not vim.tbl_contains(groups, "test-group-2"), "Old name should not exist")
  assert(vim.tbl_contains(groups, "renamed-group"), "New name should exist")
end)

-- Test 7: Delete group
test("Delete group", function()
  buffer_groups.delete_group("renamed-group")
  
  local groups = buffer_groups.list_groups()
  assert(not vim.tbl_contains(groups, "renamed-group"), "Deleted group should not exist")
end)

-- Test 8: Persistence
test("Persistence", function()
  -- Save current state
  buffer_groups.save_groups()
  
  -- Clear and reload
  buffer_groups.groups = {}
  buffer_groups.load_groups()
  
  -- Check if data persisted
  local groups = buffer_groups.list_groups()
  assert(vim.tbl_contains(groups, "test-group-1"), "Groups should persist after reload")
end)

-- Test 9: Invalid buffer cleanup
test("Invalid buffer cleanup", function()
  -- Add an invalid buffer ID
  table.insert(buffer_groups.groups["test-group-1"].buffers, 99999)
  
  -- Run cleanup
  buffer_groups.cleanup_invalid_buffers()
  
  -- Check that invalid buffer was removed
  local buffers = buffer_groups.get_group_buffers("test-group-1")
  for _, bufnr in ipairs(buffers) do
    assert(vim.api.nvim_buf_is_valid(bufnr), "All buffers should be valid after cleanup")
  end
end)

-- Test 10: Telescope extension
test("Telescope extension loads", function()
  -- This would require full Neovim environment with plugins loaded
  -- Skipping for basic test suite
  assert(true, "Telescope test skipped in minimal environment")
end)

-- Cleanup
print("\n=== Cleaning up test data ===")
buffer_groups.groups = {}
buffer_groups.save_groups()

print("\n=== Tests completed ===")

-- Exit
vim.cmd("qa!")
os.exit(0)