{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.distrobox = {
    enable = true;
    settings = {
      container_manager = "podman";
    };
    containers = {
      ubuntu = {
        image = "ubuntu:26.04";
      };

      fedora = {
        image = "fedora:44";
      };
    };
    # enableSystemdUnit
  };
}
