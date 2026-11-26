# Workstation profile — full productivity suite (desktop, browser, containers, networking/VPN)
# Hardware drivers (e.g. Nvidia) and specialized mixins (gaming, AI) are layered on top per-host.
{ config
, lib
, pkgs
, ...
}:
{
  imports = [
    ./desktop.nix
    ./mixins/containers.nix
    ./mixins/vpn-suite.nix
    ../modules/programs/chromium.nix
    ../modules/networking/opensnitch.nix
  ];

  custom.opensnitch.enable = lib.mkDefault true;
}
