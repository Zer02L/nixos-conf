# Workstation profile — full desktop suite with gaming, containers, networking tools
{ config, lib, pkgs, ... }:
{
  imports = [
    ./desktop.nix

    # Hardware (GPU)
    ../modules/hardware/nvidia.nix

    # Programs & Gaming
    ../modules/programs/steam.nix
    ../modules/programs/chromium.nix
    ../modules/programs/nsjail.nix
    ../modules/programs/flclash
    ../modules/programs/wfhelper
    ../modules/happ/happ-module.nix

    # Services
    ../modules/services/podman.nix
    ../modules/services/postgresql.nix
    ../modules/services/comfyui.nix
    ../modules/services/cloudflared.nix
    ../modules/services/cloudflare-warp.nix
    ../modules/services/amneziawg.nix
  ];
}
