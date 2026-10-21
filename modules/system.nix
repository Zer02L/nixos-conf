{
  config,
  lib,
  pkgs,
  ...
}:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelModules = [ "v4l2loopback" ];
  boot.extraModulePackages = [
    (config.boot.kernelPackages.v4l2loopback.overrideAttrs (old: {
      postInstall = (old.postInstall or "") + ''
        rm -f $out/lib/modules/*/modules.*
      '';
    }))
  ];

  # FHS-совместимость для пребилдов (нужно Zed для расширений,
  # которые скачивают свои бинарники)
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      # Используем библиотеку от GCC 16, чтобы избежать конфликтов с GLIBCXX_3.4.35
      gcc16Stdenv.cc.cc.lib
      zlib
      glib
      # Другие графические библиотеки при необходимости
    ];
  };

  systemd.tmpfiles.rules = [
    "d /mnt/steam 0755 zerg users -"
    # "d /mnt/downloads 0755 zerg users -"
    # "d /mnt/games 0755 zerg users -"
    # "d /mnt/db 0700 postgres postgres -"
  ];

  system.stateVersion = "26.05";
}
