{ inputs, ... }: {
  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops = {
    defaultSopsFile = "${inputs.self}/secrets.yaml";
    age.sshKeyPaths = [ "/home/zerg/.ssh/id_ed25519" ];
  };

  # ── добавить секреты так:
  # sops.secrets."my_api_key" = {
  #   owner   = "zerg";
  #   path    = "/home/zerg/.config/my-app/key";
  # };
  # Потом в сервисе ссылаться на config.sops.secrets."my_api_key".path
}
