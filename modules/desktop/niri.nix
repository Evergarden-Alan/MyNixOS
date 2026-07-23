{ config, pkgs, ... }:

{
  # Niri compositor 配置
  # 注意：Niri 配置文件为 KDL 格式，在 home.nix 中通过 xdg.configFile 管理

  # 安装 Niri 相关包
  home.packages = with pkgs; [
    # Niri compositor（如果 nixpkgs 中有）
    # niri

    # Wayland 工具
    wl-clipboard
    slurp
    grim
    satty
    wf-recorder
    wlogout
  ];

  # Niri 配置文件（直接复制 KDL 文件）
  xdg.configFile = {
    "niri/config.kdl".source = ../../config/niri/config.kdl;
    "niri/layout.kdl".source = ../../config/niri/layout.kdl;
    "niri/animations.kdl".source = ../../config/niri/animations.kdl;
  };

  # Wayland 环境变量
  home.sessionVariables = {
    # Wayland 原生支持
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
    SDL_VIDEODRIVER = "wayland";
    _JAVA_AWT_WM_NONREPARENTING = "1";
  };
}
