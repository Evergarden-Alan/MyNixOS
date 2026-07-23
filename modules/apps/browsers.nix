{ config, pkgs, ... }:

{
  # 浏览器
  home.packages = with pkgs; [
    firefox
    chromium
    brave
  ];

  # Firefox 配置
  programs.firefox = {
    enable = true;
  };

  # Chromium 配置
  programs.chromium = {
    enable = true;
  };
}
