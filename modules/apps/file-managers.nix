{ config, pkgs, ... }:

{
  # 文件管理器
  home.packages = with pkgs; [
    # GUI 文件管理器
    nautilus
    sushi  # 文件预览（gnome-sushi 已改名）
    file-roller  # 压缩包管理

    thunar
    thunar-volman
    thunar-archive-plugin

    # TUI 文件管理器
    yazi
  ];

  # Nautilus 扩展
  # nautilus-open-any-terminal 需要单独配置
}
