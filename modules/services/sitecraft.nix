# SiteCraft Engine & Fleet service module
# Deploys:
# 1. Main SiteCraft Engine (builder & master panel)
# 2. Fleet of Binaries (isolated instances for client websites with individual SQLite DBs & Telegram bots)
# 3. Static Client Sites (exported SSG sites served directly by Caddy at 0 MB RAM)
# 4. Multi-domain Caddy reverse proxy with automatic SSL and SSE flush_interval -1
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.services.sitecraft;

  # Helper: standard Caddy reverse proxy config for SiteCraft instances
  mkProxyConfig =
    port: ''
      encode zstd gzip

      header {
        X-Content-Type-Options "nosniff"
        X-Frame-Options "SAMEORIGIN"
        Referrer-Policy "strict-origin-when-cross-origin"
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        -Server
      }

      reverse_proxy 127.0.0.1:${toString port} {
        # Critical for SSE Live-chat and Order Tracker
        flush_interval -1

        header_up Host {host}
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-For {remote_host}
        header_up X-Forwarded-Proto {scheme}

        transport http {
          dial_timeout 5s
          response_header_timeout 60s
        }
      }
    '';
in
{
  options.custom.services.sitecraft = {
    enable = lib.mkEnableOption "SiteCraft Engine & Fleet web services";

    # --- Master / Builder Instance ---
    domain = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "sitecreator.ru";
      description = "Primary domain for the SiteCreator master platform.";
    };

    wildcardDomain = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "*.sitecreator.ru";
      description = "Wildcard subdomain pattern to route customer sites created in SiteCraft.";
    };

    customDomains = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable On-Demand TLS for arbitrary customer domains.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8090;
      description = "Internal HTTP port for the master SiteCraft instance.";
    };

    workingDirectory = lib.mkOption {
      type = lib.types.str;
      default = "/home/zerg/Projects/web/SiteCreator";
      description = "Directory where the project source and assets are located.";
    };

    executable = lib.mkOption {
      type = lib.types.str;
      default = "/home/zerg/Projects/web/SiteCreator/bin/server";
      description = "Path to the compiled SiteCraft Go binary.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/sitecraft/pb_data";
      description = "Directory for persistent SQLite database and user uploads.";
    };

    envSecret = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "sitecraft_env";
      description = "SOPS secret name containing environment variables (e.g. TELEGRAM_BOT_TOKEN).";
    };

    telegramProxy = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "http://127.0.0.1:1080";
      description = "Optional proxy for outbound Telegram Bot API requests.";
    };

    # =========================================================
    # Fleet of Binaries: Изолированные динамические сайты клиентов
    # =========================================================
    fleet = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options = {
              domain = lib.mkOption {
                type = lib.types.str;
                example = "auto-express.ru";
                description = "Public domain for this client's website.";
              };

              port = lib.mkOption {
                type = lib.types.port;
                example = 8091;
                description = "Dedicated internal port for this isolated instance.";
              };

              dataDir = lib.mkOption {
                type = lib.types.str;
                default = "/var/lib/sitecraft/fleet/${name}/pb_data";
                description = "Isolated SQLite database and assets directory for this client.";
              };

              envSecret = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "SOPS secret for this client (e.g. client's Telegram token, payment keys).";
              };
            };
          }
        )
      );
      default = { };
      description = "Fleet of isolated client website instances (Fleet of Binaries architecture).";
    };

    # =========================================================
    # Static Client Sites: Статические сайты (0 MB RAM)
    # =========================================================
    staticSites = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options = {
              domain = lib.mkOption {
                type = lib.types.str;
                example = "stomatolog-landing.ru";
                description = "Public domain for the exported static site.";
              };

              root = lib.mkOption {
                type = lib.types.str;
                default = "/var/www/${name}";
                description = "Directory with exported static HTML/CSS files.";
              };
            };
          }
        )
      );
      default = { };
      description = "Static client sites (exported SSG) served directly by Caddy.";
    };
  };

  config = lib.mkIf cfg.enable {
    # ---------------------------------------------------------
    # 1. Systemd Services (Master & Fleet instances)
    # ---------------------------------------------------------
    systemd.services = lib.mkMerge [
      {
        sitecraft = {
          description = "SiteCraft Engine & Master PocketBase Service";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];

          environment = lib.mkMerge [
            {
              ENV = "production";
              PROD = "1";
            }
            (lib.mkIf (cfg.telegramProxy != null) {
              HTTP_PROXY = cfg.telegramProxy;
              HTTPS_PROXY = cfg.telegramProxy;
              ALL_PROXY = cfg.telegramProxy;
              no_proxy = "localhost,127.0.0.1";
            })
          ];

          serviceConfig = {
            Type = "simple";
            User = "zerg";
            Group = "users";
            WorkingDirectory = cfg.workingDirectory;
            ExecStart = "${cfg.executable} serve --http=127.0.0.1:${toString cfg.port} --dir=${cfg.dataDir}";
            Restart = "always";
            RestartSec = "5s";

            EnvironmentFile = lib.mkIf (cfg.envSecret != null) [
              config.sops.secrets.${cfg.envSecret}.path
            ];

            StateDirectory = "sitecraft";
            LimitNOFILE = 65535;

            ProtectSystem = "strict";
            ProtectHome = false;
            ReadWritePaths = [
              "/var/lib/sitecraft"
              cfg.workingDirectory
              "/tmp"
            ];
            PrivateTmp = true;
            NoNewPrivileges = true;
          };
        };
      }

      # Fleet Client Instances
      (lib.mapAttrs' (
        name: inst:
        lib.nameValuePair "sitecraft-fleet-${name}" {
          description = "SiteCraft Fleet Instance: ${name} (${inst.domain})";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];

          serviceConfig = {
            Type = "simple";
            User = "zerg";
            Group = "users";
            WorkingDirectory = cfg.workingDirectory;
            ExecStart = "${cfg.executable} serve --http=127.0.0.1:${toString inst.port} --dir=${inst.dataDir}";
            Restart = "always";
            RestartSec = "5s";

            EnvironmentFile = lib.mkIf (inst.envSecret != null) [
              config.sops.secrets.${inst.envSecret}.path
            ];

            StateDirectory = "sitecraft/fleet/${name}";
            LimitNOFILE = 65535;

            ProtectSystem = "strict";
            ProtectHome = false;
            ReadWritePaths = [
              "/var/lib/sitecraft/fleet/${name}"
              cfg.workingDirectory
              "/tmp"
            ];
            PrivateTmp = true;
            NoNewPrivileges = true;
          };
        }
      ) cfg.fleet)
    ];

    sops.secrets = lib.mkIf (cfg.envSecret != null) {
      ${cfg.envSecret} = {
        mode = "0400";
        owner = "zerg";
        restartUnits = [ "sitecraft.service" ];
      };
    };

    # ---------------------------------------------------------
    # 3. Caddy Multi-Site & Dynamic Client Domains
    # ---------------------------------------------------------
    custom.caddy = {
      enable = true;
      onDemandTLS = lib.mkIf cfg.customDomains {
        enable = true;
        askEndpoint = "http://127.0.0.1:${toString cfg.port}/api/check-domain";
      };
    };

    services.caddy = {
      enable = true;
      virtualHosts = lib.mkMerge [
        # Master platform domain
        (lib.mkIf (cfg.domain != null) {
          ${cfg.domain} = {
            extraConfig = mkProxyConfig cfg.port;
          };
        })

        # Wildcard subdomains (*.sitecreator.ru)
        (lib.mkIf (cfg.wildcardDomain != null) {
          ${cfg.wildcardDomain} = {
            extraConfig = mkProxyConfig cfg.port;
          };
        })

        # Dynamic client instances (Fleet)
        (lib.mapAttrs' (
          name: inst:
          lib.nameValuePair inst.domain {
            extraConfig = mkProxyConfig inst.port;
          }
        ) cfg.fleet)

        # Static client sites (SSG, 0 MB RAM)
        (lib.mapAttrs' (
          name: site:
          lib.nameValuePair site.domain {
            extraConfig = ''
              root * ${site.root}
              file_server
              encode zstd gzip
            '';
          }
        ) cfg.staticSites)

        # On-Demand TLS for arbitrary external domains
        (lib.mkIf cfg.customDomains {
          ":443" = {
            extraConfig = ''
              tls {
                on_demand
              }
              ${mkProxyConfig cfg.port}
            '';
          };
        })
      ];
    };
  };
}
