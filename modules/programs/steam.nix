{ config, pkgs, ... }: {
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Открыть порты в брандмауэре для Steam Remote Play
    dedicatedServer.openFirewall = true; # Открыть порты в брандмауэре для Steam Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Открыть порты в брандмауэре для Steam Local Network Game Transfers
    extraCompatPackages = with pkgs; [ proton-ge-bin ];
  };

  # Включение GameMode для повышения производительности в играх
  programs.gamemode.enable = true;

  # MangoHud — оверлей производительности (FPS, температуры, нагрузка)
  # Нужен в extraPackages/extraPackages32 для Vulkan-слоя в 32-битных играх Steam
  hardware.graphics.extraPackages = with pkgs; [ mangohud ];
  hardware.graphics.extraPackages32 = with pkgs; [ mangohud ];
  environment.systemPackages = with pkgs; [ mangohud protontricks ];

  # Включить MangoHud для всех Vulkan-приложений (игры через Proton)
  # HUD скрыт по умолчанию — показывается по Shift+F12
  environment.sessionVariables = {
    MANGOHUD = "1";
  };
}
