# ~/.dotfiles/flake.nix
{
  description = "My awesome NixOS configuration";

  inputs = {
    # 系统的核心包源 (保持不变)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # 【新增】引入 Home Manager 的源代码
    home-manager = {
      url = "github:nix-community/home-manager";
      # 这一行极其重要：让 HM 和系统的 nixpkgs 保持版本一致
      inputs.nixpkgs.follows = "nixpkgs"; 
    };
  };

  # 【修改】在 outputs 的参数列表里加入 home-manager
  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations = {
      "vm" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/vm/configuration.nix
          ./modules/core.nix
          ./modules/desktop.nix

          # 【新增】将 Home Manager 作为 NixOS 的一个模块注入
          home-manager.nixosModules.home-manager
          {
            # 告诉 HM 使用系统级别的包管理器实例
            home-manager.useGlobalPkgs = true;
            # 将用户包安装到 /etc/profiles/per-user，而非污染用户家目录
            home-manager.useUserPackages = true;
            
            # 【新增】将刚才写好的配置蓝图，分配给你的用户 "alan"
            home-manager.users.alan = import ./home/home.nix;
          }
        ];
      };
    };
  };
}
