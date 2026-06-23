{
  config,
  lib,
  pkgs,
  ...
}:
{
  # KDE/Plasma устанавливает GIT_ASKPASS=ksshaskpass, который не работает
  # внутри neovim/lazy.nvim. Переопределяем на /usr/bin/false.
  home.sessionVariables.GIT_ASKPASS = "/usr/bin/false";

  home.stateVersion = "26.05";

  nixpkgs.config = {
    allowUnfree = true;
  };
  # KDE Plasma перезаписывает .gtkrc-2.0 после того, как home-manager
  # создаёт симлинк. При следующей активации HM видит обычный файл и
  # отказывается работать. Удаляем перед проверкой коллизий.
  home.activation.removeGtkrc2 = config.lib.dag.entryBefore ["checkLinkTargets"] ''
    rm -f /home/zerg/.gtkrc-2.0
  '';

  programs.home-manager.enable = true;
}
