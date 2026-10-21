{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
  cfg = config.programs.wfhelper;

  # Библиотека для точечного разрешения чтения памяти процесса Warframe (PR_SET_PTRACER)
  # без глобального отключения безопасности ядра (kernel.yama.ptrace_scope = 0).
  #
  # ЧТО НУЖНО СДЕЛАТЬ ДЛЯ РАБОТЫ:
  # 1. Собрать систему: sudo nixos-rebuild switch --flake .#zerg
  # 2. В Steam открыть Свойства Warframe -> вкладка «Общие» -> «Параметры запуска» (Launch Options).
  # 3. Добавить в параметры запуска:
  #      LD_PRELOAD="/run/current-system/sw/lib/allow_ptrace.so" %command%
  #    (Если уже используются gamemoderun / mangohud, указать LD_PRELOAD перед ними:
  #      LD_PRELOAD="/run/current-system/sw/lib/allow_ptrace.so" gamemoderun %command%)
  allowPtrace = pkgs.runCommandCC "allow-ptrace" { } ''
    mkdir -p $out/lib
    $CC -shared -fPIC -O2 -x c - -o $out/lib/allow_ptrace.so << 'EOF'
    #define _GNU_SOURCE
    #include <sys/prctl.h>
    __attribute__((constructor)) void init(void) {
        prctl(PR_SET_PTRACER, -1, 0, 0, 0);
    }
    EOF
  '';
in
{
  options.programs.wfhelper = {
    enable = mkEnableOption "WFHelper - Warframe companion desktop app";

    package = mkOption {
      type = types.package;
      default = pkgs.callPackage ./package.nix { };
      defaultText = "pkgs.callPackage ./package.nix { }";
      description = "The WFHelper package to use.";
    };

    allowPtracePackage = mkOption {
      type = types.package;
      default = allowPtrace;
      description = "Shared library preloaded into Warframe to grant ptrace access via PR_SET_PTRACER.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
      cfg.allowPtracePackage
    ];
  };
}
