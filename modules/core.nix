# ~/.dotfiles/modules/core.nix
{ config, pkgs, ... }:

{
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

  # 主力账号 —— 用户名由 options.my.username 决定
  users.users.${config.my.username} = {
    isNormalUser = true;
    description = config.my.fullName;
    extraGroups = [
      "networkmanager"
      "wheel"
      "i2c"    # ddcutil 调外接屏亮度需要
      "video"
      "input"
    ];
  };

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # 自动清理旧代际 (每周一次，保留 7 天)
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  nix.optimise.automatic = true;

  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    curl
  ];

  # SSH 服务
  services.openssh = {
    enable = true;
    # 默认允许密码登录，避免无密钥时锁死。
    # 配好公钥后建议改为 false：
    #   settings.PasswordAuthentication = false;
    #   openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAA... ${config.my.username}@${config.networking.hostName}" ];
    settings.PasswordAuthentication = true;
  };
}
