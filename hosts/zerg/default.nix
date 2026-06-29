{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.self.nixosModules.default
    ./disko.nix
    ./hardware-configuration.nix
  ];

  # временно
  documentation.enable = false;
  documentation.man.enable = false;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "zerg";
}
