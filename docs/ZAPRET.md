# DOX framework

## Purpose

DPI bypass configuration for zapret (nfqws) service (`modules/services/zapret.nix`).
Hostlist/ipset files in `dotfiles/zapret/lists/` are referenced at build time
and copied into the Nix store. Strategy parameters are defined in `.args` files
in `dotfiles/zapret/strategies/`.

## Ownership

Active. Owned by zerg. Consumed by `services.zapret`.

## Local Contracts

- `dotfiles/zapret/lists/` — hostlist and ipset files for nfqws per-domain filtering
- `dotfiles/zapret/strategies/` — `.args` файлы с блоками стратегий, разделёнными `--new`
- `dotfiles/zapret/blobs/` — бинарники TLS/QUIC/STUN для `--dpi-desync-fake-*`
- List files (`list-*.txt`, `ipset-*.txt`) tracked in Git; Nix flake requires `git add`
- **Самостоятельный модуль** — не использует `services.zapret` из nixpkgs.
  systemd unit, capabilities, iptables определяются напрямую.
- Изоляция: `ProtectKernelModules`, `ProtectKernelTunables`,
  `RestrictNamespaces`, `NoNewPrivileges` — `true`.
  Единственное ослабление: `CAP_NET_ADMIN` + `CAP_NET_RAW`
  в `AmbientCapabilities`/`CapabilityBoundingSet` (raw sockets).
- Iptables: `iptables` + `ip6tables` раздельно (без `ip46tables` — его нет на NixOS).
  UDP range'ы — через `--dport` с `:`, не через multiport.

NixOS module: `modules/services/zapret.nix`. Standalone — не использует `services.zapret`.

Service: `zapret` (systemd) — single nfqws instance with NFQUEUE.

PreStart: модули ядра + ipset `nozapret`.
Модули также в `boot.kernelModules`.

Iptables (`networking.firewall.extraCommands`):
- TCP: 80, 443, 8443, 2053, 2083, 2087, 2096
- UDP: 443, 19294-19344, 50000-50100

## Security

See [SECURITY.md](./SECURITY.md) for full threat model, capability analysis,
isolation boundaries, and trade-offs.
## Work Guidance

### Смена стратегии

В `modules/services/zapret.nix` переключить `strategyFile`:
```nix
strategyFile = ../../dotfiles/zapret/strategies/default.args;  # базовая
# strategyFile = ../../dotfiles/zapret/strategies/alt12.args;  # агрессивная (ALT12)
```

### Обновление hostlist-файлов

1. Отредактировать файлы в `dotfiles/zapret/lists/`
2. `git add` — иначе Nix flake не увидит изменения
3. `sudo nixos-rebuild switch --flake .#zerg`

### Добавление новых blob-файлов

Положить в `dotfiles/zapret/blobs/`, добавить подстановку `@blobs@/<filename>` в `modules/services/zapret.nix` (строка: `[ "@lists@" "@blobs@" ]` уже включает все файлы из blobs/).

## Verification

```bash
sudo nixos-rebuild switch --flake .#zerg
systemctl status zapret --no-pager
journalctl -u zapret -n 20 --no-pager
# Проверить capabilities:
cat /proc/$(cat /run/nfqws.pid)/status | grep -i cap
# Проверить модули:
lsmod | grep -E 'xt_NFQUEUE|xt_connbytes|xt_multiport'
# Проверить ipset:
sudo ipset list nozapret
```

## Child Doc Shape

- Create a child AGENTS.md when a folder becomes a durable boundary with its own purpose, rules, responsibilities, workflow, materials, or quality standards
- Work Guidance must reflect the current standards of the project or user instructions; if there are no specific standards or instructions yet, leave it empty
- Verification must reflect an existing check; if no verification framework exists yet, leave it empty and update it when one exists

Default section order:
- Purpose
- Ownership
- Local Contracts
- Work Guidance
- Verification
- Child DOX Index

## Style

- Keep docs concise, current, and operational
- Document stable contracts, not diary entries
- Put broad rules in parent docs and concrete details in child docs
- Prefer direct bullets with explicit names
- Do not duplicate rules across many files unless each scope needs a local version
- Delete stale notes instead of explaining history
- Trim obvious statements, repeated rules, misplaced detail, and warnings for risks that no longer exist

## Closeout

1. Re-check changed paths against the DOX chain
2. Update nearest owning docs and any affected parents or children
3. Refresh every affected Child DOX Index
4. Remove stale or contradictory text
5. Run existing verification when relevant
6. Report any docs intentionally left unchanged and why

## User Preferences

When the user requests a durable behavior change, record it here or in the relevant child AGENTS.md

Before any SWAP/DEL edit from a structural summary: read the target range in `:raw` mode first to confirm no elided lines between the visible rows.

## Child DOX Index

| Path | Covers |
|---|---|
| `dotfiles/` | Raw dotfiles symlinked into ~/.config via mkOutOfStoreSymlink |
| `home/` | Home-manager user configurations and shared modules |
| `hosts/` | Per-machine NixOS host configurations (disko, hardware, host-specific imports) |
| `modules/` | NixOS system-level modules (services, hardware, programs, networking, users) |
| `parts/` | Flake-parts модули: nixosConfigurations, homeConfigurations, nixosModules, homeManagerModules, devShells, formatter |
