{ config, pkgs, ... }:

{
  # 字体配置
  fonts = {
    packages = with pkgs; [
      # 基础字体
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-emoji

      # 编程字体
      (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })

      # 系统字体
      liberation_ttf
    ];

    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = [ "Noto Serif CJK SC" "Noto Serif" ];
        sansSerif = [ "Noto Sans CJK SC" "Noto Sans" ];
        monospace = [ "JetBrainsMono Nerd Font" "Noto Sans Mono CJK SC" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
}
