# Security analysis: zapret (nfqws) standalone module

## Описание

`modules/services/zapret.nix` — самостоятельный NixOS модуль DPI-bypass,
не использующий `services.zapret` из nixpkgs. Запускает `nfqws` (zapret 72.12)
из nixpkgs с полным набором systemd-изоляции и двумя дополнительными
capabilities для raw sockets.

## Архитектура

```
zapret.nix (NixOS module)
  ├── boot.kernelModules        xt_NFQUEUE, xt_connbytes, xt_multiport
  ├── networking.firewall       iptables rules → NFQUEUE 200
  │   ├── TCP 80,443,8443
  │   ├── TCP 2053,2083,2087,2096
  │   ├── UDP 443
  │   ├── UDP 19294:19344
  │   └── UDP 50000:50100
  └── systemd.services.zapret
      ├── preStart              modprobe + ipset nozapret
      └── serviceConfig         (см. ниже)
```

## Полный serviceConfig

```
Type = "simple"
User = "root"
Group = "root"
ExecStart = nfqws --pidfile=... <params> --qnum=200

# Изоляция (восстановлена из nixpkgs)
DevicePolicy              = closed
KeyringMode               = private
PrivateTmp                = true
PrivateMounts             = true
ProtectHome               = true
ProtectHostname           = true
ProtectKernelModules      = true
ProtectKernelTunables     = true
ProtectSystem             = strict
ProtectProc               = invisible
RemoveIPC                 = true
RestrictNamespaces        = true
RestrictRealtime          = true
RestrictSUIDSGID          = true
NoNewPrivileges           = true
SystemCallArchitectures   = native

# Единственное расширение — для raw sockets
AmbientCapabilities       = CAP_NET_ADMIN, CAP_NET_RAW
CapabilityBoundingSet     = CAP_NET_ADMIN, CAP_NET_RAW
```

## Threat model

Модуль запускает `nfqws` — open source C-бинарник, перехватывающий исходящие
пакеты через NFQUEUE и модифицирующий их для обхода DPI (Deep Packet
Inspection). Атакующий вектор: теоретический RCE через крафтовый пакет или
компрометация бинарника в nixpkgs.

## Capabilities (единственное ослабление)

| Capability | Зачем |
|---|---|
| `CAP_NET_RAW` | raw socket — отправка поддельных TLS/QUIC handshake (`--dpi-desync=fake`) |
| `CAP_NET_ADMIN` | управление netfilter, bind-fix, маркировка пакетов |

Всё остальное (загрузка модулей, write-доступ к /proc/sys, монтирование,
изменение namespace'ов, создание SUID-файлов, realtime-планирование) —
заблокировано `CapabilityBoundingSet` + опциями изоляции.

## Границы безопасности при компрометации

При гипотетической RCE в nfqws атакующий получает root внутри unit с
ограниченным bounding set:

| Действие | Возможно? | Причина |
|---|---|---|
| Создать raw socket | ✅ | CAP_NET_RAW — штатная функция сервиса |
| Манипулировать пакетами | ✅ | CAP_NET_ADMIN — штатная функция сервиса |
| Открывать outbound соединения | ✅ | не ограничено (так работает DPI-bypass) |
| Установить персистентное ПО | ❌ | ProtectSystem=strict, /etc r/o |
| Прочитать /home, /root | ❌ | ProtectHome=true |
| Загрузить kernel-модуль | ❌ | ProtectKernelModules=true |
| Трогать sysctl | ❌ | ProtectKernelTunables=true |
| Увидеть чужие процессы | ❌ | ProtectProc=invisible |
| Поднять привилегии выше | ❌ | CapabilityBoundingSet урезан, NoNewPrivileges=true |
| Создать namespace | ❌ | RestrictNamespaces=true |
| Модифицировать Nix store | ❌ | immutable + ProtectSystem |
| Модифицировать /run, /tmp | ✅ | штатная работа (pidfile, ipc) |

## Трейд-оффы

### User=root

nfqws требует root для создания raw sockets (`--dpi-desync=fake`).
nixpkgs не предоставляет бинарник с file capabilities (`setcap`),
поэтому root с ограниченным bounding set — единственный рабочий вариант.

Компенсация:
- `CapabilityBoundingSet` урезан до `CAP_NET_ADMIN` + `CAP_NET_RAW`
- `NoNewPrivileges=true` — даже root внутри unit не может exec с новыми
  привилегиями
- Вся остальная изоляция nixpkgs активна

### RuntimeMaxSec убран

В nixpkgs стоял `1h` с комментарием: "This service loves to crash silently
or cause network slowdowns." Это относилось к zapret 60.x (2022). 72.12
стабилен. `Restart=always` восстановит сервис при любом падении.

### ip46tables заменён на iptables + ip6tables

`ip46tables` не существует на NixOS (нет в пакете iptables).
Оригинальный nixpkgs-модуль использовал его, из-за чего правила firewall
молча не работали на dual-stack системах. Исправлено на раздельные вызовы.

### UDP range'ы через --dport (одиночный), не через multiport

`-m multiport --dports` не поддерживает range'ы в nftables compat-режиме
(iptables v1.8.13, nf_tables backend). Команда `iptables -m multiport
--dports 19294-19344` падает с `invalid port/service`. Решение:
- дискретные порты (443, 80) → `-m multiport --dports`
- range'ы (19294:19344) → `-p udp --dport` (одиночный, без multiport)

Подпись `:`, не `-`: `--dport 19294:19344`.

## Сравнение с nixpkgs-модулем

| Аспект | nixpkgs (stock) | Наш (standalone) |
|---|---|---|
| User | nobody (UID overflow) | root |
| CAP_NET_RAW | нет | ✅ |
| CAP_NET_ADMIN | нет | ✅ |
| ProtectKernelModules | true | true |
| RestrictNamespaces | true | true |
| NoNewPrivileges | не задан | ✅ true |
| RuntimeMaxSec | 1h | infinity |
| ip46tables | использовался (не существует) | iptables + ip6tables |
| Raw sockets для DPI-десинка | не работали | работают |
| Firewall reload | падал (ip46tables) | работает |

## Вывод

Модуль безопаснее неработающего. Единственное расширение поверхности — два
capabilities, без которых nfqws не может выполнять свою функцию. Все
остальные векторы заблокированы systemd-изоляцией на уровне nixpkgs.
