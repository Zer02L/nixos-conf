# Server profile — headless, security-hardened, zero-open-port capable
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.server;
in
{
  imports = [
    ./core.nix
    ../modules/services/tailscale.nix
    ../modules/services/cloudflared.nix
    ../modules/services/t3-server.nix
    ../modules/services/caddy.nix
  ];

  options.custom.server = {
    access = lib.mkOption {
      type = lib.types.enum [
        "public"
        "tailscale"
      ];
      default = "public";
      description = ''
        Server access policy:
        - "public": Standard firewall with public SSH allowed on port 22.
        - "tailscale": Zero-open-port posture. Public SSH port is closed; access is restricted exclusively to Tailscale (tailscale0).
      '';
    };
  };

  config = lib.mkMerge [
    # ---------------------------------------------------------
    # Baseline server configuration
    # ---------------------------------------------------------
    {
      # Headless optimizations: strip manual pages, docs and desktop tooling
      documentation.enable = lib.mkDefault false;
      documentation.man.enable = lib.mkDefault false;
      documentation.nixos.enable = lib.mkDefault false;
      programs.appimage.enable = lib.mkForce false;

      # Do not expose internal workstation ports (e.g. 3773) on servers by default
      networking.firewall.allowedTCPPorts = lib.mkDefault [ ];

      # Reliable global DNS over TLS for servers
      services.resolved.settings.Resolve.DNS = lib.mkDefault [
        "1.1.1.1#cloudflare-dns.com"
        "8.8.8.8#dns.google"
      ];

      # SSH & remote administration
      services.openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = lib.mkDefault false;
          KbdInteractiveAuthentication = lib.mkDefault false;
          PermitRootLogin = lib.mkDefault "prohibit-password";
          X11Forwarding = false;
        };
        openFirewall = lib.mkDefault true;
      };

      # Brute-force protection
      services.fail2ban = {
        enable = lib.mkDefault true;
        maxretry = 5;
      };

      # Network tuning: BBR congestion control and fq queuing discipline
      boot.kernel.sysctl = {
        "net.core.default_qdisc" = "fq";
        "net.ipv4.tcp_congestion_control" = "bbr";
      };

      # Server secrets default to host SSH key (/etc/ssh/ssh_host_ed25519_key)
      sops.age.sshKeyPaths = lib.mkDefault [ "/etc/ssh/ssh_host_ed25519_key" ];

      # Allow user zerg to deploy build closures without sudo password
      nix.settings.trusted-users = [
        "root"
        "zerg"
      ];
    }

    # ---------------------------------------------------------
    # Zero-Open-Port Tailscale-only access mode
    # ---------------------------------------------------------
    (lib.mkIf (cfg.access == "tailscale") {
      assertions = [
        {
          assertion = config.custom.tailscale.enable || config.services.tailscale.enable;
          message = "custom.server.access = 'tailscale' requires custom.tailscale.enable = true or services.tailscale.enable = true.";
        }
      ];

      # Close SSH on public network interfaces
      services.openssh.openFirewall = lib.mkForce false;

      # Restrict inbound traffic strictly to Tailscale and loopback,
      # but keep public web ports (80/443 TCP, 443 UDP for HTTP/3) open if a web server is enabled.
      networking.firewall = {
        enable = lib.mkForce true;
        allowedTCPPorts = lib.mkForce (
          lib.optionals (config.services.caddy.enable || config.services.nginx.enable) [
            80
            443
          ]
        );
        allowedTCPPortRanges = lib.mkForce [ ];
        allowedUDPPorts = lib.mkForce (
          [
            (if config.services.tailscale.enable then config.services.tailscale.port else 41641)
          ]
          ++ lib.optionals (config.services.caddy.enable || config.services.nginx.enable) [ 443 ]
        );
        allowedUDPPortRanges = lib.mkForce [ ];
        trustedInterfaces = lib.mkForce [
          "lo"
          "tailscale0"
        ];
        allowPing = lib.mkDefault false;
      };
    })
  ];
}
