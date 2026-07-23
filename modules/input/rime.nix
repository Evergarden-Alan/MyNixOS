{ config, pkgs, ... }:

{
  # Rime 词库和配置
  home.packages = with pkgs; [
    # Rime 相关包（如果 nixpkgs 中有）
    # rime-data
  ];

  # Rime 配置文件（如果有自定义配置）
  # home.file.".local/share/fcitx5/rime" = {
  #   source = ../../config/rime;
  #   recursive = true;
  # };
}
