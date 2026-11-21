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

  defaultNofakeDomains = lib.unique (
    [
      "fatsharkgames.se"
      "auth.fatsharkgames.se"
      "darktide-backend.fatsharkgames.se"
      "mission-board.fatsharkgames.se"
      "hub.fatsharkgames.se"
      "atoma.cloud"
      "bsp-auth-prod.atoma.cloud"
      "bsp-td-prod.atoma.cloud"
      "bsp-im-prod.atoma.cloud"
      "bsp-cdn-prod.atoma.cloud"
      "playdarktide.com"
      "amazonaws.com"
      "cloudfront.net"
    ]
    ++ (readListFile (listsDir + "/list-nofake.txt"))
  );

  allIncludeDomains = lib.unique (
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

  # Exclude nofake domains (AWS, CloudFront, Darktide/Atoma) from fake-based desync profile
  defaultIncludeDomains = lib.filter (d: !(builtins.elem d defaultNofakeDomains)) allIncludeDomains;

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

    nofakeDomains = lib.mkOption {
      type = lib.types.listOf lib.types.nonEmptyStr;
      default = defaultNofakeDomains;
      description = "List of critical domains to subject to DPI bypass using soft desync (split) without fake packets (e.g. AWS, CloudFront, Darktide/Atoma).";
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
    # Expose package Lua scripts in /etc/zapret2/lua for stable, accessible system path
    environment.etc."zapret2/lua".source = "${config.services.zapret2.package}/share/zapret2/lua";

    # Systemd preStart hook to initialize dotfiles sync & validation
    systemd.services."nfqws2@default" = {
      preStart = ''
        # Remove legacy symlink to /var/lib/private/zapret2 if leftover from DynamicUser
        if [ -L /var/lib/zapret2 ]; then
          rm -f /var/lib/zapret2
        fi

        mkdir -p /var/lib/zapret2/lists
        mkdir -p /var/lib/zapret2/lua
        chmod 755 /var/lib/zapret2 /var/lib/zapret2/lists /var/lib/zapret2/lua

        # Link package Lua scripts
        ln -sfn ${config.services.zapret2.package}/share/zapret2/lua/* /var/lib/zapret2/lua/

        # Ensure all expected list files exist
        touch /var/lib/zapret2/lists/list-general.txt
        touch /var/lib/zapret2/lists/list-google.txt
        touch /var/lib/zapret2/lists/list-nofake.txt
        touch /var/lib/zapret2/lists/list-exclude.txt
        touch /var/lib/zapret2/lists/private-exclude.txt
        touch /var/lib/zapret2/lists/private-include.txt
        touch /var/lib/zapret2/http-hosts.txt
        touch /var/lib/zapret2/https-general-hosts.txt

        # Sync dotfiles/zapret/lists/ to /var/lib/zapret2/lists/ (with fallback to store)
        if [ -d /home/zerg/nixos-conf/dotfiles/zapret/lists ]; then
          cp -rf /home/zerg/nixos-conf/dotfiles/zapret/lists/* /var/lib/zapret2/lists/
        elif [ -d ${listsDir} ]; then
          cp -rf ${listsDir}/* /var/lib/zapret2/lists/
        fi

        # Sync local uncommitted private files if present
        for f in /home/zerg/nixos-conf/dotfiles/zapret/lists/private-exclude.txt /home/zerg/.config/zapret2/private-exclude.txt; do
          if [ -f "$f" ]; then
            cat "$f" >> /var/lib/zapret2/lists/private-exclude.txt
          fi
        done

        for f in /home/zerg/nixos-conf/dotfiles/zapret/lists/private-include.txt /home/zerg/.config/zapret2/private-include.txt; do
          if [ -f "$f" ]; then
            cat "$f" >> /var/lib/zapret2/lists/private-include.txt
          fi
        done

        # Sync SOPS secret if decrypted
        if [ -f /run/secrets/zapret_private_hosts ]; then
          cat /run/secrets/zapret_private_hosts >> /var/lib/zapret2/lists/private-include.txt
        fi
        if [ -f /run/secrets/zapret_private_exclude ]; then
          cat /run/secrets/zapret_private_exclude >> /var/lib/zapret2/lists/private-exclude.txt
        fi

        # Deduplicate
        sort -u /var/lib/zapret2/lists/private-exclude.txt -o /var/lib/zapret2/lists/private-exclude.txt
        sort -u /var/lib/zapret2/lists/private-include.txt -o /var/lib/zapret2/lists/private-include.txt

        # Prepare and validate zapret2.conf from dotfiles (with fallback to store and last-good)
        CONF_SRC=""
        if [ -f /home/zerg/nixos-conf/dotfiles/zapret/zapret2.conf ]; then
          CONF_SRC="/home/zerg/nixos-conf/dotfiles/zapret/zapret2.conf"
        elif [ -f ${../../dotfiles/zapret/zapret2.conf} ]; then
          CONF_SRC="${../../dotfiles/zapret/zapret2.conf}"
        fi

        if [ -n "$CONF_SRC" ]; then
          TMP_CANDIDATE=$(mktemp)
          TMP_TEST=$(mktemp)
          grep -v '^[[:space:]]*#' "$CONF_SRC" | grep -v '^[[:space:]]*$' > "$TMP_CANDIDATE"

          echo "--dry-run" > "$TMP_TEST"
          cat "$TMP_CANDIDATE" >> "$TMP_TEST"

          VALIDATION_OUT=$(${config.services.zapret2.package}/bin/nfqws2 "@$TMP_TEST" 2>&1)
          if [ $? -eq 0 ]; then
            cp -f "$TMP_CANDIDATE" /var/lib/zapret2/zapret2.conf
            cp -f "$TMP_CANDIDATE" /var/lib/zapret2/zapret2.conf.last-good
          else
            echo "WARNING: $CONF_SRC has invalid syntax! Validation output:" >&2
            echo "$VALIDATION_OUT" >&2
            if [ -f /var/lib/zapret2/zapret2.conf.last-good ]; then
              echo "Keeping last known good configuration." >&2
              cp -f /var/lib/zapret2/zapret2.conf.last-good /var/lib/zapret2/zapret2.conf
            else
              echo "No last-good configuration found. Deploying candidate anyway to attempt startup." >&2
              cp -f "$TMP_CANDIDATE" /var/lib/zapret2/zapret2.conf
            fi
          fi
          rm -f "$TMP_CANDIDATE" "$TMP_TEST"
        fi

        # Ensure readable permissions for user CLI tools (zapret-test, zapret-tool)
        chmod -R 644 /var/lib/zapret2/lists/* /var/lib/zapret2/zapret2.conf 2>/dev/null || true
        chmod 666 /var/lib/zapret2/*-hosts.txt 2>/dev/null || true
        chmod 777 /var/lib/zapret2 /var/lib/zapret2/lists /var/lib/zapret2/lua 2>/dev/null || true
      '';

      serviceConfig = {
        DynamicUser = lib.mkForce false;
        User = lib.mkForce "root";
        Group = lib.mkForce "root";
        ProtectHome = lib.mkForce "read-only";
        StateDirectory = "zapret2";
        StateDirectoryMode = "0755";
        CapabilityBoundingSet = lib.mkForce [
          "CAP_NET_ADMIN"
          "CAP_NET_RAW"
          "CAP_DAC_OVERRIDE"
          "CAP_FOWNER"
          "CAP_CHOWN"
        ];
        ExecStart = lib.mkForce [
          ""
          "${config.services.zapret2.package}/bin/nfqws2 @/var/lib/zapret2/zapret2.conf"
        ];
        ExecReload = [
          ""
          "${pkgs.writeShellScript "zapret2-reload" ''
            if [ -d /home/zerg/nixos-conf/dotfiles/zapret/lists ]; then
              cp -rf /home/zerg/nixos-conf/dotfiles/zapret/lists/* /var/lib/zapret2/lists/
            fi
            chmod -R 644 /var/lib/zapret2/lists/* 2>/dev/null || true
            kill -HUP $MAINPID
          ''}"
        ];
      };
    };

    # Convenience CLI tools for managing Zapret2 without rebuilding
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "zapret-reload" ''
        echo "Syncing lists and reloading Zapret2..."
        sudo systemctl reload nfqws2@default
        echo "Done! (Check status with zapret-status)"
      '')
      (pkgs.writeShellScriptBin "zapret-restart" ''
        if [ "$EUID" -ne 0 ]; then
          exec sudo "$0" "$@"
        fi
        if ! zapret-test >/dev/null 2>&1; then
          echo "ERROR: dotfiles/zapret/zapret2.conf has syntax errors! Run 'zapret-test' to inspect." >&2
          zapret-test
          exit 1
        fi
        echo "Configuration verified. Syncing config & restarting Zapret2..."
        systemctl restart nfqws2@default
        echo "Done! (Check status with zapret-status)"
      '')
      (pkgs.writeShellScriptBin "zapret-status" ''
        systemctl status nfqws2@default
      '')
      (pkgs.writeShellScriptBin "zapret-test" ''
        TMPCONF=$(mktemp)
        echo "--dry-run" > "$TMPCONF"
        grep -v '^[[:space:]]*#' /home/zerg/nixos-conf/dotfiles/zapret/zapret2.conf | grep -v '^[[:space:]]*$' >> "$TMPCONF"
        if [ "$EUID" -ne 0 ]; then
          sudo ${config.services.zapret2.package}/bin/nfqws2 "@$TMPCONF"
        else
          ${config.services.zapret2.package}/bin/nfqws2 "@$TMPCONF"
        fi
        STATUS=$?
        rm -f "$TMPCONF"
        exit $STATUS
      '')
    ];

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

        # Profile 1.5: Soft HTTPS desync (pure split without fake) for AWS CloudFront, Atoma Cloud, Darktide, Discord
        https-nofake = {
          priority = 150;
          hosts = {
            include = cfg.nofakeDomains;
            exclude = cfg.excludeDomains;
          };
          parameters = [
            "--filter-tcp=443,8443,2053,2083,2087,2096"
            "--payload=tls_client_hello"
            "--hostlist-exclude=${privateExcludePath}"
            "--lua-desync=multisplit:pos=1,midsld"
          ];
        };

        # Profile 2: Critical HTTPS (YouTube, etc.)
        https-critical = {
          priority = 200;
          hosts = {
            include = lib.filter (d: !(builtins.elem d cfg.nofakeDomains)) cfg.includeDomains;
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
