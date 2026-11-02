# Server profile — headless, security-hardened, no desktop/GUI components
{ config, lib, pkgs, ... }:
{
  imports = [
    ./core.nix
  ];

  # Headless optimizations
  documentation.enable = lib.mkDefault false;
  documentation.man.enable = lib.mkDefault false;
  documentation.nixos.enable = lib.mkDefault false;

  # SSH & remote administration
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = lib.mkDefault false;
      KbdInteractiveAuthentication = lib.mkDefault false;
      PermitRootLogin = lib.mkDefault "prohibit-password";
    };
    openFirewall = true;
  };

  # Brute-force protection
  services.fail2ban = {
    enable = lib.mkDefault true;
    maxretry = 5;
  };

  # Server network and performance tuning
  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
  };
}
