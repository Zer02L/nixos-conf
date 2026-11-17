# Gaming mixin: Steam, controllers, proton dependencies, and gaming helpers
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../../modules/programs/steam.nix
    ../../modules/programs/wfhelper
  ];
}
