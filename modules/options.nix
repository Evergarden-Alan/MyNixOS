# ~/.dotfiles/modules/options.nix
# 全局可参数化选项 —— 改用户名/主机名只动 host 的 configuration.nix 一处
{ lib, ... }:

{
  options.my = {
    username = lib.mkOption {
      type = lib.types.str;
      default = "alan";
      description = "主用户名，同时用于系统用户与 home-manager";
    };

    fullName = lib.mkOption {
      type = lib.types.str;
      default = "Alan";
      description = "用户全名 (description)";
    };

    hostName = lib.mkOption {
      type = lib.types.str;
      default = "nixos";
      description = "主机名";
    };
  };
}
