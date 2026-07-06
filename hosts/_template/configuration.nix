# ~/.dotfiles/hosts/_template/configuration.nix
# ============ 新主机模板 ============
# 用法:
#   1. 复制本目录: cp -r hosts/_template hosts/<你的主机名>
#   2. 把装机时 nixos-generate-config 生成的 hardware-configuration.nix
#      覆盖 hosts/<你的主机名>/hardware-configuration.nix
#   3. 修改下方主机名/用户名/引导方式
#   4. sudo nixos-rebuild switch --flake .#<你的主机名>
# flake.nix 会自动发现 hosts/ 下的新主机，无需手动注册。
{ ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # ---- 引导 (双系统 Win11+NixOS: rEFInd + minimal 主题) ----
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.refind = {
    enable = true;
    extraConfig = ''
      # 引导主题 (先跑 config/scripts/install-refind-theme.sh 把主题装到 ESP)
      include themes/rEFInd-minimal/theme.conf
      # 噪音剔除: 隐藏 Windows 恢复 / 诊断工具 / OEM 残留
      dont_scan_dirs EFI/Recovery,EFI/Tools,EFI/Dell,EFI/HP
      dont_scan_files fbx64.efi,mmx64.efi
    '';
  };
  # 备选: 单系统纯 UEFI 用 systemd-boot
  # boot.loader.systemd-boot.enable = true;
  # BIOS 机器改用 grub:
  # boot.loader.grub.enable = true;
  # boot.loader.grub.device = "/dev/sda";
  # boot.loader.grub.fsIdentifier = "provided";

  # ---- 本机身份 ----
  networking.hostName = "改我";      # 必须等于 hosts/ 目录名，waybar/command-center 用 $(hostname) 定位 flake
  my.username = "alan";              # 改用户名只需改这一处
  my.fullName = "Alan";

  # 首次安装时的 NixOS 版本，之后请勿修改
  system.stateVersion = "25.11";

  # ---- 按需启用硬件模块 (取消 imports 注释) ----
  # imports = [ ./hardware-configuration.nix ../../../modules/hardware/nvidia.nix ];
}
