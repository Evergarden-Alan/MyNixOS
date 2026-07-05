# ~/.dotfiles/hosts/vm/configuration.nix
# 本机特定配置 (vm)。共享配置在 modules/ 下。
{ ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # ---- 引导 (vm 用 BIOS grub) ----
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;
  boot.loader.grub.fsIdentifier = "provided";
  # UEFI 机器改用:
  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;

  # ---- 本机身份 ----
  networking.hostName = "vm";  # 必须等于 hosts/ 目录名，waybar/command-center 用 $(hostname) 定位 flake
  my.username = "alan";
  my.fullName = "Alan";

  # 首次安装时的 NixOS 版本，之后请勿修改
  system.stateVersion = "25.11";
}
