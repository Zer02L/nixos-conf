# Server profile for Russian VPS (Selectel, Timeweb RU, Beget, RuVDS)
# - Prepared for Russian ISP DPI / TSPU censorship
# - Cloudflare Tunnel as recommended ingress (WireGuard/Tailscale may be throttled by TSPU)
# - Anti-poisoning DNS-over-TLS
# - Outbound proxy support for T3 Code to reach AI models
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../server.nix
    ../../modules/services/sitecraft.nix
  ];

  # Moscow timezone for Russian servers
  time.timeZone = lib.mkDefault "Europe/Moscow";

  # Secure DNS over TLS to prevent ISP poisoning
  services.resolved.settings.Resolve = {
    DNSOverTLS = "opportunistic";
    DNS = lib.mkDefault [
      "1.1.1.1#cloudflare-dns.com"
      "77.88.8.8#dns.yandex.ru"
    ];
  };
}
