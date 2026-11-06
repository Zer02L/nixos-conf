# T3 Code Headless Server module
# Runs t3-cli in background daemon mode under user zerg.
# Supports optional outbound HTTP/SOCKS proxy for regions with AI geoblocking (e.g. Russia).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.services.t3-server;
in
{
  options.custom.services.t3-server = {
    enable = lib.mkEnableOption "T3 Code headless background server";

    port = lib.mkOption {
      type = lib.types.port;
      default = 3773;
      description = "Port for T3 Code web interface and remote pairing.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "Host IP address to bind to.";
    };

    proxy = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "http://127.0.0.1:1080";
      description = ''
        Outbound HTTP/HTTPS proxy URL for LLM API calls (Anthropic, OpenAI, Gemini).
        Essential when running on servers in Russia to bypass geoblocking.
      '';
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Open port on the public firewall.
        Keep FALSE when using Tailscale or Cloudflare Tunnel (recommended).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.t3-server = {
      description = "T3 Code Headless Daemon";
      after = [ "network.target" ];
      wants = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = lib.mkMerge [
        {
          HOME = "/home/zerg";
          PAGER = "cat";
        }
        (lib.mkIf (cfg.proxy != null) {
          HTTP_PROXY = cfg.proxy;
          HTTPS_PROXY = cfg.proxy;
          ALL_PROXY = cfg.proxy;
          no_proxy = "localhost,127.0.0.1,100.64.0.0/10";
        })
      ];

      serviceConfig = {
        Type = "simple";
        User = "zerg";
        Group = "users";
        WorkingDirectory = "/home/zerg";
        ExecStart = "${pkgs.t3-cli}/bin/t3 server --port ${toString cfg.port} --host ${cfg.host}";
        Restart = "on-failure";
        RestartSec = "5s";

        # Security sandbox
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = false; # Required to edit user code projects in /home/zerg
        ReadWritePaths = [
          "/home/zerg"
          "/tmp"
        ];
      };
    };

    # Firewall configuration
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];

    # Always allow access over Tailscale interface if Tailscale is enabled
    networking.firewall.interfaces."tailscale0".allowedTCPPorts = lib.mkIf config.services.tailscale.enable [
      cfg.port
    ];
  };
}
