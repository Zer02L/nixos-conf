# Core profile — common baseline for ALL machines (workstations, servers, laptops)
{ config, lib, pkgs, inputs, ... }:
{
  imports = [
    ../modules/system.nix
    ../modules/nix.nix
    ../modules/networking/base.nix
    ../modules/services/zram.nix
    ../modules/services/power.nix
    ../modules/services/secrets.nix
    ../modules/programs/admin-tools.nix
    ../modules/users/zerg.nix
  ];

  # Basic system maintenance
  services.fstrim.enable = lib.mkDefault true;
  services.fstrim.interval = lib.mkDefault "weekly";

  # Common useful CLI utilities across all hosts
  environment.systemPackages = with pkgs; [
    curl
    wget
    git
    htop
    btop
    ripgrep
    tmux
  ];
}
