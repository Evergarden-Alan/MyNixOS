# Product Requirements Document (PRD)

## 产品定位
将当前 Arch Linux 系统的核心配置迁移到 NixOS 配置文件，生成完整的 Flake-based NixOS 配置，供未来安装使用。

## 目标用户
- 主用户：alan
- 使用场景：个人开发、日常办公、娱乐
- 技术水平：高级 Linux 用户，熟悉 Arch Linux

## 核心功能列表（按优先级）

### P0 - 必须实现
1. **DankMaterialShell 桌面环境配置**
   - 基于 Niri compositor
   - 集成 niri-sidebar
   - greetd 自动登录配置

2. **Shell 环境**
   - fish 作为主 shell
   - zsh 作为备用 shell
   - starship 提示符
   - zoxide 目录跳转

3. **系统服务**
   - docker
   - NetworkManager + iwd
   - bluetooth
   - tailscaled
   - power-profiles-daemon
   - snapper (btrfs 快照)

4. **输入法**
   - fcitx5 框架
   - fcitx5-rime 引擎
   - rime-ice 词库
   - rime-wubi 五笔

### P1 - 强烈建议
5. **CLI 工具**
   - bat, eza, fd, fzf, ripgrep
   - lazygit, gh (GitHub CLI)
   - btop, fastfetch
   - jq, pv, strace

6. **开发工具**
   - neovim
   - visual-studio-code-bin (需特殊处理)
   - git + git-lfs
   - nodejs, python-pip

7. **GUI 应用**
   - 浏览器：firefox, chromium, brave
   - 文件管理：nautilus, thunar
   - 终端：alacritty, kitty
   - 媒体：mpv, imv
   - obsidian (笔记)

8. **字体**
   - noto-fonts-cjk
   - noto-fonts-emoji
   - ttf-jetbrains-mono-nerd
   - ttf-liberation

### P2 - 可选功能
9. **虚拟化**
   - qemu-full + virt-manager
   - docker

10. **游戏相关**
    - steam
    - lutris
    - mangohud

11. **多媒体**
    - obs-studio
    - wf-recorder / wl-screenrec
    - easyeffects

### P3 - 暂不处理
12. **国产软件（Flatpak 替代）**
    - linuxqq
    - wechat-appimage
    - wemeet-bin
    - feishu-bin

13. **AUR 特殊包（暂不迁移）**
    - shorin-* 系列
    - quickshell-git
    - clash-verge-rev-bin

## 非功能性需求

### 性能
- 使用 Flakes 实现可复现构建
- 启用 home-manager 管理用户配置
- 合理使用 nixpkgs cache，减少编译时间

### 安全
- 锁定 flake.lock 版本
- 敏感信息（API token）不写入配置文件

### 可维护性
- 模块化拆分配置文件
- 清晰的目录结构
- 充分注释关键配置

## Out of Scope（不做什么）

1. **不立即安装 NixOS**
   - 只生成配置文件，不实际替换系统

2. **不迁移 /home 数据**
   - 用户数据保持原位，配置文件通过 home-manager 管理

3. **不处理双引导配置**
   - GRUB/refind 配置等实际安装时再处理

4. **不自动迁移 AUR 包**
   - 特殊软件包需要手动处理或替换

## 成功标准

1. 生成完整的 `flake.nix` + `configuration.nix` + `home.nix`
2. 所有 P0/P1 软件包已配置
3. 系统服务配置已转换
4. dotfiles 已整合到 home-manager
5. 配置文件可通过 `nix flake check` 验证通过
