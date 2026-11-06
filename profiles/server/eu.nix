# Server profile for European / unrestricted VPS (Hetzner, Aeza EU, Timeweb EU, OVH)
# - Native direct connectivity to AI APIs (Anthropic, OpenAI, Gemini) without proxies
# - Tailscale mesh networking as primary access
# - Global DNS over TLS (Cloudflare, Google)
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../server.nix
  ];

  # Default timezone for EU infrastructure
  time.timeZone = lib.mkDefault "UTC";

  # Global DNS over TLS
  services.resolved.settings.Resolve.DNS = lib.mkDefault [
    "1.1.1.1#cloudflare-dns.com"
    "8.8.8.8#dns.google"
  ];
}
