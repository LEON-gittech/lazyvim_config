# Buffer Groups - Advanced Buffer Management System

Buffer Groups is a powerful buffer organization system for Neovim that allows you to categorize and manage your buffers efficiently. Think of it as workspaces or projects within your editing session.

## 📋 Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Usage Guide](#usage-guide)
- [Key Bindings](#key-bindings)
- [Configuration](#configuration)
- [Advanced Features](#advanced-features)
- [Tips and Tricks](#tips-and-tricks)

## Features

### 🎯 Core Features

- **Persistent Groups**: Buffer groups are saved across Neovim sessions
- **Visual Organization**: Color-coded groups in statusline and tabline
- **Smart Filtering**: Quickly filter buffers by group in telescope picker
- **Batch Operations**: Multi-select buffers for group operations
- **Real-time Updates**: UI components update immediately when groups change
- **Intelligent Cursor Positioning**: Buffer picker automatically positions cursor on current buffer

### 🎨 Visual Features

- **Colored Group Tags**: Each group gets a unique color from a curated palette
- **Tabline Organization**: Buffers are visually grouped with separators
- **Statusline Integration**: Shows current buffer's groups
- **Telescope Integration**: Group tags in buffer picker with visual borders
- **Clean Message Display**: Filtered telescope artifacts for distraction-free experience

## Installation

The buffer groups system is already included in this AstroNvim configuration. It consists of:

1. Core module: `lua/utils/buffer_groups.lua`
2. Telescope extension: `lua/telescope/_extensions/buffer_groups.lua`
3. Plugin configuration: `lua/plugins/buffer_groups.lua`
4. Heirline integration: `lua/plugins/heirline.lua`

## Quick Start

### Basic Workflow

1. **Open some files** in your project
2. **Create a group**: `<leader>Gc` and enter a name (e.g., "Backend")
3. **Add current buffer**: `<leader>Ga` and select the group
4. **Browse grouped buffers**: `<leader>bb` to see all buffers with group tags

### Example Setup

```vim
" Create groups for a full-stack project
:lua require('utils.buffer_groups').create_group("Backend 🔧")
:lua require('utils.buffer_groups').create_group("Frontend 🎨")
:lua require('utils.buffer_groups').create_group("Tests 🧪")
:lua require('utils.buffer_groups').create_group("Docs 📚")
```

## Usage Guide

### Creating and Managing Groups

#### Create a Group
- Press `<leader>Gc`
- Enter a group name
- The group is created with a unique color

#### Delete a Group
- Press `<leader>GM` to open group manager
- Navigate to a group
- Press `<C-d>` to delete

#### Rename a Group
- Press `<leader>GM` to open group manager
- Navigate to a group
- Press `<C-r>` to rename

### Managing Buffer Membership

#### Add Buffer to Group
Three ways to add buffers:

1. **Current Buffer**: `<leader>Ga`
2. **From Buffer Picker**: `<leader>bb` then `<C-g>`
3. **Multiple Buffers**: `<leader>bb`, select with `<Tab>`, then `<C-g>`

#### Remove Buffer from Group
- **Current Buffer**: `<leader>Gr`
- **From Picker**: `<leader>bb` then `<C-r>` on a buffer

### Browsing and Filtering

#### Enhanced Buffer Browser (`<leader>bb`)
The standard buffer browser now shows:
- Colored group tags for each buffer
- Visual group borders and separators
- Helpful key hints in the prompt
- Multi-select capability
- **Smart initial selection**: Cursor starts at current buffer or first available buffer (never on separators)

#### Filter by Group
While in the buffer picker (`<leader>bb`):
- Press `<C-f>` to open group filter
- Select a group to show only its buffers
- Select "All Buffers" to reset

#### View Group Buffers
- Press `<leader>Gv`
- Select a group to view only its buffers

#### Select and Open Group
- Press `<leader>Gs`
- Select a group to open its first buffer

#### Navigate Within Current Group
- Press `<leader>Gb`
- Shows buffers in the current buffer's group
- Select a buffer to jump to it

## Key Bindings

### Buffer Group Management

| Key | Description |
|-----|-------------|
| `<leader>bb` | Browse buffers with group tags |
| `<leader>G` | Buffer Groups prefix (which-key will show menu) |
| `<leader>GM` | Manage groups (rename/delete) |
| `<leader>Ga` | Add current buffer to group |
| `<leader>Gr` | Remove current buffer from group |
| `<leader>Gv` | View buffers in specific group |
| `<leader>Gc` | Create new group |
| `<leader>Gf` | Filter buffers by group |
| `<leader>Gs` | Select group and open first buffer |
| `<leader>Gb` | Select buffer in current group |

### Telescope Picker Actions

When in telescope buffer picker (`<leader>bb`):

| Key | Description |
|-----|-------------|
| `<C-f>` | Filter buffers by group |
| `<C-g>` | Add selected buffer(s) to group |
| `<C-r>` | Remove buffer from group |
| `<Tab>` | Multi-select buffers |

### Group Manager Actions

When in group manager (`<leader>GM`):

| Key | Description |
|-----|-------------|
| `<C-d>` | Delete selected group |
| `<C-r>` | Rename selected group |
| `<Enter>` | View buffers in group |

## Configuration

### Storage Location

Buffer groups are stored in:
```
~/.local/share/nvim/buffer_groups.json
```

### Color Palette

The system uses 14 beautiful colors that work well with dark themes:
- Red, Green, Blue, Purple, Yellow, Cyan, Orange
- Light variants of each color

Colors are automatically assigned to groups and persist across sessions.

### Customization

To customize colors, edit the `group_colors` table in `lua/utils/buffer_groups.lua`:

```lua
M.group_colors = {
  { fg = "#e06c75", bg = "#3e4452" }, -- Red
  { fg = "#98c379", bg = "#3e4452" }, -- Green
  -- Add your colors here
}
```

## Advanced Features

### Persistent Sessions

Buffer groups work seamlessly with session managers. The groups persist independently of sessions, so you can:
- Switch sessions and maintain your groups
- Share group organization across different projects

### Smart Buffer Organization

The tabline automatically organizes buffers by group:
```
[📁 Backend] server.py api.py [📁 Frontend] App.jsx utils.js [📁 Ungrouped] README.md
```

### Group Templates

Create template groups for common project types:

```lua
-- In your config
local bg = require('utils.buffer_groups')

function SetupWebProject()
  bg.create_group("Backend 🔧")
  bg.create_group("Frontend 🎨")
  bg.create_group("Tests 🧪")
  bg.create_group("Config ⚙️")
  bg.create_group("Docs 📚")
end
```

### Integration with Workflow

Buffer groups integrate with:
- **Heirline**: Statusline and tabline display
- **Telescope**: Enhanced buffer picking
- **Sessions**: Independent persistence

## Tips and Tricks

### 🚀 Productivity Tips

1. **Use Emojis**: Add emojis to group names for visual distinction
   ```
   Backend 🔧, Frontend 🎨, Tests 🧪, Docs 📚
   ```

2. **Quick Switching**: Use `<leader>Gf` for fast context switching

3. **Group Navigation**: Use `<leader>Gs` to quickly jump to a group's first buffer

4. **Within-Group Navigation**: Use `<leader>Gb` to navigate between buffers in the same group

5. **Batch Operations**: Use `<Tab>` in picker to select multiple buffers

6. **Temporary Groups**: Create groups for temporary tasks
   ```
   "Bug Fix #123", "Feature: Auth", "Review: PR-456"
   ```

### 🎯 Common Workflows

#### Full-Stack Development
```
Groups: Backend, Frontend, Tests, Config, Docs
```

#### Microservices
```
Groups: Service-A, Service-B, Shared-Libs, Tests, Deploy
```

#### Feature Development
```
Groups: Feature-Core, Feature-Tests, Feature-Docs, Related-Files
```

### 🔍 Troubleshooting

#### Groups Not Showing
- Ensure buffer is listed: `:set buflisted`
- Check if buffer is valid: `:echo bufnr('%')`

#### Colors Not Updating
- Trigger update: `:doautocmd User BufferGroupsUpdate`
- Restart Neovim if needed

#### Telescope Messages
- Telescope artifacts like `}` are automatically filtered by noice.nvim
- If messages still appear, check `:checkhealth noice`

#### Performance
- Groups are lightweight and cached
- Cleanup happens automatically on save
- Initial cursor positioning is optimized for instant response

## Examples

### Creating a Feature Branch Workflow

```lua
-- When starting a new feature
local bg = require('utils.buffer_groups')

-- Create feature-specific groups
bg.create_group("Feature: User Auth")
bg.create_group("Tests: User Auth")
bg.create_group("Original Code")

-- Work on your feature with organized buffers
```

### Project Template

```lua
-- Save in your config
function SetupProject(project_type)
  local bg = require('utils.buffer_groups')
  
  if project_type == "web" then
    bg.create_group("Backend 🔧")
    bg.create_group("Frontend 🎨")
    bg.create_group("Database 🗄️")
    bg.create_group("Tests 🧪")
    bg.create_group("Config ⚙️")
  elseif project_type == "library" then
    bg.create_group("Source 📦")
    bg.create_group("Tests 🧪")
    bg.create_group("Examples 📚")
    bg.create_group("Docs 📖")
  end
end
```

## Conclusion

Buffer Groups transforms buffer management from a flat list into an organized, visual system. It's designed to match how developers think about their code - in logical groups and components.

Start simple with a few groups and expand as needed. The system grows with your workflow! 🚀