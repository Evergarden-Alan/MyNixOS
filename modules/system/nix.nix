{ config, pkgs, ... }:

{
  # Nix 配置
  nix.settings = {
    # 启用 Flakes 和新命令
    experimental-features = [ "nix-command" "flakes" ];

    # 自动优化 store
    auto-optimise-store = true;

    # 信任用户
    trusted-users = [ "root" "alan" ];

    # 构建优化
    max-jobs = "auto";
    cores = 0;  # 使用所有核心

    # 二进制缓存
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  # 垃圾回收
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # 允许非自由软件
  nixpkgs.config.allowUnfree = true;
}
