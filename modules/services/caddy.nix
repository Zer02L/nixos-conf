# Caddy web server module
# Provides multi-site hosting, automatic HTTPS (Let's Encrypt / ZeroSSL),
# HTTP/2, HTTP/3 (QUIC), firewall integration, and On-Demand TLS for customer domains.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.caddy;
in
{
  options.custom.caddy = {
    enable = lib.mkEnableOption "Caddy web server with multi-site & firewall management";

    email = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "admin@example.ru";
      description = "Default email for Let's Encrypt / ZeroSSL certificate notifications.";
    };

    onDemandTLS = {
      enable = lib.mkEnableOption "Caddy On-Demand TLS for dynamically created customer domains";
      askEndpoint = lib.mkOption {
        type = lib.types.str;
        default = "http://127.0.0.1:8090/api/check-domain";
        description = "Internal endpoint called by Caddy to verify whether a certificate should be issued for a requested domain.";
      };
    };
  };

  config = lib.mkMerge [
    # Automatically enable services.caddy when custom.caddy is enabled
    (lib.mkIf cfg.enable {
      services.caddy.enable = true;
      services.caddy.email = lib.mkIf (cfg.email != null) cfg.email;
      services.caddy.globalConfig = lib.mkIf cfg.onDemandTLS.enable ''
        on_demand_tls {
          ask ${cfg.onDemandTLS.askEndpoint}
        }
      '';
    })

    # Whenever services.caddy is active (directly or via custom.caddy)
    (lib.mkIf config.services.caddy.enable {
      # Automatically open web ports for incoming traffic
      networking.firewall.allowedTCPPorts = [
        80
        443
      ];
      # HTTP/3 (QUIC) uses UDP 443 for fast mobile connections
      networking.firewall.allowedUDPPorts = [ 443 ];
    })
  ];
}
