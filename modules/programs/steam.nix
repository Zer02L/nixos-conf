{ config, pkgs, ... }: {
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Открыть порты в брандмауэре для Steam Remote Play
    dedicatedServer.openFirewall = true; # Открыть порты в брандмауэре для Steam Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Открыть порты в брандмауэре для Steam Local Network Game Transfers
  };

  # Включение GameMode для повышения производительности в играх
  programs.gamemode.enable = true;
}
