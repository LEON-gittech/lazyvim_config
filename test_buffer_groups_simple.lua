#!/usr/bin/env lua

-- Simple test script for buffer groups
-- Run with: lua test_buffer_groups_simple.lua

-- Mock vim API for testing
local vim = {
  api = {
    nvim_buf_is_valid = function(b) return b < 1000 end,
    nvim_list_bufs = function() return {1, 2, 3} end,
    nvim_get_current_buf = function() return 1 end,
    nvim_buf_get_name = function(b) return "buffer" .. b .. ".txt" end,
    nvim_create_augroup = function() return 1 end,
    nvim_create_autocmd = function() end,
  },
  fn = {
    stdpath = function(what) return "/tmp" end,
    fnamemodify = function(path, mods) return path end,
    isdirectory = function(dir) return 1 end,
    mkdir = function(dir, flags) end,
  },
  json = {
    encode = function(t) return "{}" end,
    decode = function(s) return {} end,
  },
  notify = function(msg, level) print("NOTIFY: " .. msg) end,
  log = { levels = { INFO = 1, WARN = 2, ERROR = 3 } },
  tbl_filter = function(fn, t)
    local result = {}
    for _, v in ipairs(t) do
      if fn(v) then table.insert(result, v) end
    end
    return result
  end,
  tbl_keys = function(t)
    local keys = {}
    for k, _ in pairs(t) do table.insert(keys, k) end
    return keys
  end,
  bo = {},
}

-- Make vim global
_G.vim = vim

-- Load the module
package.path = package.path .. ";/Users/leon/.config/nvim/lua/?.lua"
local buffer_groups = require("utils.buffer_groups")

-- Test functions
local passed = 0
local failed = 0

local function test(name, fn)
  io.write("Testing " .. name .. "... ")
  local success, err = pcall(fn)
  if success then
    print("✓ PASS")
    passed = passed + 1
  else
    print("✗ FAIL: " .. tostring(err))
    failed = failed + 1
  end
end

print("=== Buffer Groups Test Suite ===\n")

-- Test 1: Create and list groups
test("Create and list groups", function()
  buffer_groups.create_group("backend")
  buffer_groups.create_group("frontend")
  
  local groups = buffer_groups.list_groups()
  assert(#groups >= 2, "Should have at least 2 groups")
end)

-- Test 2: Add buffer to group
test("Add buffer to group", function()
  local result = buffer_groups.add_buffer_to_group("backend", 1)
  assert(result == true, "Should successfully add buffer to group")
  
  local groups = buffer_groups.get_buffer_groups(1)
  assert(#groups == 1, "Buffer should be in 1 group")
  assert(groups[1] == "backend", "Buffer should be in backend group")
end)

-- Test 3: Remove buffer from group
test("Remove buffer from group", function()
  local result = buffer_groups.remove_buffer_from_group("backend", 1)
  assert(result == true, "Should successfully remove buffer")
  
  local groups = buffer_groups.get_buffer_groups(1)
  assert(#groups == 0, "Buffer should not be in any group")
end)

-- Test 4: Rename group
test("Rename group", function()
  buffer_groups.add_buffer_to_group("frontend", 2)
  local result = buffer_groups.rename_group("frontend", "ui-components")
  assert(result == true, "Should successfully rename group")
  
  local groups = buffer_groups.list_groups()
  local has_new = false
  local has_old = false
  for _, g in ipairs(groups) do
    if g == "ui-components" then has_new = true end
    if g == "frontend" then has_old = true end
  end
  
  assert(has_new, "Should have new group name")
  assert(not has_old, "Should not have old group name")
end)

-- Test 5: Delete group
test("Delete group", function()
  local result = buffer_groups.delete_group("backend")
  assert(result == true, "Should successfully delete group")
  
  local groups = buffer_groups.list_groups()
  for _, g in ipairs(groups) do
    assert(g ~= "backend", "Should not contain deleted group")
  end
end)

-- Test 6: Group info
test("Get group info", function()
  local info = buffer_groups.get_group_info("ui-components")
  assert(info ~= nil, "Should get group info")
  assert(info.name == "ui-components", "Should have correct name")
  assert(type(info.buffers) == "table", "Should have buffers table")
end)

print("\n=== Test Summary ===")
print("Passed: " .. passed)
print("Failed: " .. failed)
print("Total:  " .. (passed + failed))

if failed > 0 then
  os.exit(1)
else
  print("\nAll tests passed! ✨")
  os.exit(0)
end