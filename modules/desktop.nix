# ~/.dotfiles/modules/desktop.nix
{ config, pkgs, ... }:

{
  # -----------------
  # 1. 基础图形与显示管理器
  # -----------------
  # GDM 依赖 xserver 模块，即使主要使用 Wayland (Niri)
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.displayManager.gdm.wayland = true;
  services.xserver.xkb = {
    layout = "cn";
    variant = "";
  };

  # -----------------
  # 2. GNOME 桌面环境 (备用/兼容)
  # -----------------
  services.desktopManager.gnome.enable = true;

  # -----------------
  # 3. Niri 平铺窗口管理器
  # -----------------
  programs.niri.enable = true;

  # -----------------
  # 4. 声音 (PipeWire)
  # -----------------
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # -----------------
    # ---- 网络 (显式启用，避免 GNOME 移除后 NetworkManager 消失) ----
  networking.networkmanager.enable = true;

  # ---- 5. 蓝牙 ----
  # -----------------
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # -----------------
  # 6. 图形加速
  # -----------------
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;

  # -----------------
  # 7. 电源管理 (waybar 有 power-profiles-daemon 模块)
  # -----------------
  services.power-profiles-daemon.enable = true;

  # -----------------
  # 8. XDG Desktop Portal (屏幕共享/录屏/文件选择)
  # -----------------
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    config.common.default = [ "gnome" "gtk" ];
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];
  };

  # -----------------
  # 9. 输入法 (Fcitx5) —— 自动设置 GTK_IM_MODULE / QT_IM_MODULE / XMODIFIERS
  # -----------------
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
  };

  # -----------------
  # 10. 字体
  # -----------------
  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    lxgw-wenkai
  ];

  # -----------------
  # 11. polkit (认证代理由 home-manager 的 systemd user service 启动)
  # -----------------
  security.polkit.enable = true;

  # -----------------
  # 12. Firefox
  # -----------------
  programs.firefox.enable = true;
}
