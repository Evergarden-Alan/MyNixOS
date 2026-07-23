{ config, pkgs, ... }:

{
  # CLI 工具包
  home.packages = with pkgs; [
    # 文件操作增强
    bat         # cat 增强
    eza         # ls 增强
    fd          # find 增强
    ripgrep     # grep 增强

    # 搜索与导航
    fzf         # 模糊查找
    zoxide      # 目录跳转

    # 系统监控
    btop        # 系统监控
    fastfetch   # 系统信息
    htop        # 进程管理

    # 开发工具
    lazygit     # Git TUI
    gh          # GitHub CLI

    # 文件管理
    yazi        # 文件管理 TUI

    # 数据处理
    jq          # JSON 处理

    # 实用工具
    pv          # 进度查看
    lolcat      # 彩色输出
    sl          # 趣味命令
  ];

  # bat 配置
  programs.bat = {
    enable = true;
    config = {
      theme = "TwoDark";
      pager = "less -FR";
    };
  };

  # zoxide 配置
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
    enableZshIntegration = true;
  };

  # fzf 配置
  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
    enableZshIntegration = true;
  };
}
