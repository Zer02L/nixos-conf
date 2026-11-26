# OpenSnitch application firewall module (desktop/workstation egress control and audit)
{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.custom.opensnitch;
in
{
  options.custom.opensnitch = {
    enable = lib.mkEnableOption "OpenSnitch application firewall";

    procMonitorMethod = lib.mkOption {
      type = lib.types.enum [
        "ebpf"
        "proc"
        "ftrace"
        "audit"
      ];
      default = "ebpf";
      description = ''
        Process monitoring method used by opensnitchd.
        Fallback to "proc" if a newer kernel breaks opensnitch-ebpf builds.
      '';
    };

    silentMode = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Allow unmatched connections silently (no popups in opensnitch-ui) while
        keeping live audit logs and precedence reject rules.
      '';
    };

    blockedDomainPatterns = lib.mkOption {
      type = lib.types.listOf lib.types.nonEmptyStr;
      default = [
        "ingest\\.t3\\.codes"
        "(.+\\.)?posthog\\.com"
        "(.+\\.)?ingest(\\.[a-z0-9-]+)?\\.sentry\\.io"
        "(.+\\.)?axiom\\.co"
      ];
      description = ''
        Regular expression fragments (matched against dest.host) for domains to
        reject with priority over allow rules.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.opensnitch = {
      enable = true;

      settings = {
        DefaultAction = "allow";
        Firewall = "nftables";
        ProcMonitorMethod = cfg.procMonitorMethod;
        FwOptions.QueueBypass = true;
      };

      rules =
        lib.optionalAttrs (cfg.blockedDomainPatterns != [ ])
          {
            reject-telemetry-domains = {
              name = "reject-telemetry-domains";
              enabled = true;
              precedence = true;
              nolog = false;
              action = "reject";
              duration = "always";
              operator = {
                type = "regexp";
                sensitive = false;
                operand = "dest.host";
                data = "^(${lib.concatStringsSep "|" cfg.blockedDomainPatterns})$";
              };
            };
          }
        // lib.optionalAttrs cfg.silentMode {
          allow-default-audit = {
            name = "allow-default-audit";
            enabled = true;
            precedence = false;
            nolog = false;
            action = "allow";
            duration = "always";
            operator = {
              type = "regexp";
              sensitive = false;
              operand = "dest.ip";
              data = ".*";
            };
          };
        };
    };
  };
}
