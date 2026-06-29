{ config, lib, pkgs, ... }:

let
  lists = ../../dotfiles/zapret/lists;
  blobs = ../../dotfiles/zapret/blobs;

  # Стратегия — какой .args файл использовать.
  #   alt12.args   — агрессивная (ALT12), repeats=11, fake+multisplit, fooling=ts
  #   default.args — базовая (general.bat), multisplit, repeats=6
  strategyFile = ../../dotfiles/zapret/strategies/alt12.args;
  strategyText = builtins.readFile strategyFile;

  strategyLines = builtins.filter (line: line != "" && !(lib.hasPrefix "#" line))
    (lib.splitString "\n" strategyText);

  subst = line: builtins.replaceStrings
    [ "@lists@" "@blobs@" ]
    [ (toString lists) (toString blobs) ]
    line;

  params = map subst strategyLines;

  qnum = "200";
in {
  # ---- модули ядра (загружаются до systemd, изоляция не мешает) ----
  boot.kernelModules = [
    "xt_NFQUEUE"
    "xt_connbytes"
    "xt_multiport"
  ];

  # ---- направляем трафик на NFQUEUE ----
  # В отличие от nixpkgs-модуля, добавляем все порты из стратегии,
  # включая альтернативные (2053, 2083, 2087, 2096, 8443).
  networking.firewall.extraCommands = ''
    iptables -t mangle -A POSTROUTING -p tcp -m multiport --dports 80,443,8443 \
      -m connbytes --connbytes-dir=original --connbytes-mode=packets --connbytes 1:6 \
      -m mark ! --mark 0x40000000/0x40000000 \
      -j NFQUEUE --queue-num ${qnum} --queue-bypass
    ip6tables -t mangle -A POSTROUTING -p tcp -m multiport --dports 80,443,8443 \
      -m connbytes --connbytes-dir=original --connbytes-mode=packets --connbytes 1:6 \
      -m mark ! --mark 0x40000000/0x40000000 \
      -j NFQUEUE --queue-num ${qnum} --queue-bypass 2>/dev/null || true

    iptables -t mangle -A POSTROUTING -p tcp -m multiport --dports 2053,2083,2087,2096 \
      -m connbytes --connbytes-dir=original --connbytes-mode=packets --connbytes 1:6 \
      -m mark ! --mark 0x40000000/0x40000000 \
      -j NFQUEUE --queue-num ${qnum} --queue-bypass
    ip6tables -t mangle -A POSTROUTING -p tcp -m multiport --dports 2053,2083,2087,2096 \
      -m connbytes --connbytes-dir=original --connbytes-mode=packets --connbytes 1:6 \
      -m mark ! --mark 0x40000000/0x40000000 \
      -j NFQUEUE --queue-num ${qnum} --queue-bypass 2>/dev/null || true

    # UDP: multiport не поддерживает range'ы в nftables compat-режиме
    # Поэтому каждую группу портов — отдельным правилом с --dport (одиночный)
    iptables -t mangle -A POSTROUTING -p udp --dport 443 \
      -m mark ! --mark 0x40000000/0x40000000 \
      -j NFQUEUE --queue-num ${qnum} --queue-bypass
    ip6tables -t mangle -A POSTROUTING -p udp --dport 443 \
      -m mark ! --mark 0x40000000/0x40000000 \
      -j NFQUEUE --queue-num ${qnum} --queue-bypass 2>/dev/null || true

    iptables -t mangle -A POSTROUTING -p udp --dport 19294:19344 \
      -m mark ! --mark 0x40000000/0x40000000 \
      -j NFQUEUE --queue-num ${qnum} --queue-bypass
    ip6tables -t mangle -A POSTROUTING -p udp --dport 19294:19344 \
      -m mark ! --mark 0x40000000/0x40000000 \
      -j NFQUEUE --queue-num ${qnum} --queue-bypass 2>/dev/null || true

    iptables -t mangle -A POSTROUTING -p udp --dport 50000:50100 \
      -m mark ! --mark 0x40000000/0x40000000 \
      -j NFQUEUE --queue-num ${qnum} --queue-bypass
    ip6tables -t mangle -A POSTROUTING -p udp --dport 50000:50100 \
      -m mark ! --mark 0x40000000/0x40000000 \
      -j NFQUEUE --queue-num ${qnum} --queue-bypass 2>/dev/null || true
  '';

  # ---- сервис: nfqws с правильной изоляцией ----
  # Не используем services.zapret из nixpkgs — определяем свой systemd unit.
  # Изоляция возвращена к жёстким настройкам, кроме двух capabilities,
  # которые физически нужны nfqws для raw sockets.
  systemd.services.zapret = {
    description = "DPI bypass service (nfqws)";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    preStart = ''
      # ipset для исключений. Модули ядра уже загружены через boot.kernelModules,
      # но preStart — страховка на случай если модули выгрузили.
      ${pkgs.kmod}/bin/modprobe xt_NFQUEUE 2>/dev/null || true
      ${pkgs.kmod}/bin/modprobe xt_connbytes 2>/dev/null || true
      ${pkgs.kmod}/bin/modprobe xt_multiport 2>/dev/null || true

      if ! ${pkgs.ipset}/bin/ipset list nozapret >/dev/null 2>&1; then
        ${pkgs.ipset}/bin/ipset create nozapret hash:net 2>/dev/null || true
      fi
    '';

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.zapret}/bin/nfqws --pidfile=/run/nfqws.pid ${lib.concatStringsSep " " params} --qnum=${qnum}";
      NoNewPrivileges = true;        # страховка: даже root внутри unit не поднимет привилегии через exec
      PIDFile = "/run/nfqws.pid";
      Restart = "always";

      # ---- nfqws обязан работать от root (raw sockets, netfilter) ----
      User = "root";
      Group = "root";

      # ---- capabilities — ЕДИНСТВЕННОЕ ослабление ----
      # nfqws с --dpi-desync=fake создаёт raw IP socket (CAP_NET_RAW)
      # и управляет netfilter/iptables (CAP_NET_ADMIN).
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
      ProtectKernelModules = true;     # восстановлено — модули в boot.kernelModules
      ProtectKernelTunables = true;    # восстановлено — nfqws не пишет sysctl runtime
      ProtectSystem = "strict";
      ProtectProc = "invisible";
      RemoveIPC = true;
      RestrictNamespaces = true;       # восстановлено
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      SystemCallArchitectures = "native";

      # RuntimeMaxSec убран — nfqws 72.12 стабилен, Restart=always если упадёт
    };
  };
}
