{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    # 桌面环境
    ./modules/desktop/dms.nix
    ./modules/desktop/niri.nix
    ./modules/desktop/fuzzel.nix
    ./modules/desktop/theme.nix

    # Shell 环境
    ./modules/shell/fish.nix
    ./modules/shell/zsh.nix
    ./modules/shell/starship.nix
    ./modules/shell/cli-tools.nix

    # 输入法
    ./modules/input/fcitx5.nix
    ./modules/input/rime.nix

    # 应用程序
    ./modules/apps/terminals.nix
    ./modules/apps/browsers.nix
    ./modules/apps/editors.nix
    ./modules/apps/file-managers.nix
    ./modules/apps/media.nix
    ./modules/apps/misc.nix

    # 开发环境
    ./modules/dev/git.nix
    ./modules/dev/languages.nix
  ];

  # 用户信息
  home = {
    username = "alan";
    homeDirectory = lib.mkForce "/home/alan";
    stateVersion = "26.05";

    # 用户级软件包（各模块中定义）
    packages = with pkgs; [
      # 基础工具
    ];
  };

  # 允许非自由软件
  nixpkgs.config.allowUnfree = true;

  # home-manager 自管理
  programs.home-manager.enable = true;
}
