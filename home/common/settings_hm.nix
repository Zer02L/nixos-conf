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
  home.sessionPath = [ "$HOME/.local/share/pnpm/bin" ];

  home.stateVersion = "26.05";

  nixpkgs.config = {
    allowUnfree = true;
  };
  # Старый симлинк на /nix/store остался от предыдущей генерации, где
  # kwinrulesrc управлялся через home.file. Теперь plasma-manager пишет
  # его через activation-скрипт, который падает с EROFS, следуя за
  # симлинком в read-only store. Удаляем перед активацией.
  home.activation.removeKwinrulesrc = config.lib.dag.entryBefore ["checkLinkTargets"] ''
    rm -f /home/zerg/.config/kwinrulesrc
  '';

  # KDE Plasma перезаписывает .gtkrc-2.0 после того, как home-manager
  # создаёт симлинк. При следующей активации HM видит обычный файл и
  # отказывается работать. Удаляем перед проверкой коллизий.
  home.activation.removeGtkrc2 = config.lib.dag.entryBefore ["checkLinkTargets"] ''
    rm -f /home/zerg/.gtkrc-2.0
  '';

  programs.home-manager.enable = true;

  # systemd-таймер: раз в 4 дня оставлять только последние 10 генераций HM.
  # Удалённые GC-корни дают nix-collect-garbage очистить store.
  systemd.user.services.home-manager-expire = {
    Unit.Description = "HM keep last 10 generations";
    Service.Type = "oneshot";
    Service.ExecStart = "${pkgs.writeShellScript "hm-keep-10" ''
      ALL_IDS=$(${pkgs.home-manager}/bin/home-manager generations \
        | sed -n 's/.*: id \([0-9]\+\).*/\1/p')
      KEEP=10
      TOTAL=$(echo "$ALL_IDS" | wc -l)
      if [ "$TOTAL" -gt "$KEEP" ]; then
        REMOVE=$(echo "$ALL_IDS" | head -n -$KEEP | tr '\n' ' ')
        ${pkgs.home-manager}/bin/home-manager remove-generations $REMOVE
      fi
    ''}";
  };
  systemd.user.timers.home-manager-expire = {
    Timer.OnUnitActiveSec = "4d";
    Timer.Persistent = true;
    Install.WantedBy = [ "timers.target" ];
  };
}
