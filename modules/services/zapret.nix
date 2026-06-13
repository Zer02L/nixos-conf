{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [ inputs.zapret-discord-youtube.nixosModules.withTestTools ];

  services.zapret-discord-youtube = {
    enable = true;
    configName = "general (ALT12)";
    gameFilter = "null";
    listGeneral = [
      "example.com"
      "test.org"
      "mysite.net"
      "youtube.com"
      "discord.com"
    ];
    listExclude = [
      "ubisoft.com"
      "origin.com"
    ];
    ipsetAll = [
      "192.168.1.0/24"
      "10.0.0.1"
    ];
    ipsetExclude = [ "203.0.113.0/24" ];
  };

  services.cloudflare-warp = {
    enable = true;
    package = pkgs.cloudflare-warp;
  };

  # # 1. Включаем системную службу AdGuard Home
  # services.adguardhome = {
  #   enable = true;
  #   # Открываем порты в брандмауэре (53 для DNS, 3000 для веб-интерфейса настройки)
  #   openFirewall = true;
  # };
}
