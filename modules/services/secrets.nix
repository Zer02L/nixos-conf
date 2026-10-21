{ inputs, ... }: {
  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops = {
    defaultSopsFile = "${inputs.self}/secrets.yaml";
    age.sshKeyPaths = [ "/home/zerg/.ssh/id_ed25519" ];

    secrets = {
      "zapret_exclude_ips" = {
        mode = "0440";
        # restartUnits = [ "zapret-discord-youtube.service" ];
      };
    };
  };
}
