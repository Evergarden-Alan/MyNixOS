{ config, pkgs, ... }:

{
  # Docker
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    storageDriver = "btrfs";  # 使用 btrfs 驱动
  };

  # Libvirt/QEMU 虚拟化
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      swtpm.enable = true;  # TPM 仿真
    };
  };
  programs.virt-manager.enable = true;

  # greetd 登录管理器
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "niri-session";
        user = "alan";
      };
      default_session = {
        command = "${pkgs.greetd}/bin/agreety --cmd ${pkgs.bash}/bin/bash";
        user = "greeter";
      };
    };
  };

  # XDG Desktop Portal
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];
    config.common.default = "*";
  };

  # GNOME Keyring
  services.gnome.gnome-keyring.enable = true;

  # D-Bus
  services.dbus.enable = true;

  # 时间同步
  services.timesyncd.enable = true;

  # Flatpak（可选）
  services.flatpak.enable = true;

  # Btrfs 自动清理
  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
    fileSystems = [ "/" ];
  };

  # Snapper 快照
  services.snapper = {
    snapshotInterval = "hourly";
    cleanupInterval = "1d";
    configs = {
      home = {
        SUBVOLUME = "/home";
        ALLOW_USERS = [ "alan" ];
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;
        TIMELINE_LIMIT_HOURLY = "10";
        TIMELINE_LIMIT_DAILY = "7";
        TIMELINE_LIMIT_WEEKLY = "4";
        TIMELINE_LIMIT_MONTHLY = "3";
      };
    };
  };
}
