# Diff 功能使用指南

## 快捷键

所有 diff 相关的快捷键都在 `<Leader>D` 前缀下：

- `<Leader>Df` - **Diff with file**: 与指定文件对比
- `<Leader>Dc` - **Diff with clipboard**: 与剪贴板内容对比
- `<Leader>Db` - **Diff with buffer**: 与另一个 buffer 对比
- `<Leader>Dg` - **Diff with git**: 与 git HEAD 版本对比
- `<Leader>Dq` - **Close diff**: 关闭所有 diff 窗口
- `<Leader>Dt` - **Toggle diff**: 切换当前窗口的 diff 模式

### Diffview 快捷键（如果安装了 diffview.nvim）

- `<Leader>Dvo` - 打开 Diffview
- `<Leader>Dvc` - 关闭 Diffview
- `<Leader>Dvh` - 查看当前文件的历史
- `<Leader>DvH` - 查看整个分支的历史

### Diff 模式下的导航

当处于 diff 模式时：
- `]c` - 跳转到下一个差异
- `[c` - 跳转到上一个差异
- `do` - 获取另一侧的更改 (diff obtain)
- `dp` - 推送当前侧的更改 (diff put)

## 命令

也可以使用命令行：

- `:DiffWithFile` - 与文件对比
- `:DiffWithClipboard` - 与剪贴板对比
- `:DiffWithBuffer` - 与另一个 buffer 对比
- `:DiffWithGit` - 与 git HEAD 对比
- `:DiffClose` - 关闭 diff
- `:DiffToggle` - 切换 diff 模式

## 使用场景

### 1. 对比当前文件与另一个文件
```
<Leader>Df
输入文件路径（支持 Tab 补全）
```

### 2. 对比当前内容与剪贴板
适用于对比代码片段：
1. 复制要对比的内容到剪贴板
2. 在 Neovim 中按 `<Leader>Dc`
3. 会打开一个临时 buffer 显示剪贴板内容并进行对比

### 3. 对比两个已打开的 buffer
```
<Leader>Db
选择要对比的 buffer
```

### 4. 查看 Git 更改
```
<Leader>Dg
```
会显示当前文件相对于 git HEAD 的更改

## 提示

- Diff 模式会高亮显示差异部分
- 使用 `:diffupdate` 可以刷新 diff 显示
- 使用 `:set diffopt?` 查看当前 diff 选项
- 可以同时对比多个窗口，每个窗口执行 `:diffthis`