{ config, pkgs, ... }:

{
  # 编辑器和 IDE
  home.packages = with pkgs; [
    neovim
    vim
    vscode
  ];

  # Neovim 配置
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };
}
