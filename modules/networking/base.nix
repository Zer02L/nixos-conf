{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Hostname задаётся в hosts/<machine>/default.nix
  # networking.hostName = "my-hostname";

  networking.useDHCP = lib.mkDefault true;

  # Разрешаем сторонним сервисам изменять настройки DNS
  networking.nameservers = [
    "1.1.1.1"
    "1.0.0.1"
  ];

  # networking.networkmanager.enable = true;

  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # networking.firewall.enable = false;
}
