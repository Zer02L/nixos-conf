{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.services.custom-zapret;

  listsDir = ../../dotfiles/zapret/lists;

  readListFile =
    path:
    if builtins.pathExists path then
      builtins.filter (line: line != "" && !(lib.hasPrefix "#" line))
        (
          lib.splitString "\n" (builtins.readFile path)
        )
    else
      [ ];

  defaultExcludeDomains = lib.unique (
    [ "ru" ] ++ (readListFile (listsDir + "/list-exclude.txt"))
  );

  defaultIncludeDomains = lib.unique (
    [
      "youtube.com"
      "googlevideo.com"
      "ytimg.com"
      "ggpht.com"
      "gvt1.com"
      "youtube-nocookie.com"
      "youtu.be"
      "discord.com"
      "discordapp.com"
      "discord.gg"
      "discord.media"
      "discordapp.net"
      "discordcdn.com"
    ]
    ++ (readListFile (listsDir + "/list-google.txt"))
    ++ (readListFile (listsDir + "/list-general.txt"))
  );

  privateExcludePath = "/var/lib/zapret2/private-exclude.txt";
  privateIncludePath = "/var/lib/zapret2/private-include.txt";
in
{
  options.services.custom-zapret = {
    enable = lib.mkEnableOption "Custom Zapret2 DPI bypass service";

    autodetect = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable automatic DPI block detection and caching to /var/lib/zapret2/";
    };

    interfaces = lib.mkOption {
      type = lib.types.nullOr (lib.types.nonEmptyListOf lib.types.nonEmptyStr);
      default = null;
      example = [ "enp6s0" ];
      description = "Network interfaces to apply DPI bypass to. null means all non-local interfaces.";
    };

    excludeDomains = lib.mkOption {
      type = lib.types.listOf lib.types.nonEmptyStr;
      default = defaultExcludeDomains;
      description = "List of domain suffixes to exclude from DPI bypass.";
    };

    includeDomains = lib.mkOption {
      type = lib.types.listOf lib.types.nonEmptyStr;
      default = defaultIncludeDomains;
      description = "List of critical domains to always subject to DPI bypass immediately.";
    };

    tcpPorts = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [
        80
        443
        8443
        2053
        2083
        2087
        2096
      ];
      description = "TCP ports routed to Zapret2 at firewall level.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Systemd preStart hook to initialize private hostlists & SOPS sync
    systemd.services."nfqws2@default" = {
      preStart = ''
        mkdir -p /var/lib/zapret2
        touch ${privateExcludePath}
        touch ${privateIncludePath}

        # Sync local uncommitted files if present
        for f in /home/zerg/nixos-conf/dotfiles/zapret/lists/private-exclude.txt /home/zerg/.config/zapret2/private-exclude.txt; do
          if [ -f "$f" ]; then
            cat "$f" >> ${privateExcludePath}
          fi
        done

        for f in /home/zerg/nixos-conf/dotfiles/zapret/lists/private-include.txt /home/zerg/.config/zapret2/private-include.txt; do
          if [ -f "$f" ]; then
            cat "$f" >> ${privateIncludePath}
          fi
        done

        # Sync SOPS secret if decrypted
        if [ -f /run/secrets/zapret_private_hosts ]; then
          cat /run/secrets/zapret_private_hosts >> ${privateIncludePath}
        fi

        # Deduplicate
        sort -u ${privateExcludePath} -o ${privateExcludePath}
        sort -u ${privateIncludePath} -o ${privateIncludePath}
        chmod 644 ${privateExcludePath} ${privateIncludePath} 2>/dev/null || true
      '';
    };

    # Official NixOS Zapret2 service
    services.zapret2 = {
      enable = true;

      firewall = {
        configureAutomatically = true;
        interfaces = cfg.interfaces;
        maxPackets = 16;
        tcpPorts = cfg.tcpPorts;
        udpPorts = null; # Allow UDP (Discord voice, STUN, QUIC) to be inspected within first 16 packets
      };

      profiles = {
        # Profile 1: Plain HTTP (Port 80)
        http = {
          priority = 100;
          parameters = [
            "--filter-tcp=80"
            "--payload=http_req"
            "--hostlist-exclude=${privateExcludePath}"
            "--lua-desync=http_methodeol"
          ];
          hosts = {
            autodetect.enable = cfg.autodetect;
            exclude = cfg.excludeDomains;
          };
        };

        # Profile 2: Critical HTTPS (YouTube, Discord, etc.)
        https-critical = {
          priority = 200;
          hosts = {
            include = cfg.includeDomains;
            exclude = cfg.excludeDomains;
          };
          parameters = [
            "--filter-tcp=443,8443,2053,2083,2087,2096"
            "--payload=tls_client_hello"
            "--hostlist=${privateIncludePath}"
            "--hostlist-exclude=${privateExcludePath}"
            "--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:repeats=1"
            "--lua-desync=fakedsplit:pos=1,midsld:tcp_ts=-1000"
          ];
        };

        # Profile 3: General HTTPS with auto-detection for newly blocked hosts
        https-general = {
          priority = 300;
          hosts = {
            autodetect.enable = cfg.autodetect;
            exclude = cfg.excludeDomains;
          };
          parameters = [
            "--filter-tcp=443,8443,2053,2083,2087,2096"
            "--payload=tls_client_hello"
            "--hostlist-exclude=${privateExcludePath}"
            "--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:repeats=1"
            "--lua-desync=fakedsplit:pos=1,midsld:tcp_ts=-1000"
          ];
        };

        # Profile 4: Discord Voice / STUN
        discord-voice = {
          priority = 400;
          parameters = [
            "--filter-udp=*"
            "--payload=stun,discord_ip_discovery"
            "--lua-desync=fake:blob=0x00000000000000000000000000000000:repeats=2"
          ];
        };

        # Profile 5: QUIC (UDP 443)
        quic = {
          priority = 500;
          hosts = {
            include = [
              "youtube.com"
              "googlevideo.com"
            ];
          };
          parameters = [
            "--filter-udp=443"
            "--payload=quic_initial"
            "--lua-desync=fake:blob=fake_default_quic:repeats=2"
          ];
        };
      };
    };
  };
}
