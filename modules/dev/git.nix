{ config, pkgs, ... }:

{
  # Git 配置
  programs.git = {
    enable = true;
    lfs.enable = true;
  };

  # 复制 git 配置文件
  xdg.configFile."git/config".source = ../../config/gitconfig;

  # GitHub CLI
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
    };
  };

  # lazygit TUI
  programs.lazygit = {
    enable = true;
  };
}
