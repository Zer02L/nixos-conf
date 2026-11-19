# Security analysis: Zapret2 (nfqws2) DPI-bypass module

## Описание

`modules/services/zapret2.nix` — модуль DPI-bypass на базе Zapret2 (`nfqws2` v1.0.7+ с Lua-движком модификации пакетов), оборачивающий апстримный NixOS модуль `services.zapret2` с добавлением поддержки live-обновления конфигурации из `dotfiles/zapret/`.

## Архитектура

```
zapret2.nix (NixOS module)
  ├── networking.nftables       table inet zapret2 (postrouting + prerouting)
  │   ├── TCP 80, 443, 8443, 2053, 2083, 2087, 2096 (max 16 пакетов)
  │   └── UDP * (STUN, Discord IP discovery, QUIC 443)
  └── systemd.services."nfqws2@default"
      ├── preStart              Синхронизация списков и валидация zapret2.conf
      └── serviceConfig         (см. ниже)
```

## Полный serviceConfig

```ini
Type = "notify"
User = "root"
Group = "root"
ExecStart = nfqws2 @/var/lib/zapret2/zapret2.conf

# Изоляция (из апстримного nfqws2@.service + drop-in)
DevicePolicy              = closed
LockPersonality           = true
PrivateDevices            = true
PrivateMounts             = true
PrivateTmp                = true
ProtectClock              = true
ProtectControlGroups      = true
ProtectHome               = read-only
ProtectHostname           = true
ProtectKernelLogs         = true
ProtectKernelModules      = true
ProtectKernelTunables     = true
ProtectProc               = invisible
ProtectSystem             = full
RemoveIPC                 = true
RestrictNamespaces        = true
RestrictRealtime          = true
RestrictSUIDSGID          = true
NoNewPrivileges           = true
SystemCallArchitectures   = native
SystemCallFilter          = @system-service
UMask                     = 0077

# Capabilities для raw sockets и NFQUEUE
AmbientCapabilities       = CAP_NET_ADMIN, CAP_NET_RAW
CapabilityBoundingSet     = CAP_NET_ADMIN, CAP_NET_RAW

# Директория состояния и прав
StateDirectory            = zapret2
StateDirectoryMode        = 0755
```

## Threat model

Модуль запускает `nfqws2` — бинарник на C с поддержкой Lua-скриптов десинка, перехватывающий сетевые пакеты через NFQUEUE (до 16 пакетов на сессию) и выполняющий desync (разбиение TLS ClientHello, фейковые пакеты).
Атакующий вектор: теоретический RCE через уязвимость в парсере пакетов/Lua или компрометация бинарника.

## Capabilities (ослабления)

| Capability | Зачем |
|---|---|
| `CAP_NET_RAW` | raw socket — отправка поддельных TLS/QUIC handshake пакетов (`fake`) |
| `CAP_NET_ADMIN` | взаимодействие с NFQUEUE, привязка к исходящим интерфейсам (`bind-fix`), маркировка пакетов |

Всё остальное (загрузка модулей ядра, write-доступ к `/proc/sys`, модификация `/home`, монтирование, создание SUID-файлов) — заблокировано `CapabilityBoundingSet` и жесткой изоляцией systemd.

## Границы безопасности при компрометации

При гипотетической RCE в nfqws2 атакующий получает root внутри изолированного unit:

| Действие | Возможно? | Причина |
|---|---|---|
| Создать raw socket | ✅ | `CAP_NET_RAW` — штатная функция сервиса |
| Манипулировать пакетами | ✅ | `CAP_NET_ADMIN` — штатная функция сервиса |
| Открывать outbound соединения | ✅ | не ограничено (так работает DPI-bypass) |
| Установить персистентное ПО | ❌ | `ProtectSystem=full`, `/usr` и `/nix/store` r/o |
| Прочитать `/home` | ✅ (r/o) | `ProtectHome=read-only` (чтение списков из dotfiles) |
| Записать в `/home`, `/root` | ❌ | `ProtectHome=read-only` (запись запрещена) |
| Загрузить kernel-модуль | ❌ | `ProtectKernelModules=true` |
| Трогать sysctl | ❌ | `ProtectKernelTunables=true` |
| Увидеть чужие процессы | ❌ | `ProtectProc=invisible` |
| Поднять привилегии выше | ❌ | `CapabilityBoundingSet` урезан, `NoNewPrivileges=true` |
| Создать namespace | ❌ | `RestrictNamespaces=true` |
| Модифицировать Nix store | ❌ | immutable + `ProtectSystem` |
| Модифицировать `/run`, `/tmp` | ✅ | штатная работа (временные файлы валидации) |

## Трейд-оффы

### User=root vs DynamicUser

Апстримный NixOS-модуль использует `DynamicUser=true` со `StateDirectory=zapret2`. Это приводило к двум критическим проблемам:
1. `DynamicUser` с `StateDirectory` создает директорию внутри `/var/lib/private/` с правами `0700 root:root`. В результате пользовательские утилиты проверки (`zapret-test`, `scripts/zapret-tool show`) не имели доступа к файлам списков и автодетекта без `sudo`.
2. Эфемерный unprivileged пользователь не мог читать пользовательские файлы конфигурации в `/home/zerg` (права директории `0700`).

Решение: запуск от `User=root` с `ProtectHome=read-only` и `StateDirectoryMode=0755`. Это сохраняет безопасность (запись в `/home` исключена, capabilities ограничены), но обеспечивает надежное чтение dotfiles и прозрачную работу пользовательских CLI-инструментов.
