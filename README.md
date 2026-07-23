# NixOS Configuration

从 Arch Linux 迁移到 NixOS 的声明式配置项目。

> **📚 快速开始**: 查看 [迁移指南](docs/MIGRATION_GUIDE.md) 了解完整迁移流程

## 项目状态

- ✅ **Phase 0-10**: 配置完成并验证通过
  - Flake 基础架构
  - 系统级配置（boot, hardware, networking, users, services）
  - 桌面环境（Niri, fonts, theme）
  - 输入法（Fcitx5 + Rime）
  - Shell 环境（Fish, Zsh, CLI 工具）
  - 应用程序（终端、浏览器、编辑器等）
  - 开发环境（Git, Node.js, Python）
- ✅ **验证**: `nix flake check` 通过
- 📦 **待部署**: 准备好实际安装

## 目录结构

```
.
├── flake.nix              # Flake 入口
├── flake.lock             # 依赖锁定
├── configuration.nix      # 系统配置
├── home.nix               # 用户配置
├── modules/               # 模块化配置
│   ├── system/           # 系统级模块
│   │   ├── boot.nix
│   │   ├── hardware.nix
│   │   ├── networking.nix
│   │   ├── users.nix
│   │   ├── services.nix
│   │   ├── security.nix
│   │   └── nix.nix
│   ├── desktop/          # 桌面环境
│   │   ├── niri.nix
│   │   ├── fuzzel.nix
│   │   ├── fonts.nix
│   │   └── theme.nix
│   ├── shell/            # Shell 环境
│   │   ├── fish.nix
│   │   ├── zsh.nix
│   │   ├── starship.nix
│   │   └── cli-tools.nix
│   ├── input/            # 输入法
│   │   ├── fcitx5.nix
│   │   └── rime.nix
│   ├── apps/             # 应用程序
│   │   ├── terminals.nix
│   │   ├── browsers.nix
│   │   ├── editors.nix
│   │   ├── file-managers.nix
│   │   ├── media.nix
│   │   └── misc.nix
│   └── dev/              # 开发环境
│       ├── git.nix
│       └── languages.nix
├── config/               # 原始配置备份
├── scripts/              # 工具脚本
│   ├── backup-before-migration.sh
│   └── restore-after-migration.sh
├── docs/                 # 文档
│   ├── MIGRATION_GUIDE.md      # 迁移指南 ⭐
│   ├── DEPLOYMENT_CHECKLIST.md # 部署检查清单
│   └── ...
├── CLAUDE.md             # 项目约束
├── progress.txt          # 进度跟踪
└── lessons.md            # 问题记录
```

## 快速开始

### 🚀 迁移到 NixOS

**完整教程**: 查看 [迁移指南](docs/MIGRATION_GUIDE.md)

**快速步骤**:

1. **备份数据**
   ```bash
   cd ~/Projects/my_nixos
   ./scripts/backup-before-migration.sh
   ```

2. **制作安装 U 盘**
   - 下载 NixOS 26.05 ISO
   - 使用 `dd` 或 Rufus 制作启动盘

3. **安装系统**
   - 按照 [部署检查清单](docs/DEPLOYMENT_CHECKLIST.md) 操作
   - 复制此配置到 `/mnt/etc/nixos/`
   - 运行 `nixos-install --flake .#archlinux`

4. **恢复数据**
   ```bash
   ./scripts/restore-after-migration.sh /path/to/backup
   ```

---

## 开发者使用

### 验证配置

```bash
# 加载 Nix 环境
source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

# 快速语法检查
nix flake show

# 完整验证（首次较慢）
nix flake check

# 构建测试
nix build .#nixosConfigurations.archlinux.config.system.build.toplevel
```

### 日常维护（NixOS 安装后）

**更新系统**:
```bash
cd /etc/nixos
sudo nix flake update
sudo nixos-rebuild switch --flake .#archlinux
home-manager switch --flake .#alan
```

**安装新软件**:
```bash
# 临时使用
nix-shell -p package-name

# 永久安装：编辑配置文件后
sudo nixos-rebuild switch --flake .#archlinux
```

**回滚系统**:
```bash
sudo nixos-rebuild switch --rollback
```

**清理旧版本**:
```bash
sudo nix-collect-garbage --delete-older-than 30d
sudo nix-store --optimize
```

---

## 特性亮点

### 🎯 完全声明式
- 所有配置文件化、版本控制
- 一条命令部署到新机器
- 配置即文档

### 🔄 原子更新与回滚
- 更新失败？一键回滚
- GRUB 菜单保留历史版本
- 无需担心系统损坏

### 📦 模块化设计
- 系统配置分类清晰
- 易于启用/禁用功能
- 复用性强

### 🛡️ 安全性
- 敏感信息分离（不进版本控制）
- 最小权限原则
- 防火墙、SSH 安全配置

---

## 已包含的软件

### 桌面环境
- **Compositor**: Niri（滚动式平铺）
- **启动器**: Fuzzel
- **主题**: Adwaita Dark
- **字体**: Noto CJK, JetBrains Mono Nerd Font

### 开发工具
- **编辑器**: Neovim, VS Code
- **终端**: Alacritty, Kitty
- **Shell**: Fish (主), Zsh (备)
- **版本控制**: Git, Lazygit, GitHub CLI
- **语言**: Node.js, Python, Bun

### CLI 工具
- bat, eza, fd, ripgrep
- fzf, zoxide, btop
- yazi (文件管理)

### 应用程序
- **浏览器**: Firefox, Chromium, Brave
- **媒体**: MPV, OBS Studio
- **文件**: Nautilus, Thunar
- **笔记**: Obsidian

完整列表见各模块配置文件。

---

## 配置说明

### 系统级配置 (`configuration.nix` + `modules/system/`)
- **boot.nix**: GRUB 引导、内核参数
- **hardware.nix**: CPU 微码、GPU 驱动、蓝牙、音频
- **networking.nix**: NetworkManager, 防火墙, SSH
- **users.nix**: 用户账户和权限
- **services.nix**: Docker, Libvirt, greetd, Flatpak
- **security.nix**: Polkit, PAM
- **fonts.nix**: 字体配置

### 用户级配置 (`home.nix` + `modules/`)
- **desktop/**: 桌面环境和主题
- **shell/**: Shell 配置和 CLI 工具
- **input/**: 输入法
- **apps/**: 应用程序
- **dev/**: 开发环境

### 硬件适配

需要根据你的硬件调整：

**CPU** (`modules/system/boot.nix` 和 `hardware.nix`):
```nix
# Intel
boot.kernelModules = [ "kvm-intel" ];
hardware.cpu.intel.updateMicrocode = true;

# AMD
boot.kernelModules = [ "kvm-amd" ];
hardware.cpu.amd.updateMicrocode = true;
```

**GPU** (`modules/system/hardware.nix`):
```nix
# NVIDIA 独显：保持现有配置
# Intel 集显：保持现有配置
# AMD 集显：修改 hardware.graphics.extraPackages
```

---

## 已知问题与解决方案

### DankMaterialShell (DMS) 不可用

**问题**: DMS flake 下载失败

**解决**: 已注释掉 flake input，Niri 直接从 nixpkgs 安装

### 敏感信息管理

**重要**: API tokens 等不应进入 Git

**解决**: 创建 `~/.config/fish/secrets.fish`:
```fish
set -gx ANTHROPIC_AUTH_TOKEN "your-token"
set -gx ANTHROPIC_BASE_URL "https://api.deepseek.com/anthropic"
# ...
```

此文件已在 `.gitignore` 中排除。

### 包名变更警告

NixOS 26.05 部分包名已变更，已在配置中修复：
- `vaapiIntel` → `intel-vaapi-driver`
- `nerdfonts` → `nerd-fonts.jetbrains-mono`
- `gnome-sushi` → `sushi`
- 等等

详见 [lessons.md](lessons.md)。

---

## 文档

### 核心文档
- **[迁移指南](docs/MIGRATION_GUIDE.md)** - 完整迁移教程 ⭐
- **[部署检查清单](docs/DEPLOYMENT_CHECKLIST.md)** - 逐步操作清单
- **[问题记录](lessons.md)** - 已解决的问题和经验

### 原项目文档（参考）
- [PRD.md](docs/PRD.md) - 产品需求
- [TECH_STACK.md](docs/TECH_STACK.md) - 技术栈
- [IMPLEMENTATION_PLAN.md](docs/IMPLEMENTATION_PLAN.md) - 实施计划

---

## 常见问题

**Q: 为什么选择 NixOS？**

A: 声明式、可复现、原子更新、易回滚。一次配置，处处可用。

**Q: 迁移需要多久？**

A: 准备 1-2 小时，安装 30-60 分钟，恢复数据 30 分钟，总计约 2-4 小时。

**Q: 会丢失数据吗？**

A: 不会。提供了完整的备份脚本，先备份再安装。

**Q: 可以双系统吗？**

A: 可以。参考迁移指南的双系统方案。

**Q: 出问题怎么办？**

A: NixOS 支持回滚到任意历史版本。实在不行，从备份恢复原系统。

**Q: 软件包够用吗？**

A: nixpkgs 有超过 80,000 个包，覆盖绝大多数需求。

---

## 贡献与反馈

这是个人配置项目，但欢迎：
- 提出问题和建议
- 分享你的优化思路
- Fork 并调整为自己的配置

---

## 致谢

- NixOS 社区
- home-manager 项目
- 所有开源软件作者

---

## 许可证

个人配置项目，MIT License。
