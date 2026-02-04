{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Moscow";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ru_RU.UTF-8";
    LC_IDENTIFICATION = "ru_RU.UTF-8";
    LC_MEASUREMENT = "ru_RU.UTF-8";
    LC_MONETARY = "ru_RU.UTF-8";
    LC_NAME = "ru_RU.UTF-8";
    LC_NUMERIC = "ru_RU.UTF-8";
    LC_PAPER = "ru_RU.UTF-8";
    LC_TELEPHONE = "ru_RU.UTF-8";
    LC_TIME = "ru_RU.UTF-8";
  };

  # GUI
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  services.xserver.xkb = {
    layout = "us";
  };

  services.printing.enable = true;
  hardware.bluetooth.enable = true;

  # Audio
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Nix
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Docker
  virtualisation.docker.enable = true;

  # User
  users.users.artem = {
    isNormalUser = true;
    description = "artem";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    packages = with pkgs; [
      kdePackages.kate
    ];
  };

  # Amnezia VPN
  # ПАКЕТ НЕ УКАЗЫВАЕМ — overlay уже подменил его на stable
  programs.amnezia-vpn.enable = true;

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    git
    neofetch
    telegram-desktop
    google-chrome
    zed-editor
    bat
    dua

    gcc
    rust-analyzer
    rustup

    docker-compose

    pkg-config
    openssl
  ];

  # ⚠️ ВАЖНО: версия первого установленного NixOS
  system.stateVersion = "26.05";
}
