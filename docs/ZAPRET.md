# Zapret2 (DPI Bypass) Operational Runbook

## Purpose

DPI bypass configuration using Zapret2 (`nfqws2` with Lua-based packet mangling engine) via `modules/services/zapret2.nix` wrapping the upstream NixOS `services.zapret2` module.
Designed for zero-rebuild live updates: all domain lists and desync strategies are managed in `dotfiles/zapret/` and can be reloaded or restarted without `nixos-rebuild switch`.

## Ownership

Active. Owned by zerg. Consumed by `profiles/mixins/vpn-suite.nix` via `services.custom-zapret.enable`.

## Local Contracts

- **Core binary**: `pkgs.zapret2` (`nfqws2`).
- **Engine**: Lua modules `zapret-lib.lua` and `zapret-antidpi.lua` symlinked to `/var/lib/zapret2/lua/`.
- **Systemd Service**: `nfqws2@default.service` running as a hardened system service (`User=root`, `ProtectHome=read-only`, `StateDirectoryMode=0755`, `CAP_NET_ADMIN`, `CAP_NET_RAW`). Auto-detected hosts in `/var/lib/zapret2/` are readable without root privileges.
- **Firewall Integration**: Native `networking.nftables` (`table inet zapret2`), queue `200`, fwmark `0x40000000`. Only the first 16 packets per connection are forwarded to NFQUEUE (`maxPackets = 16`). Local RFC 1918 networks are automatically bypassed in nftables.
- **Live Configuration Source**:
  - Main config: [dotfiles/zapret/zapret2.conf](file:///home/zerg/nixos-conf/dotfiles/zapret/zapret2.conf)
  - Domain lists: [dotfiles/zapret/lists/](file:///home/zerg/nixos-conf/dotfiles/zapret/lists/)
  - Synced to `/var/lib/zapret2/` in `preStart` with automatic `#` comment stripping, syntax validation, and fallback to the nix store copy if the repo path is absent.
  - Automatic fallback: if `zapret2.conf` has invalid syntax, `preStart` preserves and reverts to `zapret2.conf.last-good` to prevent daemon downtime.
- **Profiles** (in priority order):
  1. `http` (priority 100): TCP port 80, `http_req`, `--lua-desync=http_methodeol`.
  2. `https-nofake` (priority 150): TCP ports 443, 8443, 2053, 2083, 2087, 2096 with pure `--lua-desync=multisplit:pos=1,midsld` (no fake packets) for servers that drop connections on fake TLS packets (AWS CloudFront, Atoma Cloud, Darktide from `list-nofake.txt`).
  3. `https-critical` (priority 200): TCP ports 443, 8443, etc. with `--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:repeats=1` and `fakedsplit` for YouTube, Discord, and general services (`list-general.txt`, `list-google.txt`, `private-include.txt`).
  4. `https-general` (priority 300): TCP ports 443, 8443, etc. with automatic block detection (`hosts.autodetect.enable = true` writing to `https-general-hosts.txt`).
  5. `discord-voice` (priority 400): UDP with payload detection for `stun,discord_ip_discovery` and fake desync packets.
  6. `quic` (priority 500): UDP port 443 with fake QUIC initial desync.
- **Hostlists & State**:
  - Auto-detected hosts persist under `/var/lib/zapret2/` (`0755` directory, files `0644`).
  - Excluded domains (`.ru` and `dotfiles/zapret/lists/list-exclude.txt`) bypass DPI desync completely.
  - Gaming UDP ports (e.g. Steam / Darktide matchmaker) are unaffected as only STUN/Discord and QUIC are intercepted.

## Work Guidance

### Управление на лету (без пересборки системы)

Для работы с Zapret2 в систему установлены пользовательские консольные утилиты (запускаются от обычного пользователя; при необходимости управления службой они запросят `sudo`):

```bash
# 1. Быстро перезагрузить списки без разрыва соединений (посылает SIGHUP):
zapret-reload

# 2. Перезапустить службу с предварительной проверкой синтаксиса zapret2.conf:
zapret-restart

# 3. Проверить синтаксис dotfiles/zapret/zapret2.conf перед перезапуском:
zapret-test

# 4. Проверить статус службы и последние логи:
zapret-status
```

*Эквиваленты через systemctl:*
* `sudo systemctl reload nfqws2@default` (синхронизирует `lists/` и шлет `SIGHUP`)
* `sudo systemctl restart nfqws2@default` (синхронизирует конфиг и перезапускает)

### Редактирование списков доменов

Все файлы списков находятся в [dotfiles/zapret/lists/](file:///home/zerg/nixos-conf/dotfiles/zapret/lists/):
* **[list-nofake.txt](file:///home/zerg/nixos-conf/dotfiles/zapret/lists/list-nofake.txt)**: домены, которые сбрасывают сессию при получении фейковых пакетов (`fatsharkgames.se`, `atoma.cloud`, `amazonaws.com`, `cloudfront.net`). Для них используется чистый `multisplit`.
* **[list-general.txt](file:///home/zerg/nixos-conf/dotfiles/zapret/lists/list-general.txt)**: основные заблокированные ресурсы (Discord, расширения, сторонние сервисы), для которых требуется `fake`.
* **[list-google.txt](file:///home/zerg/nixos-conf/dotfiles/zapret/lists/list-google.txt)**: YouTube и домены сервисов Google.
* **[list-exclude.txt](file:///home/zerg/nixos-conf/dotfiles/zapret/lists/list-exclude.txt)**: исключения (.ru, банки, госуслуги, VK).

> [!IMPORTANT]
> **Синтаксис списков**: Указывайте только доменные имена (суффиксы) без протокола (`https://`) и без подстановочных символов (`*`).
> - Правильно: `discord.com`, `googlevideo.com`, `fatsharkgames.se`
> - Неправильно: `https://discord.com`, `*.discord.com`, `discord.com/`
> Zapret2 выполняет поддоменный матчинг автоматически (запись `atoma.cloud` покрывает `bsp-auth-prod.atoma.cloud`).

*После добавления или удаления домена достаточно выполнить:*
```bash
zapret-reload
```

### Редактирование стратегий и параметров

Файл [dotfiles/zapret/zapret2.conf](file:///home/zerg/nixos-conf/dotfiles/zapret/zapret2.conf) содержит все флаги, очереди, профили и LUA-десинхронизаторы:
1. Отредактируйте нужный профиль (например, измените стратегию `multisplit` на `split2` или скорректируйте `pos=...`).
2. Проверьте синтаксис:
   ```bash
   zapret-test
   ```
3. Примените изменения:
   ```bash
   zapret-restart
   ```

> [!NOTE]
> Добавление новых TCP/UDP-портов перехвата (например, нестандартный порт 8080) настраивается на уровне nftables в опции `services.custom-zapret.tcpPorts` файла [modules/services/zapret2.nix](file:///home/zerg/nixos-conf/modules/services/zapret2.nix) и требует пересборки системы (`nixos-rebuild switch`).

### Приватные и локальные списки (не попадают в Git)

- **Личные серверы / VPS:** добавить в `dotfiles/zapret/lists/private-exclude.txt` (в `.gitignore`) либо через утилиту `./scripts/zapret-tool add-private`.
- **Личные сайты для обхода:** добавить в `dotfiles/zapret/lists/private-include.txt` (в `.gitignore`).
- **Секреты SOPS:**
  - `/run/secrets/zapret_private_hosts` (при объявлении секрета в `secrets.yaml`) автоматически объединяется с `private-include.txt`.
  - `/run/secrets/zapret_private_exclude` (при объявлении секрета в `secrets.yaml` или через `./scripts/zapret-tool exclude-sops <домен/IP>`) автоматически объединяется с `private-exclude.txt` для исключения личных VPS/VPN серверов.

### Сосуществование с VPN (Split Tunneling)

Для предотвращения конфликтов Zapret привязывается строго к физическим сетевым интерфейсам (`enp6s0`, `wlp5s0`), исключая виртуальные туннельные интерфейсы VPN (`happ-xray`, `tun*`, `awg*`, `warp*`):
```nix
services.custom-zapret.interfaces = [ "enp6s0" "wlp5s0" ];
```
При включенном VPN трафик, помеченный в VPN-клиенте (например, Happ) как `Direct` (в частности Discord), выходит через физический интерфейс и обрабатывается Zapret, а весь туннельный трафик VPN проходит без вмешательства.

### Включение и отключение в NixOS

Сервис настраивается декларативно в [modules/services/zapret2.nix](file:///home/zerg/nixos-conf/modules/services/zapret2.nix) и включен по умолчанию:
```nix
# Включение (в profiles/mixins/vpn-suite.nix)
services.custom-zapret.enable = true;

# Полное отключение (выключает демон и правила nftables)
services.custom-zapret.enable = false;
```
> [!NOTE]
> Изменение опций на уровне NixOS требует пересборки системы:
> ```bash
> sudo nixos-rebuild switch --flake /home/zerg/nixos-conf#zerg
> ```

---

## Troubleshooting

### 1. Экстренное отключение без пересборки (Emergency Bypass)
Если соединение зависает или `nfqws2` блокирует нужный трафик, отключить обход можно мгновенно:
```bash
# 1. Остановить службу
sudo systemctl stop nfqws2@default

# 2. Удалить таблицу правил перехвата из nftables
sudo nft delete table inet zapret2
```
*Для обратного включения (обязательно восстанавливаем таблицу nftables перед запуском):*
```bash
sudo systemctl restart nftables
sudo systemctl start nfqws2@default
```

### 2. Сайт сбрасывает сессию (TCP RST / Cloudflare / Atoma Cloud)
Если ресурс сбрасывает соединение при подключении:
1. Перенесите домен из `list-general.txt` в [dotfiles/zapret/lists/list-nofake.txt](file:///home/zerg/nixos-conf/dotfiles/zapret/lists/list-nofake.txt) (для него применится мягкий `multisplit` без фейковых пакетов).
2. Выполните:
   ```bash
   zapret-reload
   ```
3. Если ресурс является российским и не должен проходить через обход DPI — добавьте его в [dotfiles/zapret/lists/list-exclude.txt](file:///home/zerg/nixos-conf/dotfiles/zapret/lists/list-exclude.txt).

### 3. Очистка кэша автодетекта (Autodetect Cache Reset)
Если в автоматический список попали ложные блокировки:
```bash
# Просмотреть обнаруженные хосты
./scripts/zapret-tool show

# Очистить кэш автодетекта и перезагрузить службу
truncate -s 0 /var/lib/zapret2/https-general-hosts.txt
zapret-reload
```

### 4. Логи в реальном времени и предупреждения fallback
```bash
# Логи службы в реальном времени
sudo journalctl -u nfqws2@default.service -f

# Проверка сообщений об ошибках или откате на last-good
sudo journalctl -u nfqws2@default.service -e | grep -E "(WARNING|ERROR|could not load)"
```

---

## Verification

```bash
# 1. Проверить статус демона nfqws2:
zapret-status

# 2. Проверить синтаксис конфигурации dotfiles:
zapret-test

# 3. Проверить последние логи службы:
sudo journalctl -u nfqws2@default.service -n 50 --no-pager

# 4. Проверить правила и счетчики nftables (таблица должна существовать и накапливать пакеты):
sudo nft list table inet zapret2

# 5. Проверить HTTPS-доступность по профилям десинхронизации (ожидается HTTP 200, 301 или 302):
# Тест профиля https-critical (fake TLS desync для YouTube):
curl --connect-timeout 5 -m 10 -Iv https://www.youtube.com

# Тест профиля https-critical / general (Discord API / CDN):
curl --connect-timeout 5 -m 10 -Iv https://discord.com

# Тест профиля https-nofake (чистый multisplit без фейков для серверов Darktide/AWS):
curl --connect-timeout 5 -m 10 -Iv https://auth.fatsharkgames.se
```
