{ config, pkgs, ... }:

{
  # Starship 提示符
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    enableZshIntegration = true;
  };

  # 复制 starship 配置文件
  xdg.configFile."starship.toml".source = ../../config/starship.toml;
}
