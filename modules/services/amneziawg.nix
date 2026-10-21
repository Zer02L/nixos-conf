{ config, pkgs, ... }:

{
  services.happ.enable = true;

  # 1. Добавляем пакет amneziawg-go в систему
  environment.systemPackages = with pkgs; [
    amneziawg-go
    wireguard-go
  ];

  # 2. Создаём службу (пример systemd)
  systemd.services.amneziawg = {
    description = "AmneziaWG VPN Client";
    after = [ "network.target" ];
    wants = [ "network.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.amneziawg-go}/bin/amneziawg-go up /home/zerg/Downloads/WARP1632883.conf";
      ExecStop = "${pkgs.amneziawg-go}/bin/amneziawg-go down /home/zerg/Downloads/WARP1632883.conf";
      ExecReload = "${pkgs.amneziawg-go}/bin/amneziawg-go syncconf /home/zerg/Downloads/WARP1632883.conf";
      # Полезно добавить для разрешения доступа к интернету
      # ExecStartPost = "${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -o awg0 -j MASQUERADE";
      # ExecStopPost = "${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -o awg0 -j MASQUERADE";
    };

    wantedBy = [ "multi-user.target" ];
  };

  # 3. (Опционально) Настройка сетевого интерфейса для маршрутизации
  # networking.firewall.allowedUDPPorts = [ 51820 ]; # если ваш сервер слушает на этом порту
}
