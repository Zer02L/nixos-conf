# Hardware profile: Nvidia proprietary GPU drivers and graphics acceleration
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../../modules/hardware/nvidia.nix
  ];
}
