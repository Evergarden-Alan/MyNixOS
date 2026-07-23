# NixOS Configuration

从 Arch Linux 迁移到 NixOS 的声明式配置项目。

## 项目状态

- ✅ **Phase 0-2**: Flake 基础架构完成
- ✅ **Phase 3**: 系统级配置完成
- ✅ **Phase 4**: 桌面环境配置完成
- ✅ **Phase 5**: 输入法配置完成
- ✅ **Phase 6**: Shell 环境配置完成
- ✅ **Phase 7**: 应用程序配置完成
- ✅ **Phase 8**: 开发环境配置完成
- ⏳ **Phase 9**: 待验证测试
- ⏳ **Phase 11**: 待实际部署

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
├── docs/                 # 文档
├── CLAUDE.md             # 项目约束
├── progress.txt          # 进度跟踪
└── lessons.md            # 问题记录
```

## 使用方法

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

### 安装 NixOS（未来执行）

1. **备份数据**
   ```bash
   # 备份 /home 目录
   rsync -av /home/alan /backup/
   ```

2. **制作安装介质**
   - 下载 NixOS ISO
   - 制作启动 U 盘

3. **分区并安装**
   ```bash
   # 启动 NixOS Live 环境
   # 分区、格式化、挂载
   # 复制配置到 /mnt/etc/nixos/
   nixos-install
   ```

4. **首次启动**
   ```bash
   # 登录用户
   # 应用 home-manager
   home-manager switch --flake .#alan
   ```

## 已知问题

### DankMaterialShell Flake 不可用

**问题**: 从 GitHub 下载 DMS stable 分支失败

**临时方案**: 
- 已注释掉 flake.nix 中的 DMS input
- Niri 配置直接通过 nixpkgs 安装（待验证）
- 或手动安装 DMS 包

### 敏感信息处理

**重要**: API token 等敏感信息已排除在配置外

需要手动创建 `~/.config/fish/secrets.fish`:
```fish
set -gx ANTHROPIC_AUTH_TOKEN "your-token-here"
set -gx ANTHROPIC_BASE_URL "https://api.deepseek.com/anthropic"
# ... 其他敏感配置
```

## 技术栈

- **NixOS**: 26.05
- **home-manager**: release-26.05
- **Compositor**: Niri
- **Shell**: Fish + Zsh
- **输入法**: Fcitx5 + Rime
- **终端**: Alacritty + Kitty
- **浏览器**: Firefox + Chromium + Brave

## 文档

- [PRD.md](docs/PRD.md) - 产品需求文档
- [APP_FLOW.md](docs/APP_FLOW.md) - 应用流程
- [TECH_STACK.md](docs/TECH_STACK.md) - 技术栈
- [FRONTEND_GUIDELINES.md](docs/FRONTEND_GUIDELINES.md) - 前端指南
- [BACKEND_STRUCTURE.md](docs/BACKEND_STRUCTURE.md) - 后端架构
- [IMPLEMENTATION_PLAN.md](docs/IMPLEMENTATION_PLAN.md) - 实施计划

## 许可证

个人配置项目，未指定许可证。
