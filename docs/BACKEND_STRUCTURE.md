# Backend Structure (System Configuration)

## 概述

本文档描述 NixOS 系统级配置的组织方式。系统级配置通过 `configuration.nix` 及其模块化文件管理，涵盖硬件、内核、系统服务、安全等。

## 系统配置架构

```
/etc/nixos/ (或项目目录)
├── flake.nix                    # Flake 入口
├── flake.lock                   # 依赖锁定
├── configuration.nix            # 系统主配置
├── hardware-configuration.nix   # 硬件配置（自动生成）
└── modules/
    └── system/
        ├── boot.nix             # 引导配置
        ├── hardware.nix         # 硬件驱动
        ├── networking.nix       # 网络配置
        ├── users.nix            # 用户管理
        ├── services.nix         # 系统服务
        ├── security.nix         # 安全配置
        └── nix.nix              # Nix 配置
```

## flake.nix 结构

```nix
{
  description = "Alan's NixOS Configuration";

  inputs = {
    # NixOS 稳定版
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    
    # home-manager
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # DankMaterialShell
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, dms, ... }@inputs: {
    nixosConfigurations = {
      # 主机名：archlinux (或改为其他名字)
      archlinux = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
          ./hardware-configuration.nix
          
          # home-manager 作为 NixOS 模块
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.alan = import ./home.nix;
            home-manager.extraSpecialArgs = { inherit inputs; };
          }
        ];
      };
    };
  };
}
```

## configuration.nix 主配置

```nix
{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/system/boot.nix
    ./modules/system/hardware.nix
    ./modules/system/networking.nix
    ./modules/system/users.nix
    ./modules/system/services.nix
    ./modules/system/security.nix
    ./modules/system/nix.nix
  ];

  # 系统版本
  system.stateVersion = "26.05";

  # 时区与本地化
  time.timeZone = "Asia/Shanghai";
  i18n.defaultLocale = "zh_CN.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "zh_CN.UTF-8";
    LC_IDENTIFICATION = "zh_CN.UTF-8";
    LC_MEASUREMENT = "zh_CN.UTF-8";
    LC_MONETARY = "zh_CN.UTF-8";
    LC_NAME = "zh_CN.UTF-8";
    LC_NUMERIC = "zh_CN.UTF-8";
    LC_PAPER = "zh_CN.UTF-8";
    LC_TELEPHONE = "zh_CN.UTF-8";
    LC_TIME = "zh_CN.UTF-8";
  };

  # 控制台配置
  console = {
    font = "ter-v32n";
    packages = [ pkgs.terminus_font ];
    keyMap = "us";
  };

  # 允许非自由软件
  nixpkgs.config.allowUnfree = true;
}
```

## 模块详细配置

### 1. boot.nix - 引导配置

```nix
{ config, pkgs, ... }:

{
  # 引导加载器 - GRUB
  boot.loader = {
    grub = {
      enable = true;
      device = "nodev";  # UEFI 模式
      efiSupport = true;
      useOSProber = true;  # 检测其他系统（Windows）
      configurationLimit = 10;  # 保留最近10个配置
    };
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
  };

  # 或使用 systemd-boot（更简洁）
  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;

  # 内核参数
  boot.kernelPackages = pkgs.linuxPackages_latest;  # 最新内核
  boot.kernelParams = [
    "quiet"
    "splash"
  ];

  # initrd 模块
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "nvme"
    "usb_storage"
    "sd_mod"
  ];
  
  # 内核模块
  boot.kernelModules = [ "kvm-intel" ];  # Intel CPU
  # boot.kernelModules = [ "kvm-amd" ];  # AMD CPU

  # 额外模块
  boot.extraModulePackages = [ ];

  # zram 压缩内存交换
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };
}
```

### 2. hardware.nix - 硬件驱动

```nix
{ config, pkgs, ... }:

{
  # CPU 微码更新
  hardware.cpu.intel.updateMicrocode = true;
  # hardware.cpu.amd.updateMicrocode = true;  # AMD CPU

  # OpenGL/Vulkan 支持
  hardware.graphics = {
    enable = true;
    enable32Bit = true;  # 32位应用支持
    extraPackages = with pkgs; [
      intel-media-driver  # Intel VAAPI
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
      intel-compute-runtime  # OpenCL
    ];
  };

  # NVIDIA 驱动（如果有独显）
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = true;  # 使用开源内核模块
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # 蓝牙
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
      };
    };
  };

  # 声音系统 - PipeWire
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # 电源管理
  powerManagement = {
    enable = true;
    powertop.enable = true;
  };
  services.power-profiles-daemon.enable = true;
  
  # Intel 低功耗模式守护进程
  services.intel-lpmd.enable = true;
}
```

### 3. networking.nix - 网络配置

```nix
{ config, pkgs, ... }:

{
  # 主机名
  networking.hostName = "archlinux";

  # NetworkManager
  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd";  # 使用 iwd 作为 WiFi 后端
  };

  # iwd 配置
  networking.wireless.iwd = {
    enable = true;
    settings = {
      General = {
        EnableNetworkConfiguration = false;  # 由 NetworkManager 管理
      };
    };
  };

  # 防火墙
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ ];
    allowedUDPPorts = [ ];
  };

  # DNS 配置
  networking.nameservers = [ "223.5.5.5" "119.29.29.29" ];

  # hosts 文件
  networking.extraHosts = ''
    # 自定义 hosts
  '';

  # Tailscale VPN
  services.tailscale.enable = true;

  # SSH 服务
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };
}
```

### 4. users.nix - 用户管理

```nix
{ config, pkgs, ... }:

{
  # 用户账户
  users.users.alan = {
    isNormalUser = true;
    description = "Alan";
    extraGroups = [
      "wheel"        # sudo 权限
      "networkmanager"
      "docker"
      "libvirtd"
      "video"
      "audio"
      "input"
    ];
    shell = pkgs.fish;
    # 初始密码（首次登录后修改）
    initialPassword = "changeme";
  };

  # 启用 fish 为系统 shell
  programs.fish.enable = true;
  programs.zsh.enable = true;

  # sudo 配置
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
  };
}
```

### 5. services.nix - 系统服务

```nix
{ config, pkgs, ... }:

{
  # Docker
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    storageDriver = "btrfs";  # 使用 btrfs 驱动
  };

  # Libvirt/QEMU 虚拟化
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      ovmf.enable = true;  # UEFI 支持
      swtpm.enable = true;  # TPM 仿真
    };
  };
  programs.virt-manager.enable = true;

  # 文件系统服务
  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
    fileSystems = [ "/" ];
  };

  # Snapper 快照
  services.snapper = {
    configs = {
      home = {
        SUBVOLUME = "/home";
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;
        TIMELINE_LIMIT_HOURLY = 10;
        TIMELINE_LIMIT_DAILY = 7;
        TIMELINE_LIMIT_WEEKLY = 4;
        TIMELINE_LIMIT_MONTHLY = 3;
      };
    };
  };

  # greetd 登录管理器
  services.greetd = {
    enable = true;
    vt = 1;
    settings = {
      initial_session = {
        command = "niri-session";
        user = "alan";
      };
      default_session = {
        command = "${pkgs.greetd.greetd}/bin/agreety --cmd /bin/sh";
        user = "greeter";
      };
    };
  };

  # XDG Desktop Portal
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];
    config.common.default = "*";
  };

  # GNOME Keyring
  services.gnome.gnome-keyring.enable = true;

  # D-Bus
  services.dbus.enable = true;

  # 时间同步
  services.timesyncd.enable = true;

  # Flatpak（可选）
  services.flatpak.enable = true;

  # 打印服务（可选）
  # services.printing.enable = true;

  # 蓝牙音频
  services.blueman.enable = false;  # 使用 bluetui 代替
}
```

### 6. security.nix - 安全配置

```nix
{ config, pkgs, ... }:

{
  # Polkit 授权
  security.polkit.enable = true;

  # PAM 配置
  security.pam.services = {
    greetd.enableGnomeKeyring = true;
    login.enableGnomeKeyring = true;
  };

  # 实时调度权限（音频需要）
  security.rtkit.enable = true;

  # AppArmor（可选）
  # security.apparmor.enable = true;

  # 防火墙已在 networking.nix 配置
}
```

### 7. nix.nix - Nix 配置

```nix
{ config, pkgs, ... }:

{
  # 启用 Flakes 和新命令
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    trusted-users = [ "root" "alan" ];
  };

  # 垃圾回收
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # 构建优化
  nix.settings = {
    max-jobs = "auto";
    cores = 0;  # 使用所有核心
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  # 允许非自由软件
  nixpkgs.config.allowUnfree = true;
}
```

## hardware-configuration.nix

这个文件通常由 `nixos-generate-config` 自动生成，包含硬件特定配置：

```nix
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # 文件系统配置（根据实际分区调整）
  fileSystems."/" = {
    device = "/dev/nvme0n1p4";
    fsType = "btrfs";
    options = [ "subvol=@" "compress=zstd" "noatime" ];
  };

  fileSystems."/home" = {
    device = "/dev/nvme0n1p4";
    fsType = "btrfs";
    options = [ "subvol=@home" "compress=zstd" "noatime" ];
  };

  fileSystems."/boot" = {
    device = "/dev/nvme0n1p3";
    fsType = "vfat";
  };

  # Swap（使用 zram）
  swapDevices = [ ];

  # CPU 和硬件设置
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
```

## 系统软件包管理

### 系统级软件包（在 configuration.nix）

```nix
environment.systemPackages = with pkgs; [
  # 基础工具
  vim
  git
  wget
  curl
  htop
  
  # 网络工具
  networkmanagerapplet
  
  # 硬件工具
  pciutils
  usbutils
  
  # 文件系统工具
  btrfs-progs
  ntfs3g
];
```

### 用户级软件包（在 home.nix）

见 FRONTEND_GUIDELINES.md

## 服务管理

### 启用/禁用服务

```nix
# 启用服务
services.docker.enable = true;

# 配置服务
services.openssh = {
  enable = true;
  settings = {
    PasswordAuthentication = false;
  };
};
```

### 自定义 systemd 服务

```nix
systemd.services.my-service = {
  description = "My Custom Service";
  after = [ "network.target" ];
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
    Type = "simple";
    ExecStart = "${pkgs.bash}/bin/bash /path/to/script.sh";
    Restart = "on-failure";
  };
};
```

## 内核与驱动管理

### 内核版本选择

```nix
# 最新内核
boot.kernelPackages = pkgs.linuxPackages_latest;

# LTS 内核
boot.kernelPackages = pkgs.linuxPackages;

# 特定版本
boot.kernelPackages = pkgs.linuxPackages_6_6;
```

### 额外内核模块

```nix
boot.extraModulePackages = with config.boot.kernelPackages; [
  # 示例：第三方驱动
];
```

## 文件系统配置

### Btrfs 子卷结构

建议的子卷布局：
```
@           → /
@home       → /home
@snapshots  → /.snapshots
@var_log    → /var/log
@var_cache  → /var/cache
```

### 挂载选项优化

```nix
fileSystems."/" = {
  options = [
    "subvol=@"
    "compress=zstd:3"
    "noatime"
    "space_cache=v2"
  ];
};
```

## 网络高级配置

### Clash/V2Ray 代理（systemd 服务）

```nix
systemd.services.clash = {
  description = "Clash Daemon";
  after = [ "network.target" ];
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
    Type = "simple";
    ExecStart = "${pkgs.clash}/bin/clash -d /etc/clash";
    Restart = "on-failure";
  };
};
```

## 性能优化

### 构建加速

```nix
nix.settings = {
  max-jobs = 8;
  cores = 16;
  builders-use-substitutes = true;
};
```

### I/O 调度器

```nix
boot.kernelParams = [
  "elevator=bfq"  # BFQ 调度器适合桌面
];
```

## 安全加固（可选）

```nix
# 限制 sudo 日志
security.sudo.extraConfig = ''
  Defaults lecture = never
'';

# 禁用 root 登录
users.users.root.hashedPassword = "!";

# 防火墙严格模式
networking.firewall.allowPing = false;
```

## 配置部署流程

### 1. 生成基础配置
```bash
sudo nixos-generate-config --root /mnt
```

### 2. 修改配置
```bash
vim /mnt/etc/nixos/configuration.nix
```

### 3. 安装系统
```bash
sudo nixos-install
```

### 4. 重启进入 NixOS
```bash
reboot
```

### 5. 应用用户配置
```bash
home-manager switch --flake .#alan
```

## 配置验证与测试

### 构建测试（不应用）
```bash
sudo nixos-rebuild build --flake .#archlinux
```

### 虚拟机测试
```bash
nixos-rebuild build-vm --flake .#archlinux
./result/bin/run-archlinux-vm
```

### 应用配置
```bash
sudo nixos-rebuild switch --flake .#archlinux
```

### 回滚配置
```bash
sudo nixos-rebuild switch --rollback
```

## 注意事项

1. **硬件配置不要手动修改**
   - `hardware-configuration.nix` 由工具生成
   - 手动调整放在单独模块中

2. **模块化原则**
   - 功能单一，职责明确
   - 便于开关和调试

3. **版本锁定**
   - 使用 `flake.lock` 锁定依赖
   - 定期更新：`nix flake update`

4. **备份关键文件**
   - 配置目录使用 Git 管理
   - 定期推送到远程仓库
