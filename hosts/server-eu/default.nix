# European VPS host configuration (e.g. Hetzner, Aeza EU, Timeweb EU)
# Native AI API access, Tailscale zero-open-port security, T3 Code headless server.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    # European server profile (UTC, global DoT DNS, headless, hardened)
    ../../profiles/server/eu.nix

    # Storage partition layout via disko
    ./disko.nix
  ];

  networking.hostName = "server-eu";

  # UEFI bootloader
  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

  # SSH public keys for remote access
  users.users.zerg.openssh.authorizedKeys.keys = [
    # "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5... your-key"
  ];

  # ---------------------------------------------------------
  # Tailscale & Zero Open Ports
  # ---------------------------------------------------------
  custom.tailscale = {
    enable = true;
    # authKeySecret = "tailscale-auth-key"; # in secrets.yaml
    tags = [ "tag:server" ];
  };

  # Lock down public SSH once Tailscale is tested
  # custom.server.access = "tailscale";

  # ---------------------------------------------------------
  # T3 Code Headless Server
  # ---------------------------------------------------------
  # Runs natively with direct access to Claude/OpenAI/Gemini without proxy.
  custom.services.t3-server = {
    enable = true;
    port = 3773;
    # No proxy required: direct EU connectivity
  };
}
