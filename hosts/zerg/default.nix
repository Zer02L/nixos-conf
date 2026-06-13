{ config, lib, pkgs, inputs, ... }: {
  imports = [
    ../../modules
    ./disko.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "zerg";
}
