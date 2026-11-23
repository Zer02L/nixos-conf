{ config
, pkgs
, lib
, ...
}:

let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    stringAfter
    mkAfter
    ;
  cfg = config.services.happ;

  resolvectl = "${pkgs.systemd}/bin/resolvectl";
  systemctl = "${pkgs.systemd}/bin/systemctl";
  ip = "${pkgs.iproute2}/bin/ip";
  head = "${pkgs.coreutils}/bin/head";
  awk = "${pkgs.gawk}/bin/awk";
  grep = "${pkgs.gnugrep}/bin/grep";

  # xray-core runs as `nobody`. Once Happ installs `default dev happ-xray`,
  # its own outbound connections to the upstream proxy are fed back into the
  # TUN it created, so nothing can reach the internet. Route that uid via the
  # physical uplink in a separate table.
  directTable = "1010";
  directUid = "65534";

  # Keep this in sync with services.resolved.settings.Resolve.DNS in
  # modules/networking/base.nix. 1.1.1.1 / 8.8.8.8 are deliberately NOT used:
  # TSPU DNATs their UDP queries to a black hole (NXDOMAIN) and cuts DoT.
  resolverDns = [
    "9.9.9.9#dns.quad9.net"
    "149.112.112.112#dns.quad9.net"
    "94.140.14.14#dns.adguard-dns.com"
  ];

  # Both this script and the dhcpcd hook can fire when the TUN appears (dhcpcd
  # starts on every new link), so the policy rule must be added idempotently --
  # a plain `ip rule add` races and fails with "RTNETLINK answers: File exists".
  addDirectRule = ''
    if ! ${ip} rule show | ${grep} -q 'uidrange ${directUid}-${directUid} lookup ${directTable}'; then
      ${ip} rule add uidrange ${directUid}-${directUid} table ${directTable} priority 1000 || true
    fi
  '';

  # Happ's bundled TunDns looks for `resolvectl` in /usr/bin and /usr/sbin
  # only, so on NixOS it silently leaves DNS wherever it was. Sending DNS
  # through the TUN is a bootstrapping trap: xray needs to resolve its own
  # upstream server before the tunnel can carry any packets at all. Keep DNS
  # on the physical uplink instead, including for directSites domains such
  # as Discord, so the resolved address matches the real egress path.
  #
  # Zapret must also stand down while the tunnel is up. Its nfqws2 queues all
  # TCP/443 leaving the physical uplink and its `https-general` profile has no
  # hostlist, so it applies fake-TLS desync to *every* TLS ClientHello --
  # including xray's own upstream/DoH connections (1.1.1.1 / 8.8.8.8:443 from
  # routing.json). That leaves the tunnel with no working upstream and every
  # app hangs. The nft rule uses `queue ... bypass`, so stopping the daemon is
  # enough; the nftables table itself can stay in place.
  dnsScript = pkgs.writeShellScript "happ-network" ''
    set -eu
    if ${ip} link show dev ${cfg.tunInterface} > /dev/null 2>&1; then
      echo "happ-network: ${cfg.tunInterface} is up, pinning DNS to ${cfg.physicalInterface}"
      ${resolvectl} dns ${cfg.physicalInterface} ${lib.concatStringsSep " " resolverDns}
      ${resolvectl} domain ${cfg.physicalInterface} '~.' '~discord.com'
      ${resolvectl} default-route ${cfg.physicalInterface} false
      ${resolvectl} default-route ${cfg.tunInterface} false || true

      ${systemctl} stop nfqws2@default > /dev/null 2>&1 || true

      gw=$(${ip} -4 route show default dev ${cfg.physicalInterface} | ${head} -n1 | ${awk} '{print $3}')
      if [ -n "$gw" ]; then
        ${ip} route replace default via "$gw" dev ${cfg.physicalInterface} table ${directTable}
        ${addDirectRule}
      fi
    else
      echo "happ-network: ${cfg.tunInterface} is down, reverting DNS routing"
      ${resolvectl} revert ${cfg.tunInterface} || true
      ${resolvectl} domain ${cfg.physicalInterface} "" || true
      ${ip} rule del uidrange ${directUid}-${directUid} table ${directTable} priority 1000 2>/dev/null || true
      ${ip} route flush table ${directTable} || true
      ${systemctl} start nfqws2@default > /dev/null 2>&1 || true
    fi
  '';

  # The udev `remove` event for a TUN device is unreliable in practice -- on a
  # GUI disconnect it is often never delivered, so the udev-triggered script
  # above cannot be relied on to bring Zapret back. A lightweight timer keeps
  # the daemon's state in sync with the tunnel instead. Both `systemctl stop`
  # and `systemctl start` are no-ops when already in the requested state.
  zapretSyncScript = pkgs.writeShellScript "happ-zapret-sync" ''
    if ${ip} link show dev ${cfg.tunInterface} > /dev/null 2>&1; then
      ${systemctl} stop nfqws2@default > /dev/null 2>&1 || true
    else
      ${systemctl} start nfqws2@default > /dev/null 2>&1 || true
    fi
  '';

  # dhcpcd re-writes resolved's per-link settings on every lease event, so
  # pin the resolver again after each hook run. This keeps DNS off the TUN
  # even when dhcpcd (re)configures the Happ interface.
  dhcpcdHook = mkAfter ''
    ${resolvectl} dns ${cfg.physicalInterface} ${lib.concatStringsSep " " resolverDns} || true
    ${resolvectl} domain ${cfg.physicalInterface} '~.' '~discord.com' || true
    ${resolvectl} default-route ${cfg.physicalInterface} false || true
    gw=$(${ip} -4 route show default dev ${cfg.physicalInterface} | ${head} -n1 | ${awk} '{print $3}')
    if [ -n "$gw" ]; then
      ${ip} route replace default via "$gw" dev ${cfg.physicalInterface} table ${directTable} || true
      ${addDirectRule}
    fi
  '';
in
{

  options.services.happ = {
    enable = mkEnableOption "Happ proxy desktop client and background TUN daemon";

    package = mkOption {
      type = types.package;
      default = pkgs.callPackage ./happ.nix { inherit (cfg) forceXwayland forceSoftwareRendering; };
      defaultText = "pkgs.callPackage ./happ.nix { }";
      description = "The Happ package to use.";
    };

    forceXwayland = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Force Happ to run through XWayland (XCB) instead of its bundled Qt6
        Wayland plugins, which are dropped from the package entirely. Works
        around a silent startup crash on wlroots-based Wayland compositors
        (Hyprland, Sway, ...) where the bundled Qt6 Wayland integration is
        incompatible. Only affects the default `package` build above; has
        no effect if you override `services.happ.package` yourself.
      '';
    };

    forceSoftwareRendering = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Force Happ's Qt Quick UI to render in software (`QML_SCENE_GRAPH=software`,
        `LIBGL_ALWAYS_SOFTWARE=1`). Independent of `forceXwayland` -- use this if
        Happ's UI renders incorrectly or not at all due to a GPU/driver issue,
        regardless of which Qt platform backend is in use. Only affects the
        default `package` build above; has no effect if you override
        `services.happ.package` yourself.
      '';
    };

    tunInterface = mkOption {
      type = types.str;
      default = "happ-xray";
      description = ''
        Name of the TUN interface Happ brings up; it is added to the firewall's
        trusted interfaces so tunnelled traffic is not dropped.

        Happ's xray-core TUN mode names its interface ``happ-xray`` (not
        ``tun0``). Trusting the wrong name leaves the tunnel interface
        untrusted by the firewall, so the option must match the real name.
      '';
    };

    physicalInterface = mkOption {
      type = types.str;
      default = "enp6s0";
      description = ''
        Physical uplink used for traffic Happ marks as Direct (e.g. Discord).
        DNS for those domains is routed through this interface so the resolved
        address matches the real egress path (and Zapret's interface-bound DPI
        bypass). Keep it in sync with `services.custom-zapret.interfaces`.
      '';
    };
  };

  config = mkIf cfg.enable {
    # Tools Happ and its helper scripts call from the system PATH.
    environment.systemPackages = [
      cfg.package
      pkgs.net-tools
      pkgs.lsb-release
    ];

    # HWID fix. Happ reads its hardware id from Qt's QSysInfo::machineUniqueId(),
    # which on Linux comes from /var/lib/dbus/machine-id. NixOS defaults to
    # dbus-broker, which (unlike the classic dbus-daemon) does not create that
    # file, so the id is empty and the client shows a blank HWID. Linking it to
    # the real /etc/machine-id fixes it.
    #
    # Note: keep happd (below) unsandboxed. systemd sandboxing (ProtectSystem,
    # PrivateTmp, ...) enables a mount namespace whose machine-id bind-mount fails
    # here with 226/NAMESPACE and breaks TUN mode.
    systemd.tmpfiles.rules = [
      "L+ /var/lib/dbus/machine-id - - - - /etc/machine-id"
    ];

    # Firewall + TUN module for Happ's TUN mode.
    networking.firewall.checkReversePath = "loose";
    networking.firewall.trustedInterfaces = [ cfg.tunInterface ];
    boot.kernelModules = [ "tun" ];

    # DNS must stay on the physical link even while Happ owns the default
    # route: sending it through the TUN creates a bootstrapping cycle (xray
    # cannot resolve its own upstream) and every lookup times out, which is
    # what hung both Vesktop and OpenCode. Zapret also has to be paused while
    # the tunnel is up (see dnsScript). Triggered from udev so it also works
    # when the TUN is brought up/down from the Happ GUI, not just at boot.
    services.udev.extraRules = ''
      SUBSYSTEM=="net", KERNEL=="${cfg.tunInterface}", ACTION=="add|remove", TAG+="systemd", ENV{SYSTEMD_WANTS}+="happ-network.service"
    '';

    networking.dhcpcd.runHook = dhcpcdHook;

    systemd.services.happ-network = {
      description = "Happ TUN network policy (DNS, direct routes, Zapret handoff)";
      after = [ "network.target" "systemd-resolved.service" ];
      wants = [ "systemd-resolved.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = dnsScript;
      };
    };

    # Belt-and-braces: make sure Zapret comes back even when the TUN's udev
    # remove event is missed (which happens on a normal GUI disconnect).
    systemd.services.happ-zapret-sync = {
      description = "Keep Zapret paused while the Happ tunnel is up";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = zapretSyncScript;
      };
    };
    systemd.timers.happ-zapret-sync = {
      description = "Reconcile Zapret with the Happ tunnel state";
      timerConfig = {
        OnBootSec = "10s";
        OnUnitActiveSec = "5s";
        AccuracySec = "1s";
      };
      wantedBy = [ "timers.target" ];
    };

    # Happ hard-codes /opt/happ for its binaries, so we materialise the immutable
    # Nix store tree there. The copy runs only when the package changes, keeping
    # everyday rebuilds fast. Happ's actual runtime state (routing, generated core
    # configs) lives per-user under ~/.config/Happ, not under /opt/happ, so the
    # materialised tree only needs to be readable/executable, never writable --
    # making it world-writable would let any unprivileged local user replace the
    # happd binary that systemd runs as root below.
    system.activationScripts.happ-opt = stringAfter [ "stdio" ] ''
      stamp=/opt/happ/.nix-store-path
      if [ "$(cat "$stamp" 2>/dev/null)" != "${cfg.package}" ]; then
        rm -rf /opt/happ
        mkdir -p /opt/happ
        cp -r ${cfg.package}/happ/. /opt/happ/
        chown -R root:root /opt/happ
        chmod -R u=rwX,go=rX /opt/happ
        printf '%s' "${cfg.package}" > "$stamp"
      fi
    '';

    # Privileged daemon that runs the TUN cores (sing-box / tun2proxy) as root.
    systemd.services.happd = {
      description = "Happ Process Control Daemon";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      # ExecStart is a fixed /opt/happ path rather than a Nix store path, so
      # switch-to-configuration can't see a package bump from the unit alone;
      # without this, happd would keep running the old binary after an upgrade.
      restartTriggers = [ cfg.package ];

      path = with pkgs; [
        iproute2
        iptables
        procps
        net-tools
        # NB: Happ's TunDns does not search PATH for resolvectl -- it only
        # looks in /usr/bin and /usr/sbin, which have no resolvectl on NixOS.
        # TUN DNS is therefore configured by happ-network.service below; systemd
        # stays in PATH for other resolver/network tools Happ may call.
        systemd
      ];

      serviceConfig = {
        Type = "simple";
        User = "root";
        Group = "root";
        ExecStart = "/opt/happ/bin/happd";
        Restart = "on-failure";
        RestartSec = "5s";
        TimeoutStopSec = "10s";
        KillMode = "mixed";
        KillSignal = "SIGTERM";
      };
    };
  };
}
