{ config, pkgs, ... }:

{
  # 媒体应用
  home.packages = with pkgs; [
    # 视频播放
    mpv

    # 图片查看
    imv

    # 录屏与直播
    obs-studio
    wf-recorder

    # 音频处理
    pavucontrol
    easyeffects
  ];

  # MPV 配置
  programs.mpv = {
    enable = true;
  };
}
