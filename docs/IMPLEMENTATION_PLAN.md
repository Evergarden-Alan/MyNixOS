# Implementation Plan

## 实施策略

本项目采用**渐进式迁移策略**：
1. **先生成配置**（当前 Arch 环境）
2. **逐步验证**（虚拟机测试）
3. **择机部署**（实际安装 NixOS）

## Phase 0: 准备阶段

### 0.1 环境准备
- [x] 创建项目目录 `/home/alan/Projects/my_nixos`
- [ ] 安装 Nix 包管理器（在 Arch 上）
  ```bash
  sh <(curl -L https://nixos.org/nix/install) --daemon
  ```
- [ ] 启用 Flakes 功能
  ```bash
  mkdir -p ~/.config/nix
  echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
  ```
- [ ] 验证 Nix 可用
  ```bash
  nix --version
  nix flake --help
  ```

**验证标准**：`nix flake` 命令可用

---

## Phase 1: 文档与配置收集

### 1.1 收集现有配置文件
- [ ] 导出软件包列表
  ```bash
  pacman -Qe > docs/arch_packages.txt
  ```
- [ ] 复制关键配置到 `config/` 目录
  - [ ] `~/.config/niri/` → `config/niri/`
  - [ ] `~/.config/fish/` → `config/fish/`
  - [ ] `~/.config/alacritty/` → `config/alacritty/`
  - [ ] `~/.config/fuzzel/` → `config/fuzzel/`
  - [ ] `~/.config/starship.toml` → `config/starship.toml`
  - [ ] `~/.gitconfig` → `config/gitconfig`
  - [ ] `/etc/greetd/config.toml` → `config/greetd-config.toml`

### 1.2 收集系统服务信息
- [ ] 导出已启用的 systemd 服务
  ```bash
  systemctl list-unit-files --state=enabled > docs/enabled_services.txt
  ```
- [ ] 记录网络配置
  ```bash
  nmcli connection show > docs/network_connections.txt
  ```
- [ ] 记录文件系统信息
  ```bash
  lsblk -f > docs/filesystem_layout.txt
  cat /etc/fstab > docs/fstab.txt
  ```

**验证标准**：所有配置文件已备份到 `config/` 目录

---

## Phase 2: Flake 基础架构

### 2.1 创建 flake.nix
- [ ] 定义 inputs（nixpkgs, home-manager, dms）
- [ ] 定义 outputs（nixosConfigurations）
- [ ] 配置 specialArgs 传递 inputs

### 2.2 创建 configuration.nix 骨架
- [ ] 导入硬件配置占位符
- [ ] 设置基本系统参数（hostname, timezone, locale）
- [ ] 导入模块化配置文件

### 2.3 创建 home.nix 骨架
- [ ] 导入 home-manager 模块
- [ ] 设置用户基本信息
- [ ] 导入用户配置模块

### 2.4 初始化 flake.lock
- [ ] 运行 `nix flake lock` 生成锁定文件
- [ ] 验证依赖可下载

**验证标准**：`nix flake check` 通过（即使配置为空）

---

## Phase 3: 系统级配置实现

### 3.1 引导配置 (modules/system/boot.nix)
- [ ] GRUB/systemd-boot 配置
- [ ] 内核选择（linuxPackages_latest）
- [ ] initrd 模块
- [ ] zram 配置

### 3.2 硬件配置 (modules/system/hardware.nix)
- [ ] CPU 微码更新
- [ ] GPU 驱动（Intel + NVIDIA）
- [ ] 蓝牙支持
- [ ] PipeWire 音频配置
- [ ] 电源管理

### 3.3 网络配置 (modules/system/networking.nix)
- [ ] NetworkManager + iwd
- [ ] 防火墙规则
- [ ] Tailscale
- [ ] SSH 服务

### 3.4 用户管理 (modules/system/users.nix)
- [ ] 创建用户 alan
- [ ] 设置用户组
- [ ] 配置默认 shell (fish)

### 3.5 系统服务 (modules/system/services.nix)
- [ ] greetd 登录管理器
- [ ] Docker 容器化
- [ ] Libvirtd 虚拟化
- [ ] Snapper 快照服务
- [ ] XDG Desktop Portal
- [ ] GNOME Keyring

### 3.6 Nix 配置 (modules/system/nix.nix)
- [ ] 启用 Flakes
- [ ] 垃圾回收策略
- [ ] 构建优化参数
- [ ] 缓存配置

**验证标准**：`nix flake check` 通过，可构建系统配置

---

## Phase 4: 桌面环境配置

### 4.1 DankMaterialShell (modules/desktop/dms.nix)
- [ ] 导入 DMS flake 模块
- [ ] 启用 dank-material-shell
- [ ] 配置功能开关
  - [ ] systemd 集成
  - [ ] 系统监控
  - [ ] 动态主题
  - [ ] 音频波形

### 4.2 Niri Compositor (modules/desktop/niri.nix)
- [ ] 复制 niri 配置文件
- [ ] 配置环境变量（LANG, IME）
- [ ] 配置键盘布局
- [ ] 配置窗口管理规则

### 4.3 启动器与工具 (modules/desktop/fuzzel.nix)
- [ ] fuzzel 配置
- [ ] slurp 截图工具
- [ ] satty 截图编辑
- [ ] wlogout 登出菜单

### 4.4 字体配置 (modules/desktop/fonts.nix)
- [ ] noto-fonts-cjk
- [ ] noto-fonts-emoji
- [ ] JetBrains Mono Nerd Font
- [ ] Liberation 字体

### 4.5 主题配置 (modules/desktop/theme.nix)
- [ ] GTK 主题（Adwaita）
- [ ] 图标主题
- [ ] 光标主题（Breeze）
- [ ] Qt 平台主题

**验证标准**：桌面环境配置完整，无语法错误

---

## Phase 5: 输入法配置

### 5.1 Fcitx5 框架 (modules/input/fcitx5.nix)
- [ ] 启用 fcitx5
- [ ] 添加 addons（rime, gtk, qt, configtool）
- [ ] 配置环境变量

### 5.2 Rime 引擎 (modules/input/rime.nix)
- [ ] 安装 rime 词库包
  - [ ] rime-ice（拼音）
  - [ ] rime-wubi（五笔）
  - [ ] rime-wanxiang-gram（语言模型）
- [ ] 复制 rime 配置文件（如有自定义）

**验证标准**：输入法配置完整

---

## Phase 6: Shell 环境配置

### 6.1 Fish Shell (modules/shell/fish.nix)
- [ ] 启用 fish
- [ ] 配置 shellInit
- [ ] 配置 interactiveShellInit
- [ ] 设置别名
- [ ] 集成 starship 和 zoxide

### 6.2 Zsh (modules/shell/zsh.nix)
- [ ] 启用 zsh（备用）
- [ ] 基础配置

### 6.3 Starship (modules/shell/starship.nix)
- [ ] 启用 starship
- [ ] 转换 starship.toml 配置

### 6.4 CLI 工具 (modules/shell/cli-tools.nix)
- [ ] 安装 CLI 工具包
  - [ ] bat, eza, fd, fzf, ripgrep
  - [ ] jq, pv, btop, fastfetch
  - [ ] lazygit, yazi
- [ ] 配置工具（bat 主题等）
- [ ] 启用 zoxide

**验证标准**：Shell 环境配置完整

---

## Phase 7: 应用程序配置

### 7.1 终端模拟器 (modules/apps/terminals.nix)
- [ ] alacritty 配置（复制 toml 文件）
- [ ] kitty 配置

### 7.2 浏览器 (modules/apps/browsers.nix)
- [ ] firefox
- [ ] chromium
- [ ] brave-browser

### 7.3 编辑器 (modules/apps/editors.nix)
- [ ] neovim
- [ ] vim
- [ ] vscode (使用 nixpkgs.vscode 或 vscode-fhs)

### 7.4 文件管理 (modules/apps/file-managers.nix)
- [ ] nautilus
- [ ] thunar + 插件
- [ ] yazi

### 7.5 媒体应用 (modules/apps/media.nix)
- [ ] mpv
- [ ] imv
- [ ] obs-studio
- [ ] easyeffects

### 7.6 其他应用 (modules/apps/misc.nix)
- [ ] obsidian
- [ ] calibre
- [ ] baobab
- [ ] gnome-calendar
- [ ] gnome-clocks

**验证标准**：所有 P0/P1 应用已配置

---

## Phase 8: 开发环境配置

### 8.1 Git (modules/dev/git.nix)
- [ ] 启用 git
- [ ] 转换 .gitconfig 配置
- [ ] 添加 git-lfs, gh (GitHub CLI)

### 8.2 Docker (已在系统服务配置)
- [ ] 验证 docker 服务配置正确

### 8.3 编程语言 (modules/dev/languages.nix)
- [ ] nodejs + npm
- [ ] python3 + pip
- [ ] 其他语言工具

**验证标准**：开发环境配置完整

---

## Phase 9: 配置验证与测试

### 9.1 语法验证
- [ ] 运行 `nix flake check`
- [ ] 修复所有语法错误
- [ ] 确保所有模块可导入

### 9.2 构建测试
- [ ] 运行 `nix build .#nixosConfigurations.archlinux.config.system.build.toplevel`
- [ ] 验证构建成功
- [ ] 检查构建产物

### 9.3 虚拟机测试（可选，需要实际安装 NixOS 后）
- [ ] 运行 `nixos-rebuild build-vm --flake .#archlinux`
- [ ] 启动虚拟机验证
- [ ] 测试桌面环境启动
- [ ] 测试输入法切换
- [ ] 测试应用启动

**验证标准**：配置可成功构建，虚拟机测试通过

---

## Phase 10: 文档完善与版本控制

### 10.1 Git 初始化
- [ ] `git init`
- [ ] 创建 `.gitignore`（排除 result, secrets 等）
- [ ] 首次提交

### 10.2 创建状态文件（进入 Stage 3）
- [ ] 创建 `CLAUDE.md`（项目级约束）
- [ ] 创建 `progress.txt`（进度跟踪）
- [ ] 创建 `lessons.md`（避坑指南）

### 10.3 README 编写
- [ ] 项目介绍
- [ ] 目录结构说明
- [ ] 使用方法
- [ ] 安装步骤（未来）

**验证标准**：配置已版本控制，文档完整

---

## Phase 11: 实际部署准备（未来执行）

### 11.1 数据备份
- [ ] 备份 `/home/alan` 重要数据
- [ ] 备份 Arch 配置文件
- [ ] 验证备份完整性

### 11.2 NixOS 安装介质
- [ ] 下载 NixOS ISO
- [ ] 制作启动 U 盘
- [ ] 验证启动成功

### 11.3 分区规划
- [ ] 确认分区方案（复用现有分区或重新规划）
- [ ] 备份重要分区数据
- [ ] 测试分区方案

### 11.4 安装 NixOS
- [ ] 启动 NixOS Live 环境
- [ ] 分区并格式化
- [ ] 挂载文件系统
- [ ] 复制配置文件到 `/mnt/etc/nixos/`
- [ ] 运行 `nixos-install`
- [ ] 重启进入 NixOS

### 11.5 首次启动配置
- [ ] 登录用户 alan
- [ ] 验证桌面环境
- [ ] 应用 home-manager 配置
- [ ] 恢复用户数据

**验证标准**：NixOS 成功安装并运行，环境与 Arch 一致

---

## 风险点与应对策略

### 风险1：DankMaterialShell 依赖问题
- **描述**：DMS flake 可能与 nixpkgs-26.05 不兼容
- **应对**：
  1. 查阅 DMS 官方文档确认支持的 NixOS 版本
  2. 如不兼容，尝试使用 unstable 分支
  3. 最坏情况：手动打包 DMS

### 风险2：AUR 软件包缺失
- **描述**：部分 Arch AUR 包在 NixOS 不可用
- **应对**：
  1. 优先使用 Flatpak 替代（QQ, 微信等）
  2. 查找 nixpkgs 中的等价包
  3. 自行打包成 Nix derivation（复杂）

### 风险3：配置文件格式不兼容
- **描述**：某些配置文件需要大幅修改
- **应对**：
  1. 使用 `xdg.configFile` 直接复制文件
  2. 保留原始配置在 `config/` 目录作为参考

### 风险4：硬件驱动问题
- **描述**：NVIDIA 驱动或特殊硬件不工作
- **应对**：
  1. 查阅 NixOS Wiki 硬件兼容性页面
  2. 使用 nixos-hardware flake（如有对应设备）
  3. 逐步调试内核模块和驱动配置

### 风险5：数据丢失
- **描述**：安装过程中误操作导致数据丢失
- **应对**：
  1. **Phase 11 前必须完整备份**
  2. 使用 btrfs 快照保护现有数据
  3. 测试环境先验证流程

---

## 预估时间与复杂度

| Phase | 任务 | 预估时间 | 复杂度 |
|-------|------|---------|--------|
| 0 | 准备阶段 | 30分钟 | 低 |
| 1 | 配置收集 | 1小时 | 低 |
| 2 | Flake 基础 | 1小时 | 中 |
| 3 | 系统配置 | 3小时 | 高 |
| 4 | 桌面环境 | 2小时 | 高 |
| 5 | 输入法 | 1小时 | 中 |
| 6 | Shell 环境 | 1.5小时 | 中 |
| 7 | 应用程序 | 2小时 | 中 |
| 8 | 开发环境 | 1小时 | 低 |
| 9 | 验证测试 | 2小时 | 中 |
| 10 | 文档完善 | 1小时 | 低 |
| 11 | 实际部署 | 3小时 | 高 |
| **总计** | | **约18-20小时** | |

---

## 里程碑

### Milestone 1: 配置框架完成
- 完成 Phase 0-2
- 标志：Flake 结构可用，`nix flake check` 通过

### Milestone 2: 系统配置完成
- 完成 Phase 3
- 标志：系统级配置完整，可构建

### Milestone 3: 用户环境完成
- 完成 Phase 4-8
- 标志：桌面、输入法、应用全部配置完毕

### Milestone 4: 可部署状态
- 完成 Phase 9-10
- 标志：配置验证通过，文档完整，可实际安装

### Milestone 5: 生产环境运行
- 完成 Phase 11
- 标志：NixOS 成功安装，环境与 Arch 一致

---

## 执行原则

1. **一次只做一个小步骤**
   - 完成一个模块立即验证
   - 失败立即回退，不累积错误

2. **频繁提交 Git**
   - 每完成一个子任务提交一次
   - Commit message 格式：`[Phase X] 完成 XXX 模块`

3. **保持配置可回退**
   - 使用 Git 版本控制
   - NixOS 自带世代回滚机制

4. **渐进式测试**
   - Phase 9 前持续验证语法
   - Phase 9 进行完整构建测试
   - Phase 11 前在虚拟机中测试（可选）

5. **文档优先**
   - 遇到问题立即记录到 `lessons.md`
   - 配置修改同步更新文档注释
