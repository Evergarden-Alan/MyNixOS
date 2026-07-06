# ❄️ My NixOS Configuration

基于 [Nix Flakes](https://wiki.nixos.org/wiki/Flakes) 和 [Home Manager](https://github.com/nix-community/home-manager) 的个人 NixOS 配置。在任何机器上克隆此仓库，一条命令即可还原完整桌面环境。

## 🖥️ 概览

| 组件 | 选择 |
|------|------|
| **发行版** | NixOS (unstable) |
| **显示管理器** | GDM (Wayland) |
| **桌面环境** | GNOME + Niri (平铺窗口管理器) |
| **引导器** | systemd-boot (全新/UEFI) / rEFInd (双系统) / grub (BIOS/VM) |
| **Shell** | Fish + Starship |
| **终端** | Kitty / Alacritty |
| **任务栏** | Waybar |
| **通知** | Mako |
| **输入法** | Fcitx5 |
| **音频** | PipeWire |
| **壁纸** | swaybg + waypaper + matugen 自动配色 |
| **代理** | mihomo 内核 + 订阅 (大陆网络) |
| **编辑器** | VSCode / Vim |

## 📁 目录结构

```
.
├── flake.nix                  # Flake 入口：自动发现 hosts/ 下所有主机
├── flake.lock                 # 依赖版本锁定文件
├── bootstrap.sh               # 全自动安装脚本 (Live ISO 中运行)
├── .gitattributes             # 强制 *.sh/*.env 用 LF (防 Windows CRLF 坑)
├── hosts/
│   ├── _template/             # 新主机模板 (cp -r 后改名，改一行即可)
│   │   ├── configuration.nix
│   │   └── hardware-configuration.nix.placeholder
│   └── vm/
│       ├── configuration.nix  # 系统级配置（引导、网络、主机名；vm 用 BIOS grub）
│       └── hardware-configuration.nix  # 自动生成的硬件配置（机器相关）
├── modules/
│   ├── options.nix            # 全局参数 (my.username / my.fullName / my.hostName)
│   ├── core.nix               # 核心系统模块（时区、locale、用户、SSH、Nix 设置 + 自动 GC）
│   └── desktop.nix            # 桌面环境模块（GDM、GNOME、Niri、蓝牙、字体、Portal）
├── assets/
│   ├── mihomo/                # mihomo 内核 + geo 路由数据库 (大陆代理)
│   └── refind/                # rEFInd 引导主题 (双系统用，rEFInd-minimal)
├── images/
│   └── wallpaper.png          # 默认壁纸
├── home/
│   └── home.nix               # Home Manager 用户配置
└── config/                    # 用户配置文件（dotfiles，即时编辑生效）
    ├── fish/                  # Fish Shell 配置
    ├── niri/                  # Niri 窗口管理器（binds/colors/rules/hyprlock + scripts/）
    ├── waybar/                # Waybar 任务栏（自定义脚本 + logo + modules）
    ├── kitty/                 # Kitty 终端
    ├── fuzzel/                # Fuzzel 应用启动器
    ├── btop/                  # 系统资源监控
    ├── fastfetch/             # 系统信息展示
    ├── matugen/               # Matugen 配色模板 (templates/*.tera)
    ├── mihomo/                # mihomo 运行时配置目录
    ├── scripts/               # 全局脚本 (start-proxy / matugen-update / install-refind-theme)
    ├── starship.toml          # Starship 提示符主题
    ├── waypaper/              # 壁纸管理器
    └── yazi/                  # 终端文件管理器
```

## 🚀 在新机器上还原环境

### 方式一：全自动脚本 (推荐)

把仓库弄到 NixOS Live ISO 上 (USB 或 `git clone`)，然后：

```bash
cd /path/to/dotfiles
sudo bash bootstrap.sh
```

> **⚠️ Windows 用户注意 (CRLF)**: 仓库在 Windows 上 checkout 时 `core.autocrlf` 会把 `*.sh` 转成 CRLF，原样拷到 Linux 会第一行就报错（`bad interpreter` / `\r: command not found`）。已用 `.gitattributes` 强制 `*.sh`/`*.env` 用 LF 根治。若你已拷了 CRLF 版本到 Live 盘，跑前先转：
> ```bash
> sed -i 's/\r$//' bootstrap.sh config/scripts/*.sh
> ```
> 或直接在 Live 盘 `git clone`（Linux clone 出来就是 LF，无此问题）。

脚本流程：
1. 交互询问磁盘、主机名、用户名、仓库地址、文件系统、时区
2. **自动检测 `assets/mihomo/` 内核** → 下载订阅配置 → 启动代理 (大陆用户)
3. 选择 Nix 镜像 (TUNA/SJTU/USTC)
4. 选择安装模式：**全新安装** (全盘擦除, systemd-boot) 或 **双系统** (空闲空间建 NixOS ESP + root, rEFInd)
5. 自动分区、格式化、挂载、`nixos-generate-config`
6. `git clone` 仓库到 `/mnt/home/<user>/.dotfiles` (走代理)
7. 生成 `hosts/<主机名>/configuration.nix` (含引导器/镜像/身份配置)
8. `nixos-install --flake .#<主机名>`
9. 设置 `<user>` 密码 (最多重试 3 次)

**双系统模式**: 保留 Windows 分区不动，在空闲空间新建独立 ESP (装 rEFInd) + NixOS 根分区。先在 Windows 磁盘管理中压缩卷腾空间。脚本会写入 rEFInd 配置（含 minimal 主题 include），但主题文件需进新系统后跑 `install-refind-theme.sh` 装到 ESP（见下文 [rEFInd 主题](#refind-引导主题-双系统)）。

**大陆网络**: 仓库中预置了 mihomo 内核 (`assets/mihomo/`) 和两份订阅链接。脚本自动解压、下载配置、启动代理，后续 git/nix 全部走 `http://127.0.0.1:7890`。

### 方式二：手动安装 + 注册新主机

以下步骤适用于已经有 NixOS 基础系统、需要新增设备的情况。

---

### 第一步：安装 NixOS 基础系统

从 [NixOS 官网](https://nixos.org/download) 下载最新的 minimal ISO，制作启动盘后引导。

#### 1.1 分区与格式化（UEFI + btrfs 示例）

```bash
# 查看磁盘
lsblk

# 假设目标磁盘是 /dev/sda，按以下方案分区：
#   sda1: 512M  EFI System Partition
#   sda2: 剩余   btrfs (root + home + nix 子卷)
parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart ESP fat32 1MiB 512MiB
parted /dev/sda -- set 1 esp on
parted /dev/sda -- mkpart primary 512MiB 100%

# 格式化
mkfs.fat -F 32 /dev/sda1
mkfs.btrfs /dev/sda2

# 创建 btrfs 子卷
mount /dev/sda2 /mnt
btrfs subvolume create /mnt/@          # /
btrfs subvolume create /mnt/@home      # /home
btrfs subvolume create /mnt/@nix       # /nix
umount /mnt

# 挂载
mount -o compress=zstd,subvol=@ /dev/sda2 /mnt
mkdir -p /mnt/{home,nix,boot}
mount -o compress=zstd,subvol=@home /dev/sda2 /mnt/home
mount -o compress=zstd,noatime,subvol=@nix /dev/sda2 /mnt/nix
mount /dev/sda1 /mnt/boot
```

> **如果你用 ext4**（更简单）：
> ```bash
> mkfs.ext4 /dev/sda2
> mount /dev/sda2 /mnt
> mkdir /mnt/boot
> mount /dev/sda1 /mnt/boot
> ```

#### 1.2 生成硬件配置

```bash
nixos-generate-config --root /mnt
```

这会在 `/mnt/etc/nixos/` 下生成两个文件：
- `hardware-configuration.nix` — 硬件相关（磁盘 UUID、文件系统、内核模块）
- `configuration.nix` — 基础系统配置（后面会替换掉）

#### 1.3 编辑基础配置（让安装能跑通）

```bash
nano /mnt/etc/nixos/configuration.nix
```

在生成的配置中**至少**确保以下设置正确：

```nix
# 启用 Flakes 支持
nix.settings.experimental-features = [ "nix-command" "flakes" ];

# 网络
networking.networkmanager.enable = true;

# 用户（先建一个临时用户用于后续操作）
users.users.alan = {
  isNormalUser = true;
  extraGroups = [ "wheel" "networkmanager" ];
};
```

#### 1.4 执行安装

```bash
nixos-install
```

安装完成后设置 root 密码，然后 `reboot`。

---

### 第二步：克隆本仓库

用刚才创建的 `alan` 用户登录，然后：

```bash
# 安装 git（NixOS 默认没有）
nix-shell -p git

# 克隆仓库（⚠️ 必须克隆到 ~/.dotfiles）
git clone https://github.com/Evergarden-Alan/MyNixOS.git ~/.dotfiles
cd ~/.dotfiles
```

---

### 第三步：注册新主机

```bash
# 1. 从模板创建主机目录
cp -r ~/.dotfiles/hosts/_template ~/.dotfiles/hosts/当前设备名称/

# 2. 把装机时生成的 hardware-configuration.nix 复制进去
sudo cp /etc/nixos/hardware-configuration.nix ~/.dotfiles/hosts/当前设备名称/hardware-configuration.nix

# 3. 编辑 hosts/当前设备名称/configuration.nix，改三处：
#    - networking.hostName = "当前设备名称";   # 必须 = 目录名
#    - my.username = "alan";                   # 你的用户名
#    - 引导方式 (UEFI 默认 systemd-boot，BIOS 改为 grub)
```

> **说明**：`hardware-configuration.nix` 包含磁盘 UUID、文件系统布局、内核模块等机器特有信息。这是整个配置中**唯一**需要按机器替换的文件。
>
> `flake.nix` 会自动发现 `hosts/` 下的新目录——**无需手动编辑 flake.nix**。

---

### 第四步：调整机器差异项

打开 `hosts/当前设备名称/configuration.nix`，检查并修改以下内容：

| 配置项 | 位置 | 说明 |
|--------|------|------|
| `networking.hostName` | configuration.nix | 改成主机名 |
| `boot.loader.grub.device` | configuration.nix | 改成你的磁盘（如 `/dev/nvme0n1`） |
| `boot.loader.grub.fsIdentifier` | configuration.nix | btrfs 用 `provided`，ext4 可删掉这行 |
| 用户名 | `core.nix` + `home.nix` | 如果你不叫 `alan`，需要改三处 |
| SSH 公钥 | `core.nix` | 取消注释 `openssh.authorizedKeys.keys` 并填入你的公钥 |

#### 如果你的磁盘不是 btrfs

`hardware-configuration.nix` 中的 `fileSystems` 入口会自动反映你的文件系统类型，不需要手动修改。

---

### 第五步：构建系统

```bash
cd ~/.dotfiles

# 首次构建（会下载所有依赖，需要一段时间）
sudo nixos-rebuild switch --flake .#vm
```

构建完成后，你的系统已经拥有：
- GDM 登录管理器
- GNOME 桌面 + Niri 窗口管理器
- 所有系统级软件包

---

### 第六步：首次登录后的设置

#### 6.1 切换到 Niri 会话

在 GDM 登录界面，点击齿轮图标，选择 **Niri**，然后登录。

> 首次进入 Niri 后按 `Super + Shift + /` 可以看到快捷键提示。

#### 6.2 配置 API Token（用于 claude-code）

```bash
# 创建 secrets 文件（已加入 .gitignore，不会被提交）
cat > ~/.secrets << 'EOF'
set -gx ANTHROPIC_AUTH_TOKEN "你的DeepSeek或Anthropic的API Token"
EOF

# 赋予正确权限
chmod 600 ~/.secrets
```

#### 6.3 安装 claude-code（通过 npm）

```bash
npm install -g @anthropic-ai/claude-code
```

#### 6.4 配置 SSH 密钥

```bash
# 生成密钥对
ssh-keygen -t ed25519 -C "alan@$(hostname)"

# 显示公钥，复制后添加到 GitHub/GitLab 等平台
cat ~/.ssh/id_ed25519.pub
```

如果之前在 `core.nix` 中启用了 SSH 公钥认证，把你的公钥添加进去并重建：

```bash
# 编辑 core.nix，取消注释 openssh.authorizedKeys.keys 那行
# 然后重建
sudo nixos-rebuild switch --flake .#vm
```

---

### 第七步：日常维护

```bash
# 更新 flake 依赖（拉取最新的 nixpkgs 和 home-manager）
cd ~/.dotfiles && nix flake update

# 重建系统 (主机名 = hosts/ 目录名)
sudo nixos-rebuild switch --flake .#$(hostname)

# 清理旧代际，释放磁盘空间
sudo nix-collect-garbage -d
```

以上操作也可以通过 Waybar 上的按钮一键触发（已配置好命令中心）。

---

## 🔧 配置说明

### 架构设计：Imperative-Declarative Hybrid

```
┌─────────────────────────────────────────────┐
│  Home Manager (声明式)                       │
│  programs.git / vim / fish / starship / ... │  ← 二进制和基础配置由 Nix 管理
├─────────────────────────────────────────────┤
│  mkOutOfStoreSymlink (命令式热更新)           │
│  niri / waybar / fish config.fish           │  ← 配置文件即时编辑生效
├─────────────────────────────────────────────┤
│  xdg.configFile (Nix Store 软链接)            │
│  kitty / fuzzel / btop / starship.toml      │  ← 跟随 flake 版本锁定
└─────────────────────────────────────────────┘
```

**为什么这样设计？**
- Niri 和 Waybar 配置需要频繁调参，`mkOutOfStoreSymlink` 允许编辑后即时生效，无需 `nixos-rebuild`
- Git、Fish、Starship 等基础工具配置稳定，由 Home Manager 声明式管理更可靠
- 配合 `git` 实现配置的版本控制和回滚

### 系统模块

| 模块 | 职责 |
|------|------|
| `modules/core.nix` | 时区 (Asia/Shanghai)、中文 locale、用户 (可配)、Nix 设置、SSH |
| `modules/desktop.nix` | GDM (Wayland)、GNOME、Niri、PipeWire、蓝牙、GPU、Portal、字体、Fcitx5 |
| `modules/options.nix` | 全局参数 `my.username` / `my.fullName` — 改用户名只需改 host 的 configuration.nix |
| `home/home.nix` | 用户级包、Fish/Zoxide/Yazi/Git 配置、dotfiles 软链接、polkit agent、matugen |

### 快捷键速查

Niri 的快捷键定义在 `config/niri/binds.kdl`：

| 快捷键 | 功能 |
|--------|------|
| `Super + Enter` | 打开终端 (Kitty) |
| `Super + D` | 应用启动器 (Fuzzel) |
| `Super + Q` | 关闭窗口 |
| `Super + H/J/K/L` | Vim 风格焦点移动 |
| `Super + Ctrl + H/J/K/L` | 移动窗口/列 |
| `Super + V` | 切换浮动模式 |
| `Super + F` | 最大化列 |
| `Super + Alt + F` | 全屏窗口 |
| `Super + O` / `Super + G` | 总览模式 |
| `Super + 1-9` | 切换工作区 |
| `Super + Shift + S` | 区域截图 |
| `Super + Shift + E` | 退出 Niri |
| `Super + Shift + /` | 显示快捷键帮助 |
| `Alt + Tab` | 快速窗口切换 |
| `Mod + F9` | 切换护眼模式 (wlsunset) |

---

## ⚠️ 注意事项

### 机器适配清单

在新机器上部署时，你需要检查/修改：

- [ ] `hardware-configuration.nix` — 替换为新机器生成的版本
- [ ] `boot.loader.*` — 单系统 UEFI 用 systemd-boot；BIOS 用 grub；双系统 Win11+NixOS 用 rEFInd（`_template` 默认 rEFInd）
- [ ] `networking.hostName` — **必须等于 `hosts/` 目录名**（waybar rebuild 命令靠这个定位 flake）
- [ ] `my.username` — 改用户名只需改这一处（`core.nix` 和 `home.nix` 自动跟随）
- [ ] `my.fullName` — 用户全名
- [ ] `openssh.authorizedKeys.keys` in `core.nix` — 填入你的 SSH 公钥（配好后建议设 `PasswordAuthentication = false`）
- [ ] `wlsunset` 经纬度 — 在 `binds.kdl` 中改为你的位置（Mod+F9）

### 用户名修改指南 (现在只需改一处)

1. `hosts/<你的主机>/configuration.nix` → `my.username = "你的用户名";`

`core.nix` 和 `home.nix` 通过 `config.my.username` 自动读取，无需手动修改。

### 切换桌面环境

登录时在 GDM 点击齿轮选择：
- **Niri** — 平铺窗口管理器（主力环境）
- **GNOME** — 传统桌面（兼容 / 备用）

### 无法通过 nix 安装的程序

以下工具来自 AUR 或为自定义脚本，已从配置中移除/注释。如果你需要它们，请自行安装：

- `niri-sidebar` — 侧边栏扩展
- `niriusd` — Niri 服务
- `shorinclip` — 剪贴板 TUI
- `bluetui` — 蓝牙 TUI（已用 `blueman-manager` 替代）
- `wl-longshot` — 长截图（已删除依赖 Python venv 的旧实现）
- `swww` — 动画壁纸守护进程 (上游 v0.12 改名 `awww`，nixpkgs 尚未跟进 [#459434](https://github.com/nixos/nixpkgs/issues/459434)，暂用 `swaybg`)

### 更新 mihomo 内核

```bash
# 从 GitHub Releases 下载最新 linux-amd64 .gz
# 放到 assets/mihomo/，替换旧文件
# geo 数据库同理: https://github.com/MetaCubeX/meta-rules-dat/releases
```

### rEFInd 引导主题 (双系统)

双系统模式用 rEFInd 作引导器，自动扫描 ESP 上 Win11 + NixOS 引导项并按 `os_*.png` 匹配图标。`assets/refind/rEFInd-minimal/` 是预置主题（自带 `os_nixos.png` + `os_win.png`）。

进新系统后把主题装到 ESP：

```bash
sudo bash config/scripts/install-refind-theme.sh          # 默认 minimal
# 可选主题: minimal (推荐, 自带 NixOS 图标) | dawn | sublime
```

脚本把主题拷到 `ESP/EFI/refind/themes/` 并在 `refind.conf` 追加 `include`，同时检查 UEFI 启动顺序（确保 rEFInd 排第一，否则开机直进 Win11）。

> ⚠️ `nixos-rebuild` 会重新生成 `refind.conf` 抹掉 include 行。持久化需把 `boot.loader.refind.extraConfig` 写进 `hosts/<主机名>/configuration.nix`（`_template` 已含，bootstrap.sh 双系统模式也会自动写入）。

### Matugen 配色系统

壁纸切换时自动运行 `matugen-update.sh` 生成 Material You 配色到：
- `~/.config/waybar/colors.css`
- `~/.config/niri/colors.kdl`
- `~/.config/niri/hypr-colors.conf`

模板和配置在 `config/matugen/`。手动更新配色：`Mod+Alt+M` 或 `Mod+Alt+T`。

---

## 📦 依赖管理

```
nixpkgs (nixos-unstable)
├── home-manager (follows nixpkgs)
├── NixOS 系统级包 (environment.systemPackages)
└── 用户级包 (home.packages)
    ├── 桌面环境组件 (waybar, mako, fcitx5, ...)
    ├── 终端工具 (kitty, btop, ripgrep, eza, bat, ...)
    ├── 截图录屏 (grim, slurp, wf-recorder, ...)
    └── 运行环境 (nodejs → npm → claude-code)
```

`home-manager` 通过 `inputs.nixpkgs.follows` 与系统共用一个 nixpkgs 版本，避免重复下载。

---

## 📄 许可证

MIT
