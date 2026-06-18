# ~/.dotfiles/modules/desktop.nix
{ config, pkgs, ... }:

{
  # -----------------
  # 1. 基础图形与显示管理器
  # -----------------
  # 注意：GDM 目前依赖 xserver 模块，即使主要使用 Wayland（Niri）
  services.xserver.enable = true;
  # 使用 GDM 作为登录界面，同时支持 GNOME 和 Niri
  services.displayManager.gdm.enable = true;
  # 优先使用 Wayland 模式（对 Niri 必要，GNOME 也推荐）
  services.displayManager.gdm.wayland = true;
  services.xserver.xkb = {
    layout = "cn";
    variant = "";
  };

  # -----------------
  # 2. GNOME 桌面环境
  # -----------------
  services.desktopManager.gnome.enable = true;

  # -----------------
  # 3. Niri 平铺窗口管理器
  # -----------------
  programs.niri.enable = true; # 就这一行，NixOS 会搞定所有依赖和 GDM 的注册

  # 启用声音系统
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # 安装火狐
  programs.firefox.enable = true;
}
