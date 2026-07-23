# Frontend Guidelines (User Configuration)

## 概述

本文档描述用户配置文件的组织方式。在 NixOS 环境下，用户配置通过 **home-manager** 声明式管理。

## 目录结构

```
/home/alan/Projects/my_nixos/
├── flake.nix                    # Flake 入口
├── flake.lock                   # 锁定版本
├── configuration.nix            # 系统级配置
├── home.nix                     # 用户级配置 (home-manager)
├── modules/                     # 模块化配置
│   ├── desktop/                 # 桌面环境相关
│   │   ├── niri.nix            # Niri compositor 配置
│   │   ├── dms.nix             # DankMaterialShell 配置
│   │   ├── fuzzel.nix          # 启动器配置
│   │   └── greetd.nix          # 登录管理器配置
│   ├── shell/                   # Shell 环境
│   │   ├── fish.nix            # Fish shell 配置
│   │   ├── zsh.nix             # Zsh 配置
│   │   ├── starship.nix        # Starship 提示符
│   │   └── cli-tools.nix       # CLI 工具集合
│   ├── input/                   # 输入法
│   │   ├── fcitx5.nix          # Fcitx5 框架
│   │   └── rime.nix            # Rime 引擎配置
│   ├── apps/                    # 应用程序
│   │   ├── terminals.nix       # 终端模拟器
│   │   ├── browsers.nix        # 浏览器
│   │   ├── editors.nix         # 编辑器
│   │   └── media.nix           # 媒体应用
│   ├── dev/                     # 开发环境
│   │   ├── git.nix             # Git 配置
│   │   ├── docker.nix          # Docker 配置
│   │   └── languages.nix       # 编程语言
│   └── services/                # 系统服务
│       ├── network.nix         # 网络服务
│       ├── bluetooth.nix       # 蓝牙
│       └── virtualization.nix  # 虚拟化
├── config/                      # 原始配置文件 (参考用)
│   ├── niri/
│   │   ├── config.kdl
│   │   ├── layout.kdl
│   │   └── animations.kdl
│   ├── fish/
│   │   └── config.fish
│   ├── alacritty/
│   │   ├── alacritty.toml
│   │   └── dank-theme.toml
│   ├── fuzzel/
│   │   ├── fuzzel.ini
│   │   └── colors.ini
│   ├── starship.toml
│   └── gitconfig
└── docs/                        # 文档
    ├── PRD.md
    ├── APP_FLOW.md
    ├── TECH_STACK.md
    ├── FRONTEND_GUIDELINES.md
    ├── BACKEND_STRUCTURE.md
    └── IMPLEMENTATION_PLAN.md
```

## home-manager 配置结构

### home.nix 主文件

```nix
{ config, pkgs, inputs, ... }:

{
  imports = [
    # 桌面环境
    ./modules/desktop/dms.nix
    ./modules/desktop/niri.nix
    ./modules/desktop/fuzzel.nix
    
    # Shell 环境
    ./modules/shell/fish.nix
    ./modules/shell/zsh.nix
    ./modules/shell/starship.nix
    ./modules/shell/cli-tools.nix
    
    # 输入法
    ./modules/input/fcitx5.nix
    ./modules/input/rime.nix
    
    # 应用程序
    ./modules/apps/terminals.nix
    ./modules/apps/browsers.nix
    ./modules/apps/editors.nix
    ./modules/apps/media.nix
    
    # 开发环境
    ./modules/dev/git.nix
    ./modules/dev/docker.nix
  ];

  home = {
    username = "alan";
    homeDirectory = "/home/alan";
    stateVersion = "26.05";
    
    # 用户级软件包
    packages = with pkgs; [
      # 基础工具在各模块中定义
    ];
  };

  # 允许非自由软件
  nixpkgs.config.allowUnfree = true;

  # home-manager 自管理
  programs.home-manager.enable = true;
}
```

## 配置文件管理规范

### 1. 配置文件来源

**从 Arch Linux 迁移的配置文件：**
1. 先复制到 `config/` 目录保存原始版本
2. 在对应的 `.nix` 模块中用 home-manager 声明式配置

### 2. 配置文件转换方式

#### 方式 A：直接嵌入（小文件）
```nix
# modules/shell/starship.nix
{ config, pkgs, ... }:

{
  programs.starship = {
    enable = true;
    settings = {
      # 直接写入配置
      add_newline = false;
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };
    };
  };
}
```

#### 方式 B：引用文件（大文件）
```nix
# modules/desktop/niri.nix
{ config, pkgs, ... }:

{
  xdg.configFile."niri/config.kdl".source = ../config/niri/config.kdl;
  xdg.configFile."niri/layout.kdl".source = ../config/niri/layout.kdl;
  xdg.configFile."niri/animations.kdl".source = ../config/niri/animations.kdl;
}
```

#### 方式 C：模板替换（含变量）
```nix
# modules/shell/fish.nix
{ config, pkgs, ... }:

{
  programs.fish = {
    enable = true;
    shellInit = ''
      set fish_greeting ""
      set -p PATH ~/.local/bin
    '';
    interactiveShellInit = ''
      starship init fish | source
      zoxide init fish --cmd cd | source
    '';
  };
}
```

### 3. 敏感信息处理

**不要将敏感信息写入 Nix 配置！**

```nix
# ❌ 错误示例
environment.variables = {
  ANTHROPIC_AUTH_TOKEN = "sk-ff2afb3ae42a42d99d7a84e26e5c8df4";
};

# ✅ 正确做法：使用外部文件
programs.fish.interactiveShellInit = ''
  if test -f ~/.config/fish/secrets.fish
    source ~/.config/fish/secrets.fish
  end
'';
```

手动创建 `~/.config/fish/secrets.fish`：
```fish
set -gx ANTHROPIC_AUTH_TOKEN "sk-xxx"
set -gx ANTHROPIC_BASE_URL "https://api.deepseek.com/anthropic"
```

## 模块化规范

### 模块命名规则
- 文件名：小写，连字符分隔（如 `cli-tools.nix`）
- 模块功能单一，职责明确
- 避免循环依赖

### 模块结构模板

```nix
# modules/apps/example.nix
{ config, pkgs, lib, ... }:

{
  # 软件包安装
  home.packages = with pkgs; [
    package1
    package2
  ];

  # 程序配置
  programs.example = {
    enable = true;
    # 配置项
  };

  # 配置文件管理
  xdg.configFile."example/config".text = ''
    # 配置内容
  '';

  # 环境变量
  home.sessionVariables = {
    EXAMPLE_VAR = "value";
  };
}
```

## 桌面环境配置策略

### DankMaterialShell 配置

```nix
# modules/desktop/dms.nix
{ config, pkgs, inputs, ... }:

{
  imports = [
    inputs.dms.homeModules.dank-material-shell
  ];

  programs.dank-material-shell = {
    enable = true;
    systemd = {
      enable = true;
      restartIfChanged = true;
    };
    enableSystemMonitoring = true;
    enableVPN = false;  # 根据需求
    enableDynamicTheming = true;
    enableAudioWavelength = true;
    enableCalendarEvents = false;
  };
}
```

### Niri 配置

由于 Niri 的配置文件是 KDL 格式（无原生 Nix 支持），采用**文件引用方式**：

```nix
# modules/desktop/niri.nix
{ config, pkgs, ... }:

{
  xdg.configFile = {
    "niri/config.kdl".source = ../config/niri/config.kdl;
    "niri/layout.kdl".source = ../config/niri/layout.kdl;
    "niri/animations.kdl".source = ../config/niri/animations.kdl;
  };
}
```

### 输入法配置

```nix
# modules/input/fcitx5.nix
{ config, pkgs, ... }:

{
  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-rime
      fcitx5-gtk
      fcitx5-configtool
    ];
  };

  # Rime 词库
  home.file.".local/share/fcitx5/rime" = {
    source = ../config/rime;
    recursive = true;
  };
}
```

## 字体配置

```nix
# modules/desktop/fonts.nix
{ config, pkgs, ... }:

{
  fonts.fontconfig.enable = true;
  
  home.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    liberation_ttf
  ];
}
```

## 主题配置

```nix
# modules/desktop/theme.nix
{ config, pkgs, ... }:

{
  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
    cursorTheme = {
      name = "Breeze";
      package = pkgs.kdePackages.breeze;
      size = 24;
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk3";
  };
}
```

## CLI 工具配置

```nix
# modules/shell/cli-tools.nix
{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    bat       # cat 增强
    eza       # ls 增强
    fd        # find 增强
    fzf       # 模糊查找
    ripgrep   # grep 增强
    jq        # JSON 处理
    btop      # 系统监控
    fastfetch # 系统信息
    lazygit   # Git TUI
    yazi      # 文件管理 TUI
  ];

  # bat 配置
  programs.bat = {
    enable = true;
    config = {
      theme = "TwoDark";
    };
  };

  # eza 别名
  programs.fish.shellAliases = {
    ls = "eza --icons";
    ll = "eza -l --icons";
    la = "eza -la --icons";
    tree = "eza --tree --icons";
  };

  # zoxide
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
    enableZshIntegration = true;
  };
}
```

## 配置更新流程

### 开发环境（生成配置阶段）

```bash
# 1. 编辑配置文件
vim modules/shell/fish.nix

# 2. 验证语法
nix flake check

# 3. 预览更改
nix flake show

# 4. 提交版本控制
git add .
git commit -m "feat: add fish shell configuration"
```

### 生产环境（实际使用 NixOS）

```bash
# 1. 应用用户配置
home-manager switch --flake .#alan

# 2. 应用系统配置
sudo nixos-rebuild switch --flake .

# 3. 回滚（如果出错）
home-manager generations  # 查看历史版本
home-manager switch --switch-generation <num>
```

## 配置验证清单

### 语法检查
- [ ] `nix flake check` 通过
- [ ] 无 Nix 语法错误
- [ ] 模块导入路径正确

### 功能验证
- [ ] 桌面环境启动正常
- [ ] 输入法切换正常
- [ ] Shell 环境变量生效
- [ ] CLI 工具可用
- [ ] 应用程序启动正常

### 兼容性检查
- [ ] Wayland 应用正常显示
- [ ] X11 应用通过 XWayland 正常运行
- [ ] 字体渲染正确
- [ ] 主题应用一致

## 注意事项

1. **配置文件权限**
   - home-manager 管理的文件为只读
   - 需手动编辑时，先编辑 Nix 配置再 switch

2. **配置冲突**
   - 避免同时用 system 和 home-manager 配置同一项
   - 优先用 home-manager 管理用户级配置

3. **配置备份**
   - 原始 Arch 配置保存在 `config/` 目录
   - Nix 配置使用 Git 版本控制

4. **性能优化**
   - 使用 `nix-direnv` 加速 shell 环境
   - 合理使用 `nix-output-monitor` 查看构建进度
