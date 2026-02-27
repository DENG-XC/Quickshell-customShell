# Quickshell Custom Shell

A custom desktop shell component set built with [Quickshell](https://quickshell.outfoxxed.me/) for Linux, designed specifically for the [niri](https://github.com/YaLTeR/niri) scrollable-tiling Wayland compositor.

> [!NOTE]
> This project has only been tested on a single 2K monitor. Compatibility with other resolutions or multi-monitor setups is not guaranteed.

## Features

- Top Bar
- App Launcher
- Clipboard Manager
- Notification Center
- Media Control
- Weather Widget
- Calendar
- Screen Lock
- Performance Monitor
- Wallpaper Selector

## Dependencies

| Dependency | Required | Description |
|------------|----------|-------------|
| [niri](https://github.com/YaLTeR/niri) | ✅ Yes | Scrollable-tiling Wayland compositor (this shell only works with niri) |
| [quickshell](https://quickshell.outfoxxed.me/) | ✅ Yes | The desktop shell framework |
| [clipse](https://github.com/savedra1/clipse) | ✅ Yes | Clipboard manager for Wayland |
| [swww](https://github.com/LGFae/swww) | ✅ Yes | Wallpaper daemon for Wayland |

## Installation

### 1. Install dependencies

```bash
# Arch Linux (AUR)
yay -S niri quickshell clipse swww

# Or use your preferred package manager
```

### 2. Clone the repository

```bash
git clone https://github.com/DENG-XC/Quickshell-customShell.git
```

### 3. Move files to quickshell config directory

```bash
mv Quickshell-customShell/* ~/.config/quickshell/
```

### 4. Run

```bash
qs -p ~/.config/quickshell/shell/Shell.qml
```

Or add to your niri config for auto-start:

```kdl
// ~/.config/niri/config.kdl
Spawn-at-startup "qs" "-p" "/home/yourusername/.config/quickshell/shell/Shell.qml"
```

## Set up

```kdl
// ~/.config/niri/config.kdl
spawn-at-startup "swww-daemon" # run swww-daemon on startup
spawn-at-startup "clipse" "-listen" # run listener on startup
Mod+W { spawn "bash" "-c" "qs -p ~/.config/quickshell/shell/Shell.qml ipc call Config setAppLauncher"; } # toggle AppLauncher
```

### Theme Colors

You can customize the color scheme in `Config.qml`:

```qml
property color text: "#e6eaf0"
property color background: "#0f1115"
property color foreground: "#181b21"
// ... more colors
```

## Known Issues

- Only tested on single 2K monitor
- May not work correctly on multi-monitor setups
- Requires niri compositor (will not work with other compositors)

## Acknowledgments

- [Quickshell](https://quickshell.outfoxxed.me/) - The amazing shell framework
- [niri](https://github.com/YaLTeR/niri) - The scrollable-tiling Wayland compositor
- [clipse](https://github.com/savedra1/clipse) - Clipboard manager for Wayland
- [swww](https://github.com/LGFae/swww) - Wallpaper daemon

---

# 中文说明

一套基于 [Quickshell](https://quickshell.outfoxxed.me/) 构建的 Linux 桌面组件，专为 [niri](https://github.com/YaLTeR/niri) 滚动平铺 Wayland 合成器设计。

> [!NOTE]
> 本项目仅在单屏 2K 分辨率下测试过，不保证在其他分辨率或多屏环境下的兼容性。

## 功能特性

- 顶栏
- 应用启动器
- 剪贴板管理器
- 通知中心
- 媒体控制
- 天气组件
- 日历
- 锁屏
- 性能监控
- 壁纸选择器

## 依赖

| 依赖 | 必须 | 说明 |
|------------|----------|-------------|
| [niri](https://github.com/YaLTeR/niri) | ✅ 是 | 滚动平铺 Wayland 合成器（本组件仅支持 niri） |
| [quickshell](https://quickshell.outfoxxed.me/) | ✅ 是 | 桌面 shell 框架 |
| [clipse](https://github.com/savedra1/clipse) | ✅ 是 | Wayland 剪贴板管理器 |
| [swww](https://github.com/LGFae/swww) | ✅ 是 | Wayland 壁纸守护进程 |

## 安装

### 1. 安装依赖

```bash
# Arch Linux (AUR)
yay -S niri quickshell clipse swww

# 或使用你喜欢的包管理器
```

### 2. 克隆仓库

```bash
git clone https://github.com/DENG-XC/Quickshell-customShell.git
```

### 3. 移动文件到 quickshell 配置目录

```bash
mv Quickshell-customShell/* ~/.config/quickshell/
```

### 4. 运行

```bash
qs -p ~/.config/quickshell/shell/Shell.qml
```

或添加到 niri 配置文件实现开机自启：

```kdl
// ~/.config/niri/config.kdl
Spawn-at-startup "qs" "-p" "/home/你的用户名/.config/quickshell/shell/Shell.qml"
```

## 配置

```kdl
// ~/.config/niri/config.kdl
spawn-at-startup "swww-daemon" # 启动 swww-daemon
spawn-at-startup "clipse" "-listen" # 启动 clipse 监听器
Mod+W { spawn "bash" "-c" "qs -p ~/.config/quickshell/shell/Shell.qml ipc call Config setAppLauncher"; } # 切换应用启动器
```

### 主题颜色

你可以在 `Config.qml` 中自定义配色方案：

```qml
property color text: "#e6eaf0"
property color background: "#0f1115"
property color foreground: "#181b21"
// ... 更多颜色
```

## 已知问题

- 仅在单屏 2K 分辨率下测试
- 多屏环境下可能无法正常工作
- 仅支持 niri 合成器（无法在其他合成器上运行）

## 致谢

- [Quickshell](https://quickshell.outfoxxed.me/) - 出色的 shell 框架
- [niri](https://github.com/YaLTeR/niri) - 滚动平铺 Wayland 合成器
- [clipse](https://github.com/savedra1/clipse) - Wayland 剪贴板管理器
- [swww](https://github.com/LGFae/swww) - 壁纸守护进程
