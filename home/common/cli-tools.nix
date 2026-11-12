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

    # Цветной вывод команд. Нужен бинарник `grc` — fish-плагин
    # pkgs.fishPlugins.grc (см. common/shell.nix) ставит только
    # обёртки-функции и сам grc не содержит.
    grc

    zapret
    zrok

    herdr

    nps

    unzip

    # T3 Code CLI & headless server
    t3-cli

    # Oh My Pi (omp) AI coding agent
    omp

  ];
}
