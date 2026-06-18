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
    # 安全建议：禁用密码登录，使用密钥认证
    # 如需临时开启密码登录，请在使用后立即关闭
    settings.PasswordAuthentication = false;
    # 添加你的 SSH 公钥（替换为实际公钥）：
    # openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3... alan@nixos" ];
  };
}
