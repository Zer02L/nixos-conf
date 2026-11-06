# Tailscale mesh networking module
# Provides secure peer-to-peer connectivity, optional subnet/exit-node routing,
# and integration with sops-nix for automatic authentication keys.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.tailscale;
in
{
  options.custom.tailscale = {
    enable = lib.mkEnableOption "Tailscale mesh networking";

    authKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to file containing Tailscale auth key.";
    };

    authKeySecret = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Name of the sops secret storing the Tailscale auth key (e.g. 'tailscale-auth-key').";
    };

    tags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "tag:server" ];
      description = "ACL tags to advertise for this node on your tailnet.";
    };

    useRoutingFeatures = lib.mkOption {
      type = lib.types.enum [
        "none"
        "client"
        "server"
        "both"
      ];
      default = "none";
      description = "Enable IP forwarding / loose reverse path filtering for subnet routers or exit nodes.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open UDP port for incoming Tailscale traffic on the firewall.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      openFirewall = cfg.openFirewall;
      authKeyFile =
        if cfg.authKeySecret != null then
          config.sops.secrets.${cfg.authKeySecret}.path
        else
          cfg.authKeyFile;
      extraUpFlags = lib.optionals (cfg.tags != [ ]) [
        "--advertise-tags=${lib.concatStringsSep "," cfg.tags}"
      ];
    };

    # Automatically declare sops secret when authKeySecret is specified
    sops.secrets = lib.mkIf (cfg.authKeySecret != null) {
      ${cfg.authKeySecret} = {
        restartUnits = [ "tailscaled.service" ];
      };
    };

    # Always trust tailscale virtual network interface
    networking.firewall.trustedInterfaces = [ "tailscale0" ];

    # Kernel IP forwarding & loose reverse-path filter for routing/exit-nodes
    boot.kernel.sysctl = lib.mkIf (cfg.useRoutingFeatures != "none") {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };
    networking.firewall.checkReversePath = lib.mkIf (cfg.useRoutingFeatures != "none") "loose";
  };
}
