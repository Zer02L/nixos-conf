{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
  cfg = config.programs.flclash;
in
{
  options.programs.flclash = {
    enable = mkEnableOption "FlClash proxy desktop client";

    package = mkOption {
      type = types.package;
      default = pkgs.callPackage ./package.nix { };
      defaultText = "pkgs.callPackage ./package.nix { }";
      description = "The FlClash package to use.";
    };

    tunMode = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Enable TUN mode support. This configures the systemd helper service
        (`flclash-helper.service`) that runs with elevated privileges to manage
        the TUN network interface and system routing without running the GUI as root.
      '';
    };

    user = mkOption {
      type = types.str;
      default = "zerg";
      description = "User account permitted to communicate with FlClashHelperService.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
    ];

    # Required for TUN/TAP virtual network devices
    boot.kernelModules = mkIf cfg.tunMode [ "tun" ];

    # Loose reverse path filtering prevents dropped packets under TUN routing
    networking.firewall.checkReversePath = mkIf cfg.tunMode "loose";

    systemd.services.flclash-helper = mkIf cfg.tunMode {
      description = "FlClash Helper starts the FlClash Core with the privileges TUN mode needs";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      path = with pkgs; [
        iproute2
        iptables
        nftables
        procps
        coreutils
      ];

      serviceConfig = {
        Type = "simple";
        ExecStart = pkgs.writeShellScript "flclash-helper-start" ''
          export FLCLASH_HELPER_OWNER_UID="$(${pkgs.coreutils}/bin/id -u ${cfg.user})"
          export FLCLASH_HELPER_OWNER_GID="$(${pkgs.coreutils}/bin/id -g ${cfg.user})"
          exec ${cfg.package}/opt/FlClash/FlClashHelperService
        '';
        RuntimeDirectory = "flclash";
        RuntimeDirectoryMode = "0755";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}
