{ config, lib, pkgs, ... }: {
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelModules = [ "v4l2loopback" ];
  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];

  # FHS-совместимость для пребилдов (нужно Zed для расширений,
  # которые скачивают свои бинарники)
  programs.nix-ld.enable = true;

  systemd.tmpfiles.rules = [
    "d /mnt/steam 0755 zerg users -"
    "d /mnt/downloads 0755 zerg users -"
    "d /mnt/games 0755 zerg users -"
    "d /mnt/db 0700 postgres postgres -"
  ];

  system.stateVersion = "26.05";
}
