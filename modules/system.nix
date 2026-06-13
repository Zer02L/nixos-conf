{ config, lib, pkgs, ... }: {
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # FHS-совместимость для пребилдов (нужно Zed для расширений,
  # которые скачивают свои бинарники)
  programs.nix-ld.enable = true;

  system.stateVersion = "25.05";
}
