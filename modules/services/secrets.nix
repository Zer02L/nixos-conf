{
  config,
  lib,
  inputs,
  ...
}:
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops = {
    defaultSopsFile = lib.mkDefault "${inputs.self}/secrets.yaml";

    # Default decryption key: user's SSH key for workstation.
    # Server profile overrides this with [ "/etc/ssh/ssh_host_ed25519_key" ].
    age.sshKeyPaths = lib.mkDefault [ "/home/zerg/.ssh/id_ed25519" ];

    secrets = lib.mkMerge [
      # Workstation-specific secrets
      (lib.mkIf (config.networking.hostName == "zerg") {
        "zapret_exclude_ips" = {
          mode = "0440";
        };
      })
    ];
  };
}
