{ config, pkgs, ... }:

{
  # 其他应用
  home.packages = with pkgs; [
    # 笔记与知识管理
    obsidian

    # 电子书管理
    calibre

    # GNOME 应用
    baobab           # 磁盘空间分析
    gnome-calendar   # 日历
    gnome-clocks     # 时钟
    gnome-font-viewer  # 字体查看
    seahorse         # 密钥管理

    # 系统工具
    mission-center   # 系统监控
    gparted         # 分区管理

    # 实用工具
    localsend       # 局域网文件传输
  ];
}
