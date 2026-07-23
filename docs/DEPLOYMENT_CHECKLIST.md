# NixOS 部署检查清单

## 前期准备（当前在 Arch Linux）

### 1. 数据备份 ✓ TODO
- [ ] 备份 /home 目录到外部存储
  ```bash
  sudo rsync -av --progress /home/alan /path/to/backup/
  ```
- [ ] 备份重要配置（已在 config/ 目录）
- [ ] 导出浏览器书签和密码
- [ ] 导出 SSH 密钥和 GPG 密钥
  ```bash
  cp -r ~/.ssh ~/backup/
  gpg --export-secret-keys > ~/backup/gpg-private.asc
  ```
- [ ] 记录当前磁盘分区情况
  ```bash
  lsblk -f > ~/backup/partitions.txt
  sudo fdisk -l > ~/backup/fdisk.txt
  ```

### 2. 下载 NixOS 安装介质
- [ ] 下载 NixOS 26.05 ISO
  - 官网: https://nixos.org/download.html
  - 选择 GNOME 或 Minimal ISO
- [ ] 验证 ISO 校验和
- [ ] 制作启动 U 盘
  ```bash
  sudo dd if=nixos-26.05.iso of=/dev/sdX bs=4M status=progress
  ```

### 3. 硬件信息收集
- [ ] CPU 型号（Intel/AMD）
  ```bash
  lscpu | grep "Model name"
  ```
- [ ] GPU 型号（Intel/NVIDIA/AMD）
  ```bash
  lspci | grep VGA
  ```
- [ ] 网络接口
  ```bash
  ip link show
  nmcli connection show
  ```
- [ ] 无线网卡驱动确认

---

## 安装阶段（NixOS Live 环境）

### 4. 启动 Live 环境
- [ ] 从 U 盘启动
- [ ] 连接网络
  ```bash
  # 有线网络自动连接
  # 无线网络
  sudo systemctl start wpa_supplicant
  wpa_cli
  > add_network
  > set_network 0 ssid "你的WiFi名"
  > set_network 0 psk "密码"
  > enable_network 0
  > quit
  ```
- [ ] 验证网络
  ```bash
  ping -c 3 nixos.org
  ```

### 5. 磁盘分区
根据你的需求选择方案：

#### 方案 A: 全新安装（清空所有数据）
```bash
# 列出磁盘
lsblk

# 分区（假设目标磁盘为 /dev/nvme0n1）
sudo parted /dev/nvme0n1 -- mklabel gpt
sudo parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 512MiB
sudo parted /dev/nvme0n1 -- set 1 esp on
sudo parted /dev/nvme0n1 -- mkpart primary 512MiB 100%

# 格式化
sudo mkfs.vfat -F 32 -n BOOT /dev/nvme0n1p1
sudo mkfs.btrfs -L nixos /dev/nvme0n1p2
```

#### 方案 B: 双系统（保留 Windows）
- [ ] 缩小 Windows 分区（从 Windows 磁盘管理）
- [ ] 创建 NixOS 分区
  ```bash
  # 在空闲空间创建分区
  sudo parted /dev/nvme0n1 -- mkpart primary 200GiB 100%
  sudo mkfs.btrfs -L nixos /dev/nvme0n1p4
  ```

### 6. Btrfs 子卷设置
```bash
# 挂载并创建子卷
sudo mount /dev/disk/by-label/nixos /mnt
sudo btrfs subvolume create /mnt/@
sudo btrfs subvolume create /mnt/@home
sudo btrfs subvolume create /mnt/@nix
sudo btrfs subvolume create /mnt/@log
sudo umount /mnt

# 重新挂载子卷
sudo mount -o subvol=@,compress=zstd,noatime /dev/disk/by-label/nixos /mnt
sudo mkdir -p /mnt/{home,nix,var/log,boot}
sudo mount -o subvol=@home,compress=zstd,noatime /dev/disk/by-label/nixos /mnt/home
sudo mount -o subvol=@nix,compress=zstd,noatime /dev/disk/by-label/nixos /mnt/nix
sudo mount -o subvol=@log,compress=zstd,noatime /dev/disk/by-label/nixos /mnt/var/log
sudo mount /dev/disk/by-label/BOOT /mnt/boot
```

### 7. 生成硬件配置
```bash
sudo nixos-generate-config --root /mnt
```

### 8. 复制项目配置
```bash
# 方法 A: 从 GitHub（如果已推送）
cd /mnt/etc/nixos
sudo rm configuration.nix hardware-configuration.nix
sudo git clone https://github.com/your-username/my-nixos.git .

# 方法 B: 从 U 盘
sudo cp -r /path/to/my_nixos/* /mnt/etc/nixos/

# 保留生成的 hardware-configuration.nix
sudo mv /mnt/etc/nixos/hardware-configuration.nix.backup /mnt/etc/nixos/hardware-configuration.nix
```

### 9. 修改配置以匹配硬件
编辑 `/mnt/etc/nixos/configuration.nix`:
- [ ] 取消注释 `imports = [ ./hardware-configuration.nix ];`
- [ ] 删除临时的 fileSystems 占位符
- [ ] 根据 CPU 类型调整（Intel/AMD）
  - `modules/system/boot.nix`: `boot.kernelModules`
  - `modules/system/hardware.nix`: `hardware.cpu.intel/amd.updateMicrocode`
- [ ] 根据 GPU 调整
  - Intel 集显: 保持现有配置
  - NVIDIA: 确认 `hardware.nvidia` 配置
  - AMD: 修改 `hardware.graphics.extraPackages`

### 10. 安装系统
```bash
sudo nixos-install --flake /mnt/etc/nixos#archlinux
```

- [ ] 安装过程无错误
- [ ] 设置 root 密码

### 11. 首次启动
```bash
sudo reboot
```

---

## 首次登录配置

### 12. 登录系统
- [ ] 使用初始密码 "changeme" 登录用户 alan
- [ ] 修改密码
  ```bash
  passwd
  ```

### 13. 应用 home-manager
```bash
home-manager switch --flake /etc/nixos#alan
```

### 14. 恢复个人数据
- [ ] 恢复 SSH 密钥
  ```bash
  cp -r /backup/ssh ~/.ssh
  chmod 700 ~/.ssh
  chmod 600 ~/.ssh/id_*
  ```
- [ ] 恢复 GPG 密钥
  ```bash
  gpg --import /backup/gpg-private.asc
  ```
- [ ] 恢复浏览器数据
- [ ] 恢复文档、图片等个人文件

### 15. 创建敏感信息配置
```bash
nano ~/.config/fish/secrets.fish
```

添加：
```fish
set -gx ANTHROPIC_AUTH_TOKEN "your-token"
set -gx ANTHROPIC_BASE_URL "https://api.deepseek.com/anthropic"
set -gx ANTHROPIC_MODEL deepseek-v4-pro
# ... 其他敏感配置
```

### 16. 验证关键功能
- [ ] 网络连接正常
- [ ] 桌面环境启动（Niri）
- [ ] 输入法工作（Fcitx5 + Rime）
- [ ] 终端正常（Alacritty/Kitty）
- [ ] 浏览器正常
- [ ] 声音输出正常
- [ ] 蓝牙连接正常（如有）

### 17. 系统更新
```bash
cd /etc/nixos
sudo nix flake update
sudo nixos-rebuild switch --flake .#archlinux
home-manager switch --flake .#alan
```

---

## 故障排查

### 启动失败
- 检查 GRUB 配置
- 使用 Live USB 修复：
  ```bash
  sudo mount /dev/disk/by-label/nixos /mnt
  sudo nixos-enter --root /mnt
  nixos-rebuild boot --flake /etc/nixos#archlinux
  ```

### 图形界面无法启动
- 检查显卡驱动配置
- 查看日志：
  ```bash
  journalctl -b | grep -i error
  systemctl status greetd
  ```

### 网络不可用
- 检查 NetworkManager 状态
  ```bash
  systemctl status NetworkManager
  nmcli device status
  ```

### Niri 无法启动
- 回退到 TTY (Ctrl+Alt+F2)
- 检查 Niri 日志
- 临时使用其他 compositor

---

## 回滚方案

### 如果安装失败想回到 Arch
1. 从 Arch Linux Live USB 启动
2. 重新挂载原分区
3. 重装 GRUB
4. 恢复备份数据

### NixOS 配置回滚
```bash
# 列出历史版本
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# 回滚到上一版本
sudo nixos-rebuild switch --rollback

# 回滚到指定版本
sudo nix-env --switch-generation 5 --profile /nix/var/nix/profiles/system
sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
```

---

## 完成标志
- [ ] 系统正常启动
- [ ] 桌面环境完整运行
- [ ] 所有硬件正常工作
- [ ] 个人数据已恢复
- [ ] 常用软件可用
- [ ] 开发环境配置完成
