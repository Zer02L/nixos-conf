{ inputs, pkgs, ... }: {
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  home.packages = with pkgs; [
    secretspec
    sops
    age
    bitwarden-cli
  ];

  sops = {
    defaultSopsFile = "${inputs.self}/secrets.yaml";
    age.sshKeyPaths = [ "/home/zerg/.ssh/id_ed25519" ];
  };

  # ── примеры для user-level секретов ──
  # sops.secrets."api_telegram_token" = {
  #   path = "/home/zerg/.config/telegram-bot/token";
  # };
}
