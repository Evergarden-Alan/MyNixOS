# Application Flow

## 系统启动流程

```
[GRUB/rEFInd]
    ↓
[Linux Kernel + initramfs]
    ↓
[systemd init]
    ↓
[greetd (TTY1)]
    ↓
[自动登录 alan]
    ↓
[niri-session 启动]
    ↓
┌─────────────────────────────────────┐
│  DankMaterialShell (Niri compositor) │
│  ├─ niri-sidebar                     │
│  ├─ fcitx5 (输入法)                  │
│  ├─ pipewire (音频)                  │
│  └─ NetworkManager                   │
└─────────────────────────────────────┘
```

## 用户交互流程

### 1. 桌面启动后
```
[按 Super] → fuzzel 启动器
           → 输入应用名 → 启动应用

[鼠标右键] → niri-sidebar 侧边栏
            ├─ 系统监控
            ├─ 快捷操作
            └─ 应用启动

[Ctrl+Alt+T] → alacritty 终端
```

### 2. 终端工作流
```
[打开 alacritty]
    ↓
[fish shell]
    ↓
├─ cd <dir>     → zoxide 快速跳转
├─ ls           → eza (彩色列表)
├─ cat <file>   → bat (语法高亮)
├─ vim <file>   → neovim
└─ lazygit      → Git 可视化管理
```

### 3. 开发流程
```
[VSCode / Neovim]
    ↓
[编辑代码]
    ↓
[终端执行]
    ├─ docker compose up  (容器环境)
    ├─ npm run dev        (前端开发)
    ├─ python main.py     (脚本执行)
    └─ git commit         (lazygit 管理)
```

### 4. 浏览器使用
```
[fuzzel] → firefox / chromium / brave
    ↓
[浏览网页]
    ├─ fcitx5 输入中文 (Ctrl+Space 切换)
    ├─ 复制链接/文本
    └─ 下载文件 → ~/Downloads
```

### 5. 文件管理
```
[fuzzel] → nautilus / thunar
    ↓
├─ 浏览文件
├─ 右键菜单 → 打开终端 (nautilus-open-any-terminal)
├─ 挂载外部设备 (thunar-volman)
└─ 压缩/解压 (file-roller / thunar-archive-plugin)

[终端] → yazi (TUI 文件管理器)
```

### 6. 媒体播放
```
[点击视频文件] → mpv 播放
[点击图片]     → imv 查看
[OBS Studio]   → 录屏/直播
```

## 系统服务状态流程

### Docker 服务
```
[系统启动] → docker.service (enabled)
           → docker.socket 监听
           → 用户运行 docker ps
```

### 网络管理
```
[系统启动] → NetworkManager.service
           → iwd.service (WiFi backend)
           → 自动连接已保存网络
           ↓
[GUI 管理] → nm-connection-editor
```

### 蓝牙管理
```
[系统启动] → bluetooth.service
           ↓
[TUI 管理] → bluetui
```

### 快照管理
```
[定时任务] → snapper-timeline.timer (自动快照)
           → snapper-cleanup.timer (清理旧快照)
           ↓
[GUI 管理] → btrfs-assistant
```

## 输入法切换流程

```
[启动应用]
    ↓
[fcitx5 自动启动]
    ↓
[英文输入状态]
    ↓
[按 Ctrl+Space]
    ↓
[切换到 Rime]
    ↓
├─ 拼音输入 (rime-ice)
├─ 五笔输入 (rime-wubi)
└─ LLM 翻译 (rime-llm-translator)
```

## 错误处理流程

### 应用崩溃
```
[应用崩溃]
    ↓
[systemd-coredump 捕获]
    ↓
[journalctl -xe 查看日志]
    ↓
[重启应用或系统服务]
```

### 网络断开
```
[NetworkManager 检测断开]
    ↓
[自动尝试重连]
    ↓
[失败] → nm-connection-editor 手动诊断
```

### 磁盘满
```
[磁盘空间不足]
    ↓
[snapper 自动清理旧快照]
    ↓
[仍不足] → baobab (磁盘空间分析器)
           → 手动清理
```

## 关键状态转换

### 从桌面到终端
- 默认状态：DankMaterialShell 桌面
- 触发：Super+Enter 或快捷键
- 新状态：alacritty 全屏终端

### 从工作到休息
- 默认状态：应用运行中
- 触发：Super+L 锁屏 或合盖
- 新状态：greetd 锁屏界面

### 从登录到桌面
- 默认状态：greetd 登录界面
- 触发：输入密码 或自动登录
- 新状态：Niri 桌面环境加载完成

## 配置热重载

### Niri 配置
```
[编辑 ~/.config/niri/config.kdl]
    ↓
[niri msg reload-config]
    ↓
[配置立即生效]
```

### Fish Shell 配置
```
[编辑 ~/.config/fish/config.fish]
    ↓
[source ~/.config/fish/config.fish]
    或重启终端
```

### NixOS 配置（未来）
```
[编辑 /etc/nixos/configuration.nix]
    ↓
[sudo nixos-rebuild switch]
    ↓
[系统配置更新]
    ↓
[部分服务重启]
```
