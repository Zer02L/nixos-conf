# Network & VPN suite: AmneziaWG, Cloudflare WARP/Tunnel, FlClash, Happ, and dynamic VPN timezone
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../../modules/services/amneziawg.nix
    ../../modules/services/cloudflare-warp.nix
    ../../modules/services/cloudflared.nix
    ../../modules/services/vpn-timezone.nix
    ../../modules/programs/flclash
    ../../modules/programs/nsjail.nix
    ../../modules/happ/happ-module.nix
  ];

  services.vpnTimezone = {
    enable = lib.mkDefault true;
    defaultTimeZone = lib.mkDefault "Europe/Moscow";
  };
}
