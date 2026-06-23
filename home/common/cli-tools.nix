{ config, lib, pkgs, ... }: {
  home.packages = with pkgs; [
    neovim
    bat
    eza
    lazygit
    fzf
    ripgrep-all
    btop
    fastfetch
    starship
    zoxide

    devenv
    nodejs_24

    antigravity-cli

    bitwarden-cli
    zapret2
    zrok
  ];
}
