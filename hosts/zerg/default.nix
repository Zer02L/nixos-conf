{ config, lib, pkgs, inputs, ... }: {
  imports = [
    inputs.self.nixosModules.default
    ./disko.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "zerg";
}
