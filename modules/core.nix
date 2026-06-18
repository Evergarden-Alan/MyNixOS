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

# 你的主力账号
  users.users."alan" = {
    isNormalUser = true;
    description = "alan";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.systemPackages = with pkgs; [
    vim
    git
    wget
  ];

# 全局启用 SSH 服务
  services.openssh = {
    enable = true;
    # 推荐的科学配置：通常建议开启密码登录或配置好 authorizedKeys，避免把自己锁在外面
    settings.PasswordAuthentication = true; 
  };
}
