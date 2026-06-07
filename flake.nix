{
  description = "NixOS unstable config with selective stable packages";

  inputs = {
    # Основной nixpkgs — unstable
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Отдельно фиксируем nixpkgs для PyCharm на ревизии, где `jetbrains.pycharm = 2025.3.3`.
    nixpkgs-pycharm.url = "github:NixOS/nixpkgs/5b2c2d84341b2afb5647081c1386a80d7a8d8605";

    # Stable nixpkgs — только для отдельных пакетов
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";

    # Home Manager (master для unstable)
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    kimi-code = {
      url = "github:MoonshotAI/kimi-code";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-pycharm,
      nixpkgs-stable,
      home-manager,
      kimi-code,
      ...
    }:
    let
      system = "x86_64-linux";

      # pkgs из unstable
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      # pkgs из stable
      pkgsStable = import nixpkgs-stable {
        inherit system;
        config.allowUnfree = true;
      };

      # pkgs из фиксированного nixpkgs только для PyCharm
      pkgsPycharm = import nixpkgs-pycharm {
        inherit system;
        config.allowUnfree = true;
      };

      # Overlay: берём amnezia-vpn из stable
      amneziaOverlay = final: prev: {
        amnezia-vpn = pkgsStable.amnezia-vpn;
      };

      # Overlay: держим PyCharm на отдельной зафиксированной ревизии nixpkgs,
      # чтобы он оставался на версии 2025.3.3 независимо от обновления остальной системы.
      pycharmOverlay = final: prev: {
        jetbrains = prev.jetbrains // {
          pycharm = pkgsPycharm.jetbrains.pycharm;
        };
      };
    in
    {
      nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
        inherit system;

        modules = [
          # Подключаем pkgs и overlay
          {
            nixpkgs.pkgs = pkgs;
            nixpkgs.overlays = [
              amneziaOverlay
              pycharmOverlay
            ];
          }

          ./hosts/desktop/configuration.nix

          # Home Manager
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.users.artem = { config, lib, pkgs, ... }: import ./home/user.nix {
              inherit config lib pkgs;
              kimi-code = kimi-code.packages.${system}.kimi-code;
            };
          }
        ];
      };
    };
}
