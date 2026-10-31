{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [

    aria2

    atuin
    eza
    fzf
    btop
    fastfetch
    starship
    zoxide

    zapret
    zrok

    herdr

    nps

    unzip

    # T3 Code CLI & headless server
    (pkgs.callPackage ./pkgs/t3-cli.nix { })

  ];
}
