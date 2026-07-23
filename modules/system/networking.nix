{ config, pkgs, ... }:

{
  # 主机名
  networking.hostName = "archlinux";

  # NetworkManager
  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd";  # 使用 iwd 作为 WiFi 后端
  };

  # iwd 配置
  networking.wireless.iwd = {
    enable = true;
    settings = {
      General = {
        EnableNetworkConfiguration = false;  # 由 NetworkManager 管理
      };
    };
  };

  # 防火墙
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ ];
    allowedUDPPorts = [ ];
  };

  # DNS 配置
  networking.nameservers = [ "223.5.5.5" "119.29.29.29" ];

  # Tailscale VPN
  services.tailscale.enable = true;

  # SSH 服务
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };
}
