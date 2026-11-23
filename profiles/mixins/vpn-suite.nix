# Network & VPN suite: AmneziaWG, Cloudflare WARP/Tunnel, FlClash, Happ, and dynamic VPN timezone
{ config
, lib
, pkgs
, ...
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
    ../../modules/services/zapret2.nix
  ];

  # Happ is the primary VPN client on this host. The other TUN-based clients
  # stay installed for manual use, but their privileged helper daemons must not
  # auto-start: several daemons competing for the default route and DNS is what
  # kills connectivity as soon as Happ connects. Start them on demand with
  # `sudo systemctl start <unit>` if you actually want to use them.
  systemd.services.cloudflare-warp.wantedBy = lib.mkForce [ ];
  systemd.services.flclash-helper.wantedBy = lib.mkForce [ ];
  # AmneziaWG's ExecStart is currently invalid (`amneziawg-go up <conf>`), so
  # the unit only prints usage and exits -- no reason to start it at boot.
  systemd.services.amneziawg.wantedBy = lib.mkForce [ ];

  services.custom-zapret.enable = lib.mkDefault true;

  services.vpnTimezone = {
    enable = lib.mkDefault true;
    defaultTimeZone = lib.mkDefault "Europe/Moscow";
  };
}
