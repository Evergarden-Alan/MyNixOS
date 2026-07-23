# NixOS Configuration Project Constraints

## 项目概述

从 Arch Linux 迁移到 NixOS 的声明式配置项目。目标：生成完整可用的 NixOS Flake 配置。

## 全局约束

### 1. 代码风格

#### Nix 代码规范
- **缩进**：2 空格
- **命名**：camelCase（变量/函数），kebab-case（文件名）
- **字符串**：优先使用 `''多行字符串''`，避免转义
- **列表**：元素较多时每行一个
- **注释**：中文注释用于说明意图，英文注释用于技术细节

#### 目录结构
```
/home/alan/Projects/my_nixos/
├── flake.nix                 # Flake 入口
├── flake.lock                # 版本锁定
├── configuration.nix         # 系统配置
├── home.nix                  # 用户配置
├── modules/                  # 模块化配置
├── config/                   # 原始配置备份
├── docs/                     # 文档
├── CLAUDE.md                 # 本文件
├── progress.txt              # 进度跟踪
└── lessons.md                # 避坑指南
```

### 2. 模块化原则

- **每个模块单一职责**：一个 `.nix` 文件只管理一类功能
- **清晰的依赖关系**：避免循环依赖
- **可独立开关**：通过 `enable = true/false` 控制模块启用

### 3. 版本管理

- **锁定主版本**：使用 `flake.lock` 固定依赖版本
- **定期更新**：通过 `nix flake update` 升级依赖
- **回滚机制**：利用 Git 和 NixOS generations 回滚

### 4. 敏感信息处理

**严禁将敏感信息写入 Nix 配置文件！**

- ❌ 禁止：API token, 密码, 私钥
- ✅ 正确：使用外部文件 + `.gitignore`

示例：
```nix
# ❌ 错误
environment.variables.API_TOKEN = "sk-xxx";

# ✅ 正确
programs.fish.interactiveShellInit = ''
  if test -f ~/.config/fish/secrets.fish
    source ~/.config/fish/secrets.fish
  end
'';
```

### 5. 文件命名规范

- **Nix 文件**：小写，连字符分隔（`cli-tools.nix`）
- **配置备份**：保持原始文件名（`config.kdl`, `alacritty.toml`）
- **文档**：大写，下划线分隔（`IMPLEMENTATION_PLAN.md`）

### 6. Commit 规范

格式：`[Phase X] 简短描述`

示例：
- `[Phase 2] 创建 flake.nix 基础结构`
- `[Phase 3] 添加系统服务配置`
- `[Phase 4] 配置 DankMaterialShell`
- `[Bug] 修复 niri 配置路径错误`

### 7. 禁止的操作

- ❌ 不要直接编辑 `flake.lock`（使用 `nix flake update`）
- ❌ 不要在系统配置和 home-manager 中重复配置同一项
- ❌ 不要硬编码路径（使用 `${pkgs.xxx}` 或相对路径）
- ❌ 不要跳过验证步骤（每个模块完成后立即 `nix flake check`）

### 8. 优先级原则

**P0 > P1 > P2 > P3**

- **P0**：核心桌面环境、Shell、输入法（必须实现）
- **P1**：日常应用、开发工具（强烈建议）
- **P2**：游戏、多媒体（可选）
- **P3**：国产软件、AUR 包（暂不处理）

遇到时间不足时，按优先级削减功能。

## 进度跟踪

**查看进度**：`cat progress.txt`

**更新进度**：完成任务后，将任务从 `[Next]` 移动到 `[Done]`

## 问题记录

**遇到坑时**：立即记录到 `lessons.md`

格式：
```markdown
## [日期] 问题标题
**问题**：描述问题
**原因**：根本原因
**解决方案**：具体步骤
**教训**：下次如何避免
```

## 验证流程

### 每完成一个模块
1. 运行 `nix flake check`
2. 确认无语法错误
3. Commit 到 Git

### Phase 9 完整验证
1. 运行 `nix build .#nixosConfigurations.archlinux.config.system.build.toplevel`
2. 验证构建成功
3. 检查构建产物大小是否合理

### Phase 11 实际部署前
1. ✅ 完整备份 `/home/alan` 数据
2. ✅ 验证配置在虚拟机中可用
3. ✅ 确认回滚方案可行

## 技术栈约束

### NixOS 版本
- **NixOS**: `26.05` (stable)
- **home-manager**: `release-26.05`
- **Nix**: 2.x with Flakes

### 桌面环境
- **Compositor**: Niri (from DankMaterialShell)
- **Shell**: DankMaterialShell (stable branch)
- **Login Manager**: greetd

### 输入法
- **Framework**: fcitx5
- **Engine**: rime
- **Dict**: rime-ice, rime-wubi

### 字体
- **中文**: noto-fonts-cjk
- **编程**: JetBrains Mono Nerd Font
- **Emoji**: noto-fonts-emoji

## 特殊注意事项

### DankMaterialShell 配置
- 必须使用 `inputs.dms.homeModules.dank-material-shell`（home-manager 模式）
- 文档：https://danklinux.com/docs/dankmaterialshell/nixos-flake

### Niri 配置
- 配置文件为 KDL 格式，无法用 Nix 语法表达
- 使用 `xdg.configFile` 直接复制文件

### 硬件配置
- `hardware-configuration.nix` 由 `nixos-generate-config` 自动生成
- 手动调整放在单独模块中，不修改自动生成文件

### Btrfs 分区
- 当前系统使用 btrfs + 子卷
- 迁移时需保留子卷结构或重新规划

## 工作流程

### 当前阶段（Phase 0-2）
正在生成配置文件，尚未安装 NixOS。

### 工作环境
- 在 Arch Linux 上开发配置
- 使用 Nix 包管理器验证语法
- 配置完成后择机安装 NixOS

### 日常开发流程
1. 编辑 `.nix` 文件
2. `nix flake check` 验证语法
3. 更新 `progress.txt`
4. Git commit
5. 继续下一个任务

## 参考资源

- **NixOS Manual**: https://nixos.org/manual/nixos/stable/
- **home-manager Manual**: https://nix-community.github.io/home-manager/
- **NixOS Wiki**: https://nixos.wiki/
- **DankMaterialShell Docs**: https://danklinux.com/docs/
- **Nix Pills**: https://nixos.org/guides/nix-pills/

## 联系与协作

- **项目负责人**: alan
- **协作方式**: 通过 Claude 逐步完成配置生成
- **问题反馈**: 记录在 `lessons.md`
