{ config, pkgs, ... }:

{
  home.username = "artem";
  home.homeDirectory = "/home/artem";
  home.stateVersion = "25.05";

  programs.zsh.enable = true;
  programs.git.enable = true;

  home.packages = with pkgs; [
    neovim
    ripgrep
  ];
}

