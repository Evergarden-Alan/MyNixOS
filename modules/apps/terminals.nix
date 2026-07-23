{ config, pkgs, ... }:

{
  # 终端模拟器
  home.packages = with pkgs; [
    alacritty
    kitty
  ];

  # Alacritty 配置
  programs.alacritty = {
    enable = true;
  };

  # 复制 alacritty 配置文件
  xdg.configFile = {
    "alacritty/alacritty.toml".source = ../../config/alacritty/alacritty.toml;
    "alacritty/dank-theme.toml".source = ../../config/alacritty/dank-theme.toml;
  };

  # Kitty 配置
  programs.kitty = {
    enable = true;
    theme = "Tokyo Night";
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 12;
    };
    settings = {
      background_opacity = "0.95";
      confirm_os_window_close = 0;
    };
  };
}
