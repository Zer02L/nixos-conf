{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    eza
    fzf
    btop
    fastfetch
    starship
    zoxide

    bitwarden-cli
    zapret
    zrok

    herdr

    nps
  ];
}
