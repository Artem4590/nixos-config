{ config, pkgs, ... }:

{
  home.username = "artem";
  home.homeDirectory = "/home/artem";
  home.stateVersion = "26.05";

  programs.fish.enable = true;

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.wezterm.enable = true;

  programs.git = {
    enable = true;
    extraConfig.core.editor = "vim";
  };

  programs.vim = {
    enable = true;
    extraConfig = ''
      syntax on
    '';
  };

  # Предпочитаемый терминал для приложений, которые читают переменную TERMINAL.
  home.sessionVariables.TERMINAL = "wezterm";

  home.packages = with pkgs; [
    neovim
    code-cursor
    telegram-desktop
    google-chrome
    zed-editor
    bat
    dua
    neofetch
    rust-analyzer
    rustup
  ];
}
