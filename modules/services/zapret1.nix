{
  config,
  lib,
  pkgs,
  ...
}:

let
  lists = ../../dotfiles/zapret/lists;
  blobs = ../../dotfiles/zapret/blobs;

  # ---------- ИЗМЕНЕНИЕ: стратегия amazon_UDP (fake) ----------
  strategyFile = ../../dotfiles/zapret/strategies/amazon_UDP.args;
  strategyText = builtins.readFile strategyFile;

  strategyLines = builtins.filter (line: line != "" && !(lib.hasPrefix "#" line)) (
    lib.splitString "\n" strategyText
  );

  subst =
    line: builtins.replaceStrings [ "@lists@" "@blobs@" ] [ (toString lists) (toString blobs) ] line;

  params = map subst strategyLines;

  qnum = "200";
in
{
  # ---- модули ядра (добавлен xt_set для ipset) ----
  boot.kernelModules = [
    "xt_NFQUEUE"
    "xt_connbytes"
    "xt_multiport"
    "xt_set" # <-- новый модуль
  ];

  # ---- направляем трафик на NFQUEUE с учётом ipset-исключений ----
  networking.firewall.extraCommands = ''
    # TCP: основные порты
    iptables -t mangle -A POSTROUTING -p tcp -m multiport --dports 80,443,8443 \
      -m connbytes --connbytes-dir=original --connbytes-mode=packets --connbytes 1:6 \
      -m set ! --match-set nozapret dst \
      -m mark ! --mark 0x40000000/0x40000000 \
      -j NFQUEUE --queue-num ${qnum} --queue-bypass
    ip6tables -t mangle -A POSTROUTING -p tcp -m multiport --dports 80,443,8443 \
      -m connbytes --connbytes-dir=original --connbytes-mode=packets --connbytes 1:6 \
      -m set ! --match-set nozapret dst \
      -m mark ! --mark 0x40000000/0x40000000 \
      -j NFQUEUE --queue-num ${qnum} --queue-bypass 2>/dev/null || true

    # TCP: альтернативные порты
    iptables -t mangle -A POSTROUTING -p tcp -m multiport --dports 2053,2083,2087,2096 \
      -m connbytes --connbytes-dir=original --connbytes-mode=packets --connbytes 1:6 \
      -m set ! --match-set nozapret dst \
      -m mark ! --mark 0x40000000/0x40000000 \
      -j NFQUEUE --queue-num ${qnum} --queue-bypass
    ip6tables -t mangle -A POSTROUTING -p tcp -m multiport --dports 2053,2083,2087,2096 \
      -m connbytes --connbytes-dir=original --connbytes-mode=packets --connbytes 1:6 \
      -m set ! --match-set nozapret dst \
      -m mark ! --mark 0x40000000/0x40000000 \
      -j NFQUEUE --queue-num ${qnum} --queue-bypass 2>/dev/null || true

    # UDP: порт 443
    iptables -t mangle -A POSTROUTING -p udp --dport 443 \
      -m set ! --match-set nozapret dst \
      -m mark ! --mark 0x40000000/0x40000000 \
      -j NFQUEUE --queue-num ${qnum} --queue-bypass
    ip6tables -t mangle -A POSTROUTING -p udp --dport 443 \
      -m set ! --match-set nozapret dst \
      -m mark ! --mark 0x40000000/0x40000000 \
      -j NFQUEUE --queue-num ${qnum} --queue-bypass 2>/dev/null || true

    # UDP: диапазон 19294-19344 (обычно для игр)
    iptables -t mangle -A POSTROUTING -p udp --dport 19294:19344 \
      -m set ! --match-set nozapret dst \
      -m mark ! --mark 0x40000000/0x40000000 \
      -j NFQUEUE --queue-num ${qnum} --queue-bypass
    ip6tables -t mangle -A POSTROUTING -p udp --dport 19294:19344 \
      -m set ! --match-set nozapret dst \
      -m mark ! --mark 0x40000000/0x40000000 \
      -j NFQUEUE --queue-num ${qnum} --queue-bypass 2>/dev/null || true

    # UDP: диапазон 50000-50100
    iptables -t mangle -A POSTROUTING -p udp --dport 50000:50100 \
      -m set ! --match-set nozapret dst \
      -m mark ! --mark 0x40000000/0x40000000 \
      -j NFQUEUE --queue-num ${qnum} --queue-bypass
    ip6tables -t mangle -A POSTROUTING -p udp --dport 50000:50100 \
      -m set ! --match-set nozapret dst \
      -m mark ! --mark 0x40000000/0x40000000 \
      -j NFQUEUE --queue-num ${qnum} --queue-bypass 2>/dev/null || true

    # ---------- ДОПОЛНИТЕЛЬНО: UDP для Steam (Darktide) ----------
    iptables -t mangle -A POSTROUTING -p udp --dport 27000:27030 \
      -m set ! --match-set nozapret dst \
      -m mark ! --mark 0x40000000/0x40000000 \
      -j NFQUEUE --queue-num ${qnum} --queue-bypass
    ip6tables -t mangle -A POSTROUTING -p udp --dport 27000:27030 \
      -m set ! --match-set nozapret dst \
      -m mark ! --mark 0x40000000/0x40000000 \
      -j NFQUEUE --queue-num ${qnum} --queue-bypass 2>/dev/null || true
  '';

  # ---- сервис: nfqws с правильной изоляцией ----
  systemd.services.zapret = {
    description = "DPI bypass service (nfqws)";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    preStart = ''
      # Загружаем модули (включая xt_set)
      ${pkgs.kmod}/bin/modprobe xt_NFQUEUE 2>/dev/null || true
      ${pkgs.kmod}/bin/modprobe xt_connbytes 2>/dev/null || true
      ${pkgs.kmod}/bin/modprobe xt_multiport 2>/dev/null || true
      ${pkgs.kmod}/bin/modprobe xt_set 2>/dev/null || true

      # Создаём ipset, если его нет
      if ! ${pkgs.ipset}/bin/ipset list nozapret >/dev/null 2>&1; then
        ${pkgs.ipset}/bin/ipset create nozapret hash:net 2>/dev/null || true
      fi

      # ---------- ИСКЛЮЧЕНИЯ ДЛЯ СЕРВЕРОВ DARKTIDE (AWS/CloudFront) ----------
      # Добавляем известные подсети (при необходимости дополните/обновите)
      ${pkgs.ipset}/bin/ipset add nozapret 51.20.0.0/16 2>/dev/null || true
      ${pkgs.ipset}/bin/ipset add nozapret 13.53.0.0/16 2>/dev/null || true
      ${pkgs.ipset}/bin/ipset add nozapret 13.248.0.0/16 2>/dev/null || true
      ${pkgs.ipset}/bin/ipset add nozapret 99.86.0.0/16 2>/dev/null || true
      ${pkgs.ipset}/bin/ipset add nozapret 108.157.0.0/16 2>/dev/null || true
      ${pkgs.ipset}/bin/ipset add nozapret 143.204.0.0/16 2>/dev/null || true
    '';

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.zapret}/bin/nfqws --pidfile=/run/nfqws.pid ${lib.concatStringsSep " " params} --qnum=${qnum}";
      NoNewPrivileges = true;
      PIDFile = "/run/nfqws.pid";
      Restart = "always";

      User = "root";
      Group = "root";

      AmbientCapabilities = [
        "CAP_NET_ADMIN"
        "CAP_NET_RAW"
      ];
      CapabilityBoundingSet = [
        "CAP_NET_ADMIN"
        "CAP_NET_RAW"
      ];
      DevicePolicy = "closed";
      KeyringMode = "private";
      PrivateTmp = true;
      PrivateMounts = true;
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectSystem = "strict";
      ProtectProc = "invisible";
      RemoveIPC = true;
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      SystemCallArchitectures = "native";
    };
  };
}
