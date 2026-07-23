{ config, pkgs, ... }:

{
  # Polkit 授权
  security.polkit.enable = true;

  # PAM 配置
  security.pam.services = {
    greetd.enableGnomeKeyring = true;
    login.enableGnomeKeyring = true;
  };

  # 实时调度权限（音频需要）
  security.rtkit.enable = true;
}
