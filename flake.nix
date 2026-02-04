{
  description = "NixOS unstable config with selective stable packages";

  inputs = {
    # Основной nixpkgs — unstable
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Stable nixpkgs — только для отдельных пакетов
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";

    # Точечный pin для zed-editor 0.224.11
    nixpkgs-zed.url = "github:NixOS/nixpkgs/f20176b44b6edbe6e7d9340ae03d3c41e25ecc07";

    # Home Manager (master для unstable)
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-stable,
      nixpkgs-zed,
      home-manager,
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

      # pkgs из pinned commit для zed-editor
      pkgsZed = import nixpkgs-zed {
        inherit system;
        config.allowUnfree = true;
      };

      # Overlay: берём amnezia-vpn из stable
      amneziaOverlay = final: prev: {
        amnezia-vpn = pkgsStable.amnezia-vpn;
      };

      # Overlay: фиксируем zed-editor на 0.224.11
      zedOverlay = final: prev: {
        zed-editor = pkgsZed.zed-editor;
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
              zedOverlay
            ];
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
