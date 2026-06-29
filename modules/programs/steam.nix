{ config, pkgs, ... }: {
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Открыть порты в брандмауэре для Steam Remote Play
    dedicatedServer.openFirewall = true; # Открыть порты в брандмауэре для Steam Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Открыть порты в брандмауэре для Steam Local Network Game Transfers
  };

  # Включение GameMode для повышения производительности в играх
  programs.gamemode.enable = true;

  # MangoHud — оверлей производительности (FPS, температуры, нагрузка)
  # Нужен в extraPackages/extraPackages32 для Vulkan-слоя в 32-битных играх Steam
  hardware.graphics.extraPackages = with pkgs; [ mangohud ];
  hardware.graphics.extraPackages32 = with pkgs; [ mangohud ];
  environment.systemPackages = with pkgs; [ mangohud ];
}
