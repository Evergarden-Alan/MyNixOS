{
  description = "Alan's NixOS Configuration - Migrated from Arch Linux";

  inputs = {
    # NixOS 稳定版 26.05
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # home-manager 用户环境管理
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # DankMaterialShell 桌面环境
    # 注意：当前 stable 分支下载失败，稍后重试或使用主分支
    # dms = {
    #   url = "github:AvengeMedia/DankMaterialShell/stable";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    # NixOS 系统配置
    nixosConfigurations = {
      # 主机名：archlinux（可根据需要修改）
      archlinux = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          # 系统配置
          ./configuration.nix

          # 硬件配置（安装时生成）
          # ./hardware-configuration.nix

          # home-manager 作为 NixOS 模块集成
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.alan = import ./home.nix;
            home-manager.extraSpecialArgs = { inherit inputs; };
          }
        ];
      };
    };
  };
}
