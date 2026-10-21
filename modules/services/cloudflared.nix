{ config, pkgs, ... }:
{
  networking.wg-quick.interfaces.gif-wg0 = {
    configFile = "/etc/wireguard/clients/gif-wg0.conf";
    autostart = false;
  };
  services.cloudflared = {
    enable = true;
  };
}
