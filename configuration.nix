{ config, pkgs, inputs, ... }:

{
  imports = [
    # 硬件配置（安装时由 nixos-generate-config 生成）
    # ./hardware-configuration.nix

    # 系统模块
    ./modules/system/boot.nix
    ./modules/system/hardware.nix
    ./modules/system/networking.nix
    ./modules/system/users.nix
    ./modules/system/services.nix
    ./modules/system/security.nix
    ./modules/system/nix.nix
  ];

  # 系统版本（不要修改）
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

  # 基础系统软件包
  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    curl
    htop
  ];
}
