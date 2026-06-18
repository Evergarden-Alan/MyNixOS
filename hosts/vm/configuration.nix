# ~/.dotfiles/hosts/vm/configuration.nix
{ config, pkgs, ... }:

{
  imports =
    [ ./hardware-configuration.nix ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;
  boot.loader.grub.fsIdentifier = "provided";

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # 不要修改这个版本号
  system.stateVersion = "26.05"; 
}
