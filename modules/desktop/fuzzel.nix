{ config, pkgs, ... }:

{
  # fuzzel 启动器
  programs.fuzzel = {
    enable = true;
    settings = {
      # 配置将从复制的文件中读取，或在此定义
    };
  };

  # 复制 fuzzel 配置文件
  xdg.configFile = {
    "fuzzel/fuzzel.ini".source = ../../config/fuzzel/fuzzel.ini;
    "fuzzel/colors.ini".source = ../../config/fuzzel/colors.ini;
  };
}
