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
  # 1. В Steam открыть Свойства Warframe -> вкладка «Общие» -> «Параметры запуска» (Launch Options).
  # 2. Добавить в параметры запуска:
  #      LD_PRELOAD="/home/zerg/.local/share/wfhelper/allow_ptrace.so" %command%
  #    (Если уже используются gamemoderun / mangohud / PROTON_LOG=1, указать LD_PRELOAD перед ними:
  #      LD_PRELOAD="/home/zerg/.local/share/wfhelper/allow_ptrace.so" PROTON_LOG=1 %command%)
  #    Также после `sudo nixos-rebuild switch --flake .#zerg` библиотека доступна в:
  #      /run/current-system/sw/lib/allow_ptrace.so
  allowPtrace = pkgs.runCommandCC "allow-ptrace" { } ''
    mkdir -p $out/lib
    $CC -shared -fPIC -O2 -nostdlib -x c - -o $out/lib/allow_ptrace.so << 'EOF'
    #define _GNU_SOURCE

    #ifndef PR_SET_PTRACER
    #define PR_SET_PTRACER 0x59616d61
    #endif
    #ifndef PR_SET_PTRACER_ANY
    #define PR_SET_PTRACER_ANY ((unsigned long)-1)
    #endif

    // Прямой системный вызов prctl (sys_prctl = 157 на x86_64) без libc
    static inline long sys_prctl(int option, unsigned long arg2) {
        long ret;
        register long r10 __asm__("r10") = 0;
        register long r8  __asm__("r8")  = 0;
        register long r9  __asm__("r9")  = 0;
        __asm__ volatile (
            "syscall"
            : "=a" (ret)
            : "a" (157), "D" (option), "S" (arg2), "d" (0), "r" (r10), "r" (r8), "r" (r9)
            : "rcx", "r11", "memory"
        );
        return ret;
    }

    __attribute__((constructor)) static void init(void) {
        sys_prctl(PR_SET_PTRACER, PR_SET_PTRACER_ANY);
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
