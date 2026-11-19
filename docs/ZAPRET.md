# DOX framework

## Purpose

DPI bypass configuration using Zapret2 (`nfqws2` with Lua-based packet mangling engine) via `modules/services/zapret2.nix` wrapping the upstream NixOS `services.zapret2` module.

## Ownership

Active. Owned by zerg. Consumed by `profiles/mixins/vpn-suite.nix` via `services.custom-zapret.enable`.

## Local Contracts

- **Core binary**: `pkgs.zapret2` (`nfqws2`).
- **Engine**: Lua modules `zapret-lib.lua` and `zapret-antidpi.lua`.
- **Systemd Service**: `nfqws2@default.service` running as a sandboxed system service (`DynamicUser=true`, `CAP_NET_ADMIN`, `CAP_NET_RAW`).
- **Firewall Integration**: Native `networking.nftables` (`table inet zapret2`), queue `200`, fwmark `0x40000000`. Only the first 16 packets per connection are forwarded to NFQUEUE (`maxPackets = 16`). Local RFC 1918 networks are automatically bypassed in nftables.
- **Profiles**:
  1. `http` (priority 100): TCP port 80, `http_req`, `--lua-desync=http_methodeol`.
  2. `https-critical` (priority 200): TCP ports 80, 443, 8443, 2053, 2083, 2087, 2096 with immediate desync for critical services (YouTube, Discord, etc.).
  3. `https-general` (priority 300): TCP ports 80, 443, 8443, 2053, 2083, 2087, 2096 with automatic block detection (`hosts.autodetect.enable = true`).
  4. `discord-voice` (priority 400): UDP with payload detection for `stun,discord_ip_discovery` and fake desync packets.
  5. `quic` (priority 500): UDP port 443 with fake QUIC initial desync.
- **Hostlists & State**:
  - Auto-detected hosts persist under `/var/lib/zapret2/`.
  - Excluded domains (`.ru` and `dotfiles/zapret/lists/list-exclude.txt`) bypass DPI desync completely.
  - Gaming UDP ports (e.g. Steam/Darktide) are unaffected as only STUN/Discord and QUIC are intercepted.

## Work Guidance

### Включение и отключение
Сервис настраивается через опцию `services.custom-zapret`:
```nix
# Включение (по умолчанию включено в profiles/mixins/vpn-suite.nix)
services.custom-zapret.enable = true;

# Полное отключение
services.custom-zapret.enable = false;
```

### Добавление хостов и исключений
В [modules/services/zapret2.nix](file:///home/zerg/nixos-conf/modules/services/zapret2.nix) или в конфигурации хоста:
```nix
services.custom-zapret = {
  includeDomains = [ "example.com" ]; # Всегда десинхронизировать сразу
  excludeDomains = [ "bank.ru" ];     # Никогда не десинхронизировать
};
```
Списки из [dotfiles/zapret/lists/](file:///home/zerg/nixos-conf/dotfiles/zapret/lists) подгружаются автоматически при сборке.

### Приватные и локальные списки (не попадают в Git)
- **Личные серверы / VPS:** добавить в `dotfiles/zapret/lists/private-exclude.txt` (файл в `.gitignore`, никогда не попадёт на GitHub).
- **Личные сайты для обхода:** добавить в `dotfiles/zapret/lists/private-include.txt` (также в `.gitignore`).
При старте службы `nfqws2@default` эти файлы автоматически подхватываются из `dotfiles` или `~/.config/zapret2/`.

### Утилита управления историей (`scripts/zapret-tool`)
В репозитории доступен скрипт [scripts/zapret-tool](file:///home/zerg/nixos-conf/scripts/zapret-tool):
```bash
# 1. Посмотреть автодетектированные домены
./scripts/zapret-tool show

# 2. Интерактивно выбрать (через fzf) проверенные сайты и перенести в публичный list-general.txt
./scripts/zapret-tool promote

# 3. Зашифровать все автодетектированные домены в secrets.yaml через SOPS
./scripts/zapret-tool backup-sops

# 4. Быстро добавить личный домен в локальный uncommitted private-exclude.txt
./scripts/zapret-tool add-private my-vps.org
```

## Verification

```bash
# Проверить статус демона nfqws2:
systemctl status nfqws2@default.service --no-pager

# Проверить последние логи демона:
journalctl -u nfqws2@default.service -n 50 --no-pager

# Проверить активные правила nftables для zapret2:
sudo nft list table inet zapret2

# Проверить доступность YouTube и Discord:
curl -Iv https://www.youtube.com
curl -Iv https://discord.com
```
