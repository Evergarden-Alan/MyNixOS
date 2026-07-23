# Arch Linux 到 NixOS 迁移指南

本指南将帮助你从 Arch Linux 完整迁移到 NixOS，保留所有配置和数据。

## 为什么选择 NixOS？

- **声明式配置**：整个系统配置可版本控制、可复现
- **原子升级和回滚**：更新失败？一条命令回滚
- **隔离开发环境**：项目特定的依赖不污染全局
- **多版本共存**：同时安装多个版本的软件包

## 迁移概览

```
Arch Linux (当前) → 备份数据 → 安装 NixOS → 应用配置 → 恢复数据
                      ↓              ↓             ↓            ↓
                   1-2小时        30-60分钟      10分钟      30分钟
```

**总耗时：约 2-4 小时**（取决于数据量和网速）

---

## 阶段 1：准备工作（Arch Linux）

### 1.1 运行备份脚本

```bash
cd ~/Projects/my_nixos
./scripts/backup-before-migration.sh
```

这将备份：
- 家目录重要文件
- SSH/GPG 密钥
- 系统配置
- 硬件信息

**备份位置**：`~/nixos-backup/YYYYMMDD_HHMMSS/`

### 1.2 手动导出数据

1. **浏览器**
   - Firefox：设置 → 账户 → 同步，或导出书签
   - Chrome：设置 → 密码 → 导出

2. **重要账号信息**
   - 记录所有需要的密码和 API tokens
   - 截图或记录双因素认证恢复码

3. **外部存储**
   ```bash
   # 复制备份到外部硬盘
   cp -r ~/nixos-backup /mnt/external-drive/
   ```

### 1.3 下载 NixOS ISO

访问 https://nixos.org/download.html

选择：
- **GNOME ISO**（推荐，图形界面方便操作）
- 或 **Minimal ISO**（命令行）

```bash
# 制作启动 U 盘（将 sdX 替换为实际设备）
sudo dd if=nixos-26.05-gnome-x86_64-linux.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

---

## 阶段 2：安装 NixOS

### 2.1 启动 Live 环境

1. 重启并从 U 盘启动
2. 选择 NixOS Live 环境
3. 等待进入桌面或命令行

### 2.2 连接网络

**有线网络**：自动连接

**无线网络**（命令行）：
```bash
sudo systemctl start wpa_supplicant
wpa_cli
> add_network
> set_network 0 ssid "WiFi名称"
> set_network 0 psk "密码"
> enable_network 0
> quit
```

**无线网络**（GNOME）：右上角网络图标直接连接

验证：
```bash
ping -c 3 nixos.org
```

### 2.3 磁盘分区

⚠️ **警告：以下操作会删除数据！确保已备份！**

#### 方案 A：全新安装（推荐）

```bash
# 查看磁盘
lsblk

# 假设目标磁盘为 /dev/nvme0n1
DISK=/dev/nvme0n1

# 创建 GPT 分区表
sudo parted $DISK -- mklabel gpt

# 创建 EFI 分区（512MB）
sudo parted $DISK -- mkpart ESP fat32 1MiB 512MiB
sudo parted $DISK -- set 1 esp on

# 创建根分区（剩余空间）
sudo parted $DISK -- mkpart primary 512MiB 100%

# 格式化
sudo mkfs.vfat -F 32 -n BOOT ${DISK}p1
sudo mkfs.btrfs -L nixos ${DISK}p2
```

#### 方案 B：与 Windows 双系统

1. 在 Windows 中缩小分区（磁盘管理 → 压缩卷）
2. 记录空闲空间起始位置（如 200GiB）
3. 创建 NixOS 分区：

```bash
DISK=/dev/nvme0n1
START=200GiB  # 根据实际情况调整

sudo parted $DISK -- mkpart primary $START 100%
sudo mkfs.btrfs -L nixos ${DISK}p4  # 分区号可能不同，用 lsblk 确认
```

### 2.4 创建 Btrfs 子卷

```bash
# 挂载根分区
sudo mount /dev/disk/by-label/nixos /mnt

# 创建子卷
sudo btrfs subvolume create /mnt/@
sudo btrfs subvolume create /mnt/@home
sudo btrfs subvolume create /mnt/@nix
sudo btrfs subvolume create /mnt/@log

# 卸载
sudo umount /mnt

# 重新挂载子卷
OPTS="compress=zstd,noatime"
sudo mount -o subvol=@,$OPTS /dev/disk/by-label/nixos /mnt
sudo mkdir -p /mnt/{home,nix,var/log,boot}
sudo mount -o subvol=@home,$OPTS /dev/disk/by-label/nixos /mnt/home
sudo mount -o subvol=@nix,$OPTS /dev/disk/by-label/nixos /mnt/nix
sudo mount -o subvol=@log,$OPTS /dev/disk/by-label/nixos /mnt/var/log
sudo mount /dev/disk/by-label/BOOT /mnt/boot
```

### 2.5 生成配置

```bash
sudo nixos-generate-config --root /mnt
```

这会创建：
- `/mnt/etc/nixos/configuration.nix`
- `/mnt/etc/nixos/hardware-configuration.nix`

### 2.6 应用项目配置

```bash
cd /mnt/etc/nixos

# 备份生成的 hardware-configuration.nix
sudo cp hardware-configuration.nix hardware-configuration.nix.generated

# 方法 A：从 GitHub（如果已推送）
sudo rm -rf *
sudo git clone https://github.com/your-username/my-nixos.git .

# 方法 B：从备份
sudo rm -rf *
sudo cp -r /path/to/backup/my_nixos/* .

# 恢复硬件配置
sudo cp hardware-configuration.nix.generated hardware-configuration.nix
```

### 2.7 修改配置

编辑 `configuration.nix`：

```bash
sudo nano /mnt/etc/nixos/configuration.nix
```

1. **取消注释硬件配置导入**：
   ```nix
   imports = [
     ./hardware-configuration.nix  # 取消注释这行
     ...
   ];
   ```

2. **删除临时占位符**（从 "临时根文件系统占位符" 到 "基础系统软件包" 之间的内容）

3. **调整 CPU 设置**（如果是 AMD）：

   编辑 `modules/system/boot.nix`:
   ```nix
   boot.kernelModules = [ "kvm-amd" ];  # Intel 改为 kvm-intel
   ```

   编辑 `modules/system/hardware.nix`:
   ```nix
   hardware.cpu.amd.updateMicrocode = true;  # Intel 改为 intel
   ```

4. **调整 GPU 设置**（如果没有 NVIDIA）：

   编辑 `modules/system/hardware.nix`，注释掉 NVIDIA 部分：
   ```nix
   # services.xserver.videoDrivers = [ "nvidia" ];
   # hardware.nvidia = { ... };
   ```

### 2.8 安装系统

```bash
sudo nixos-install --flake /mnt/etc/nixos#archlinux
```

过程中会：
- 下载所有软件包（可能需要 20-40 分钟）
- 构建系统配置
- 安装 GRUB 引导

最后会提示设置 root 密码（可选，因为已配置用户 alan）。

### 2.9 重启

```bash
sudo reboot
```

移除 U 盘，系统将启动到 GRUB。

---

## 阶段 3：首次配置

### 3.1 登录

- **用户名**：`alan`
- **初始密码**：`changeme`

登录后立即修改密码：
```bash
passwd
```

### 3.2 应用 home-manager

```bash
home-manager switch --flake /etc/nixos#alan
```

这会安装并配置：
- 桌面环境（Niri）
- Shell 环境（Fish）
- 所有用户级应用

### 3.3 恢复数据

```bash
# 挂载备份（外部硬盘或其他位置）
sudo mkdir -p /mnt/backup
sudo mount /dev/sdX1 /mnt/backup

# 运行恢复脚本
cd /etc/nixos
./scripts/restore-after-migration.sh /mnt/backup/nixos-backup/YYYYMMDD_HHMMSS
```

### 3.4 创建敏感信息配置

```bash
nano ~/.config/fish/secrets.fish
```

添加你的 API tokens 和其他敏感信息（参考备份中的配置）。

### 3.5 重启验证

```bash
reboot
```

重启后检查：
- ✓ 桌面环境正常启动
- ✓ 输入法可用
- ✓ 网络连接正常
- ✓ 声音输出正常

---

## 阶段 4：日常使用

### 系统更新

```bash
cd /etc/nixos

# 更新 flake 依赖
sudo nix flake update

# 应用系统更新
sudo nixos-rebuild switch --flake .#archlinux

# 应用用户配置更新
home-manager switch --flake .#alan
```

### 安装新软件

**临时使用**（不写入配置）：
```bash
nix-shell -p package-name
```

**永久安装**：

1. 编辑配置文件：
   - 系统级：`/etc/nixos/configuration.nix`
   - 用户级：`/etc/nixos/modules/apps/*.nix`

2. 添加包名到 `environment.systemPackages` 或 `home.packages`

3. 应用配置：
   ```bash
   sudo nixos-rebuild switch --flake /etc/nixos#archlinux
   # 或
   home-manager switch --flake /etc/nixos#alan
   ```

### 回滚

如果更新后出现问题：

```bash
# 列出历史版本
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# 回滚到上一版本
sudo nixos-rebuild switch --rollback

# 重启时也可以从 GRUB 选择旧版本
```

### 清理旧版本

```bash
# 删除 30 天前的旧版本
sudo nix-collect-garbage --delete-older-than 30d

# 优化存储空间
sudo nix-store --optimize
```

---

## 常见问题

### Q: 如何在 NixOS 中使用 AUR 包？

A: NixOS 没有 AUR。替代方案：
1. 在 nixpkgs 中搜索替代包
2. 使用 `buildFHSUserEnv` 创建 FHS 环境
3. 使用 Docker 容器
4. 自己打包（创建 derivation）

### Q: 某个软件无法运行，提示缺少库

A: NixOS 不遵循 FHS。解决方法：
```bash
# 临时修复
nix-shell -p package-name

# 或使用 steam-run（FHS 环境）
steam-run ./binary
```

### Q: 如何使用不在 nixpkgs 中的软件？

A: 使用 `home.file` 或 `environment.systemPackages` 手动安装：
```nix
home.file.".local/bin/my-app".source = /path/to/binary;
```

### Q: NixOS 占用空间很大

A: 这是正常的（保留多个版本）。定期清理：
```bash
sudo nix-collect-garbage -d
sudo nix-store --optimize
```

---

## 获取帮助

- **官方文档**：https://nixos.org/manual/
- **NixOS Wiki**：https://wiki.nixos.org/
- **社区**：
  - Discord: https://discord.gg/RbvHtGa
  - Discourse: https://discourse.nixos.org/
  - Reddit: r/NixOS

## 总结

🎉 恭喜！你已经成功迁移到 NixOS！

现在你拥有：
- ✅ 完全可复现的系统配置
- ✅ Git 版本控制
- ✅ 原子更新和回滚能力
- ✅ 声明式的软件管理

享受 NixOS 带来的便利吧！
