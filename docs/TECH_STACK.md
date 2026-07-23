# Technology Stack

## NixOS 基础

### 核心版本
- **NixOS**: `26.05` (stable channel)
- **Nix**: `2.x` (with Flakes enabled)
- **home-manager**: `release-26.05` branch

### Flake 输入源
```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

## 桌面环境

### Wayland Compositor
- **Niri**: latest (from DankMaterialShell flake)
- **DankMaterialShell**: stable branch
- **niri-sidebar**: bundled with DMS

### 显示管理器
- **greetd**: `0.10.x`
- **agreety**: bundled with greetd (fallback greeter)

### 启动器 & 工具
- **fuzzel**: `1.14.x` (应用启动器)
- **slurp**: `1.5.x` (区域选择)
- **satty**: `0.21.x` (截图编辑)
- **wlogout**: `1.2.x` (登出菜单)

## Shell 环境

### Shell
- **fish**: `4.8.x` (主 shell)
- **zsh**: `5.9.x` (备用 shell)
- **bash**: 系统默认

### 提示符 & 增强
- **starship**: `1.26.x`
- **zoxide**: `0.10.x`

### CLI 工具
- **bat**: `0.26.x` (cat 增强)
- **eza**: `0.23.x` (ls 增强)
- **fd**: `10.4.x` (find 增强)
- **fzf**: `0.74.x` (模糊查找)
- **ripgrep**: latest (文本搜索)
- **jq**: `1.8.x` (JSON 处理)
- **btop**: `1.4.x` (系统监控)
- **fastfetch**: `2.66.x` (系统信息)

## 输入法

### 框架
- **fcitx5**: `5.1.x`
- **fcitx5-configtool**: `5.1.14`
- **fcitx5-gtk**: `5.1.7`
- **fcitx5-qt**: `5.1.14`

### 输入引擎
- **fcitx5-rime**: `5.1.14`
- **fcitx5-mozc**: `3.34.x` (可选日语)

### Rime 词库
- **rime-ice**: latest git (拼音)
- **rime-wubi**: `0.0.0.20231025` (五笔)
- **rime-wanxiang-gram-zh-hans**: latest (语言模型)
- **rime-llm-translator**: latest git (AI翻译)

## 字体

### 中文字体
- **noto-fonts-cjk**: `20240730`
- **noto-fonts-emoji**: `2.051`

### 编程字体
- **ttf-jetbrains-mono-nerd**: `3.4.0` (Nerd Font 图标)
- **ttf-jetbrains-maple-mono-nf-xx-xx**: `1.2304.76` (Maple Mono)

### 系统字体
- **noto-fonts**: latest
- **ttf-liberation**: `2.1.5` (替代 Windows 字体)

## 终端模拟器

- **alacritty**: `0.17.0` (主终端)
- **kitty**: `0.48.0` (备用终端)

## 编辑器 & IDE

### 文本编辑器
- **neovim**: `0.12.4`
- **vim**: `9.2.x` (系统默认)

### IDE
- **visual-studio-code**: `1.129.1` (需使用 vscode-bin 或 nixpkgs.vscode)

## 版本控制

### Git
- **git**: `2.55.0`
- **git-lfs**: `3.7.1`
- **github-cli (gh)**: `2.96.0`
- **lazygit**: `0.63.1` (TUI)

## 浏览器

### 主浏览器
- **firefox**: `152.0.x`
- **chromium**: `150.0.x`
- **brave**: `1.92.x` (需使用 brave-browser 包)

## 文件管理

### GUI
- **nautilus**: `50.2.2` (GNOME Files)
- **thunar**: `4.20.9` (Xfce)
- **thunar-volman**: `4.20.0` (自动挂载)
- **thunar-archive-plugin**: `0.6.0`

### TUI
- **yazi**: `26.5.6` (现代化 TUI)

### 工具
- **file-roller**: `44.7` (压缩包管理)
- **gparted**: `1.8.1` (分区管理)
- **baobab**: `50.0` (磁盘空间分析)

## 媒体播放

### 视频
- **mpv**: `0.41.0`

### 图片
- **imv**: `5.0.1` (Wayland 图片查看)

### 录屏
- **obs-studio**: `32.1.2`
- **wf-recorder**: `0.6.0`
- **wl-screenrec**: latest git

### 音频
- **easyeffects**: `8.2.7` (音效处理)

## 音频系统

- **pipewire**: `1.6.8`
- **pipewire-alsa**: `1.6.8`
- **pipewire-jack**: `1.6.8`
- **pipewire-pulse**: `1.6.8`
- **wireplumber**: `0.5.15`
- **pavucontrol**: `6.2` (音量控制 GUI)

## 网络

### 网络管理
- **NetworkManager**: `1.56.1`
- **iwd**: `3.12` (WiFi backend)
- **nm-connection-editor**: `1.36.0`

### VPN & 代理
- **tailscale**: `1.98.9`
- **dnsmasq**: `2.93` (DNS 缓存)

### 蓝牙
- **bluez**: `5.87`
- **bluetui**: `0.8.1` (TUI 管理)

## 开发环境

### 容器化
- **docker**: `29.6.x`

### 虚拟化
- **qemu**: `11.0.2` (qemu-full)
- **virt-manager**: `5.1.0`
- **virt-viewer**: `11.0`
- **libvirt**: latest

### 编程语言
- **nodejs**: `26.4.0`
- **npm**: `12.0.1`
- **python3**: system (with pip)
- **python-pip**: `26.1.2`

### 图像处理
- **imagemagick**: `7.1.2.27`
- **ffmpegthumbnailer**: `2.3.0`

## 系统工具

### 文件系统
- **btrfs-progs**: `7.1`
- **snapper**: `0.13.1` (快照管理)
- **btrfs-assistant**: `2.2` (GUI)
- **ntfs-3g**: `2026.7.7`

### 硬件管理
- **intel-ucode**: `20260512` (微码更新)
- **intel-media-driver**: `26.1.5`
- **intel-lpmd**: `0.1.0` (低功耗模式)

### 电源管理
- **power-profiles-daemon**: `0.30`

### 监控工具
- **smartmontools**: `7.5` (硬盘健康)
- **lshw**: `B.02.20` (硬件信息)
- **usbutils**: `019`

## XDG Portals

- **xdg-desktop-portal-gnome**: `50.0`
- **xdg-desktop-portal-gtk**: `1.15.3`
- **xdg-desktop-portal-hyprland**: `1.4.0` (可能不需要)
- **xdg-desktop-portal-wlr**: `0.8.2`

## GNOME 应用

- **gnome-keyring**: `50.0` (密钥环)
- **seahorse**: `47.0.1` (密钥管理 GUI)
- **gnome-calendar**: `50.0`
- **gnome-clocks**: `50.0`
- **gnome-font-viewer**: `50.0`

## 笔记 & 知识管理

- **obsidian**: `1.12.7` (需使用 AppImage 或 nixpkgs.obsidian)
- **calibre**: `9.11.0` (电子书管理)

## 游戏 & 娱乐 (P2)

- **steam**: latest
- **lutris**: `0.5.22`
- **mangohud**: `0.8.4`

## GPU 驱动

### NVIDIA (如果使用独显)
- **nvidia-open-dkms**: `610.43.03`
- **nvidia-utils**: `610.43.03`
- **nvidia-settings**: `610.43.03`
- **lib32-nvidia-utils**: `610.43.03` (32位游戏)

### Intel (集显)
- **mesa**: latest
- **vulkan-intel**: `26.1.5`
- **lib32-vulkan-intel**: `26.1.5`

## 构建工具

- **base-devel**: NixOS 等价物 (gcc, make, 等)
- **mkinitcpio**: NixOS 使用自己的 initrd 生成

## systemd 服务

### 启用的服务
- docker.service
- NetworkManager.service
- iwd.service
- bluetooth.service
- greetd.service
- power-profiles-daemon.service
- tailscaled.service
- libvirtd.service
- sshd.service (可选)
- systemd-timesyncd.service

### 定时任务
- snapper-timeline.timer
- snapper-cleanup.timer

## 包管理器 (不迁移)

- ~~paru~~, ~~yay~~ - NixOS 不需要 AUR helper
- **flatpak**: 可选启用 (用于特殊应用)

## 版本锁定策略

### 使用精确版本的场景
- 系统关键组件 (kernel, systemd)
- 已知有破坏性更新的软件

### 使用 nixos-26.05 channel 的场景
- 大部分用户软件
- 开发工具

### 使用 unstable 的场景
- 需要最新功能的软件 (neovim, vscode)
- 通过 overlay 单独引入
