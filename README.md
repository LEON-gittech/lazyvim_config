# AstroNvim Configuration with Buffer Groups

**NOTE:** This is for AstroNvim v5+

An enhanced [AstroNvim](https://github.com/AstroNvim/AstroNvim) configuration featuring a powerful Buffer Groups management system and other productivity improvements.

## 🛠️ Installation

#### Make a backup of your current nvim and shared folder

```shell
mv ~/.config/nvim ~/.config/nvim.bak
mv ~/.local/share/nvim ~/.local/share/nvim.bak
mv ~/.local/state/nvim ~/.local/state/nvim.bak
mv ~/.cache/nvim ~/.cache/nvim.bak
```

#### Create a new user repository from this template

Press the "Use this template" button above to create a new repository to store your user configuration.

You can also just clone this repository directly if you do not want to track your user configuration in GitHub.

#### Clone the repository

```shell
git clone https://github.com/<your_user>/<your_repository> ~/.config/nvim
```

#### Start Neovim

```shell
nvim
```

## ✨ Key Features

### 🎯 Buffer Groups Management

This configuration includes a comprehensive buffer organization system that allows you to categorize and manage buffers efficiently.

**What are Buffer Groups?**
- Organize buffers into logical groups (e.g., "Backend", "Frontend", "Tests")
- Visual indicators with color-coded tags
- Persistent across sessions
- Quick filtering and navigation

**Quick Start:**
- `<leader>bb` - Browse buffers with group tags
- `<leader>G` - Buffer Groups prefix (press to see all options)
- `<leader>Ga` - Add current buffer to a group
- `<leader>Gs` - Select a group and open its first buffer
- `<leader>Gb` - Select buffer in current group

For detailed documentation, see [Buffer Groups Guide](docs/buffer-groups.md).

### 🔥 Other Enhancements

- **Enhanced LSP**: Improved navigation with Glance, better Python support
- **Smart Comments**: Context-aware commenting for embedded languages
- **Aerial Navigation**: Quick class/function navigation
- **Session Management**: Improved session handling with Resession
- **Python Tools**: Integrated Ruff for fast Python formatting

## 📚 Documentation

- [Buffer Groups - Advanced Buffer Management](docs/buffer-groups.md) - Complete guide to the buffer groups system

## 🚀 Quick Tips

1. **Organize by Project Structure**:
   ```
   Backend 🔧 | Frontend 🎨 | Tests 🧪 | Docs 📚
   ```

2. **Use `<leader>bb` for Everything**: The enhanced buffer browser shows group tags and supports filtering

3. **Visual Cues**: Each group gets a unique color in the tabline and statusline

## 🤝 Contributing

Feel free to submit issues and enhancement requests!
