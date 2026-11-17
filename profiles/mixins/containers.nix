# Containers mixin: Podman container engine and toolset
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../../modules/services/podman.nix
  ];
}
