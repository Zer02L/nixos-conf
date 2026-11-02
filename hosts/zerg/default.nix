{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ../../profiles/workstation.nix
    ./disko.nix
    ./hardware-configuration.nix
  ];

  # временно
  documentation.enable = false;
  documentation.man.enable = false;

  services.fstrim.enable = true;
  services.fstrim.interval = "weekly";

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "zerg";

  services.comfyui-podman = {
    enable = true;
    autoStart = false; # запуск по требованию через comfy start (или systemctl --user start comfyui)
  };
}
