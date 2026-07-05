# ~/.dotfiles/flake.nix
{
  description = "My awesome NixOS configuration";

  inputs = {
    # 系统核心包源
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      # 让 HM 与系统共用同一份 nixpkgs，避免重复下载
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Matugen —— Material You 配色生成器 (仓库自带 flake)
    matugen = {
      url = "github:InioX/matugen";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, matugen, ... }@inputs: let
    lib = nixpkgs.lib;
    # 自动发现 hosts/ 下的所有主机目录 (排除 _template 模板)
    hostNames = builtins.filter (n: n != "_template")
      (builtins.attrNames (builtins.readDir ./hosts));

    mkHost = hostName: lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs hostName; };
      modules = [
        ./modules/options.nix
        ./hosts/${hostName}/configuration.nix
        ./modules/core.nix
        ./modules/desktop.nix
        home-manager.nixosModules.home-manager
        ({
          config,
          ...
        }: {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          # 把 nixos 的用户名与 flake inputs 传给 home-manager
          home-manager.extraSpecialArgs = {
            inherit inputs;
            myUsername = config.my.username;
          };
          # 用户名由 options.my.username 决定，改用户名只动 host 的 configuration.nix
          home-manager.users.${config.my.username} = import ./home/home.nix;
        })
      ];
    };
  in {
    nixosConfigurations = lib.genAttrs hostNames mkHost;
  };
}
