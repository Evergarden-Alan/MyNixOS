{ config, pkgs, ... }:

{
  # 用户账户
  users.users.alan = {
    isNormalUser = true;
    description = "Alan";
    extraGroups = [
      "wheel"          # sudo 权限
      "networkmanager" # 网络管理
      "docker"         # Docker
      "libvirtd"       # 虚拟化
      "video"          # 视频设备
      "audio"          # 音频设备
      "input"          # 输入设备
    ];
    shell = pkgs.fish;
    # 初始密码（首次登录后修改）
    initialPassword = "changeme";
  };

  # 启用 fish 为系统 shell
  programs.fish.enable = true;

  # 启用 zsh（备用）
  programs.zsh.enable = true;

  # sudo 配置
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
  };
}
