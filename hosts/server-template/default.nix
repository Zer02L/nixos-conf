# Server Host Template
# Copy this directory to hosts/<your-server-name> when setting up a new server/VPS.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    # Server role: headless, hardened SSH, fail2ban, bbr, core system tools
    ../../profiles/server.nix

    # Storage partition layout via disko
    ./disko.nix

    # Hardware detection (generate on the server via `nixos-generate-config --show-hardware-config > hardware-configuration.nix`)
    # ./hardware-configuration.nix
  ];

  networking.hostName = "server-template";

  # Bootloader for UEFI systems
  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

  # Define SSH public keys for remote access
  users.users.zerg.openssh.authorizedKeys.keys = [
    # "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5... your-key"
  ];

  # Optional: Server-specific services
  # services.cloudflared.enable = true;
  # services.caddy.enable = true;
  # services.postgresql.enable = true;
  # virtualisation.podman.enable = true;
}
