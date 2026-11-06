# Cloudflare Tunnel service module
# Exposes internal services securely to the internet without opening public inbound ports.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.cloudflared;
in
{
  options.custom.cloudflared = {
    enable = lib.mkEnableOption "Cloudflare Tunnel service";

    tunnelId = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "UUID of the locally-managed Cloudflare Tunnel.";
    };

    credentialsSecret = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "SOPS secret name for the tunnel credentials JSON. Defaults to 'cloudflared-<tunnelId>.json'.";
    };

    ingress = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        "app.example.com" = "http://127.0.0.1:8080";
      };
      description = "Mapping of hostnames to upstream local URLs.";
    };

    defaultIngress = lib.mkOption {
      type = lib.types.str;
      default = "http_status:404";
      description = "Fallback response for unmatched hostnames.";
    };
  };

  config = lib.mkMerge [
    # WireGuard interface configuration (disabled by default)
    {
      networking.wg-quick.interfaces.gif-wg0 = {
        configFile = "/etc/wireguard/clients/gif-wg0.conf";
        autostart = false;
      };
    }

    # Declarative Cloudflare tunnel integration
    (lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = cfg.tunnelId != "";
          message = "custom.cloudflared.tunnelId must be set before enabling Cloudflare Tunnel.";
        }
      ];

      sops.secrets =
        let
          secName =
            if cfg.credentialsSecret != null then
              cfg.credentialsSecret
            else
              "cloudflared-${cfg.tunnelId}.json";
        in
        {
          ${secName} = {
            restartUnits = [ "cloudflared-tunnel-${cfg.tunnelId}.service" ];
          };
        };

      services.cloudflared = {
        enable = true;
        tunnels.${cfg.tunnelId} = {
          credentialsFile =
            let
              secName =
                if cfg.credentialsSecret != null then
                  cfg.credentialsSecret
                else
                  "cloudflared-${cfg.tunnelId}.json";
            in
            config.sops.secrets.${secName}.path;
          default = cfg.defaultIngress;
          ingress = cfg.ingress;
        };
      };
    })
  ];
}
