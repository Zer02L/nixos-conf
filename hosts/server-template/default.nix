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
    # Server role: headless, hardened SSH, fail2ban, BBR, Tailscale & Cloudflared support
    ../../profiles/server.nix

    # Storage partition layout via disko (GPT + UEFI)
    ./disko.nix

    # Hardware detection (generate on the server via `nixos-generate-config --show-hardware-config > hardware-configuration.nix`)
    # ./hardware-configuration.nix
  ];

  networking.hostName = "server-template";

  # Bootloader for UEFI systems (disko ESP partition)
  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

  # Define SSH public keys for remote administration
  users.users.zerg.openssh.authorizedKeys.keys = [
    # "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5... your-public-key"
  ];

  # =========================================================
  # Network & Zero-Open-Port Security (Dreams of Code pattern)
  # =========================================================

  # 1. Zero Open Ports via Tailscale:
  # Once Tailscale is authenticated, set access = "tailscale" to close public port 22
  # and only allow SSH over your private tailnet.
  # custom.server.access = "tailscale"; # Options: "public" | "tailscale"
  # custom.tailscale = {
  #   enable = true;
  #   tags = [ "tag:server" ];
  #   authKeySecret = "tailscale-auth-key"; # Stored in secrets.yaml
  # };

  # 2. Expose local services via Cloudflare Tunnel (no open ports needed):
  # custom.cloudflared = {
  #   enable = true;
  #   tunnelId = "YOUR-TUNNEL-UUID";
  #   credentialsSecret = "cloudflared-tunnel.json"; # Stored in secrets.yaml
  #   ingress = {
  #     "api.example.com" = "http://127.0.0.1:8080";
  #   };
  # };

  # =========================================================
  # Native Services instead of Docker (Dreams of Code pattern)
  # =========================================================
  # Run services natively with systemd sandboxing and ephemeral users.
  #
  # systemd.services.example-app = {
  #   description = "Example Backend Service";
  #   wantedBy = [ "multi-user.target" ];
  #   after = [ "network.target" ];
  #   serviceConfig = {
  #     # ExecStart = "${pkgs.my-app}/bin/my-app";
  #     DynamicUser = true;             # Ephemeral unprivileged user
  #     StateDirectory = "example-app"; # Creates /var/lib/example-app owned by the service
  #     Restart = "on-failure";
  #
  #     # Load secrets safely into $CREDENTIALS_DIRECTORY without exposing in environment
  #     # LoadCredential = [
  #     #   "db_password:${config.sops.secrets.db_password.path}"
  #     # ];
  #   };
  # };
}
