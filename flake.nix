{
  description = "NixOS unstable config with selective stable packages";

  inputs = {
    # Основной nixpkgs — unstable
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Stable nixpkgs — только для отдельных пакетов
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";

    # Home Manager (master для unstable)
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-stable, home-manager, ... }:
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

    # Overlay: берём amnezia-vpn из stable
    amneziaOverlay = final: prev: {
      amnezia-vpn = pkgsStable.amnezia-vpn;
    };
  in {
    nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
      inherit system;

      modules = [
        # Подключаем pkgs и overlay
        {
          nixpkgs.pkgs = pkgs;
          nixpkgs.overlays = [ amneziaOverlay ];
        }

        ./hosts/desktop/configuration.nix

        # Home Manager
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.users.artem = import ./home/user.nix;
        }
      ];
    };
  };
}

