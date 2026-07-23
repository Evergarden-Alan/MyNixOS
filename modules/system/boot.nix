{ config, pkgs, ... }:

{
  # 引导加载器 - GRUB (UEFI)
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

  # 内核
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # 内核参数
  boot.kernelParams = [
    "quiet"
    "splash"
  ];

  # initrd 模块（根据硬件调整）
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "nvme"
    "usb_storage"
    "sd_mod"
  ];

  # 内核模块
  boot.kernelModules = [ "kvm-intel" ];  # Intel CPU
  # boot.kernelModules = [ "kvm-amd" ];  # AMD CPU 时改用这行

  # zram 压缩内存交换
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };
}
