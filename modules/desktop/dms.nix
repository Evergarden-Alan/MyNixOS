{ config, pkgs, ... }:

{
  # DankMaterialShell (DMS) 配置
  # DMS 通过 NixOS 模块提供 Niri 和相关工具

  # Wayland 辅助工具
  home.packages = with pkgs; [
    wl-clipboard
    slurp
    grim
    satty
    wf-recorder
    wlogout
  ];

  # 复制 Niri 配置文件
  xdg.configFile = {
    "niri/config.kdl".source = ../../config/niri/config.kdl;
    "niri/layout.kdl".source = ../../config/niri/layout.kdl;
    "niri/animations.kdl".source = ../../config/niri/animations.kdl;
    "niri/blur.kdl".source = ../../config/niri/blur.kdl;
    "niri/shorin-windowrules.kdl".source = ../../config/niri/shorin-windowrules.kdl;

    # DMS 特定配置
    "niri/dms" = {
      source = ../../config/niri/dms;
      recursive = true;
    };

    # Niri 脚本
    "niri/scripts" = {
      source = ../../config/niri/scripts;
      recursive = true;
    };
  };

  # Wayland 环境变量
  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
    SDL_VIDEODRIVER = "wayland";
    _JAVA_AWT_WM_NONREPARENTING = "1";
  };
}
