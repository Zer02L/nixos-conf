{ config, pkgs, ... }:
{
  services.cloudflare-warp.enable = true;
  services.cloudflare-warp.openFirewall = true; # Важно для обхода блокировок портов
  environment.systemPackages = [ pkgs.cloudflare-warp ];

  # Переопределяем только создание директории, не трогая внутренности демона
  systemd.services.cloudflare-warp = {
    preStart = ''
      mkdir -p /var/lib/cloudflare-warp
      chmod 700 /var/lib/cloudflare-warp
    '';
  };
}
