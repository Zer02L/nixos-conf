{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    # System role
    ../../profiles/workstation.nix

    # Hardware drivers
    ../../profiles/hardware/nvidia.nix

    # Workload mixins
    ../../profiles/mixins/gaming.nix
    ../../profiles/mixins/ai.nix

    # Storage & hardware configuration
    ./disko.nix
    ./hardware-configuration.nix
  ];

  # временно
  documentation.enable = false;
  documentation.man.enable = false;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "zerg";

  services.comfyui-podman = {
    enable = true;
    autoStart = false; # запуск по требованию через comfy start (или systemctl --user start comfyui)
  };
}
